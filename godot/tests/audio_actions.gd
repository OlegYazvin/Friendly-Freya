extends SceneTree

const ActionAudioScript = preload("res://scripts/action_audio.gd")

class CueProbe:
	extends Node
	var cues: Array[String] = []

	func play(cue_id: String, _volume_db: float = 0.0) -> void:
		cues.append(cue_id)

	func stop_cue(_cue_id: String) -> void:
		pass

var failures: Array[String] = []


func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("AUDIO_ACTIONS: " + message)


func _test_lone_imp_bark(scene: Node3D) -> void:
	# Main intentionally skips audio setup in headless mode. Install one real
	# aggressive recording and player so this test exercises the normal bark
	# selection/playback path without needing an audio device.
	var bark_path: String = str(scene.BARK_AGGRESSIVE_SAMPLE_CANDIDATES[0])
	var bark_stream: AudioStream = ResourceLoader.load(bark_path, "AudioStream") as AudioStream
	_check(bark_stream != null, "recorded aggressive bark asset could not load")
	if bark_stream == null:
		return
	var bark_player = AudioStreamPlayer.new()
	scene.add_child(bark_player)
	scene.bark_sfx_players.append(bark_player)
	scene.bark_sfx_streams_aggressive.append(bark_stream)
	var saved_dogs: Array = scene.dogs
	var saved_position: Vector3 = scene.freya.global_position
	scene.dogs = []
	scene.freya.global_position = Vector3(5.0, 0.0, 5.0)
	_check(scene._nearest_caged_kennel_dog().is_empty(), "imp-only test point overlaps a kennel cage")
	var imp = Node3D.new()
	scene.add_child(imp)
	imp.global_position = scene.freya.global_position + Vector3(1.0, 0.0, 0.0)
	var cursor_before: int = scene.bark_sfx_cursor
	scene.world_time = 10.0
	Input.action_press("aggressive_social")
	_check(scene._imp_interrupted_by_defenders({}, imp, scene.IMP_BARK_INTERRUPT_TIME + 0.01), "R did not stop the lone imp")
	_check(scene.bark_sfx_cursor == cursor_before + 1, "R stopped a lone imp without playing Freya's bark")
	if scene.bark_sfx_cursor == cursor_before + 1:
		var player_index = cursor_before % scene.bark_sfx_players.size()
		var played: AudioStream = scene.bark_sfx_players[player_index].stream
		_check(played != null and scene.bark_sfx_streams_aggressive.has(played), "imp-only bark did not use the recorded aggressive pool")
	scene._imp_interrupted_by_defenders({}, imp, 0.01)
	_check(scene.bark_sfx_cursor == cursor_before + 1, "nearby imps stacked duplicate Freya barks in one sound gap")
	scene.world_time += scene.IMP_ISOLATED_BARK_SOUND_GAP + 0.01
	scene._imp_interrupted_by_defenders({}, imp, 0.01)
	_check(scene.bark_sfx_cursor == cursor_before + 2, "sustained isolated defense did not repeat a real bark after the gap")
	if not saved_dogs.is_empty():
		var state: Dictionary = saved_dogs[0]
		var dog: Node3D = state.get("node", null)
		var saved_dog_position = dog.global_position
		dog.global_position = scene.freya.global_position + Vector3(0.8, 0.0, 0.0)
		state["army_aligned"] = false
		scene.dogs = [state]
		scene.world_time += 1.0
		scene._imp_interrupted_by_defenders({}, imp, 0.01)
		_check(scene.bark_sfx_cursor == cursor_before + 2, "imp cue doubled the existing nearby-dog bark interaction")
		dog.global_position = saved_dog_position
	Input.action_release("aggressive_social")
	if not saved_dogs.is_empty():
		var state: Dictionary = saved_dogs[0].duplicate()
		var dog: Node3D = state.get("node", null)
		var saved_dog_position: Vector3 = dog.global_position
		var saved_order: String = scene.pack_order
		dog.global_position = imp.global_position
		state["army_aligned"] = true
		state["alien_possessed"] = false
		scene.dogs = [state]
		scene.pack_order = scene.PACK_ORDER_GUARD
		scene.world_time = 30.0
		var pack_cursor: int = scene.bark_sfx_cursor
		_check(scene._imp_interrupted_by_defenders({}, imp, scene.IMP_PACK_CONTAIN_TIME + 0.01), "pack defender did not stop the imp")
		_check(scene.bark_sfx_cursor == pack_cursor + 1, "pack-only imp intercept did not play one recorded aggressive bark")
		if scene.bark_sfx_cursor == pack_cursor + 1:
			var pack_player_index: int = pack_cursor % scene.bark_sfx_players.size()
			_check(scene.bark_sfx_streams_aggressive.has(scene.bark_sfx_players[pack_player_index].stream), "pack defender used an unrelated bark recording")
		scene._imp_interrupted_by_defenders({}, imp, scene.IMP_PACK_CONTAIN_TIME + 0.01)
		_check(scene.bark_sfx_cursor == pack_cursor + 1, "simultaneous imp intercepts stacked pack barks")
		scene.world_time += scene.IMP_PACK_BARK_SOUND_GAP + 0.01
		scene._imp_interrupted_by_defenders({}, imp, scene.IMP_PACK_CONTAIN_TIME + 0.01)
		_check(scene.bark_sfx_cursor == pack_cursor + 2, "later pack intercept did not play another recorded bark")
		dog.global_position = saved_dog_position
		scene.pack_order = saved_order
	scene.dogs = saved_dogs
	scene.freya.global_position = saved_position
	bark_player.stop()
	bark_player.stream = null
	scene.bark_sfx_players.erase(bark_player)
	scene.bark_sfx_streams_aggressive.erase(bark_stream)
	bark_player.free()
	imp.queue_free()


func _stage_imp_at_dog(scene: Node3D, dog_position: Vector3) -> void:
	var imp = Node3D.new()
	scene.add_child(imp)
	imp.global_position = dog_position + Vector3(0.3, 0.0, 0.0)
	scene.free_aliens.append({
		"node": imp,
		"phase": "seek_dog",
		"dog_target_index": 0,
		"dog_transfer_timer": 0.0,
		"interrupt_progress": 0.0
	})


func _test_imp_transfer_window(scene: Node3D) -> bool:
	_check(not scene.dogs.is_empty(), "no dog available for the imp transfer test")
	if scene.dogs.is_empty():
		return false
	var saved_dogs: Array = scene.dogs
	var saved_stores: Array[int] = scene.store_building_indices.duplicate()
	var saved_freya_position: Vector3 = scene.freya.global_position
	var state: Dictionary = saved_dogs[0].duplicate()
	var dog: Node3D = state.get("node", null)
	_check(dog != null and is_instance_valid(dog), "imp transfer target has no live dog")
	if dog == null or not is_instance_valid(dog):
		return false
	var saved_dog_position: Vector3 = dog.global_position
	var park: Vector2 = scene.dog_park.get_center()
	var dog_position = Vector3(park.x, 0.0, park.y)
	dog.global_position = dog_position
	scene.freya.global_position = dog_position + Vector3(1.4, 0.0, 0.0)
	state["alien_possessed"] = false
	state["possession_immune"] = false
	state["has_dog_armor"] = false
	state["army_aligned"] = false
	scene.dogs = [state]
	scene.store_building_indices.clear()
	scene._clear_free_aliens()
	_stage_imp_at_dog(scene, dog_position)
	scene._update_free_aliens(0.01)
	_check(scene.status_label.text == "An imp is reaching for a dog — bark or guard it!", "contact did not show the imp transfer warning")
	scene._update_free_aliens(2.0)
	_check(scene.free_aliens.size() == 1 and not bool(scene.dogs[0].get("alien_possessed", false)), "dog was transferred before the two-second reading window")
	if scene.free_aliens.size() == 1:
		Input.action_press("aggressive_social")
		scene._update_free_aliens(0.22)
		scene._update_free_aliens(0.22)
		Input.action_release("aggressive_social")
		_check(scene.free_aliens.is_empty() and not bool(scene.dogs[0].get("alien_possessed", false)), "R could not intercept the imp after two seconds")
	scene._clear_free_aliens()
	state = scene.dogs[0]
	state["alien_possessed"] = false
	scene.dogs[0] = state
	_stage_imp_at_dog(scene, dog_position)
	scene._update_free_aliens(0.01)
	scene._update_free_aliens(2.0)
	_check(scene.free_aliens.size() == 1 and not bool(scene.dogs[0].get("alien_possessed", false)), "unopposed transfer completed before two seconds")
	scene._update_free_aliens(2.5)
	_check(scene.free_aliens.is_empty() and bool(scene.dogs[0].get("alien_possessed", false)), "unopposed imp transfer did not eventually resolve")
	_check(scene.status_label.text == "The imp slipped into a dog. Watch Freya's senses.", "successful imp transfer did not replace its warning")
	scene._clear_free_aliens()
	dog.global_position = saved_dog_position
	scene.dogs = saved_dogs
	scene.store_building_indices.append_array(saved_stores)
	scene.freya.global_position = saved_freya_position
	return true


func _test_park_drill_reward(scene: Node3D) -> void:
	_check(not scene.dog_park_training_items.is_empty(), "no park drill available")
	if scene.dog_park_training_items.is_empty():
		return
	var probe = CueProbe.new()
	scene.add_child(probe)
	var saved_audio: Node = scene.action_audio
	scene.action_audio = probe
	var item: Dictionary = scene.dog_park_training_items[0]
	var path: PackedVector3Array = item.get("path", PackedVector3Array())
	_check(path.size() >= 2, "park drill path is incomplete")
	if path.size() < 2:
		return
	var kind: String = str(item.get("kind", ""))
	var duration: float = float(item.get("duration", 1.6))
	scene.dog_park_training_completed.clear()
	scene.freya.global_position = path[0]
	scene.active_dog_park_training = {
		"kind": kind,
		"route": path,
		"approach_start": path[0],
		"elapsed": 0.0,
		"duration": duration
	}
	scene._update_dog_park_training(scene.DOG_PARK_TRAINING_APPROACH_SEC + duration + 0.01)
	_check(scene.dog_park_training_completed.has(kind), "first park drill did not complete")
	_check(probe.cues.count("claim") == 1, "first park drill did not play the exact recorded reward cue")
	_check(ResourceLoader.exists(str(ActionAudioScript.CUE_PATHS["claim"]), "AudioStream"), "recorded drill reward asset is unavailable")
	scene.active_dog_park_training = {
		"kind": kind,
		"route": path,
		"approach_start": path[0],
		"elapsed": 0.0,
		"duration": duration
	}
	scene._update_dog_park_training(scene.DOG_PARK_TRAINING_APPROACH_SEC + duration + 0.01)
	_check(probe.cues.count("claim") == 1, "repeat park drill replayed the first-time reward cue")
	scene.action_audio = saved_audio
	probe.queue_free()


func _test_storefront_spawn_cue(scene: Node3D) -> void:
	_check(not scene.store_building_indices.is_empty(), "no storefront generator available")
	if scene.store_building_indices.is_empty():
		return
	var cue_path: String = str(ActionAudioScript.CUE_PATHS.get("alien_emerge", ""))
	_check(cue_path == "res://assets/audio/actions/slime_squelch_433839.ogg", "storefront emergence does not use the exact recorded cue")
	_check(ResourceLoader.exists(cue_path, "AudioStream"), "recorded imp emergence asset is unavailable")
	var store_index: int = scene.store_building_indices[0]
	var saved_store: Dictionary = scene.buildings[store_index].duplicate()
	var saved_position: Vector3 = scene.freya.global_position
	var saved_audio: Node = scene.action_audio
	var probe = CueProbe.new()
	scene.add_child(probe)
	scene.action_audio = probe
	scene._clear_free_aliens()
	var store: Dictionary = scene.buildings[store_index]
	store["alien_occupied"] = true
	store["alien_spawn_cooldown"] = 0.0
	scene.buildings[store_index] = store
	var spawn_position: Vector3 = scene._free_alien_spawn_position(store_index)
	scene.freya.global_position = spawn_position + Vector3(0.0, 0.0, 1.0)
	scene._update_free_alien_generation(0.01)
	_check(scene.free_aliens.size() == 1, "occupied storefront did not generate a nearby imp")
	_check(probe.cues == ["alien_emerge"], "nearby storefront spawn did not request exactly one recorded emergence cue")
	store = scene.buildings[store_index]
	store["alien_spawn_cooldown"] = 0.0
	scene.buildings[store_index] = store
	scene.freya.global_position = spawn_position + Vector3(scene.FREE_ALIEN_SPAWN_AUDIO_RADIUS + 1.0, 0.0, 0.0)
	scene._update_free_alien_generation(0.01)
	_check(scene.free_aliens.size() == 2, "occupied storefront did not generate a distant imp")
	_check(probe.cues == ["alien_emerge"], "distant storefront spawn requested an audible or fallback cue")
	store = scene.buildings[store_index]
	store["alien_occupied"] = false
	store["alien_spawn_cooldown"] = 0.0
	scene.buildings[store_index] = store
	scene._update_free_alien_generation(0.01)
	_check(scene.free_aliens.size() == 2 and probe.cues == ["alien_emerge"], "unoccupied storefront produced an imp or cue")
	scene._clear_free_aliens()
	scene.buildings[store_index] = saved_store
	scene.freya.global_position = saved_position
	scene.action_audio = saved_audio
	probe.queue_free()
	# If the exact stream has no player, the audio service must leave another
	# cue's player untouched instead of selecting it as a replacement.
	var strict_audio = ActionAudioScript.new()
	var other_player = AudioStreamPlayer.new()
	other_player.volume_db = -17.0
	strict_audio.add_child(other_player)
	strict_audio._players["claim"] = other_player
	strict_audio.play("alien_emerge", -3.0)
	_check(strict_audio._players.size() == 1 and other_player.volume_db == -17.0, "missing exact emergence player fell back to another recording")
	strict_audio.free()


func _test_short_recorded_eating_and_vomit(scene: Node3D) -> void:
	var expected_eating = [
		{"path": scene.EAT_FOOD_SAMPLE_CANDIDATES[0], "max_length": 0.44},
		{"path": scene.EAT_BONE_SAMPLE_CANDIDATES[0], "max_length": 0.34},
		{"path": scene.EAT_POOP_SAMPLE_CANDIDATES[0], "max_length": 0.56},
		{"path": scene.EAT_POOP_SAMPLE_CANDIDATES[1], "max_length": 0.56}
	]
	for entry in expected_eating:
		var path: String = str(entry["path"])
		var stream: AudioStream = ResourceLoader.load(path, "AudioStream") as AudioStream
		_check(stream != null, "short recorded eating cue could not load: " + path)
		if stream != null:
			_check(stream.get_length() <= float(entry["max_length"]), "eating cue outlasts its pose: " + path)
	var family_path: String = str(ActionAudioScript.CUE_PATHS.get("family_pills_eaten", ""))
	var family_stream: AudioStream = ResourceLoader.load(family_path, "AudioStream") as AudioStream
	_check(family_stream != null, "recorded family pill-eating cue could not load")
	if family_stream != null:
		_check(family_stream.get_length() <= 1.2, "family pill-eating cue runs into the convulsion")
	var vomit_path: String = str(scene.VOMIT_SAMPLE_CANDIDATES[0])
	_check(vomit_path == "res://assets/audio/vomit/dog_gagging_135415.mp3", "vomit did not select the exact real gagging recording")
	var vomit_stream: AudioStream = ResourceLoader.load(vomit_path, "AudioStream") as AudioStream
	_check(vomit_stream != null, "recorded gagging cue could not load")
	if vomit_stream != null:
		_check(vomit_stream.get_length() <= 1.3, "vomit cue is longer than a brief gag")


func _test_story_and_captive_cues(scene: Node3D) -> void:
	var cry_path: String = str(ActionAudioScript.CUE_PATHS.get("ryah_cry", ""))
	var bottle_path: String = str(ActionAudioScript.CUE_PATHS.get("family_pills_landed", ""))
	_check(cry_path == "res://assets/audio/actions/girl_crying_ryah_218184.ogg", "Ryah cry is not mapped to the recorded voice excerpt")
	_check(bottle_path == "res://assets/audio/actions/plastic_bottle_landing_173597.ogg", "pill landing still maps to bottle shaking")
	var cry_stream: AudioStream = ResourceLoader.load(cry_path, "AudioStream") as AudioStream
	var bottle_stream: AudioStream = ResourceLoader.load(bottle_path, "AudioStream") as AudioStream
	_check(cry_stream != null and cry_stream.get_length() <= 1.8, "recorded Ryah cry is missing or outlasts its visual")
	_check(bottle_stream != null and bottle_stream.get_length() <= 0.82, "recorded pill bottle landing is missing or overlaps the next story cue")
	var saved_audio: Node = scene.action_audio
	var probe = CueProbe.new()
	scene.add_child(probe)
	scene.action_audio = probe
	var saved_time: float = scene.world_time
	scene.world_time = 40.0
	scene._trigger_ryah_alien_defense()
	scene._trigger_ryah_alien_defense()
	_check(probe.cues == ["ryah_cry"], "back-to-back alien attempts stacked Ryah cries")
	scene.world_time += scene.RYAH_CRY_AUDIO_GAP + 0.01
	scene._trigger_ryah_alien_defense()
	_check(probe.cues == ["ryah_cry", "ryah_cry"], "later Ryah defense did not replay its recorded cry")
	var whine_path: String = str(ActionAudioScript.CUE_PATHS.get("dog_whine", ""))
	_check(ResourceLoader.exists(whine_path, "AudioStream"), "recorded captive whine asset is missing")
	_check(scene.kennel != null and scene.kennel_building_index >= 0, "kennel unavailable for captive whine test")
	if scene.kennel != null and scene.kennel_building_index >= 0:
		var saved_position: Vector3 = scene.freya.global_position
		var saved_store_index: int = scene.active_store_index
		var saved_snapshot: Dictionary = scene._kennel_snapshot()
		var saved_building: Dictionary = scene.buildings[scene.kennel_building_index].duplicate()
		scene._clear_alien_occupation(scene.kennel_building_index)
		scene.kennel.depossess_caged_dog(0)
		scene.freya.global_position = scene.kennel.to_global(Vector3(-2.78, 0.0, -2.25))
		scene.active_store_index = scene.kennel_building_index
		scene._apply_store_focus_visuals()
		probe.cues.clear()
		scene.world_time = 50.0
		scene._update_kennel(0.01)
		_check(probe.cues == ["dog_whine"], "approaching an unpossessed caged dog did not play one recorded whine")
		scene._update_kennel(0.01)
		_check(probe.cues == ["dog_whine"], "stationary cage interaction repeated a whine every frame")
		scene.freya.global_position = Vector3(1000.0, 0.0, 1000.0)
		scene._update_kennel(0.01)
		scene.freya.global_position = scene.kennel.to_global(Vector3(-2.78, 0.0, -2.25))
		scene._update_kennel(0.01)
		_check(probe.cues == ["dog_whine"], "rapid re-entry stacked captive whines")
		scene.world_time += 2.61
		scene._update_kennel(0.01)
		_check(probe.cues == ["dog_whine", "dog_whine"], "approach during cooldown never played its recorded whine after the cooldown")
		scene.freya.global_position = Vector3(1000.0, 0.0, 1000.0)
		scene._update_kennel(0.01)
		scene.freya.global_position = scene.kennel.to_global(Vector3(-2.78, 0.0, -2.25))
		scene._update_kennel(0.01)
		_check(probe.cues == ["dog_whine", "dog_whine"], "rapid return after the delayed whine stacked captive whines")
		scene._restore_kennel_snapshot(saved_snapshot)
		scene.buildings[scene.kennel_building_index] = saved_building
		scene.freya.global_position = saved_position
		scene.active_store_index = saved_store_index
		scene._apply_store_focus_visuals()
	scene.world_time = saved_time
	scene.action_audio = saved_audio
	probe.queue_free()


func _test_kennel_spawn_cue(scene: Node3D) -> void:
	var cue_path: String = str(ActionAudioScript.CUE_PATHS.get("kennel_spawn_bark", ""))
	_check(cue_path == "res://assets/audio/barks/aggressive_bark_01.wav", "kennel spawn is not mapped to its exact recorded dog bark")
	_check(ResourceLoader.exists(cue_path, "AudioStream"), "recorded kennel spawn bark is unavailable")
	_check(scene.kennel != null and scene.kennel.possessed, "occupied kennel unavailable for spawn sound test")
	if scene.kennel == null or not scene.kennel.possessed:
		return
	var saved_position: Vector3 = scene.freya.global_position
	var saved_snapshot: Dictionary = scene._kennel_snapshot()
	var saved_audio: Node = scene.action_audio
	var probe = CueProbe.new()
	scene.add_child(probe)
	scene.action_audio = probe
	var spawn_position: Vector3 = scene.kennel.get_possessed_dog_spawn_world_position()
	scene.freya.global_position = spawn_position + Vector3(0.0, 0.0, 1.0)
	scene.kennel.spawn_timer = 0.01
	scene._update_kennel(0.02)
	_check(scene.kennel.total_possessed_dogs_spawned == int(saved_snapshot.get("total_possessed_dogs_spawned", 0)) + 1, "nearby kennel dog did not spawn successfully")
	_check(probe.cues == ["kennel_spawn_bark"], "nearby live kennel dog spawn did not request exactly one recorded bark")
	scene.freya.global_position = spawn_position + Vector3(scene.KENNEL_DOG_SPAWN_AUDIO_RADIUS + 3.0, 0.0, 0.0)
	scene.kennel.spawn_timer = 0.01
	scene._update_kennel(0.02)
	_check(scene.kennel.total_possessed_dogs_spawned == int(saved_snapshot.get("total_possessed_dogs_spawned", 0)) + 2, "distant kennel dog did not spawn successfully")
	_check(probe.cues == ["kennel_spawn_bark"], "distant kennel spawn requested an audible cue")
	scene.freya.global_position = spawn_position + Vector3(0.0, 0.0, 1.0)
	scene._on_kennel_possessed_dog_spawn_requested(spawn_position, 99)
	_check(probe.cues == ["kennel_spawn_bark"], "failed kennel registration requested a bark")
	scene._on_kennel_possessed_dog_spawn_requested(spawn_position, 3)
	_check(probe.cues == ["kennel_spawn_bark"], "unconfirmed kennel spawn requested a bark")
	_check(scene._restore_kennel_snapshot(saved_snapshot), "could not restore kennel after spawn sound test")
	_check(probe.cues == ["kennel_spawn_bark"], "restoring kennel dogs replayed the live spawn bark")
	scene.freya.global_position = saved_position
	scene.action_audio = saved_audio
	probe.queue_free()
	var strict_audio = ActionAudioScript.new()
	var other_player = AudioStreamPlayer.new()
	other_player.volume_db = -17.0
	strict_audio.add_child(other_player)
	strict_audio._players["claim"] = other_player
	strict_audio.play("kennel_spawn_bark", -3.0)
	_check(strict_audio._players.size() == 1 and other_player.volume_db == -17.0, "missing exact kennel bark player fell back to another recording")
	strict_audio.free()


func _test_quiet_occupation_restore(scene: Node3D) -> void:
	var kennel_index: int = scene.kennel_building_index
	_check(kennel_index >= 0 and scene.kennel != null, "kennel unavailable for quiet restore test")
	if kennel_index < 0 or scene.kennel == null:
		return
	var clean_index = -1
	for index in range(scene.buildings.size()):
		if index != kennel_index and index != scene.freya_home_index and not bool(scene.buildings[index].get("alien_occupied", false)) and not scene._building_is_controlled_by_freya(index):
			clean_index = index
			break
	_check(clean_index >= 0, "no clean building available for quiet restore test")
	if clean_index < 0:
		return
	var saved_kennel: Dictionary = scene.buildings[kennel_index].duplicate()
	var saved_clean: Dictionary = scene.buildings[clean_index].duplicate()
	var saved_kennel_snapshot: Dictionary = scene._kennel_snapshot()
	var saved_chapter_clears: int = scene.chapter_occupations_cleared
	var saved_audio: Node = scene.action_audio
	var saved_status: String = scene.status_label.text
	var probe = CueProbe.new()
	scene.add_child(probe)
	scene.action_audio = probe
	var kennel_id: String = scene._save_building_id_from_index(kennel_index)
	var clean_id: String = scene._save_building_id_from_index(clean_index)
	var saved_states: Dictionary = {}
	saved_states[kennel_id] = {"owner": "none", "alien_occupied": false}
	scene._restore_building_states(saved_states)
	_check(not scene.kennel.possessed, "saved clean kennel remained occupied")
	_check(probe.cues.is_empty() and scene.chapter_occupations_cleared == saved_chapter_clears, "clean-kennel restore played a cleanse cue or changed chapter progress")
	saved_states.clear()
	saved_states[clean_id] = {"owner": "none", "alien_occupied": true, "alien_occupant_serial": 444}
	scene._restore_building_states(saved_states)
	_check(bool(scene.buildings[clean_index].get("alien_occupied", false)), "saved alien hold was not restored")
	_check(probe.cues.is_empty() and scene.status_label.text == saved_status, "occupation restore played an emergence cue or showed a new-threat status")
	saved_states[clean_id] = {"owner": "none", "alien_occupied": false}
	scene._restore_building_states(saved_states)
	_check(probe.cues.is_empty() and scene.chapter_occupations_cleared == saved_chapter_clears, "clearing reconstructed alien hold played a cue or advanced the chapter")
	scene.buildings[kennel_index] = saved_kennel
	scene.buildings[clean_index] = saved_clean
	_check(scene._restore_kennel_snapshot(saved_kennel_snapshot), "could not restore kennel after quiet restore test")
	scene.chapter_occupations_cleared = saved_chapter_clears
	scene.action_audio = saved_audio
	probe.queue_free()


func _run() -> void:
	_check(change_scene_to_file("res://scenes/Main.tscn") == OK, "could not load Main")
	await scene_changed
	var scene: Node3D = current_scene
	scene.set_process(false)
	_test_lone_imp_bark(scene)
	_test_storefront_spawn_cue(scene)
	_test_park_drill_reward(scene)
	_test_short_recorded_eating_and_vomit(scene)
	_test_story_and_captive_cues(scene)
	_check(_test_imp_transfer_window(scene), "timed imp transfer test aborted")
	_test_kennel_spawn_cue(scene)
	_test_quiet_occupation_restore(scene)
	await process_frame
	if failures.is_empty():
		print("AUDIO_ACTIONS_OK: recorded imp barks, captive whine, Ryah cry, pill landing, near-only kennel and storefront spawns, quiet occupation restore, drill reward, short eating/vomit cues, and timed imp transfer defense")
	quit(0 if failures.is_empty() else 1)
