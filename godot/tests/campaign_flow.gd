extends SceneTree

const GameSaveScript = preload("res://scripts/game_save.gd")
const ActionAudioScript = preload("res://scripts/action_audio.gd")
const TEST_SAVE_PATH = "user://friendly_freya_campaign_flow_test.json"
var failures: Array[String] = []


class CueProbe:
	extends Node
	var cues: Array[String] = []

	func play(cue_id: String, _volume_db: float = 0.0) -> void:
		cues.append(cue_id)


func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	create_timer(90.0).timeout.connect(_on_watchdog_timeout)
	call_deferred("run")


func _on_watchdog_timeout() -> void:
	push_error("CAMPAIGN_FLOW_FAIL: test timed out")
	cleanup_save()
	quit(1)


func cleanup_save() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH + suffix))


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
		push_error("CAMPAIGN_FLOW: " + description)


func route_is_connected(scene) -> bool:
	var connected: Array[int] = []
	for index in range(scene.buildings.size()):
		if scene._building_is_controlled_by_freya(index):
			connected.append(index)
	for target_index in scene.chapter_target_indices:
		var touches = false
		for earlier_index in connected:
			if scene._chapter_block_is_neighbor(scene._building_block_for_index(target_index), scene._building_block_for_index(earlier_index)):
				touches = true
				break
		if not touches:
			return false
		connected.append(target_index)
	return true


func check_nearly_cleared_hold(scene) -> void:
	var hold_index = -1
	for index in scene.chapter_target_indices:
		if bool(scene.buildings[index].get("alien_occupied", false)):
			hold_index = index
			break
	check(hold_index >= 0, "no occupied hold for near-clear input regression")
	if hold_index < 0:
		return
	var original_position: Vector3 = scene.freya.global_position
	var footprint: Rect2 = scene.buildings[hold_index].get("footprint", Rect2())
	var found_wall_approach = false
	for fraction in [0.15, 0.35, 0.5, 0.65, 0.85]:
		if found_wall_approach:
			break
		var x = lerpf(footprint.position.x, footprint.end.x, fraction)
		var z = lerpf(footprint.position.y, footprint.end.y, fraction)
		for distance in [0.7, 1.0, 1.3, 1.6]:
			for candidate in [
				Vector2(footprint.position.x - distance, z),
				Vector2(footprint.end.x + distance, z),
				Vector2(x, footprint.position.y - distance),
				Vector2(x, footprint.end.y + distance)
			]:
				if not scene._is_walkable(candidate.x, candidate.y, scene.FREYA_COLLISION_RADIUS):
					continue
				scene.freya.global_position = Vector3(candidate.x, 0.0, candidate.y)
				var target: Dictionary = scene._find_nearest_claim_target()
				if bool(target.get("found", false)) and int(target.get("type", -1)) == scene.CLAIM_TARGET_ALIEN_BUILDING and int(target.get("index", -1)) == hold_index:
					found_wall_approach = true
					break
			if found_wall_approach:
				break
	check(found_wall_approach, "occupied hold has no reachable Space target at its wall")
	if found_wall_approach:
		var hold: Dictionary = scene.buildings[hold_index]
		# The input-only run stalled at 0.0807 because target selection stopped
		# before the final weakening step. Keep this precise near-clear state.
		hold["alien_integrity"] = scene.ALIEN_BUILDING_MIN_INTEGRITY + 0.0007
		scene.buildings[hold_index] = hold
		var finishing_target: Dictionary = scene._find_nearest_claim_target()
		check(bool(finishing_target.get("found", false)) and int(finishing_target.get("type", -1)) == scene.CLAIM_TARGET_ALIEN_BUILDING and int(finishing_target.get("index", -1)) == hold_index, "nearly cleared hold stopped accepting Space")
		scene._weaken_alien_building(hold_index, 0.1)
		check(not bool(scene.buildings[hold_index].get("alien_occupied", false)), "last wall weakening did not break the hold")
	scene.freya.global_position = original_position


func check_last_building_reward_cue(scene, cue_probe: CueProbe, building_index: int, finish_chapter: bool, finish_map: bool) -> void:
	# Complete the same physical Space claim with one chapter site left. Check
	# chapter, all-map, and simultaneous rewards with the same recorded cue.
	if finish_map:
		if bool(scene.buildings[scene.kennel_building_index].get("alien_occupied", false)):
			scene._clear_alien_occupation(scene.kennel_building_index)
		scene._set_claim_owner(scene.CLAIM_TARGET_BUILDING, scene.kennel_building_index, scene.CLAIM_OWNER_FREYA)
	scene._set_claim_owner(scene.CLAIM_TARGET_BUILDING, building_index, scene.CLAIM_OWNER_NONE)
	scene.chapter_complete = not finish_chapter
	scene.campaign_complete = not finish_chapter
	scene.chapter_assisted_stronghold = true
	scene.chapter_final_signal_cue_pending = false
	scene.freya_victory_complete = false
	scene.tap_to_claim_enabled = false
	scene._clear_tap_claim_state()
	var original_position: Vector3 = scene.freya.global_position
	scene._force_building_surrounding_claims_for_validation(building_index, scene.CLAIM_OWNER_FREYA)
	var interior: Rect2 = scene.buildings[building_index].get("store_interior_rect", Rect2())
	scene.freya.global_position = Vector3(interior.get_center().x, original_position.y, interior.get_center().y)
	var target: Dictionary = scene._find_nearest_claim_target()
	var label = "combined chapter/map" if finish_chapter and finish_map else ("all-map" if finish_map else "chapter")
	check(bool(target.get("found", false)) and int(target.get("type", -1)) == scene.CLAIM_TARGET_BUILDING and int(target.get("index", -1)) == building_index, "%s reward setup has no live building claim" % label)
	check(not scene._chapter_completion_requirements_met() and not scene.freya_victory_complete, "%s reward was already complete before the final mark" % label)
	check(scene._controlled_building_count() == scene._claimable_building_total() - (1 if finish_map else 2), "%s reward setup has the wrong number of unclaimed buildings" % label)
	if bool(target.get("found", false)) and int(target.get("index", -1)) == building_index:
		cue_probe.cues.clear()
		Input.action_press("claim")
		scene._update_claiming(scene.BUILDING_CLAIM_FILL_TIME + 0.25)
		Input.action_release("claim")
		scene._check_chapter_completion()
		check(scene._building_is_controlled_by_freya(building_index) and scene.chapter_complete and scene._chapter_completion_requirements_met(), "%s final mark did not complete its chapter site" % label)
		check(scene.freya_victory_complete == finish_map, "%s final mark had the wrong all-map victory state" % label)
		check(cue_probe.cues == ["claim"], "%s final mark requested duplicate or missing recorded reward cues: %s" % [label, str(cue_probe.cues)])
		scene._check_chapter_completion()
		scene._check_victory_condition()
		check(cue_probe.cues == ["claim"], "%s completed reward replayed its recorded cue" % label)
	scene.freya.global_position = original_position


func check_already_owned_finale() -> void:
	check(change_scene_to_file("res://scenes/Main.tscn") == OK, "could not open owned-map finale")
	await scene_changed
	var scene = current_scene
	scene.set_process(false)
	scene.game_save_incompatible = true
	for index in range(scene.buildings.size()):
		if index == scene.freya_home_index or index == scene.kennel_building_index:
			continue
		if bool(scene.buildings[index].get("alien_occupied", false)):
			scene._clear_alien_occupation(index)
		scene._set_claim_owner(scene.CLAIM_TARGET_BUILDING, index, scene.CLAIM_OWNER_FREYA)
	scene.pack_order = scene.PACK_ORDER_ASSIST
	scene.pack_assist_target_index = scene.chapter_target_indices[0]
	scene._start_campaign_chapter(3)
	check(scene.chapter_target_indices.size() == 4, "owned map lost the four-site final route")
	check(scene.pack_order == scene.PACK_ORDER_FOLLOW and scene.pack_assist_target_index == -1, "chapter two order carried into the final signal")
	check(scene.chapter_final_stronghold_index >= 0 and scene.chapter_required_occupation_clears == 0, "owned map did not choose a clear final signal site")
	check(not scene.chapter_assisted_stronghold, "owned map silently awarded the final pack objective")
	scene._check_chapter_completion()
	check(not scene.chapter_complete, "owned map completed without an ally at the final signal")
	var final_index: int = scene.chapter_final_stronghold_index
	if final_index < 0:
		return
	var claim_path: String = str(ActionAudioScript.CUE_PATHS.get("claim", ""))
	check(claim_path == "res://assets/audio/actions/bubble_pop_669918.ogg" and ResourceLoader.exists(claim_path, "AudioStream"), "final-signal cue is not the exact recorded objective sound")
	var saved_audio: Node = scene.action_audio
	var cue_probe = CueProbe.new()
	scene.add_child(cue_probe)
	scene.action_audio = cue_probe
	var footprint: Rect2 = scene.buildings[final_index].get("footprint", Rect2())
	scene._update_minimap_dynamic(0.0)
	check(scene.minimap.next_chapter_target_building == footprint, "clear final signal is absent from the minimap next-site diamond")
	check("Secure the final signal with an ally" in scene._chapter_objectives_text() and not "(0/0)" in scene._chapter_objectives_text(), "clear final signal guidance is misleading")
	var ally: Dictionary = scene.dogs[0]
	ally["army_aligned"] = true
	ally["alien_possessed"] = false
	ally["node"].set_army_aligned(true)
	var approach: Vector3 = scene._alien_building_approach_position(final_index, footprint.get_center())
	ally["node"].global_position = approach
	scene.dogs[0] = ally
	scene.pack_order = scene.PACK_ORDER_ASSIST
	scene.pack_assist_target_index = final_index
	scene._update_chapter_three_recovery()
	check(not scene.chapter_assisted_stronghold, "assist silently satisfied the clear final signal's guard order")
	check(cue_probe.cues.is_empty(), "assist attempt played a final-signal success cue")
	scene.pack_order = scene.PACK_ORDER_GUARD
	scene.pack_guard_dog_index = -1
	scene.pack_guard_position = Vector2(approach.x, approach.z)
	var unfinished_index = -1
	for target_index in scene.chapter_target_indices:
		if target_index != final_index:
			unfinished_index = target_index
			break
	check(unfinished_index >= 0, "owned-map finale has no independent site for guard-cue test")
	if unfinished_index < 0:
		scene.action_audio = saved_audio
		cue_probe.queue_free()
		return
	scene._set_claim_owner(scene.CLAIM_TARGET_BUILDING, unfinished_index, scene.CLAIM_OWNER_NONE)
	scene._update_chapter_three_recovery()
	check(scene.chapter_assisted_stronghold and scene.chapter_final_signal_cue_pending and cue_probe.cues.is_empty(), "guard arrival did not queue exactly one final-signal cue")
	scene._check_chapter_completion()
	check(not scene.chapter_complete and cue_probe.cues == ["claim"] and not scene.chapter_final_signal_cue_pending, "nonfinal guard success did not play one recorded objective cue")
	scene._check_chapter_completion()
	check(cue_probe.cues == ["claim"], "rechecking a nonfinal guard success replayed its cue")
	scene._set_claim_owner(scene.CLAIM_TARGET_BUILDING, unfinished_index, scene.CLAIM_OWNER_FREYA)
	scene.chapter_assisted_stronghold = false
	cue_probe.cues.clear()
	scene._update_chapter_three_recovery()
	check(scene.chapter_final_signal_cue_pending and cue_probe.cues.is_empty(), "last-goal guard arrival played before chapter completion")
	scene._check_chapter_completion()
	check(scene.chapter_assisted_stronghold and scene.chapter_complete, "owned map could not finish with a real ally guarding the clear final signal")
	check(cue_probe.cues == ["claim"] and not scene.chapter_final_signal_cue_pending, "last-goal guard success doubled the chapter completion cue")
	scene._check_chapter_completion()
	check(cue_probe.cues == ["claim"], "completed chapter replayed the final-signal cue")
	check_last_building_reward_cue(scene, cue_probe, unfinished_index, true, false)
	check_last_building_reward_cue(scene, cue_probe, unfinished_index, false, true)
	check_last_building_reward_cue(scene, cue_probe, unfinished_index, true, true)
	scene.action_audio = saved_audio
	cue_probe.queue_free()


func run() -> void:
	cleanup_save()
	await check_already_owned_finale()
	check(change_scene_to_file("res://scenes/Main.tscn") == OK, "could not open Main")
	await scene_changed
	var scene = current_scene
	scene.set_process(false)
	scene.game_save_test_path = TEST_SAVE_PATH
	check(scene.campaign_chapter == 1 and scene.chapter_target_indices.size() == 8, "first chapter route missing")
	scene._seed_chapter_strongholds()
	var first_holds = 0
	for index in scene.chapter_target_indices:
		if bool(scene.buildings[index].get("alien_occupied", false)):
			first_holds += 1
	check(first_holds == 2 and scene._chapter_active_generator_count() > 0, "first chapter did not seed two holds and a generator")
	check_nearly_cleared_hold(scene)
	for index in range(scene.buildings.size()):
		if bool(scene.buildings[index].get("alien_occupied", false)):
			scene._clear_alien_occupation(index)
	for index in scene.chapter_target_indices:
		scene._set_claim_owner(scene.CLAIM_TARGET_BUILDING, index, scene.CLAIM_OWNER_FREYA)
	scene._start_campaign_chapter(2)
	check(scene.campaign_chapter == 2 and scene.chapter_target_indices.size() == 5, "second chapter route missing")
	check(route_is_connected(scene), "second chapter route disconnected")
	check(scene.chapter_required_occupation_clears == 1, "second chapter hold missing")
	var second_hold = -1
	for index in scene.chapter_target_indices:
		if bool(scene.buildings[index].get("alien_occupied", false)):
			second_hold = index
	check(second_hold >= 0, "second chapter hold is outside the route")
	check(scene.chapter_final_stronghold_index == second_hold, "second chapter relay site was not recorded")
	if second_hold >= 0:
		var relay_visual: Node3D = scene.buildings[second_hold].get("alien_visual_root", null)
		check(relay_visual != null and relay_visual.get_node_or_null("ScentRelayMarker") != null, "second chapter hold has no scent relay marker")
		check("Scent relay:" in scene._chapter_objectives_text(), "second chapter goals do not name the relay")
	check(scene.dogs.size() >= 2, "two ally candidates missing")
	for index in range(mini(2, scene.dogs.size())):
		var state: Dictionary = scene.dogs[index]
		state["army_aligned"] = true
		state["alien_possessed"] = false
		state["possession_immune"] = index == 0
		state["has_dog_armor"] = index == 1
		scene.dogs[index] = state
	if second_hold >= 0:
		scene._clear_alien_occupation(second_hold)
	for index in scene.chapter_target_indices:
		scene._set_claim_owner(scene.CLAIM_TARGET_BUILDING, index, scene.CLAIM_OWNER_FREYA)
	scene._check_chapter_completion()
	check(scene.chapter_complete and scene._chapter_protected_ally_count() >= 2, "second chapter could not complete")
	scene._continue_campaign_story()
	check(scene.campaign_chapter == 3 and scene.chapter_target_indices.size() == 4, "third chapter route missing")
	check(route_is_connected(scene), "third chapter route disconnected")
	check(scene.chapter_required_occupation_clears == 1, "final stronghold missing")
	var final_hold = -1
	for index in scene.chapter_target_indices:
		if bool(scene.buildings[index].get("alien_occupied", false)):
			final_hold = index
	check(final_hold >= 0, "final stronghold is outside the route")
	if final_hold >= 0:
		# The live weakening action records whether the pack helped.
		var ally: Dictionary = scene.dogs[0]
		var footprint: Rect2 = scene.buildings[final_hold].get("footprint", Rect2())
		var approach: Vector3 = scene._alien_building_approach_position(final_hold, footprint.get_center())
		ally["node"].global_position = approach
		scene.dogs[0] = ally
		scene.pack_order = scene.PACK_ORDER_ASSIST
		scene.pack_assist_target_index = final_hold
		scene._weaken_alien_building(final_hold, 0.1)
		check(scene.chapter_assisted_stronghold, "pack help did not count at final stronghold")
		scene._clear_alien_occupation(final_hold)
	for index in scene.chapter_target_indices:
		scene._set_claim_owner(scene.CLAIM_TARGET_BUILDING, index, scene.CLAIM_OWNER_FREYA)
	scene._check_chapter_completion()
	check(scene.chapter_complete and scene.campaign_complete, "final chapter could not complete")
	if not scene.chapter_complete:
		push_error("CAMPAIGN_FLOW_FAIL: " + ", ".join(failures))
		cleanup_save()
		quit(1)
		return
	scene._continue_campaign_story()
	var saved_final: Dictionary = GameSaveScript.read_save(TEST_SAVE_PATH)
	check(bool(saved_final.get("ok", false)) and bool(saved_final.get("state", {}).get("campaign", {}).get("campaign_complete", false)), "final chapter was not saved before ending handoff")
	if not bool(saved_final.get("ok", false)) or not bool(saved_final.get("state", {}).get("campaign", {}).get("campaign_complete", false)):
		cleanup_save()
		quit(1)
		return
	await scene_changed
	check(current_scene != null and current_scene.scene_file_path == "res://scenes/CampaignEnding.tscn", "credits scene did not open")
	if current_scene != null and current_scene.scene_file_path == "res://scenes/CampaignEnding.tscn":
		check(int(current_scene._summary.get("chapters_secured", 0)) == 3 and int(current_scene._summary.get("allied_dogs", 0)) >= 2 and current_scene._summary.has("claimed_sites"), "live campaign summary did not reach credits")
	await process_frame
	await process_frame
	cleanup_save()
	if failures.is_empty():
		print("CAMPAIGN_FLOW_OK: three chapter routes, seeded holds, owned-map final guard, single claim/chapter/victory reward cues, protected allies, pack assistance, and credits")
		quit()
	else:
		push_error("CAMPAIGN_FLOW_FAIL: " + ", ".join(failures))
		quit(1)
