extends SceneTree

# Input-driven route regressions; rare dog/collision states are explicitly staged.
# Run headless with --script res://tests/dejank_flow.gd. No imported assets change.
var failures: Array[String] = []

func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	call_deferred("run")

func check(ok: bool, description: String) -> void:
	if not ok:
		failures.append(description)
		push_error("DEJANK: " + description)

func frames(count: int = 3) -> void:
	for i in range(count):
		await process_frame

func key(code: Key, down: bool) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	await frames(2)

func tap(code: Key) -> void:
	await key(code, true)
	await key(code, false)

func open_scene(path: String) -> void:
	paused = false
	check(change_scene_to_file(path) == OK, "could not open " + path)
	await frames(5)

func check_skip(s: Node, route: String) -> void:
	check(s.scene_file_path == "res://scenes/Main.tscn", route + " did not reach gameplay")
	check(s.possessed_dog_behavior_enabled and not s.first_exit_abduction_pending, route + " disabled dog behavior or queued a skipped cinematic")
	check(s.post_intro_meal_tutorial_active and not s.post_intro_meal_exit_required, route + " missing optional food guidance")
	check(s.post_intro_meal_panel.visible and s.post_intro_meal_bowl_pointer.visible, route + " food guidance invisible")
	check(s.freya_hunger > 99.9 and s.freya_inside_home, route + " lost Hunger or usable home start")
	# The actual threat lookup must be live, not merely a readiness flag. Stage a
	# city dog briefly, then restore it before any simulation/input frame runs.
	for dog in s.dogs:
		if dog.get("park", false):
			continue
		var saved_position: Vector3 = dog.node.global_position
		dog.node.global_position = s.freya.global_position + Vector3.RIGHT
		check(s._nearest_possessed_dog_threat(3.35).get("found", false), route + " still suppresses possessed-dog threats")
		dog.node.global_position = saved_position
		break
	var home = s.buildings[s.freya_home_index]
	var out: Vector2 = home.home_layout.entry_outside_pos
	check(not s._try_block_post_intro_home_exit(out, Vector3.FORWARD), route + " unexpectedly gated the exit")

func run() -> void:
	await open_scene("res://scenes/Startup.tscn")
	current_scene.skip_to_game_button.grab_focus()
	await tap(KEY_ENTER)
	check_skip(current_scene, "startup skip")
	var s = current_scene
	# Normal F input at the skipped route's actual spawn must reach the bowl.
	await tap(KEY_F)
	check(s.freya_hunger < 0.2 and s.post_intro_meal_tutorial_completed, "skip spawn could not eat using F")
	check(not s.first_exit_abduction_pending and s.possessed_dog_behavior_enabled, "eating changed skip readiness")
	check(s._action_has_key("toggle_objectives", KEY_G), "G goals toggle is not bound")
	var goals_test_window_size = root.size
	root.size = Vector2i(800, 450)
	await frames(2)
	await tap(KEY_G)
	check(s.objectives_pinned and s.objectives_panel.visible, "G did not pin goals after release")
	s._show_status("An imp is reaching for a dog — bark or guard it!", 5.0, 2)
	await frames(2)
	check(s.objectives_status_panel.visible and s.objectives_status_label.text == s.status_label.text, "pinned goals hid the imp warning")
	check(not s.status_panel.visible, "pinned goals left a duplicate HUD status")
	var goals_status_rect: Rect2 = s.objectives_status_panel.get_global_rect()
	check(root.get_visible_rect().encloses(goals_status_rect), "pinned-goals warning left the 800x450 viewport")
	check(s.objectives_panel.get_global_rect().encloses(goals_status_rect), "pinned-goals warning left the goals panel")
	check(goals_status_rect.encloses(s.objectives_status_label.get_global_rect()), "pinned-goals warning text exceeds its background")
	check(s.objectives_scroll.get_global_rect().end.y + 8.0 <= goals_status_rect.position.y, "pinned-goals warning overlaps the scrollable tasks")
	check(s.objectives_scroll.get_v_scroll_bar().max_value > s.objectives_scroll.get_v_scroll_bar().page, "goals test window did not need scrolling")
	await tap(KEY_PAGEDOWN)
	check(s.objectives_scroll.scroll_vertical > 0, "PageDown did not scroll pinned goals")
	await tap(KEY_PAGEUP)
	check(s.objectives_scroll.scroll_vertical == 0, "PageUp did not scroll pinned goals to top")
	await tap(KEY_G)
	check(not s.objectives_pinned and not s.objectives_panel.visible, "G did not close pinned goals")
	check(s.status_panel.visible and not s.objectives_status_panel.visible, "closing goals did not restore HUD status")
	await key(KEY_TAB, true)
	check(s.objectives_panel.visible, "held Tab did not show goals")
	await key(KEY_TAB, false)
	check(not s.objectives_panel.visible, "released Tab left goals open")
	await tap(KEY_G)
	check(s.objectives_pinned and s.objectives_panel.visible, "G did not repin goals")
	await tap(KEY_ESCAPE)
	check(s.pause_menu_open and paused, "Escape did not open pause")
	check(not s.objectives_pinned and not s.objectives_panel.visible, "pause did not clear pinned goals")
	check(s.pause_resume_button.has_focus(), "opening pause did not focus Resume")
	await tap(KEY_ESCAPE)
	check(not s.pause_menu_open and not paused, "Escape did not resume paused gameplay")
	check(not s.objectives_panel.visible, "goals reopened after pause cleared their pin")
	root.size = goals_test_window_size
	await frames(2)
	await tap(KEY_ESCAPE)
	check(s.pause_menu_open and paused and s.pause_resume_button.has_focus(), "reopening pause did not refocus Resume")
	await tap(KEY_ENTER)
	check(not s.pause_menu_open and not paused, "Enter on focused Resume did not resume gameplay")
	await tap(KEY_ESCAPE)
	check(s.pause_menu_open and paused, "Escape did not reopen pause after keyboard Resume")
	s.pause_controls_button.grab_focus()
	await tap(KEY_ENTER)
	check(s.pause_controls_panel.visible, "keyboard did not open Controls")
	await tap(KEY_PAGEDOWN)
	check(s.pause_controls_scroll.scroll_vertical > 0, "PageDown did not scroll Controls")
	await tap(KEY_PAGEUP)
	check(s.pause_controls_scroll.scroll_vertical == 0, "PageUp did not scroll Controls to top")
	s.pause_howto_button.grab_focus()
	await tap(KEY_ENTER)
	check(s.pause_howto_panel.visible, "keyboard did not open How To Play")
	await tap(KEY_PAGEDOWN)
	check(s.pause_howto_scroll.scroll_vertical > 0, "PageDown did not scroll How To Play")
	s.pause_intro_button.grab_focus()
	await tap(KEY_ENTER)
	check(current_scene == s and paused and s.pause_restart_prompt.visible and s.pause_restart_prompt.cancel_button.has_focus(), "pause restart did not focus its cancel choice")
	await tap(KEY_ESCAPE)
	check(current_scene == s and paused and s.pause_menu_panel.visible and s.pause_intro_button.has_focus(), "pause restart Escape did not keep gameplay paused")
	await tap(KEY_ENTER)
	s.pause_restart_prompt.confirm_button.grab_focus()
	await tap(KEY_ENTER)
	check(current_scene.scene_file_path == "res://scenes/IntroCutscene.tscn" and not paused, "confirmed pause restart did not clear pause and route to UFO")
	await tap(KEY_ESCAPE)
	check_skip(current_scene, "UFO skip after replay")

	await open_scene("res://scenes/IntroCutscene.tscn")
	s = current_scene
	s.set_process(false)
	for line_index in range(1, 4):
		var line: Dictionary = s.IntroTimeline.SCENES[line_index]
		for offset in [0.1, float(line.rune_duration) + float(line.morph_duration) * 0.5]:
			s.timeline_time = float(line.start) + offset
			s._apply_timeline_time(s.timeline_time)
			await tap(KEY_SPACE)
			check(s.speech_text_label.text == str(line.english), "Next failed to resolve English: " + str(line.id))
			check(s.current_scene_id == str(line.id), "first Next skipped the line")
			await tap(KEY_SPACE)
			check(s.current_scene_id == str(s.IntroTimeline.SCENES[line_index + 1].id), "second Next did not advance")
	# Advance the fleet through its real input handler into the generated home.
	await tap(KEY_SPACE)
	s = current_scene
	check(s.family_intro_active and not s.possessed_dog_behavior_enabled, "UFO completion lost family handoff")
	await tap(KEY_ESCAPE)
	check(not s.family_intro_active and s.post_intro_meal_tutorial_active and s.post_intro_meal_exit_required, "family skip lost meal/tutorial handoff")
	check(s.first_exit_abduction_pending and not s.possessed_dog_behavior_enabled, "family skip lost the pending reveal")

	# Fresh skip for staged interaction/animation/UI regressions.
	await open_scene("res://scenes/Main.tscn")
	s = current_scene
	s.set_process(false)
	s.post_intro_meal_tutorial_active = false
	s.post_intro_meal_panel.hide()
	s.possessed_dog_tutorial_seen = true
	var park: Vector2 = s.dog_park.get_center()
	s.freya.global_position = Vector3(park.x, 0, park.y)
	# Keep two dogs in range: one possessed, one freed. All other NPC state stays
	# in the live world, outside this focused interaction loop.
	s.dogs = s.dogs.slice(0, 2)
	for i in range(2):
		var d: Dictionary = s.dogs[i]
		d.node.global_position = s.freya.global_position + Vector3(1.0 if i == 0 else -1.0, 0, 0)
		d.speed = 0.0
		d.dir = Vector3.ZERO
		d.wander = 999.0
		d.pref_timer = 999.0
		d.flee_timer = 0.0
		d.alien_possessed = i == 0
		d.army_aligned = false
		d.socialization_progress = 3.9 if i == 0 else 0.0
	s.freya_hunger = 0.0
	s.freya_vomit = 0.0
	Input.action_press("friendly_social")
	for i in range(45):
		s._update_dogs(0.1)
	Input.action_release("friendly_social")
	check(not s.dogs[0].army_aligned and s.dogs[0].socialization_progress == 0.0, "possessed contact recruited or banked progress")
	check(s.dogs[1].army_aligned, "freed dog in mixed group did not recruit")
	check(s.freya_hunger > 0.0 and s.freya_vomit > 0.0, "possessed social costs lost")
	# The real exorcism path must clear stale pre-cleanse progress too.
	s.dogs[0].socialization_progress = 3.9
	s.dogs[0] = s._update_exorcism_for_dog(s.dogs[0], 0, s.ALIEN_EXPEL_BARK_TIME, true, true)
	check(not s.dogs[0].alien_possessed and s.dogs[0].socialization_progress == 0.0, "cleanse retained stale recruitment progress")
	s.freya_hunger = 100.0
	Input.action_press("friendly_social")
	s._update_dogs(0.5)
	Input.action_release("friendly_social")
	check(s.dogs[0].socialization_progress == 0.0, "full Hunger advanced freed recruitment")
	# Army membership survives possession independently; it is not re-awarded.
	s.dogs[1].alien_possessed = true
	s.freya_hunger = 0.0
	Input.action_press("friendly_social")
	s._update_dogs(0.5)
	Input.action_release("friendly_social")
	check(s.dogs[1].army_aligned and s.dogs[1].alien_possessed, "possession changed existing army alignment")
	s.status_timer = 0.0
	s.dogs[1].exorcism_latched = false
	s.dogs[1] = s._update_exorcism_for_dog(s.dogs[1], 1, s.ALIEN_EXPEL_BARK_TIME, true, true)
	s.dogs[0].exorcism_latched = false
	s.dogs[0] = s._update_exorcism_for_dog(s.dogs[0], 0, s.ALIEN_EXPEL_BARK_TIME, true, true)
	check(s.status_label.text.contains("An alien fled"), "mixed-group wrong guess overwrote expulsion success")
	check(s.status_panel.visible, "status text has no visible background")
	await frames(2)
	check(s.status_panel.size.y < 150.0, "first status layout expanded into an empty tall panel")
	check(s.status_panel.get_global_rect().encloses(s.status_label.get_global_rect()), "status text exceeds its background")

	# Real input/collision path at the closed park fence. Camera defines forward.
	s.dogs.clear()
	# Compare the spatial broad phase against the previous exhaustive wall test
	# at wall corners and padded boundaries, including overlapping grid cells.
	for wall in s.store_walk_blockers:
		for pad in [0.0, 0.245, 0.45]:
			for point in [wall.position - Vector2(pad, pad), wall.end + Vector2(pad, pad), wall.get_center()]:
				var expected = false
				for other in s.store_walk_blockers:
					if other.grow(pad).has_point(point):
						expected = true
						break
				check(s._point_in_store_wall(point, pad) == expected, "spatial wall query changed a boundary")
	var occupied_index: int = s.store_building_indices[0]
	check(s._occupy_building_with_alien(occupied_index, 900002), "collision occupation setup")
	var footprint: Rect2 = s.buildings[occupied_index].footprint
	for pad in [0.0, 0.245, 0.45]:
		for point in [footprint.position - Vector2(pad, pad), footprint.end + Vector2(pad, pad), footprint.get_center()]:
			var expected = false
			for index in s.enterable_building_indices:
				var building: Dictionary = s.buildings[index]
				if building.get("alien_occupied", false) and building.footprint.grow(pad).has_point(point):
					expected = true
			check(s._point_in_occupied_store(point, pad) == expected, "spatial occupied-building query changed a boundary")
	s._clear_alien_occupation(occupied_index)
	check(not s._point_in_occupied_store(footprint.get_center(), 0.0), "cleared occupation retained a stale collision entry")
	s.freya.global_position = Vector3(park.x, 0, s.dog_park.position.y + 0.5)
	s.camera_node.position = s.freya.position + Vector3(0, 5, 6)
	s.camera_node.look_at(s.freya.position)
	Input.action_press("move_up")
	Input.action_press("run")
	for i in range(30):
		s._update_freya(0.1)
	var blocked_pos = s.freya.position
	s._update_freya(0.1)
	check(s.freya.position.distance_to(blocked_pos) < 0.01, "blocked movement setup did not hit the fence")
	check(s.freya._anim_player.current_animation == s.freya._anim_idle, "blocked Freya still uses locomotion")
	Input.action_release("move_up")
	Input.action_release("run")
	# Measured walk speed affects cadence; facing intent alone cannot start gait.
	s.freya.update_ground_motion(0.1, Vector3(0.2, 0, 0), Vector3.RIGHT, false)
	var slow_cadence = s.freya._anim_player.speed_scale
	s.freya.update_ground_motion(0.1, Vector3(0.46, 0, 0), Vector3.RIGHT, false)
	check(s.freya._anim_player.speed_scale > slow_cadence, "gait cadence ignores displacement")
	s.freya.update_ground_motion(0.1, Vector3.ZERO, Vector3.RIGHT, true)
	check(s.freya._anim_player.current_animation == s.freya._anim_idle, "intent restarted stopped gait")

	s.claim_meter_panel.show()
	s.claim_meter_label.text = "Aliens 8 · Reinforced ×4"
	await frames(4)
	check(s.claim_meter_bar.size.x <= s.claim_meter_panel.size.x - 20.0, "claim bar exceeds panel bounds")
	check(s.claim_meter_bar.get_global_rect().end.x <= s.claim_meter_panel.get_global_rect().end.x, "claim bar protrudes from panel")
	for window_size in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(800, 450)]:
		root.size = window_size
		await frames()
		for target_type in [s.CLAIM_TARGET_TREE, s.CLAIM_TARGET_LIGHT_POLE, s.CLAIM_TARGET_FIRE_HYDRANT, s.CLAIM_TARGET_MAILBOX, s.CLAIM_TARGET_BUILDING, s.CLAIM_TARGET_ALIEN_BUILDING]:
			s.active_claim_target_type = target_type
			s.active_claim_target_index = 0
			var target: Vector3 = s._claim_target_world_position(target_type, 0)
			s.camera_node.global_position = target + Vector3(4, 6, 5)
			s.camera_node.look_at(target)
			Input.action_press("claim")
			s._update_claim_meter_overlay()
			await frames()
			check(s.claim_meter_panel.visible, "claim layout case was not actually shown")
			var panel: Rect2 = s.claim_meter_panel.get_global_rect()
			check(root.get_visible_rect().encloses(panel), "claim panel leaves viewport at " + str(window_size))
			check(panel.encloses(s.claim_meter_bar.get_global_rect()), "claim bar leaves panel at " + str(window_size))
			check(panel.encloses(s.claim_meter_label.get_global_rect()), "claim label leaves panel at " + str(window_size))
			Input.action_release("claim")
	root.size = Vector2i(1280, 720)
	# Stage ownership only; the unchanged victory predicate and acknowledgment
	# run through production code. Last-building timed claiming has separate checks.
	s.freya_victory_complete = false
	s._check_victory_condition()
	check(not s.freya_victory_complete and not s.victory_panel.visible, "victory fired without full ownership")
	for i in range(s.buildings.size()):
		s.buildings[i] = s._apply_claim_owner_to_entry(s.buildings[i], s.CLAIM_OWNER_FREYA)
	s._check_victory_condition()
	check(s.freya_victory_complete and s.victory_panel.visible, "completion has no acknowledgment")
	for window_size in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(800, 450)]:
		root.size = window_size
		await frames(4)
		var panel: Rect2 = s.victory_panel.get_global_rect()
		check(root.get_visible_rect().encloses(panel), "completion panel leaves viewport at " + str(window_size))
		check(panel.encloses(s.victory_continue_button.get_global_rect()), "completion button leaves panel")
	root.size = Vector2i(1280, 720)
	await tap(KEY_ENTER)
	check(not s.victory_panel.visible, "completion acknowledgment cannot continue exploring")
	for i in range(61):
		s._process(0.1)
	check(s.territory_label.text.contains("Neighborhood complete!") and s._objectives_text().contains("Neighborhood complete!"), "completion disappears when status expires")
	check(s.status_timer <= 0.0, "completion persistence test did not outlast temporary status")
	if failures.is_empty():
		print("DEJANK_FLOW_OK: input routes, food, replay, Next phases, recruitment, blocked gait, claim bounds, outcome priority, and persistent completion")
	else:
		push_error("DEJANK_FLOW_FAIL: " + ", ".join(failures))
	quit(0 if failures.is_empty() else 1)
