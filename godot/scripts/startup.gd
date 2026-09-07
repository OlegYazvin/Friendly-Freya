extends Control

const AudioPreferencesScript = preload("res://scripts/audio_preferences.gd")
const INTRO_SCENE_PATH = "res://scenes/IntroCutscene.tscn"
const GAME_SCENE_PATH = "res://scenes/Main.tscn"
const STARTUP_HERO_BACKGROUND_PATH = "res://assets/images/startup_freya_hero_v2.png"
const TITLE_CARD_THEME_PATH = "res://assets/audio/menu/title_card_theme_8bit.wav"
const RELEASE_REQUIRED_RESOURCES = [
	"res://assets/models/freya_portuguese_water_dog.glb",
	"res://assets/models/freya_portuguese_water_dog_Atlas.png",
	STARTUP_HERO_BACKGROUND_PATH,
	TITLE_CARD_THEME_PATH,
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
@onready var settings_button: Button = %SettingsButton
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var master_volume_value_label: Label = %MasterVolumeValueLabel
@onready var settings_back_button: Button = %SettingsBackButton
@onready var hero_background: TextureRect = $HeroBackground
@onready var menu_center: CenterContainer = $MenuCenter

var selection_locked := false
var title_card_theme_player: AudioStreamPlayer
var title_card_theme_stream: AudioStream
var master_volume := AudioPreferencesScript.DEFAULT_MASTER_VOLUME


func _ready() -> void:
	master_volume = AudioPreferencesScript.load_and_apply_master_volume()
	_sync_audio_settings_ui()
	_create_title_card_theme_player()
	watch_intro_button.pressed.connect(_on_watch_intro_pressed)
	skip_to_game_button.pressed.connect(_on_skip_to_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	settings_back_button.pressed.connect(_on_settings_back_pressed)
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	watch_intro_button.grab_focus()

	if OS.get_environment("FREYA_RELEASE_CONTENT_VALIDATE") == "1":
		_run_release_content_validation()
	elif OS.get_environment("FREYA_STARTUP_VALIDATE") == "1":
		_run_startup_validation()


func _on_watch_intro_pressed() -> void:
	_select_destination(INTRO_SCENE_PATH)


func _on_skip_to_game_pressed() -> void:
	_select_destination(GAME_SCENE_PATH)


func _on_settings_pressed() -> void:
	if selection_locked:
		return
	settings_panel.visible = true
	settings_back_button.grab_focus()


func _on_settings_back_pressed() -> void:
	if selection_locked:
		return
	settings_panel.visible = false
	settings_button.grab_focus()


func _on_master_volume_changed(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	AudioPreferencesScript.apply_master_volume(master_volume)
	AudioPreferencesScript.save_master_volume(master_volume)
	if master_volume_value_label != null:
		master_volume_value_label.text = AudioPreferencesScript.display_percent(master_volume)


func _sync_audio_settings_ui() -> void:
	if master_volume_slider != null:
		master_volume_slider.set_value_no_signal(master_volume)
	if master_volume_value_label != null:
		master_volume_value_label.text = AudioPreferencesScript.display_percent(master_volume)


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
	settings_button.disabled = true
	settings_back_button.disabled = true
	master_volume_slider.editable = false
	if title_card_theme_player != null and is_instance_valid(title_card_theme_player):
		title_card_theme_player.stop()


func _create_title_card_theme_player() -> void:
	title_card_theme_stream = _load_exact_audio_stream(TITLE_CARD_THEME_PATH)
	title_card_theme_player = AudioStreamPlayer.new()
	title_card_theme_player.name = "TitleCardTheme"
	title_card_theme_player.bus = "Master"
	title_card_theme_player.volume_db = -9.0
	title_card_theme_player.stream = title_card_theme_stream
	title_card_theme_player.finished.connect(_on_title_card_theme_finished)
	add_child(title_card_theme_player)
	if title_card_theme_stream == null:
		push_warning("Title-card theme is missing; startup music playback disabled.")
		return
	if not OS.has_feature("server") and DisplayServer.get_name() != "headless":
		title_card_theme_player.play()


func _on_title_card_theme_finished() -> void:
	if selection_locked:
		return
	if title_card_theme_player == null or not is_instance_valid(title_card_theme_player) or title_card_theme_stream == null:
		return
	title_card_theme_player.play()


func _load_exact_audio_stream(path: String) -> AudioStream:
	# Audio policy: the exact mapped clip either loads or this event stays silent.
	if path.is_empty():
		return null
	if FileAccess.file_exists(path):
		if path.to_lower().ends_with(".wav"):
			var wav := AudioStreamWAV.load_from_file(path)
			if wav != null:
				return wav
		elif path.to_lower().ends_with(".ogg") or path.to_lower().ends_with(".oga"):
			var ogg := AudioStreamOggVorbis.load_from_file(path)
			if ogg != null:
				return ogg
		elif path.to_lower().ends_with(".mp3"):
			var mp3 := AudioStreamMP3.load_from_file(path)
			if mp3 != null:
				return mp3
	if ResourceLoader.exists(path):
		var imported_stream = load(path)
		if imported_stream is AudioStream:
			return imported_stream as AudioStream
	return null


func _run_startup_validation() -> void:
	var failures: Array[String] = []
	var visible_buttons: Array[Button] = []
	for node in find_children("*", "Button", true, false):
		if node is Button and (node as Button).is_visible_in_tree():
			visible_buttons.append(node as Button)

	if visible_buttons.size() != 3:
		failures.append("visible_button_count_%d" % visible_buttons.size())
	if not ResourceLoader.exists(STARTUP_HERO_BACKGROUND_PATH):
		failures.append("startup_hero_background_resource_missing")
	if not ResourceLoader.exists(TITLE_CARD_THEME_PATH):
		failures.append("title_card_theme_resource_missing")
	if title_card_theme_player == null or not is_instance_valid(title_card_theme_player):
		failures.append("title_card_theme_player_missing")
	elif title_card_theme_player.stream == null:
		failures.append("title_card_theme_stream_missing")
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
	if settings_button == null:
		failures.append("settings_button_missing")
	elif settings_button.text != "Settings":
		failures.append("settings_label_bad")
	elif not settings_button.pressed.is_connected(_on_settings_pressed):
		failures.append("settings_signal_missing")
	if settings_panel == null:
		failures.append("settings_panel_missing")
	elif settings_panel.visible:
		failures.append("settings_panel_initially_visible")
	if master_volume_slider == null:
		failures.append("master_volume_slider_missing")
	elif absf(master_volume_slider.min_value - 0.0) > 0.001 or absf(master_volume_slider.max_value - 1.0) > 0.001:
		failures.append("master_volume_slider_range_bad")
	elif not master_volume_slider.value_changed.is_connected(_on_master_volume_changed):
		failures.append("master_volume_slider_signal_missing")
	if master_volume_value_label == null:
		failures.append("master_volume_value_label_missing")
	elif master_volume_value_label.text != AudioPreferencesScript.display_percent(master_volume):
		failures.append("master_volume_value_label_bad")
	if settings_back_button == null:
		failures.append("settings_back_button_missing")
	elif settings_back_button.text != "Back":
		failures.append("settings_back_label_bad")
	elif not settings_back_button.pressed.is_connected(_on_settings_back_pressed):
		failures.append("settings_back_signal_missing")
	if get_viewport().gui_get_focus_owner() != watch_intro_button:
		failures.append("watch_intro_default_focus_missing")
	if settings_panel != null and settings_back_button != null and settings_button != null:
		_on_settings_pressed()
		if not settings_panel.visible or get_viewport().gui_get_focus_owner() != settings_back_button:
			failures.append("settings_open_focus_bad")
		_on_settings_back_pressed()
		if settings_panel.visible or get_viewport().gui_get_focus_owner() != settings_button:
			failures.append("settings_back_focus_bad")
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
	if not selection_locked or not watch_intro_button.disabled or not skip_to_game_button.disabled or not settings_button.disabled:
		failures.append("selection_did_not_lock_main_buttons")
	if settings_back_button != null and not settings_back_button.disabled:
		failures.append("selection_did_not_lock_settings_back")
	if master_volume_slider != null and master_volume_slider.editable:
		failures.append("selection_did_not_lock_volume_slider")
	if title_card_theme_player != null and is_instance_valid(title_card_theme_player) and title_card_theme_player.playing:
		failures.append("selection_did_not_stop_title_theme")

	if failures.is_empty():
		print("STARTUP_OK: heroic Freya background, title-card theme, three choices, audio settings slider, default focus, signals, loadable routes, and selection lock validated")
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
		print("RELEASE_CONTENT_OK: heroic startup art, title-card theme, active CC0 model, and 24-bark library imports present; inactive reference models and imports excluded")
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
