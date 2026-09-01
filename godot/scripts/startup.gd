extends Control

const INTRO_SCENE_PATH = "res://scenes/IntroCutscene.tscn"
const GAME_SCENE_PATH = "res://scenes/Main.tscn"

@onready var watch_intro_button: Button = %WatchIntroButton
@onready var skip_to_game_button: Button = %SkipToGameButton

var selection_locked := false


func _ready() -> void:
	watch_intro_button.pressed.connect(_on_watch_intro_pressed)
	skip_to_game_button.pressed.connect(_on_skip_to_game_pressed)
	watch_intro_button.grab_focus()

	if OS.get_environment("FREYA_STARTUP_VALIDATE") == "1":
		_run_startup_validation()


func _on_watch_intro_pressed() -> void:
	_select_destination(INTRO_SCENE_PATH)


func _on_skip_to_game_pressed() -> void:
	_select_destination(GAME_SCENE_PATH)


func _select_destination(scene_path: String) -> void:
	if selection_locked:
		return
	_lock_selection()
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Could not open startup destination %s (error %d)." % [scene_path, error])


func _lock_selection() -> void:
	selection_locked = true
	watch_intro_button.disabled = true
	skip_to_game_button.disabled = true


func _run_startup_validation() -> void:
	var failures: Array[String] = []
	var visible_buttons: Array[Button] = []
	for node in find_children("*", "Button", true, false):
		if node is Button and (node as Button).visible:
			visible_buttons.append(node as Button)

	if visible_buttons.size() != 2:
		failures.append("visible_button_count_%d" % visible_buttons.size())
	if watch_intro_button == null:
		failures.append("watch_intro_button_missing")
	elif watch_intro_button.text != "Watch Intro":
		failures.append("watch_intro_label_bad")
	elif not watch_intro_button.pressed.is_connected(_on_watch_intro_pressed):
		failures.append("watch_intro_signal_missing")
	if skip_to_game_button == null:
		failures.append("skip_to_game_button_missing")
	elif skip_to_game_button.text != "Skip To Game":
		failures.append("skip_to_game_label_bad")
	elif not skip_to_game_button.pressed.is_connected(_on_skip_to_game_pressed):
		failures.append("skip_to_game_signal_missing")
	if get_viewport().gui_get_focus_owner() != watch_intro_button:
		failures.append("watch_intro_default_focus_missing")
	if INTRO_SCENE_PATH != "res://scenes/IntroCutscene.tscn":
		failures.append("watch_intro_route_bad")
	if GAME_SCENE_PATH != "res://scenes/Main.tscn":
		failures.append("skip_to_game_route_bad")
	if not ResourceLoader.exists(INTRO_SCENE_PATH):
		failures.append("intro_scene_missing")
	elif not (load(INTRO_SCENE_PATH) is PackedScene):
		failures.append("intro_scene_not_loadable")
	if not ResourceLoader.exists(GAME_SCENE_PATH):
		failures.append("game_scene_missing")
	elif not (load(GAME_SCENE_PATH) is PackedScene):
		failures.append("game_scene_not_loadable")
	if str(ProjectSettings.get_setting("application/run/main_scene", "")) != "res://scenes/Startup.tscn":
		failures.append("startup_not_project_main_scene")

	_lock_selection()
	if not selection_locked or not watch_intro_button.disabled or not skip_to_game_button.disabled:
		failures.append("selection_did_not_lock_both_buttons")

	if failures.is_empty():
		print("STARTUP_OK: two choices, default focus, signals, loadable routes, and selection lock validated")
		get_tree().quit()
	else:
		push_error("STARTUP_FAIL: " + ", ".join(failures))
		get_tree().quit(1)
