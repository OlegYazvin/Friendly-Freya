extends "res://tests/natural_campaign_route.gd"

# A focused keyboard route through the full opening. Reuse the natural route's
# input and walkability helpers; this script never advances a scene or changes
# gameplay progress by calling an action method directly.
const IntroTimelineScript = preload("res://scripts/intro_timeline.gd")
const FamilyIntroTimelineScript = preload("res://scripts/family_intro_timeline.gd")
const INTRO_SCENE_PATH = "res://scenes/IntroCutscene.tscn"
const MAIN_SCENE_PATH = "res://scenes/Main.tscn"

var first_exit_full_thought_advanced = false


func _tap(code: Key) -> void:
	if code == KEY_SPACE and game != null and is_instance_valid(game) and game.first_exit_abduction_active:
		if game.first_exit_continue_button != null and game.first_exit_continue_button.visible:
			first_exit_full_thought_advanced = game.first_exit_thought_label != null and game.first_exit_thought_label.text == game.FIRST_EXIT_IMMUNITY_TEXT
	await super._tap(code)


func _wait_for_scene(path: String, seconds: float = 12.0) -> bool:
	var deadline = Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if current_scene != null and current_scene.scene_file_path == path:
			return true
		await process_frame
	_fail("scene did not reach %s" % path)
	return false


func _watch_ufo_by_input() -> bool:
	if not await _wait_for_scene(INTRO_SCENE_PATH):
		return false
	var intro: Node = current_scene
	if intro.current_scene_id != str(IntroTimelineScript.SCENES[0]["id"]):
		_fail("UFO intro did not start at the establishing scene")
		return false
	await _tap(KEY_SPACE)
	if intro.current_scene_id != str(IntroTimelineScript.SCENES[1]["id"]):
		_fail("Space did not advance the UFO establishing scene")
		return false

	# Let the first translated line finish at its natural pace. It must stay
	# visible after its authored scene end until the player presses Next.
	var first_line: Dictionary = IntroTimelineScript.SCENES[1]
	var deadline = Time.get_ticks_msec() + 12000
	while Time.get_ticks_msec() < deadline and intro.timeline_time < float(first_line["end"]) - 0.03:
		await process_frame
	if intro.current_scene_id != str(first_line["id"]) or intro.speech_text_label.text != str(first_line["english"]):
		_fail("first UFO English line did not become complete and readable")
		return false
	await create_timer(0.4).timeout
	if current_scene != intro or intro.current_scene_id != str(first_line["id"]) or intro.speech_text_label.text != str(first_line["english"]):
		_fail("UFO English line disappeared before Space/Next")
		return false
	print("WATCH_INTRO_UFO_HOLD_OK scene=%s time=%.2f" % [intro.current_scene_id, intro.timeline_time])
	await _tap(KEY_SPACE)
	if intro.current_scene_id != str(IntroTimelineScript.SCENES[2]["id"]):
		_fail("Space did not advance the held UFO English line")
		return false

	var visited: Dictionary = {str(IntroTimelineScript.SCENES[0]["id"]): true, str(first_line["id"]): true}
	for tap_index in range(16):
		if current_scene != intro:
			break
		visited[str(intro.current_scene_id)] = true
		await _tap(KEY_SPACE)
	if not await _wait_for_scene(MAIN_SCENE_PATH):
		return false
	for scene in IntroTimelineScript.SCENES:
		if not visited.has(str(scene["id"])):
			_fail("UFO Next route missed %s" % scene["id"])
			return false
	print("WATCH_INTRO_UFO_NEXT_OK scenes=%d" % visited.size())
	return true


func _watch_family_by_input() -> bool:
	if not game.family_intro_active or game.family_intro_static:
		_fail("Watch Intro did not enter the live-home family sequence")
		return false
	if game.family_intro_current_scene_id != str(FamilyIntroTimelineScript.SCENES[0]["id"]):
		_fail("family intro did not start at the home establishing scene")
		return false
	await _tap(KEY_SPACE)
	var first_line: Dictionary = FamilyIntroTimelineScript.SCENES[1]
	if game.family_intro_current_scene_id != str(first_line["id"]):
		_fail("Space did not advance the family establishing scene")
		return false
	var deadline = Time.get_ticks_msec() + 12000
	while Time.get_ticks_msec() < deadline and game.family_intro_time < float(first_line["end"]) - 0.03:
		await process_frame
	if game.family_intro_current_scene_id != str(first_line["id"]) or game.family_dialogue_label.text != str(first_line["text"]):
		_fail("first family line did not become complete and readable")
		return false
	await create_timer(0.4).timeout
	if not game.family_intro_active or game.family_intro_current_scene_id != str(first_line["id"]) or game.family_dialogue_label.text != str(first_line["text"]):
		_fail("family dialogue disappeared before Space/Next")
		return false
	print("WATCH_INTRO_FAMILY_HOLD_OK scene=%s time=%.2f" % [game.family_intro_current_scene_id, game.family_intro_time])
	await _tap(KEY_SPACE)
	if game.family_intro_current_scene_id != str(FamilyIntroTimelineScript.SCENES[2]["id"]):
		_fail("Space did not advance the held family line")
		return false

	var visited: Dictionary = {str(FamilyIntroTimelineScript.SCENES[0]["id"]): true, str(first_line["id"]): true}
	for tap_index in range(48):
		if not game.family_intro_active:
			break
		visited[str(game.family_intro_current_scene_id)] = true
		await _tap(KEY_SPACE)
	if game.family_intro_active:
		_fail("family intro remained active after keyboard Next sequence")
		return false
	for scene in FamilyIntroTimelineScript.SCENES:
		if not visited.has(str(scene["id"])):
			_fail("family Next route missed %s" % scene["id"])
			return false
	if not game.post_intro_meal_tutorial_active or not game.post_intro_meal_exit_required or not game.first_exit_abduction_pending:
		_fail("family handoff did not require the meal and first-exit reveal")
		return false
	print("WATCH_INTRO_FAMILY_NEXT_OK scenes=%d" % visited.size())
	return true


func _run() -> void:
	_cleanup_save()
	route_started_ms = Time.get_ticks_msec()
	if change_scene_to_file("res://scenes/Startup.tscn") != OK:
		_fail("could not open Startup")
		quit(1)
		return
	await scene_changed
	await _frames(3)
	current_scene.watch_intro_button.grab_focus()
	await _tap(KEY_ENTER)
	if await _watch_ufo_by_input():
		game = current_scene
		game.game_save_test_path = TEST_SAVE_PATH
		if await _watch_family_by_input():
			_build_navigation()
			if await _walk_to(game.freya_home_bowl_position, 1.05):
				await _tap(KEY_F)
				if game.freya_hunger > 1.0 or not game.post_intro_meal_tutorial_completed:
					_fail("F at the live-home bowl did not finish the required meal")
				else:
					print("WATCH_INTRO_MEAL_OK hunger=%.1f" % game.freya_hunger)
					var home: Dictionary = game.buildings[game.freya_home_index]
					var outside: Vector2 = home.get("home_layout", {}).get("entry_outside_pos", Vector2.ZERO)
					if await _walk_to(outside, 0.9):
						if game.possessed_dog_tutorial_active:
							await _tap(KEY_SPACE)
						await _frames(4)
						if game.freya_inside_home or not game.first_exit_abduction_completed or game.first_exit_abduction_active or not first_exit_full_thought_advanced:
							_fail("home exit did not complete the full first-exit thought through Space")
						if not game.first_exit_freya_immunity_confirmed or not game.possessed_dog_behavior_enabled or game.first_exit_abduction_pending:
							_fail("first-exit reveal did not return to ordinary dog gameplay")
						if failures.is_empty():
							print("WATCH_INTRO_FIRST_EXIT_OK pos=%s immunity=%s" % [_world_position(), game.first_exit_freya_immunity_confirmed])
	_release_movement()
	_cleanup_save()
	if failures.is_empty():
		print("WATCH_INTRO_ROUTE_OK: Watch Intro, held English dialogue, family Next, meal, first-exit thought, and gameplay used keyboard input")
		quit()
	else:
		push_error("WATCH_INTRO_ROUTE_FAIL: " + ", ".join(failures))
		quit(1)
