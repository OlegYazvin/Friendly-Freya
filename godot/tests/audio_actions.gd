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
	scene.dogs = saved_dogs
	scene.freya.global_position = saved_position
	imp.queue_free()


func _test_park_drill_reward(scene: Node3D) -> void:
	_check(not scene.dog_park_training_items.is_empty(), "no park drill available")
	if scene.dog_park_training_items.is_empty():
		return
	var probe = CueProbe.new()
	scene.add_child(probe)
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


func _run() -> void:
	_check(change_scene_to_file("res://scenes/Main.tscn") == OK, "could not load Main")
	await scene_changed
	var scene: Node3D = current_scene
	scene.set_process(false)
	_test_lone_imp_bark(scene)
	_test_storefront_spawn_cue(scene)
	_test_park_drill_reward(scene)
	await process_frame
	if failures.is_empty():
		print("AUDIO_ACTIONS_OK: lone-imp R bark, near-only exact storefront emergence without fallback, and first park drill reward use recorded cues")
	quit(0 if failures.is_empty() else 1)
