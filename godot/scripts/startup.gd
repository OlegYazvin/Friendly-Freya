extends Control

const INTRO_SCENE_PATH = "res://scenes/IntroCutscene.tscn"
const GAME_SCENE_PATH = "res://scenes/Main.tscn"
const STARTUP_HERO_BACKGROUND_PATH = "res://assets/images/startup_freya_hero_v2.png"
const RELEASE_REQUIRED_RESOURCES = [
	"res://assets/models/freya_portuguese_water_dog.glb",
	"res://assets/models/freya_portuguese_water_dog_Atlas.png",
	STARTUP_HERO_BACKGROUND_PATH,
	"res://assets/audio/barks/conversational_bark_01.wav",
	"res://assets/audio/barks/conversational_bark_02.wav",
	"res://assets/audio/barks/conversational_bark_03.wav",
	"res://assets/audio/barks/conversational_bark_04.wav",
	"res://assets/audio/barks/excited_social_bark_01.wav",
	"res://assets/audio/barks/excited_social_bark_02.wav",
	"res://assets/audio/barks/excited_social_bark_03.wav",
	"res://assets/audio/barks/excited_social_bark_04.wav",
	"res://assets/audio/barks/excited_social_bark_05.wav",
	"res://assets/audio/barks/excited_social_bark_06.wav",
	"res://assets/audio/barks/bark_real_01.wav",
	"res://assets/audio/barks/bark_real_02.wav",
	"res://assets/audio/barks/bark_real_03.wav",
	"res://assets/audio/barks/bark_real_04.wav",
	"res://assets/audio/barks/bark_real_05.wav",
	"res://assets/audio/barks/bark_real_06.wav",
	"res://assets/audio/barks/bark_real_07.wav",
	"res://assets/audio/barks/bark_real_08.wav",
	"res://assets/audio/barks/aggressive_bark_01.wav",
	"res://assets/audio/barks/aggressive_bark_02.wav",
	"res://assets/audio/barks/aggressive_bark_03.wav",
	"res://assets/audio/barks/aggressive_bark_04.wav",
	"res://assets/audio/barks/aggressive_bark_05.wav",
	"res://assets/audio/barks/aggressive_bark_06.wav"
]
const RELEASE_EXCLUDED_RESOURCES = [
	"res://assets/models/dog_golden.glb",
	"res://assets/models/dog_golden_Tex_Puppy.png",
	"res://assets/models/dog_husky.glb",
	"res://assets/models/dog_labrador.glb",
	"res://assets/models/dog_labrador_Tex_Beagle.png",
	"res://assets/models/dog_neighbor_01.glb",
	"res://assets/models/dog_neighbor_02.glb",
	"res://assets/models/buildings/building_apartment.glb",
	"res://assets/models/buildings/building_apartment_Apartment_BaseColor.png",
	"res://assets/models/buildings/building_big.glb",
	"res://assets/models/buildings/building_house.glb",
	"res://assets/models/buildings/building_house_PUSHILIN_house.png",
	"res://assets/models/buildings/building_large_01.glb",
	"res://assets/models/buildings/building_large_02.glb",
	"res://assets/models/buildings/building_roofgarden.glb"
]

@onready var watch_intro_button: Button = %WatchIntroButton
@onready var skip_to_game_button: Button = %SkipToGameButton
@onready var hero_background: TextureRect = $HeroBackground
@onready var menu_center: CenterContainer = $MenuCenter

var selection_locked := false


func _ready() -> void:
	watch_intro_button.pressed.connect(_on_watch_intro_pressed)
	skip_to_game_button.pressed.connect(_on_skip_to_game_pressed)
	watch_intro_button.grab_focus()

	if OS.get_environment("FREYA_RELEASE_CONTENT_VALIDATE") == "1":
		_run_release_content_validation()
	elif OS.get_environment("FREYA_STARTUP_VALIDATE") == "1":
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
	if not ResourceLoader.exists(STARTUP_HERO_BACKGROUND_PATH):
		failures.append("startup_hero_background_resource_missing")
	if hero_background == null or hero_background.texture == null:
		failures.append("startup_hero_background_not_displayed")
	elif hero_background.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_COVERED:
		failures.append("startup_hero_background_not_aspect_covered")
	if menu_center == null or menu_center.anchor_right > 0.5:
		failures.append("startup_menu_not_in_left_safe_area")
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
		print("STARTUP_OK: heroic Freya background, two choices, default focus, signals, loadable routes, and selection lock validated")
		get_tree().quit()
	else:
		push_error("STARTUP_FAIL: " + ", ".join(failures))
		get_tree().quit(1)


func _run_release_content_validation() -> void:
	var failures: Array[String] = []
	var packed_imports := DirAccess.get_files_at("res://.godot/imported")
	for resource_path in RELEASE_REQUIRED_RESOURCES:
		if not ResourceLoader.exists(resource_path):
			failures.append("required_resource_missing_%s" % resource_path.get_file())
		if not _packed_import_exists(packed_imports, resource_path):
			failures.append("required_import_missing_%s" % resource_path.get_file())
	for resource_path in RELEASE_EXCLUDED_RESOURCES:
		if ResourceLoader.exists(resource_path):
			failures.append("excluded_resource_present_%s" % resource_path.get_file())
		if _packed_import_exists(packed_imports, resource_path):
			failures.append("excluded_import_present_%s" % resource_path.get_file())
	if DirAccess.dir_exists_absolute("res://assets/models"):
		for packed_file in DirAccess.get_files_at("res://assets/models"):
			if packed_file.begins_with("dog_"):
				failures.append("unexpected_dog_reference_%s" % packed_file)
	if DirAccess.dir_exists_absolute("res://assets/models/buildings"):
		for packed_file in DirAccess.get_files_at("res://assets/models/buildings"):
			failures.append("unexpected_building_reference_%s" % packed_file)

	if failures.is_empty():
		print("RELEASE_CONTENT_OK: heroic startup art, active CC0 model, and 24-bark library imports present; inactive reference models and imports excluded")
		get_tree().quit()
	else:
		push_error("RELEASE_CONTENT_FAIL: " + ", ".join(failures))
		get_tree().quit(1)


func _packed_import_exists(packed_imports: PackedStringArray, resource_path: String) -> bool:
	var prefix := resource_path.get_file() + "-"
	for packed_import in packed_imports:
		if packed_import.begins_with(prefix):
			return true
	return false
