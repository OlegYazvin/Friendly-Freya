extends SceneTree

# Real-frame check for the optional press-once controls. The fixture prepares
# an eligible interior and a clean dog; only keyboard input advances them.
var failures: Array[String] = []
var game: Node


func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	set_meta("freya_perf_stress_no_save", true)
	create_timer(55.0).timeout.connect(_watchdog_timeout)
	call_deferred("_run")


func _watchdog_timeout() -> void:
	push_error("CLAIM_INPUT_LIVE_FAIL: test timed out")
	quit(1)


func _check(condition: bool, description: String) -> bool:
	if condition:
		return true
	failures.append(description)
	push_error("CLAIM_INPUT_LIVE: " + description)
	return false


func _frames(count: int = 2) -> void:
	for _index in range(count):
		await process_frame


func _tap(code: Key) -> void:
	for down in [true, false]:
		var event = InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await _frames()


func _stage_interior() -> int:
	for index in game.enterable_building_indices:
		if index == game.freya_home_index or index == game.kennel_building_index:
			continue
		if bool(game.buildings[index].get("alien_occupied", false)) or game._building_is_controlled_by_freya(index) or not game._building_has_adjacent_freya_control(index):
			continue
		for item in game._building_surrounding_claimables(index):
			game._set_claim_owner(int(item.get("type", -1)), int(item.get("index", -1)), game.CLAIM_OWNER_FREYA)
		if not bool(game._building_claim_status(index).get("eligible", false)):
			continue
		var interior: Rect2 = game.buildings[index].get("store_interior_rect", Rect2())
		var center = interior.get_center()
		game.freya.global_position = Vector3(center.x, 0.0, center.y)
		var target: Dictionary = game._find_nearest_claim_target()
		if bool(target.get("found", false)) and int(target.get("type", -1)) == game.CLAIM_TARGET_BUILDING and int(target.get("index", -1)) == index:
			return index
	return -1


func _stage_clean_dog() -> int:
	var candidate = -1
	for index in range(game.dogs.size()):
		if not bool(game.dogs[index].get("army_aligned", false)):
			candidate = index
			break
	if candidate < 0:
		return -1
	var dog: Dictionary = game.dogs[candidate]
	var node: Node3D = dog.get("node", null)
	if node == null or not is_instance_valid(node):
		return -1
	node.global_position = game.freya.global_position + Vector3(0.9, 0.0, 0.0)
	var selected = game._nearest_social_dog_index()
	if selected < 0:
		return -1
	dog = game.dogs[selected]
	dog["alien_possessed"] = false
	dog["speed"] = 0.0
	dog["wander"] = 999.0
	dog["flee_timer"] = 0.0
	dog["socialization_progress"] = 0.0
	game.dogs[selected] = dog
	return selected


func _run() -> void:
	if not _check(change_scene_to_file("res://scenes/Main.tscn") == OK, "could not open Main"):
		_finish()
		return
	await scene_changed
	game = current_scene
	await _frames()
	game._complete_post_intro_meal_tutorial()
	game.possessed_dog_behavior_enabled = false
	game.possessed_dog_tutorial_seen = true
	game.freya_hunger = 0.0
	game.tap_to_claim_enabled = true
	var building_index = _stage_interior()
	if not _check(building_index >= 0, "no connected clean interior fixture"):
		_finish()
		return
	await _frames()

	var started_at = game.world_time
	await _tap(KEY_SPACE)
	if not _check(game.tap_claim_active and not Input.is_action_pressed("claim"), "Space did not keep the interior action active after release"):
		_finish()
		return
	var first_progress = float(game.buildings[building_index].get("claim_progress", 0.0))
	await create_timer(0.4).timeout
	if not _check(game.tap_claim_active and float(game.buildings[building_index].get("claim_progress", 0.0)) > first_progress, "interior claim did not advance across live frames after Space release"):
		_finish()
		return
	var claim_deadline = Time.get_ticks_msec() + 18000
	while Time.get_ticks_msec() < claim_deadline and not game._building_is_controlled_by_freya(building_index):
		await process_frame
	if not _check(game._building_is_controlled_by_freya(building_index) and not game.tap_claim_active and not Input.is_action_pressed("claim"), "released Space did not finish and stop the live interior claim"):
		_finish()
		return
	print("CLAIM_INPUT_LIVE_INTERIOR_OK index=%d world_seconds=%.2f" % [building_index, game.world_time - started_at])

	game.freya_hunger = 0.0
	var dog_index = _stage_clean_dog()
	if not _check(dog_index >= 0, "no clean dog fixture"):
		_finish()
		return
	await _frames()
	await _tap(KEY_C)
	if not _check(game.tap_social_active and game.tap_social_dog_index == dog_index and not Input.is_action_pressed("friendly_social"), "C did not lock the selected dog after release"):
		_finish()
		return
	var first_social_progress = float(game.dogs[dog_index].get("socialization_progress", 0.0))
	await create_timer(0.4).timeout
	if not _check(float(game.dogs[dog_index].get("socialization_progress", 0.0)) > first_social_progress, "socializing did not advance across live frames after C release"):
		_finish()
		return
	var recruit_deadline = Time.get_ticks_msec() + 9000
	while Time.get_ticks_msec() < recruit_deadline and not bool(game.dogs[dog_index].get("army_aligned", false)):
		await process_frame
	_check(bool(game.dogs[dog_index].get("army_aligned", false)) and not game.tap_social_active and not Input.is_action_pressed("friendly_social"), "released C did not recruit and auto-stop in live play")
	_finish()


func _finish() -> void:
	Input.action_release("claim")
	Input.action_release("friendly_social")
	paused = false
	if failures.is_empty():
		print("CLAIM_INPUT_LIVE_OK: released Space completed an interior claim and released C recruited a dog through live frames")
		quit()
	else:
		push_error("CLAIM_INPUT_LIVE_FAIL: " + ", ".join(failures))
		quit(1)
