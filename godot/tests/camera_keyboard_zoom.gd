extends SceneTree

# Exercise physical keyboard zoom through Godot's input dispatch, including
# the existing zoom limits and the paused-game guard.
var failures: Array[String] = []


func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	create_timer(75.0).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run")


func _on_watchdog_timeout() -> void:
	push_error("CAMERA_KEYBOARD_ZOOM_FAIL: test timed out")
	quit(1)


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
		push_error("CAMERA_KEYBOARD_ZOOM: " + description)


func _tap(key_code: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key_code
		event.physical_keycode = key_code
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame


func _run() -> void:
	_check(change_scene_to_file("res://scenes/Main.tscn") == OK, "could not open Main")
	await scene_changed
	var scene = current_scene
	scene.set_process(false)
	_check(scene._action_has_key("camera_zoom_in", KEY_EQUAL), "equals key is not bound to zoom in")
	_check(scene._action_has_key("camera_zoom_out", KEY_MINUS), "minus key is not bound to zoom out")
	var controls_text: String = scene.pause_controls_scroll.get_child(0).text
	var howto_text: String = scene.pause_howto_scroll.get_child(0).text
	_check("- / =" in controls_text, "pause controls omit keyboard zoom")
	_check("-/=" in howto_text, "How To Play omits keyboard zoom")

	var start_zoom: float = scene.camera_zoom_target
	await _tap(KEY_EQUAL)
	_check(is_equal_approx(scene.camera_zoom_target, start_zoom - scene.CAMERA_ZOOM_STEP), "equals key did not zoom in")
	await _tap(KEY_MINUS)
	_check(is_equal_approx(scene.camera_zoom_target, start_zoom), "minus key did not zoom out")

	scene.camera_zoom_target = scene.CAMERA_ZOOM_MIN
	await _tap(KEY_EQUAL)
	_check(is_equal_approx(scene.camera_zoom_target, scene.CAMERA_ZOOM_MIN), "keyboard zoom passed the minimum distance")
	scene.camera_zoom_target = scene.CAMERA_ZOOM_MAX
	await _tap(KEY_MINUS)
	_check(is_equal_approx(scene.camera_zoom_target, scene.CAMERA_ZOOM_MAX), "keyboard zoom passed the maximum distance")

	scene._toggle_pause_menu(1, false)
	var paused_zoom: float = scene.camera_zoom_target
	await _tap(KEY_EQUAL)
	_check(is_equal_approx(scene.camera_zoom_target, paused_zoom), "keyboard zoom changed the paused game")
	scene._toggle_pause_menu(0, false)
	await _tap(KEY_EQUAL)
	_check(is_equal_approx(scene.camera_zoom_target, paused_zoom - scene.CAMERA_ZOOM_STEP), "keyboard zoom did not resume after pause")

	if failures.is_empty():
		print("CAMERA_KEYBOARD_ZOOM_OK: equals/minus input, limits, pause guard, and help text")
		quit()
	else:
		push_error("CAMERA_KEYBOARD_ZOOM_FAIL: " + ", ".join(failures))
		quit(1)
