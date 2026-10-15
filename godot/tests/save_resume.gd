extends SceneTree

const GameSaveScript = preload("res://scripts/game_save.gd")
const TEST_PATH = "user://friendly_freya_save_test.json"
const LEGACY_PATH = "user://friendly_freya_save_test_legacy.json"
var failures: Array[String] = []


func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	create_timer(90.0).timeout.connect(_on_watchdog_timeout)
	call_deferred("run")


func _on_watchdog_timeout() -> void:
	push_error("SAVE_RESUME_FAIL: test timed out")
	quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
		push_error("SAVE_RESUME: " + description)


func frames(count: int = 3) -> void:
	for i in range(count):
		await process_frame


func run() -> void:
	check(change_scene_to_file("res://scenes/Main.tscn") == OK, "could not open Main")
	await scene_changed
	var scene = current_scene
	scene.set_process(false)
	var claim_index = -1
	var occupied_index = -1
	for index in range(scene.buildings.size()):
		if index == scene.freya_home_index or index == scene.kennel_building_index:
			continue
		if claim_index < 0:
			claim_index = index
		elif occupied_index < 0:
			occupied_index = index
			break
	check(claim_index >= 0 and occupied_index >= 0, "no buildings available for save test")
	scene._set_claim_owner(scene.CLAIM_TARGET_BUILDING, claim_index, "freya")
	scene._set_claim_owner(scene.CLAIM_TARGET_TREE, 0, "freya")
	check(scene._occupy_building_with_alien(occupied_index, 117), "could not occupy test building")
	var dog_state: Dictionary = scene.dogs[0]
	dog_state["alien_possessed"] = false
	dog_state["alien_expelled"] = true
	dog_state["army_aligned"] = true
	dog_state["possession_immune"] = true
	dog_state["has_dog_armor"] = true
	dog_state["pack_order"] = "guard"
	dog_state["guard_building_index"] = claim_index
	dog_state["node"].set_army_aligned(true)
	dog_state["node"].set_dog_armor(true)
	scene.dogs[0] = dog_state
	scene.freya_hunger = 42.5
	scene.freya_vomit = 55.0
	scene.freya_social = 63.0
	scene.freya_strength = 3
	scene.freya_carries_immunity_dose = true
	scene.freya_carries_dog_armor = true
	scene.freya_carries_clinic_kit = true
	scene.chapter_target_indices.clear()
	scene.chapter_target_indices.append(claim_index)
	scene.chapter_target_indices.append(occupied_index)
	scene.pack_order = scene.PACK_ORDER_GUARD
	scene.pack_guard_position = Vector2(23.25, 42.5)
	scene.dog_park_training_completed.clear()
	scene.dog_park_training_completed.append("weave_poles")
	var generator_index = -1
	for index in scene.store_building_indices:
		if bool(scene.buildings[index].get("generates_free_aliens", false)) and index != occupied_index:
			generator_index = index
			break
	check(generator_index >= 0, "no storefront generator for imp save test")
	if generator_index >= 0:
		check(scene._occupy_building_with_alien(generator_index, 118), "could not occupy generator for imp test")
		check(scene._spawn_free_alien_from_store(generator_index), "could not spawn imp for save test")
		if not scene.free_aliens.is_empty():
			var imp: Dictionary = scene.free_aliens[0]
			imp["dog_attempt_cooldown"] = 3.2
			imp["interrupt_progress"] = 0.25
			scene.free_aliens[0] = imp
	if scene.kennel != null:
		scene.kennel.advance_spawn_clock(8.2)
		scene._clear_alien_occupation(scene.kennel_building_index)
		scene.kennel.depossess_caged_dog(0)
		scene.kennel.release_caged_dog(0)
	scene.campaign_chapter = 3
	scene.campaign_complete = true
	scene.chapter_complete = true
	scene.chapter_occupations_cleared = 1
	scene.chapter_required_occupation_clears = 1
	scene.chapter_assisted_stronghold = true
	scene.chapter_final_stronghold_index = occupied_index
	var kennel_before: Dictionary = scene._kennel_snapshot()
	var snapshot: Dictionary = scene._snapshot_game_state()
	check(GameSaveScript.write_save(snapshot, TEST_PATH), "save write failed")
	var loaded = GameSaveScript.read_save(TEST_PATH)
	check(bool(loaded.get("ok", false)), "save read failed")
	check(loaded.get("state", {}).get("world_seed", "") == snapshot.world_seed, "seed not persisted")
	check(GameSaveScript.write_save(snapshot, TEST_PATH), "second save write failed")
	var corrupt = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	corrupt.store_string("{}")
	corrupt.close()
	var recovered = GameSaveScript.read_save(TEST_PATH)
	check(bool(recovered.get("ok", false)) and recovered.get("source", "") == "backup", "backup recovery failed")
	var future = snapshot.duplicate(true)
	future["version"] = GameSaveScript.VERSION + 1
	check(not GameSaveScript.write_save(future, TEST_PATH), "future save version was accepted")
	check(change_scene_to_file("res://scenes/Startup.tscn") == OK, "could not open title for resume")
	await scene_changed
	var startup = current_scene
	startup.resume_save_path = TEST_PATH
	startup._on_resume_game_pressed()
	await scene_changed
	scene = current_scene
	scene.set_process(false)
	check(absf(scene.freya_hunger - 42.5) < 0.01 and absf(scene.freya_vomit - 55.0) < 0.01 and absf(scene.freya_social - 63.0) < 0.01, "meters were not restored: %s" % [str([scene.freya_hunger, scene.freya_vomit, scene.freya_social])])
	check(scene.freya_strength == 3 and scene.freya_carries_immunity_dose and scene.freya_carries_dog_armor and scene.freya_carries_clinic_kit, "carried supplies were not restored")
	check(scene._building_is_controlled_by_freya(claim_index), "claimed building was not restored")
	check(scene._entry_is_claimed_by(scene.trees[0], "freya"), "tree claim was not restored")
	check(bool(scene.buildings[occupied_index].get("alien_occupied", false)), "building occupation was not restored")
	check(bool(scene.dogs[0].get("army_aligned", false)) and not bool(scene.dogs[0].get("alien_possessed", true)), "dog alignment or possession was not restored")
	check(bool(scene.dogs[0].get("possession_immune", false)) and bool(scene.dogs[0].get("has_dog_armor", false)), "dog upgrades were not restored")
	check(str(scene.dogs[0].get("pack_order", "")) == "guard", "pack order was not restored")
	check(scene.campaign_chapter == 3 and scene.campaign_complete and scene.chapter_complete, "campaign chapter or completion was not restored")
	check(not scene.chapter_result_dismissed, "an unviewed chapter result was dismissed on resume")
	check(scene.chapter_complete_panel != null and scene.chapter_complete_panel.visible, "completed chapter lost its continue-story route on resume")
	check(scene.chapter_occupations_cleared == 1 and scene.chapter_required_occupation_clears == 1 and scene.chapter_assisted_stronghold, "campaign objectives were not restored")
	check(scene.chapter_final_stronghold_index == occupied_index, "final stronghold site was not restored")
	scene._continue_campaign_story()
	check(current_scene == scene and scene.chapter_complete_panel.visible and "Could not save" in str(scene.chapter_complete_panel.get_node("Content/Detail").text), "failed final save did not keep the ending retry route")
	await frames(2)
	check(current_scene == scene, "failed final save changed scenes")
	check(scene.chapter_target_indices == [claim_index, occupied_index], "chapter targets were not restored")
	check(scene.pack_order == scene.PACK_ORDER_GUARD and scene.pack_guard_position.distance_to(Vector2(23.25, 42.5)) < 0.001, "pack order was not restored")
	check(scene.dog_park_training_completed == ["weave_poles"], "park training reward was not restored")
	check(scene.free_aliens.size() == 1 and absf(float(scene.free_aliens[0].get("dog_attempt_cooldown", 0.0)) - 3.2) < 0.001 and absf(float(scene.free_aliens[0].get("interrupt_progress", 0.0)) - 0.25) < 0.001, "free imp state was not restored")
	check(JSON.stringify(scene._kennel_snapshot()) == JSON.stringify(kennel_before), "kennel budget or cages were not restored: before=%s after=%s" % [JSON.stringify(kennel_before), JSON.stringify(scene._kennel_snapshot())])
	var restored_spawn: Dictionary = {}
	var restored_rescue: Dictionary = {}
	for state in scene.dogs:
		if str(state.get("stable_id", "")) == "kennel_spawn:1":
			restored_spawn = state
		elif str(state.get("stable_id", "")) == "kennel_rescue:0":
			restored_rescue = state
	check(not restored_spawn.is_empty() and bool(restored_spawn.get("alien_possessed", false)) and is_instance_valid(restored_spawn.get("node", null)), "kennel spawned dog roster state was not restored")
	check(not restored_rescue.is_empty() and not bool(restored_rescue.get("alien_possessed", true)) and is_instance_valid(restored_rescue.get("node", null)), "kennel rescued dog roster state was not restored")
	# A player can clear and claim the last hold before giving a pack order.
	# The cleared site must still allow the assist objective to be recovered.
	scene.chapter_complete = false
	scene.campaign_complete = false
	scene.chapter_assisted_stronghold = false
	if generator_index >= 0:
		var generator_footprint: Rect2 = scene.buildings[generator_index].get("footprint", Rect2())
		var generator_post = Vector2(generator_footprint.position.x - 1.0, generator_footprint.get_center().y)
		scene.pack_order = scene.PACK_ORDER_ASSIST
		scene.pack_assist_target_index = generator_index
		scene.dogs[0]["node"].global_position = Vector3(generator_post.x, 0.0, generator_post.y)
		scene._weaken_alien_building(generator_index, 0.1)
		check(not scene.chapter_assisted_stronghold, "a nonfinal alien hold counted as the final pack assist")
	scene._clear_alien_occupation(occupied_index)
	scene._set_claim_owner(scene.CLAIM_TARGET_BUILDING, occupied_index, "freya")
	var final_footprint: Rect2 = scene.buildings[occupied_index].get("footprint", Rect2())
	var final_post = Vector2(final_footprint.position.x - 1.0, final_footprint.get_center().y)
	check(scene._chapter_claimed_target_count() == scene.chapter_target_indices.size(), "recovery setup did not claim all chapter sites")
	scene._update_minimap_dynamic(0.0)
	check(scene.minimap.chapter_target_buildings.has(final_footprint), "claimed final site lost its recovery marker on the minimap")
	scene.pack_order = scene.PACK_ORDER_GUARD
	scene.pack_guard_position = final_post
	scene.dogs[0]["node"].global_position = Vector3(final_post.x, 0.0, final_post.y)
	check("press [2] to guard" in scene._chapter_objectives_text(), "cleared final site gave no recovery guidance")
	scene._update_chapter_three_recovery()
	check(scene.chapter_assisted_stronghold, "a cleared final site could not be secured by an active allied guard")
	scene._toggle_pause_menu(1, false)
	scene._on_pause_exit_pressed()
	check(current_scene == scene and not scene.pause_menu_open and "Could not save" in str(scene.status_label.text), "failed Quit Game save exited or hid the retry guidance")
	await frames(2)
	check(current_scene == scene, "failed Quit Game save changed scenes")
	var older_chapter_one = snapshot.duplicate(true)
	older_chapter_one["campaign"]["chapter"] = 1
	older_chapter_one["campaign"]["chapter_complete"] = false
	older_chapter_one["campaign"]["campaign_complete"] = false
	older_chapter_one["campaign"]["chapter_occupations_cleared"] = 0
	older_chapter_one["campaign"].erase("required_occupation_clears")
	older_chapter_one["campaign"].erase("assisted_stronghold")
	for id in older_chapter_one["collections"]["buildings"]:
		if str(id) == scene._save_building_id_from_index(scene.kennel_building_index):
			continue
		var record: Dictionary = older_chapter_one["collections"]["buildings"][id]
		record["alien_occupied"] = false
		record["alien_integrity"] = 0.0
		record["alien_occupant_count"] = 0
		older_chapter_one["collections"]["buildings"][id] = record
	check(scene._restore_game_state(older_chapter_one), "legacy chapter one map could not be restored")
	var repaired_holds = 0
	for index in range(scene.buildings.size()):
		if index != scene.kennel_building_index and bool(scene.buildings[index].get("alien_occupied", false)):
			repaired_holds += 1
	check(scene.campaign_chapter == 1 and not scene.chapter_complete and scene.chapter_required_occupation_clears == 2 and repaired_holds >= 2 and scene._building_is_controlled_by_freya(claim_index), "legacy chapter one restore did not seed enough safe strongholds")
	check(scene.chapter_complete_panel == null or not scene.chapter_complete_panel.visible, "unfinished legacy chapter kept the completed panel")
	var backup_before = FileAccess.get_file_as_string(TEST_PATH + ".bak")
	var future_payload = JSON.stringify(future)
	var hasher = HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(future_payload.to_utf8_buffer())
	var future_envelope = JSON.stringify({"format": "friendly_freya", "payload": future_payload, "sha256": hasher.finish().hex_encode()})
	var future_primary = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	future_primary.store_string(future_envelope)
	future_primary.close()
	var incompatible = GameSaveScript.read_save(TEST_PATH)
	check(not bool(incompatible.get("ok", false)) and str(incompatible.get("error", "")) == "unsupported_version_2" and str(incompatible.get("source", "")) == "primary", "future save silently fell back to an older backup")
	check(not GameSaveScript.has_resume(TEST_PATH), "future save was offered as a resumable game")
	check(not GameSaveScript.write_save(snapshot, TEST_PATH), "future save was overwritten")
	check(FileAccess.get_file_as_string(TEST_PATH) == future_envelope and FileAccess.get_file_as_string(TEST_PATH + ".bak") == backup_before, "incompatible save or backup changed")
	var valid_primary = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	valid_primary.store_string(backup_before)
	valid_primary.close()
	var future_backup = FileAccess.open(TEST_PATH + ".bak", FileAccess.WRITE)
	future_backup.store_string(future_envelope)
	future_backup.close()
	check(not GameSaveScript.write_save(snapshot, TEST_PATH), "future-version backup was overwritten")
	check(FileAccess.get_file_as_string(TEST_PATH) == backup_before and FileAccess.get_file_as_string(TEST_PATH + ".bak") == future_envelope, "future-version backup protection changed either slot")
	var legacy = snapshot.duplicate(true)
	legacy["version"] = 0
	legacy.erase("story")
	legacy.erase("campaign")
	legacy.erase("kennel")
	var legacy_payload = JSON.stringify(legacy)
	hasher = HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(legacy_payload.to_utf8_buffer())
	var legacy_envelope = JSON.stringify({"format": "friendly_freya", "payload": legacy_payload, "sha256": hasher.finish().hex_encode()})
	var legacy_file = FileAccess.open(LEGACY_PATH, FileAccess.WRITE)
	legacy_file.store_string(legacy_envelope)
	legacy_file.close()
	var migrated = GameSaveScript.read_save(LEGACY_PATH)
	check(bool(migrated.get("ok", false)) and int(migrated.get("state", {}).get("version", -1)) == GameSaveScript.VERSION and migrated.get("state", {}).get("campaign", null) is Dictionary and migrated.get("state", {}).get("kennel", null) is Dictionary, "version 0 save did not migrate")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH + ".bak"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH + ".tmp"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_PATH))
	await frames()
	if failures.is_empty():
		print("SAVE_RESUME_OK: versioned write, legacy migration, backup recovery, future-version preservation, seed, campaign, claims, occupation, dog state, supplies, meters, and kennel state restored")
		quit()
	else:
		push_error("SAVE_RESUME_FAIL: " + ", ".join(failures))
		quit(1)
