extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	create_timer(90.0).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run")


func _on_watchdog_timeout() -> void:
	push_error("CHAPTER_GUIDE_FAIL: test timed out")
	quit(1)


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error("CHAPTER_GUIDE: " + message)


func _run() -> void:
	root.size = Vector2i(800, 450)
	_check(change_scene_to_file("res://scenes/Main.tscn") == OK, "could not open Main")
	await scene_changed
	var scene = current_scene
	scene.set_process(false)
	scene.status_label.text = ""
	scene._seed_chapter_strongholds()
	_check(scene.status_label.text.is_empty(), "initial strongholds announced over the home lesson")
	_check("10–17s" in scene._chapter_objectives_text() and "22m" in scene._chapter_objectives_text(), "generator output and reinforcement radius are missing from goals")
	var generator_index = scene._nearest_active_generator_index()
	_check(generator_index >= 0, "initial chapter has no active source to mark")
	if generator_index >= 0:
		var generator_state: Dictionary = scene.buildings[generator_index].duplicate()
		var generator_rect: Rect2 = generator_state.get("footprint", Rect2())
		scene._update_minimap_dynamic(0.0)
		_check(scene.minimap.active_generator_building == generator_rect, "minimap does not mark the nearest active source")
		_check("Orange ! on minimap" in scene._chapter_objectives_text(), "generator badge has no goals legend")
		var inactive_generator: Dictionary = generator_state.duplicate()
		inactive_generator["alien_occupied"] = false
		scene.buildings[generator_index] = inactive_generator
		scene._update_minimap_dynamic(0.0)
		_check(scene.minimap.active_generator_building == Rect2(), "inactive source kept its minimap badge")
		scene.buildings[generator_index] = generator_state
		scene._update_minimap_dynamic(0.0)
		_check(scene.minimap.active_generator_building == generator_rect, "reactivated source lost its minimap badge")
	var first_site = scene._next_chapter_target_index()
	_check(first_site >= 0, "no first highlighted site")
	if first_site >= 0:
		_check(not bool(scene.buildings[first_site].get("alien_occupied", false)), "first suggested site is an alien-locked stronghold")
		_check(scene._building_has_adjacent_freya_control(first_site), "first suggested site is disconnected")
		scene._update_minimap_dynamic(0.0)
		_check(scene.minimap.next_chapter_target_building == scene.buildings[first_site].get("footprint", Rect2()), "minimap diamond does not point to the first named site")
		_check("Cyan diamond on minimap" in scene._chapter_objectives_text(), "next-site minimap legend is missing")
		var map_view = Rect2(Vector2.ZERO, Vector2(320.0, 180.0))
		var service_point = Vector2(90.0, 70.0)
		var badge_point = scene.minimap._next_target_badge_position(service_point, map_view, true)
		_check(badge_point.distance_to(service_point) >= 24.0, "next-site diamond covers a service letter")
		_check(map_view.grow(-14.0).has_point(badge_point), "service-target diamond clips at the map edge")
	_check("Hold R" in scene._chapter_guide_text(), "park dog bark cue missing")
	scene.alien_expulsion_count = 1
	_check("Hold C" in scene._chapter_guide_text(), "freed dog recruitment cue missing")
	var ally: Dictionary = scene.dogs[0]
	ally["alien_possessed"] = false
	ally["army_aligned"] = true
	scene.dogs[0] = ally
	if first_site >= 0:
		var marks = scene._building_surrounding_claimables(first_site)
		if not marks.is_empty():
			var drill_cue: String = scene._chapter_guide_text()
			_check("Try F at a park obstacle" in drill_cue and "+8% assist" in drill_cue, "optional first park drill was not taught")
			scene.freya_inside_home = false
			scene.post_intro_meal_tutorial_active = false
			scene._update_chapter_guide()
			await process_frame
			_check(root.get_visible_rect().encloses(scene.chapter_guide_panel.get_global_rect()), "park drill cue clips at 800x450")
			scene.dog_park_training_completed.append("weave_poles")
			_check("Hold Space" in scene._chapter_guide_text() and "nearby objects" in scene._chapter_guide_text(), "first property marking cue missing")
			scene.freya_inside_home = false
			scene.post_intro_meal_tutorial_active = false
			scene._update_chapter_guide()
			await process_frame
			_check(root.get_visible_rect().encloses(scene.chapter_guide_panel.get_global_rect()), "long marking cue clips at 800x450")
			_check(scene.chapter_guide_panel.get_global_rect().end.y <= root.get_visible_rect().end.y - 15.0, "long marking cue loses the bottom margin")
		for item in marks:
			scene._set_claim_owner(int(item["type"]), int(item["index"]), scene.CLAIM_OWNER_FREYA)
		var marked_cue = scene._chapter_guide_text()
		_check("Enter" in marked_cue and "hold Space inside" in marked_cue, "marked property entry cue missing: " + marked_cue)
		scene._set_claim_owner(scene.CLAIM_TARGET_BUILDING, first_site, scene.CLAIM_OWNER_FREYA)
		_check(scene._chapter_claimed_target_count() == 1, "first property setup was not claimed")
		scene._update_minimap_dynamic(0.0)
		var following_site = scene._next_chapter_target_index()
		_check(following_site < 0 or scene.minimap.next_chapter_target_building == scene.buildings[following_site].get("footprint", Rect2()), "minimap diamond did not follow the next named site")
		_check(scene.minimap.next_chapter_target_building != scene.buildings[first_site].get("footprint", Rect2()), "minimap diamond stayed on the claimed first site")
	var stronghold = scene._chapter_guide_stronghold_index()
	_check(stronghold >= 0, "no first stronghold to teach")
	_check("alien hold" in scene._chapter_guide_text() and "Hold Space beside its wall" in scene._chapter_guide_text(), "post-claim stronghold cue missing")
	if stronghold >= 0:
		scene._clear_alien_occupation(stronghold)
		_check("teal paw lodge" in scene._chapter_guide_text(), "stronghold result did not point to rescue")

	scene.freya_inside_home = false
	scene.post_intro_meal_tutorial_active = false
	scene._update_chapter_guide()
	await process_frame
	_check(scene.chapter_guide_panel.visible, "first-step panel was hidden during active play")
	_check(scene.chapter_guide_title.get_theme_font_size("font_size") >= 16 and scene.chapter_guide_label.get_theme_font_size("font_size") >= 18, "next-step text is too small")
	_check(root.get_visible_rect().encloses(scene.chapter_guide_panel.get_global_rect()), "first-step panel clips at 800x450")
	_check(not scene.chapter_guide_panel.get_global_rect().intersects(scene.territory_label.get_parent().get_global_rect()), "next-step panel overlaps chapter status at 800x450")
	scene._layout_objectives_panel()
	await process_frame
	_check(root.get_visible_rect().encloses(scene.objectives_panel.get_global_rect()), "Tab goals panel clips at 800x450")
	scene._layout_pause_menu()
	await process_frame
	_check(root.get_visible_rect().encloses(scene.pause_menu_panel.get_global_rect()), "pause panel clips at 800x450")
	scene.objectives_panel.show()
	scene._update_chapter_guide()
	_check(not scene.chapter_guide_panel.visible, "first-step panel overlaps held Tab goals")
	scene.objectives_panel.hide()
	# This check simulates a normal H press without starting the first-exit cutscene.
	scene.first_exit_abduction_pending = false
	Input.action_press("toggle_guidance")
	scene._process(0.0)
	Input.action_release("toggle_guidance")
	_check(scene.chapter_guide_hidden and not scene.chapter_guide_panel.visible, "H input did not hide first-step panel")
	var saved: Dictionary = scene._snapshot_game_state()
	_check(bool(saved["story"].get("chapter_guide_hidden", false)), "tip dismissal was not saved")
	scene.chapter_guide_hidden = false
	scene._restore_player_and_story(saved)
	_check(scene.chapter_guide_hidden, "tip dismissal was not restored")
	_check(InputMap.has_action("toggle_guidance") and scene._action_has_key("toggle_guidance", KEY_H), "H tip toggle is not bound")
	scene.chapter_guide_hidden = false
	# The H simulation above refreshes the home focus from Freya's position.
	# Stage the later-chapter UI as an outdoor play state.
	scene.freya_inside_home = false
	scene._start_campaign_chapter(2)
	_check("M (medicine) or A (armor) on the minimap" in scene._chapter_guide_text(), "chapter 2 does not teach protection pickup")
	scene.freya_carries_immunity_dose = true
	_check("Press F beside an unprotected clean ally" in scene._chapter_guide_text(), "chapter 2 does not teach carried protection")
	ally = scene.dogs[0]
	ally["possession_immune"] = true
	scene.dogs[0] = ally
	_check("recruit another clean ally" in scene._chapter_guide_text(), "chapter 2 does not guide a one-ally recovery")
	var second_ally: Dictionary = scene.dogs[1]
	second_ally["alien_possessed"] = false
	second_ally["army_aligned"] = true
	second_ally["possession_immune"] = true
	scene.dogs[1] = second_ally
	_check("cyan diamond" in scene._chapter_guide_text() or "Scent relay" in scene._chapter_guide_text(), "chapter 2 does not continue to route sites after protection")
	scene._update_chapter_guide()
	await process_frame
	_check(scene.chapter_guide_panel.visible and root.get_visible_rect().encloses(scene.chapter_guide_panel.get_global_rect()), "chapter 2 guide clips or disappears in the viewport")
	scene._start_campaign_chapter(3)
	for building_index in scene.chapter_target_indices:
		if building_index != scene.chapter_final_stronghold_index:
			scene._set_claim_owner(scene.CLAIM_TARGET_BUILDING, building_index, scene.CLAIM_OWNER_FREYA)
	_check("press 3 near it" in scene._chapter_guide_text(), "chapter 3 does not teach the pack-assisted final hold")
	for window_size in [Vector2i(800, 450), Vector2i(960, 540)]:
		root.size = window_size
		scene._update_chapter_guide()
		await process_frame
		_check(scene.chapter_guide_panel.visible and root.get_visible_rect().encloses(scene.chapter_guide_panel.get_global_rect()), "chapter 3 final-hold guide clips at %s" % window_size)
		_check(not scene.chapter_guide_panel.get_global_rect().intersects(scene.territory_label.get_parent().get_global_rect()), "chapter 3 final-hold guide overlaps chapter status at %s" % window_size)
	root.size = Vector2i(800, 450)
	if scene.chapter_final_stronghold_index >= 0:
		scene._clear_alien_occupation(scene.chapter_final_stronghold_index)
		_check("press 2 beside it to guard" in scene._chapter_guide_text(), "chapter 3 does not teach cleared-signal recovery")
		scene._update_chapter_guide()
		await process_frame
		_check(scene.chapter_guide_panel.visible and root.get_visible_rect().encloses(scene.chapter_guide_panel.get_global_rect()), "chapter 3 recovery guide clips or disappears in the viewport")
	scene.objectives_panel.show()
	scene._update_chapter_guide()
	_check(not scene.chapter_guide_panel.visible, "later-chapter guide overlaps held Tab goals")
	if failures.is_empty():
		print("CHAPTER_GUIDE_OK: first-chapter cues, later protection/pack/recovery cues, active-source minimap badge, generator range/output, Tab suppression, 800x450 fit, and saved dismissal")
		quit()
	else:
		push_error("CHAPTER_GUIDE_FAIL: " + ", ".join(failures))
		quit(1)
