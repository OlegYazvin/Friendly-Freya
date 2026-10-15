extends SceneTree

# Isolated input and save-byte checks for starting over from title and pause.
const GameSaveScript = preload("res://scripts/game_save.gd")
const TEST_PATH = "user://friendly_freya_new_game_test.json"

var failures: Array[String] = []


func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	create_timer(120.0).timeout.connect(_watchdog_timeout)
	call_deferred("_run")


func _watchdog_timeout() -> void:
	_cleanup()
	push_error("NEW_GAME_SAFETY_FAIL: test timed out")
	quit(1)


func _check(ok: bool, description: String) -> void:
	if not ok:
		failures.append(description)
		push_error("NEW_GAME_SAFETY: " + description)


func _frames(count: int = 3) -> void:
	for i in range(count):
		await process_frame


func _tap(code: Key) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(2)
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(2)


func _open_scene(path: String) -> void:
	paused = false
	_check(change_scene_to_file(path) == OK, "could not open " + path)
	await scene_changed
	await _frames(2)


func _cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH + suffix))


func _future_envelope(state: Dictionary) -> String:
	var future = state.duplicate(true)
	future["version"] = GameSaveScript.VERSION + 1
	var payload = JSON.stringify(future)
	var hash = HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(payload.to_utf8_buffer())
	return JSON.stringify({"format": "friendly_freya", "payload": payload, "sha256": hash.finish().hex_encode()})


func _write_text(path: String, content: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "could not create isolated save file")
	if file != null:
		file.store_string(content)
		file.close()


func _run() -> void:
	_cleanup()
	await _open_scene("res://scenes/Main.tscn")
	var game = current_scene
	var snapshot: Dictionary = game._snapshot_game_state()
	_check(GameSaveScript.write_save(snapshot, TEST_PATH), "valid test save could not be written")
	var original = FileAccess.get_file_as_string(TEST_PATH)

	await _open_scene("res://scenes/Startup.tscn")
	var title = current_scene
	title.resume_save_path = TEST_PATH
	_check(title.watch_intro_button.text == "New Game: Watch Intro" and title.skip_to_game_button.text == "New Game: Skip Intro", "fresh-start title choices are not explicit")
	title.skip_to_game_button.grab_focus()
	await _tap(KEY_ENTER)
	_check(current_scene == title and title.fresh_start_prompt.visible and title.fresh_start_prompt.cancel_button.has_focus(), "saved title Skip did not open a cancel-focused confirmation")
	await _tap(KEY_ESCAPE)
	_check(current_scene == title and not title.fresh_start_prompt.visible and title.skip_to_game_button.has_focus(), "Escape did not cancel title new game")
	_check(FileAccess.get_file_as_string(TEST_PATH) == original, "title cancel changed the saved campaign")
	await _tap(KEY_ENTER)
	title.fresh_start_prompt.confirm_button.grab_focus()
	await _tap(KEY_ENTER)
	_check(current_scene.scene_file_path == "res://scenes/Main.tscn", "confirmed title Skip did not start a new game")
	_check(FileAccess.get_file_as_string(TEST_PATH) == original, "confirming a new game rewrote the old save before autosave")

	game = current_scene
	game.game_save_test_path = TEST_PATH
	game._toggle_pause_menu(1, false)
	game.pause_intro_button.grab_focus()
	await _tap(KEY_ENTER)
	_check(game.pause_menu_open and paused and game.pause_restart_prompt.visible and game.pause_restart_prompt.cancel_button.has_focus(), "pause restart did not warn and keep the game paused")
	await _tap(KEY_ESCAPE)
	_check(current_scene == game and paused and game.pause_menu_open and game.pause_menu_panel.visible and game.pause_intro_button.has_focus(), "Escape did not return to the paused session")
	_check(FileAccess.get_file_as_string(TEST_PATH) == original, "pause restart cancel changed the save")
	await _tap(KEY_ENTER)
	game.pause_restart_prompt.confirm_button.grab_focus()
	await _tap(KEY_ENTER)
	_check(current_scene.scene_file_path == "res://scenes/IntroCutscene.tscn" and not paused, "confirmed pause restart did not unpause and open intro")

	await _open_scene("res://scenes/Startup.tscn")
	title = current_scene
	title.resume_save_path = TEST_PATH
	title.watch_intro_button.grab_focus()
	await _tap(KEY_ENTER)
	_check(current_scene == title and title.fresh_start_prompt.visible, "saved title Watch Intro did not require confirmation")
	title.fresh_start_prompt.confirm_button.grab_focus()
	await _tap(KEY_ENTER)
	_check(current_scene.scene_file_path == "res://scenes/IntroCutscene.tscn", "confirmed title Watch Intro did not open intro")
	_check(FileAccess.get_file_as_string(TEST_PATH) == original, "title Watch Intro overwrote save before playing")
	await _open_scene("res://scenes/CampaignEnding.tscn")
	var ending = current_scene
	ending.resume_save_path = TEST_PATH
	ending._on_skip_pressed()
	ending.replay_button.pressed.emit()
	_check(ending.replay_prompt.visible and ending.replay_prompt.cancel_button.has_focus(), "saved ending Replay did not focus its confirmation cancel")
	await _tap(KEY_ESCAPE)
	_check(current_scene == ending and paused and not ending.replay_prompt.visible and ending.replay_button.has_focus(), "ending Escape did not keep the credits and focus Replay")
	_check(FileAccess.get_file_as_string(TEST_PATH) == original, "ending Replay cancel changed the completed save")

	_check(GameSaveScript.write_save(snapshot, TEST_PATH), "could not prepare valid backup")
	var valid_primary = FileAccess.get_file_as_string(TEST_PATH)
	var future = _future_envelope(snapshot)
	_write_text(TEST_PATH, future)
	var valid_backup = FileAccess.get_file_as_string(TEST_PATH + ".bak")
	await _open_scene("res://scenes/Startup.tscn")
	title = current_scene
	title.resume_save_path = TEST_PATH
	title._refresh_resume_button()
	_check(not title.resume_game_button.visible, "future primary was shown as resumable")
	title._on_skip_to_game_pressed()
	_check(title.fresh_start_prompt.visible and not title.fresh_start_prompt.confirm_button.visible and "copy both" in title.fresh_start_prompt.detail_label.text, "future primary did not explain how to preserve both save files")
	root.size = Vector2i(800, 450)
	await _frames(3)
	var notice_bounds: Rect2 = title.fresh_start_prompt.panel.get_global_rect()
	var back_bounds: Rect2 = title.fresh_start_prompt.cancel_button.get_global_rect()
	var logical_viewport: Rect2 = root.get_visible_rect()
	# canvas_items stretch keeps a 1280x720 logical UI while the window shrinks.
	_check(logical_viewport.encloses(notice_bounds), "incompatible-save notice leaves the 800x450 stretched viewport: %s in %s" % [str(notice_bounds), str(logical_viewport)])
	_check(notice_bounds.encloses(back_bounds) and back_bounds.size.y * 450.0 / logical_viewport.size.y >= 24.0, "incompatible-save Back button is clipped or too small at 800x450")
	root.size = Vector2i(1280, 720)
	await _frames(2)
	await _tap(KEY_ESCAPE)
	_check(current_scene == title and FileAccess.get_file_as_string(TEST_PATH) == future and FileAccess.get_file_as_string(TEST_PATH + ".bak") == valid_backup, "future primary or backup changed")

	_write_text(TEST_PATH, valid_primary)
	_write_text(TEST_PATH + ".bak", future)
	await _open_scene("res://scenes/Startup.tscn")
	title = current_scene
	title.resume_save_path = TEST_PATH
	title._refresh_resume_button()
	title._on_watch_intro_pressed()
	_check(title.fresh_start_prompt.visible and not title.fresh_start_prompt.confirm_button.visible, "future backup did not block title new game")
	await _tap(KEY_ESCAPE)
	title._on_resume_game_pressed()
	_check(title.fresh_start_prompt.visible and not title.fresh_start_prompt.confirm_button.visible, "future backup allowed an unsavable Resume")
	await _tap(KEY_ESCAPE)
	_check(FileAccess.get_file_as_string(TEST_PATH) == valid_primary and FileAccess.get_file_as_string(TEST_PATH + ".bak") == future, "future backup check changed save bytes")
	await _open_scene("res://scenes/CampaignEnding.tscn")
	ending = current_scene
	ending.resume_save_path = TEST_PATH
	ending._on_skip_pressed()
	ending.replay_button.pressed.emit()
	_check(ending.replay_prompt.visible and not ending.replay_prompt.confirm_button.visible and paused, "future backup did not block ending Replay")
	await _tap(KEY_ESCAPE)
	ending.explore_button.pressed.emit()
	_check(ending.replay_prompt.visible and not ending.replay_prompt.confirm_button.visible and paused, "future backup allowed unsavable Keep Exploring")
	await _tap(KEY_ESCAPE)
	_check(current_scene == ending and FileAccess.get_file_as_string(TEST_PATH) == valid_primary and FileAccess.get_file_as_string(TEST_PATH + ".bak") == future, "ending future-version notices changed save bytes")

	await _open_scene("res://scenes/Main.tscn")
	game = current_scene
	_check(FileAccess.get_file_as_string(TEST_PATH) == valid_primary and FileAccess.get_file_as_string(TEST_PATH + ".bak") == future, "loading Main changed future-version save bytes")
	game.game_save_test_path = TEST_PATH
	var pause_slots: Dictionary = GameSaveScript.inspect_slots(TEST_PATH)
	_check(bool(pause_slots.get("incompatible", false)), "pause setup lost future backup: %s" % str(pause_slots))
	game._toggle_pause_menu(1, false)
	game._on_pause_intro_pressed()
	_check(game.pause_restart_prompt.visible and not game.pause_restart_prompt.confirm_button.visible and paused, "future backup did not block pause restart: prompt=%s confirm=%s paused=%s slots=%s" % [str(game.pause_restart_prompt.visible), str(game.pause_restart_prompt.confirm_button.visible), str(paused), str(pause_slots)])
	await _tap(KEY_ESCAPE)
	_check(current_scene == game and game.pause_menu_open and paused, "future backup notice did not return to paused game")
	game._toggle_pause_menu(0, false)
	_check(FileAccess.get_file_as_string(TEST_PATH) == valid_primary and FileAccess.get_file_as_string(TEST_PATH + ".bak") == future, "pause future-version check changed save bytes")
	_cleanup()
	await _frames()
	if failures.is_empty():
		print("NEW_GAME_SAFETY_OK: title, pause, ending confirm/cancel, keyboard focus, future primary/backup preservation")
		quit()
	else:
		push_error("NEW_GAME_SAFETY_FAIL: " + ", ".join(failures))
		quit(1)
