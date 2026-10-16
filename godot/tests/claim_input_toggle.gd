extends SceneTree

const InputPreferences = preload("res://scripts/input_preferences.gd")
const TEST_SETTINGS_PATH = "user://friendly_freya_press_to_continue_test.cfg"
var failures: Array[String] = []


func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	create_timer(75.0).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run")


func _on_watchdog_timeout() -> void:
	push_error("CLAIM_INPUT_TOGGLE_FAIL: test timed out")
	quit(1)


func _check(condition: bool, description: String) -> void:
	if condition:
		return
	failures.append(description)
	push_error("CLAIM_INPUT_TOGGLE: " + description)


func _frames(count: int = 2) -> void:
	for _index in range(count):
		await process_frame


func _key(code: Key, pressed: bool) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await _frames()


func _tap(code: Key) -> void:
	await _key(code, true)
	await _key(code, false)


func _place_at_unclaimed_tree(scene: Node) -> Dictionary:
	for tree_index in range(scene.trees.size()):
		var tree: Dictionary = scene.trees[tree_index]
		if scene._entry_is_claimed(tree):
			continue
		var position: Vector2 = tree.get("pos", Vector2.ZERO)
		scene.freya.global_position = Vector3(position.x, 0.0, position.y)
		var target: Dictionary = scene._find_nearest_claim_target()
		if bool(target.get("found", false)) and int(target.get("type", -1)) == scene.CLAIM_TARGET_TREE and int(target.get("index", -1)) == tree_index:
			return target
	return {}


func _run() -> void:
	_check(change_scene_to_file("res://scenes/Main.tscn") == OK, "could not open Main")
	await scene_changed
	var scene = current_scene
	scene.set_process(false)
	var old_size = root.size
	scene.tap_to_claim_enabled = false
	scene.pause_tap_claim_checkbox.set_pressed_no_signal(false)
	scene.input_preferences_path = TEST_SETTINGS_PATH
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS_PATH))

	var target = _place_at_unclaimed_tree(scene)
	_check(not target.is_empty(), "no isolated tree claim target")
	if target.is_empty():
		_finish(scene, old_size)
		return
	var tree_index = int(target.get("index", -1))
	scene.camera_focus = scene.freya.global_position + Vector3(0.0, 0.95, 0.0)
	scene._update_camera(0.0)

	# The original hold control remains the default and resets a released mark.
	Input.action_press("claim")
	scene._update_claiming(0.35)
	_check(float(scene.trees[tree_index].get("claim_progress", 0.0)) > 0.0, "default hold did not advance a mark")
	Input.action_release("claim")
	await _frames()
	scene._update_claiming(0.2)
	_check(float(scene.trees[tree_index].get("claim_progress", 0.0)) == 0.0, "default release did not reset a mark")

	# Enable the saved option through the same focused pause control a keyboard
	# player uses, at both supported small review sizes.
	for window_size in [Vector2i(800, 450), Vector2i(960, 540)]:
		root.size = window_size
		await _frames()
		scene._toggle_pause_menu(1, false)
		if not scene.pause_controls_panel.visible:
			scene._on_pause_controls_pressed()
		await _frames()
		_check(scene.pause_tap_claim_checkbox.has_focus(), "Controls did not focus the press-once option at " + str(window_size))
		_check(root.get_visible_rect().encloses(scene.pause_tap_claim_checkbox.get_global_rect()), "press-once option leaves viewport at " + str(window_size))
		_check(scene.pause_controls_panel.get_global_rect().encloses(scene.pause_tap_claim_checkbox.get_global_rect()), "press-once option leaves Controls panel at " + str(window_size))
		if window_size == Vector2i(800, 450):
			await _tap(KEY_ENTER)
			_check(scene.tap_to_claim_enabled and scene.pause_tap_claim_checkbox.button_pressed, "Enter did not enable press-once controls")
			_check(InputPreferences.load_press_to_continue(TEST_SETTINGS_PATH), "press-once setting did not persist")
		scene._toggle_pause_menu(0, false)
		await _frames()

	Input.action_press("claim")
	scene._update_claiming(0.35)
	_check(scene.tap_claim_active and scene.tap_claim_target_type == scene.CLAIM_TARGET_TREE and scene.tap_claim_target_index == tree_index, "first Space did not lock the tree")
	var first_progress = float(scene.trees[tree_index].get("claim_progress", 0.0))
	Input.action_release("claim")
	await _frames()
	scene._update_claiming(0.35)
	_check(scene.tap_claim_active and float(scene.trees[tree_index].get("claim_progress", 0.0)) > first_progress, "tree progress did not continue after Space release")
	for window_size in [Vector2i(800, 450), Vector2i(960, 540)]:
		root.size = window_size
		await _frames()
		scene._update_claim_meter_overlay()
		_check(scene.claim_meter_panel.visible and scene.claim_meter_hint_label.visible, "active tap claim lacks a visible cancel cue at " + str(window_size))
		_check(Rect2(Vector2.ZERO, scene.claim_meter_panel.size).encloses(scene.claim_meter_hint_label.get_rect()), "cancel cue leaves claim meter at " + str(window_size))
		_check(root.get_visible_rect().encloses(scene.claim_meter_panel.get_global_rect()), "claim meter leaves viewport at " + str(window_size))
		scene.claim_meter_label.text = "Aliens 8 · Reinforced ×4"
		await _frames()
		_check(scene.claim_meter_bar.get_global_rect().end.y <= scene.claim_meter_hint_label.get_global_rect().position.y, "long claim label overlaps cancel cue at " + str(window_size))
		scene._update_claim_meter_overlay()

	Input.action_press("claim")
	scene._update_claiming(0.1)
	_check(not scene.tap_claim_active and float(scene.trees[tree_index].get("claim_progress", 0.0)) == 0.0, "second Space did not stop/reset a mark")
	Input.action_release("claim")
	await _frames()

	Input.action_press("claim")
	scene._update_claiming(0.35)
	Input.action_release("claim")
	await _frames()
	Input.action_press("move_right")
	scene._update_claiming(0.1)
	_check(not scene.tap_claim_active and float(scene.trees[tree_index].get("claim_progress", 0.0)) == 0.0, "movement did not stop/reset tap claim")
	Input.action_release("move_right")
	await _frames()

	Input.action_press("claim")
	scene._update_claiming(0.35)
	Input.action_release("claim")
	await _frames()
	_check(scene.tap_claim_active, "focus-loss claim fixture did not arm")
	scene.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	_check(not scene.tap_claim_active and scene.active_claim_target_type == scene.CLAIM_TARGET_NONE and float(scene.trees[tree_index].get("claim_progress", 0.0)) == 0.0, "window focus loss did not stop/reset tap claim")

	Input.action_press("claim")
	scene._update_claiming(0.35)
	Input.action_release("claim")
	await _frames()
	scene.freya.global_position += Vector3(0.5, 0.0, 0.0)
	scene._update_claiming(0.1)
	_check(not scene.tap_claim_active, "displacement did not stop tap claim")
	scene.freya.global_position -= Vector3(0.5, 0.0, 0.0)
	await _frames()
	Input.action_press("claim")
	scene._update_claiming(0.35)
	Input.action_release("claim")
	await _frames()
	scene._set_claim_owner(scene.CLAIM_TARGET_TREE, tree_index, scene.CLAIM_OWNER_FREYA)
	scene._update_claiming(0.1)
	_check(not scene.tap_claim_active and scene.active_claim_target_type == scene.CLAIM_TARGET_NONE, "unavailable Space target retargeted without a new press")
	scene._set_claim_owner(scene.CLAIM_TARGET_TREE, tree_index, scene.CLAIM_OWNER_NONE)
	await _frames()
	Input.action_press("aggressive_social")
	Input.action_press("claim")
	scene._update_claiming(0.2)
	_check(not scene.tap_claim_active, "R bark with Space unexpectedly armed a tap claim")
	Input.action_release("claim")
	Input.action_release("aggressive_social")
	await _frames()

	var dumpster_index = -1
	for index in range(scene.dumpsters.size()):
		if not bool(scene.dumpsters[index].get("searched", false)):
			dumpster_index = index
			break
	_check(dumpster_index >= 0, "no unsearched dumpster for Space priority")
	if dumpster_index >= 0:
		var dumpster_pos: Vector2 = scene.dumpsters[dumpster_index].get("pos", Vector2.ZERO)
		scene.freya.global_position = Vector3(dumpster_pos.x, 0.0, dumpster_pos.y)
		Input.action_press("claim")
		scene._update_claiming(0.2)
		_check(bool(scene.dumpsters[dumpster_index].get("searched", false)) and not scene.tap_claim_active, "dumpster search did not stay a one-press action")
		Input.action_release("claim")
		await _frames()

	# Stage only the prerequisites; Space itself must complete the entire ten-
	# second interior action after the physical key has been released.
	var building_index = -1
	for index in scene.enterable_building_indices:
		if index == scene.freya_home_index or index == scene.kennel_building_index:
			continue
		if bool(scene.buildings[index].get("alien_occupied", false)) or scene._building_is_controlled_by_freya(index) or not scene._building_has_adjacent_freya_control(index):
			continue
		for item in scene._building_surrounding_claimables(index):
			scene._set_claim_owner(int(item.get("type", -1)), int(item.get("index", -1)), scene.CLAIM_OWNER_FREYA)
		if not bool(scene._building_claim_status(index).get("eligible", false)):
			continue
		var interior: Rect2 = scene.buildings[index].get("store_interior_rect", Rect2())
		var center = interior.get_center()
		scene.freya.global_position = Vector3(center.x, 0.0, center.y)
		var interior_target: Dictionary = scene._find_nearest_claim_target()
		if bool(interior_target.get("found", false)) and int(interior_target.get("type", -1)) == scene.CLAIM_TARGET_BUILDING and int(interior_target.get("index", -1)) == index:
			building_index = index
			break
	_check(building_index >= 0, "no connected interior for ten-second tap claim")
	if building_index >= 0:
		Input.action_press("claim")
		scene._update_claiming(0.4)
		Input.action_release("claim")
		await _frames()
		scene._update_claiming(9.8)
		_check(scene._building_is_controlled_by_freya(building_index) and not scene.tap_claim_active, "released Space did not finish interior claim")

	# C locks a single dog so a nearby reserve cannot silently become the target.
	scene.freya_hunger = 0.0
	var recruit_index = -1
	for dog_index in range(scene.dogs.size()):
		if not bool(scene.dogs[dog_index].get("army_aligned", false)):
			recruit_index = dog_index
			break
	_check(recruit_index >= 0, "no recruitable test dog")
	if recruit_index >= 0:
		var recruit: Dictionary = scene.dogs[recruit_index]
		recruit["alien_possessed"] = false
		recruit["speed"] = 0.0
		recruit["wander"] = 999.0
		recruit["socialization_progress"] = 0.0
		(recruit["node"] as Node3D).global_position = scene.freya.global_position + Vector3(1.0, 0.0, 0.0)
		scene.dogs[recruit_index] = recruit
		Input.action_press("friendly_social")
		scene._update_tap_social_input()
		_check(scene.tap_social_active and scene.tap_social_dog_index == recruit_index, "first C did not lock an independent dog")
		Input.action_release("friendly_social")
		await _frames()
		scene._update_dogs(0.6)
		_check(float(scene.dogs[recruit_index].get("socialization_progress", 0.0)) > 0.0, "C socializing did not continue after release")
		Input.action_press("friendly_social")
		scene._update_tap_social_input()
		_check(not scene.tap_social_active, "second C did not stop socializing")
		Input.action_release("friendly_social")
		await _frames()

		Input.action_press("friendly_social")
		scene._update_tap_social_input()
		Input.action_release("friendly_social")
		await _frames()
		_check(scene.tap_social_active, "focus-loss social fixture did not arm")
		scene.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		_check(not scene.tap_social_active, "application focus loss did not stop socializing")

		Input.action_press("friendly_social")
		scene._update_tap_social_input()
		Input.action_release("friendly_social")
		await _frames()
		Input.action_press("move_left")
		scene._update_tap_social_input()
		_check(not scene.tap_social_active, "movement did not stop socializing")
		Input.action_release("move_left")
		await _frames()
		scene.freya_hunger = 100.0
		Input.action_press("friendly_social")
		scene._update_tap_social_input()
		_check(not scene.tap_social_active, "full Hunger armed an unusable C action")
		Input.action_release("friendly_social")
		scene.freya_hunger = 0.0
		await _frames()

		Input.action_press("friendly_social")
		scene._update_tap_social_input()
		Input.action_release("friendly_social")
		await _frames()
		(recruit["node"] as Node3D).global_position += Vector3(10.0, 0.0, 0.0)
		scene._update_tap_social_input()
		_check(not scene.tap_social_active, "out-of-range dog kept C socializing active")
		(recruit["node"] as Node3D).global_position = scene.freya.global_position + Vector3(1.0, 0.0, 0.0)
		await _frames()

		Input.action_press("friendly_social")
		scene._update_tap_social_input()
		Input.action_release("friendly_social")
		await _frames()
		scene._toggle_pause_menu(1, false)
		_check(not scene.tap_social_active, "pause did not stop socializing")
		scene._toggle_pause_menu(0, false)
		await _frames()

		Input.action_press("friendly_social")
		scene._update_tap_social_input()
		Input.action_release("friendly_social")
		await _frames()
		for _step in range(10):
			if not scene.tap_social_active:
				break
			scene._update_dogs(0.5)
		_check(bool(scene.dogs[recruit_index].get("army_aligned", false)) and not scene.tap_social_active, "recruitment did not auto-stop C")

	_finish(scene, old_size)


func _finish(scene: Node, old_size: Vector2i) -> void:
	Input.action_release("claim")
	Input.action_release("friendly_social")
	Input.action_release("move_left")
	Input.action_release("move_right")
	paused = false
	root.size = old_size
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS_PATH))
	if failures.is_empty():
		print("CLAIM_INPUT_TOGGLE_OK: keyboard setting, object/interior claims, single-dog recruitment, target/focus/stop safety, and 800/960 UI bounds")
		quit()
	else:
		push_error("CLAIM_INPUT_TOGGLE_FAIL: " + ", ".join(failures))
		quit(1)
