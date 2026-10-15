extends Control

const AudioPreferencesScript = preload("res://scripts/audio_preferences.gd")
const ActionAudioScript = preload("res://scripts/action_audio.gd")
const GameSaveScript = preload("res://scripts/game_save.gd")
const FreshStartPromptScript = preload("res://scripts/fresh_start_prompt.gd")
const INTRO_SCENE_PATH = "res://scenes/IntroCutscene.tscn"
const GAME_SCENE_PATH = "res://scenes/Main.tscn"
const EXPORTED_CAMPAIGN_ROUTE_PATH = "res://tests/natural_campaign_route.gd"
const EXPORTED_PERF_STRESS_PATH = "res://tests/performance_stress.gd"
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
@onready var resume_game_button: Button = %ResumeGameButton
@onready var settings_button: Button = %SettingsButton
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var master_volume_value_label: Label = %MasterVolumeValueLabel
@onready var settings_back_button: Button = %SettingsBackButton
@onready var hero_background: TextureRect = $HeroBackground
@onready var menu_center: CenterContainer = $MenuCenter
@onready var prompt_label: Label = $MenuCenter/MenuPanel/Margin/Choices/Prompt

var selection_locked := false
var title_card_theme_player: AudioStreamPlayer
var title_card_theme_stream: AudioStream
var action_audio: Node
var master_volume := AudioPreferencesScript.DEFAULT_MASTER_VOLUME
var resume_save_path: String = GameSaveScript.SAVE_PATH
var fresh_start_prompt
var pending_new_game_scene_path := ""
var pending_new_game_button: Button


func _ready() -> void:
	master_volume = AudioPreferencesScript.load_and_apply_master_volume()
	_sync_audio_settings_ui()
	_create_title_card_theme_player()
	action_audio = ActionAudioScript.new()
	add_child(action_audio)
	watch_intro_button.pressed.connect(_on_watch_intro_pressed)
	skip_to_game_button.pressed.connect(_on_skip_to_game_pressed)
	resume_game_button.pressed.connect(_on_resume_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	settings_back_button.pressed.connect(_on_settings_back_pressed)
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	_create_fresh_start_prompt()
	_refresh_resume_button()
	if resume_game_button.visible and (_is_automated_title_view() or not GameSaveScript.inspect_slots(resume_save_path).incompatible):
		resume_game_button.grab_focus()
	else:
		watch_intro_button.grab_focus()
	var exported_campaign_qa = OS.get_environment("FREYA_EXPORTED_CAMPAIGN_QA") == "1"
	var exported_perf_stress = OS.get_environment("FREYA_EXPORTED_PERF_STRESS") == "1"
	if exported_campaign_qa and exported_perf_stress:
		push_error("Only one exported QA route may run at a time.")
		get_tree().quit(1)
		return
	if exported_campaign_qa and not bool(get_tree().get_meta("freya_exported_campaign_qa_started", false)):
		get_tree().set_meta("freya_exported_campaign_qa_started", true)
		get_tree().set_meta("freya_flow_validation", true)
		call_deferred("_launch_exported_campaign_qa")
	elif exported_perf_stress and not bool(get_tree().get_meta("freya_exported_perf_stress_started", false)):
		get_tree().set_meta("freya_exported_perf_stress_started", true)
		get_tree().set_meta("freya_flow_validation", true)
		get_tree().set_meta("freya_perf_stress_no_save", true)
		call_deferred("_launch_exported_perf_stress")

	if OS.get_environment("FREYA_RELEASE_CONTENT_VALIDATE") == "1":
		_run_release_content_validation()
	elif OS.get_environment("FREYA_STARTUP_VALIDATE") == "1":
		_run_startup_validation()
	elif OS.get_environment("FREYA_STARTUP_VIEW").strip_edges().to_lower() == "confirm_new_game":
		call_deferred("_capture_new_game_confirmation")


func _launch_exported_campaign_qa() -> void:
	# Official release templates do not accept --script path overrides. Attach
	# the bundled SceneTree controller only for the exported Windows QA run.
	var route_script := load(EXPORTED_CAMPAIGN_ROUTE_PATH) as Script
	if route_script == null:
		push_error("Exported campaign QA route is missing from the PCK.")
		get_tree().quit(1)
		return
	var tree := get_tree()
	tree.set_script(route_script)
	if tree.get_script() != route_script:
		push_error("Could not attach exported campaign QA route to SceneTree.")
		tree.quit(1)
		return
	print("EXPORTED_CAMPAIGN_QA_START: bundled keyboard route attached")
	tree.call("_initialize")


func _launch_exported_perf_stress() -> void:
	# The release template cannot use --script. Start the bundled graphical
	# stress controller from the same exported PCK as the player's game.
	var stress_script := load(EXPORTED_PERF_STRESS_PATH) as Script
	if stress_script == null:
		push_error("Exported performance stress route is missing from the PCK.")
		get_tree().quit(1)
		return
	var tree := get_tree()
	tree.set_script(stress_script)
	if tree.get_script() != stress_script:
		push_error("Could not attach exported performance stress route to SceneTree.")
		tree.quit(1)
		return
	print("EXPORTED_PERF_STRESS_START: bundled graphical stress route attached")
	tree.call("_initialize")


func _on_watch_intro_pressed() -> void:
	_request_new_game(INTRO_SCENE_PATH, watch_intro_button)


func _on_skip_to_game_pressed() -> void:
	_request_new_game(GAME_SCENE_PATH, skip_to_game_button)


func _request_new_game(scene_path: String, source_button: Button) -> void:
	if selection_locked or fresh_start_prompt.visible:
		return
	# Automated normal-input checks never inspect or replace a player's real
	# default save. A focused check can still use an explicit isolated path.
	if _is_automated_title_view() and resume_save_path == GameSaveScript.SAVE_PATH:
		_begin_new_game(scene_path)
		return
	var slots: Dictionary = GameSaveScript.inspect_slots(resume_save_path)
	pending_new_game_button = source_button
	if bool(slots.get("incompatible", false)):
		_show_fresh_start_notice(FreshStartPromptScript.incompatible_save_detail(resume_save_path, bool(slots.get("newer", false))))
		return
	if bool(slots.get("has_files", false)):
		_show_new_game_decision(scene_path, source_button, bool(slots.get("has_valid_save", false)))
		return
	_begin_new_game(scene_path)


func _show_new_game_decision(scene_path: String, source_button: Button, has_valid_save: bool) -> void:
	pending_new_game_scene_path = scene_path
	pending_new_game_button = source_button
	var detail = "Starting a new game will replace the existing saved campaign when the new game saves. Choose Resume Game to continue it." if has_valid_save else FreshStartPromptScript.unreadable_save_detail(resume_save_path)
	fresh_start_prompt.show_decision("Start a new story?", detail, "Start New Game", "Keep Progress")
	_set_title_choices_enabled(false)
	action_audio.play("button", -11.0)


func _capture_new_game_confirmation() -> void:
	# A deterministic saved-game preview never creates or reads a player's save.
	_show_new_game_decision(GAME_SCENE_PATH, skip_to_game_button, true)


func _begin_new_game(scene_path: String) -> void:
	action_audio.play_persistent("button", -11.0)
	_select_destination(scene_path)


func _create_fresh_start_prompt() -> void:
	fresh_start_prompt = FreshStartPromptScript.new()
	fresh_start_prompt.name = "FreshStartPrompt"
	add_child(fresh_start_prompt)
	fresh_start_prompt.accepted.connect(_on_fresh_start_accepted)
	fresh_start_prompt.canceled.connect(_on_fresh_start_canceled)


func _show_fresh_start_notice(detail: String) -> void:
	fresh_start_prompt.show_notice("Save from another version", detail)
	_set_title_choices_enabled(false)
	action_audio.play("button", -11.0)


func _on_fresh_start_accepted() -> void:
	var scene_path = pending_new_game_scene_path
	pending_new_game_scene_path = ""
	var slots: Dictionary = GameSaveScript.inspect_slots(resume_save_path)
	if bool(slots.get("incompatible", false)):
		_show_fresh_start_notice(FreshStartPromptScript.incompatible_save_detail(resume_save_path, bool(slots.get("newer", false))))
		return
	if not scene_path.is_empty():
		_begin_new_game(scene_path)


func _on_fresh_start_canceled() -> void:
	pending_new_game_scene_path = ""
	_set_title_choices_enabled(true)
	if pending_new_game_button != null:
		pending_new_game_button.grab_focus()
	pending_new_game_button = null
	action_audio.play("button", -11.0)


func _set_title_choices_enabled(enabled: bool) -> void:
	watch_intro_button.disabled = not enabled
	skip_to_game_button.disabled = not enabled
	resume_game_button.disabled = not enabled
	settings_button.disabled = not enabled
	settings_back_button.disabled = not enabled
	master_volume_slider.editable = enabled


func _is_automated_title_view() -> bool:
	return OS.get_environment("FREYA_STARTUP_VALIDATE") == "1" or not OS.get_environment("FREYA_STARTUP_VIEW").is_empty() or bool(get_tree().get_meta("freya_flow_validation", false))


func _on_resume_game_pressed() -> void:
	if selection_locked or fresh_start_prompt.visible:
		return
	var slots: Dictionary = GameSaveScript.inspect_slots(resume_save_path)
	if bool(slots.get("incompatible", false)):
		pending_new_game_button = resume_game_button
		_show_fresh_start_notice(FreshStartPromptScript.incompatible_save_detail(resume_save_path, bool(slots.get("newer", false))))
		return
	var result = GameSaveScript.read_save(resume_save_path)
	if not bool(result.get("ok", false)):
		_refresh_resume_button()
		return
	action_audio.play_persistent("button", -11.0)
	get_tree().set_meta(GameSaveScript.RESUME_META, result["state"])
	_select_destination(GAME_SCENE_PATH)


func _refresh_resume_button() -> void:
	# Test and deterministic capture routes must remain independent of a local
	# player's user:// data, while the ordinary menu offers a valid resume.
	var automated = _is_automated_title_view()
	var capture_view = OS.get_environment("FREYA_STARTUP_VIEW").strip_edges().to_lower()
	if capture_view == "menu":
		resume_game_button.visible = false
	elif capture_view in ["resume", "confirm_new_game"]:
		resume_game_button.visible = true
	else:
		resume_game_button.visible = not automated and GameSaveScript.has_resume(resume_save_path)
	if not automated:
		var slots: Dictionary = GameSaveScript.inspect_slots(resume_save_path)
		if bool(slots.get("incompatible", false)):
			prompt_label.text = "Another-version save found. Open its game version."
		elif bool(slots.get("has_files", false)) and not bool(slots.get("has_valid_save", false)):
			prompt_label.text = "An unreadable save exists. Back it up first."
		else:
			prompt_label.text = "The invasion is about to begin."


func _on_settings_pressed() -> void:
	if selection_locked:
		return
	action_audio.play("button", -11.0)
	settings_panel.visible = true
	settings_back_button.grab_focus()


func _on_settings_back_pressed() -> void:
	if selection_locked:
		return
	action_audio.play("button", -11.0)
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
	resume_game_button.disabled = true
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
	elif watch_intro_button.text != "New Game: Watch Intro":
		failures.append("watch_intro_label_bad")
	elif not watch_intro_button.pressed.is_connected(_on_watch_intro_pressed):
		failures.append("watch_intro_signal_missing")
	if skip_to_game_button == null:
		failures.append("skip_to_game_button_missing")
	elif skip_to_game_button.text != "New Game: Skip Intro":
		failures.append("skip_to_game_label_bad")
	elif not skip_to_game_button.pressed.is_connected(_on_skip_to_game_pressed):
		failures.append("skip_to_game_signal_missing")
	if resume_game_button == null:
		failures.append("resume_button_missing")
	elif not resume_game_button.pressed.is_connected(_on_resume_game_pressed):
		failures.append("resume_signal_missing")
	elif resume_game_button.visible:
		failures.append("resume_button_visible_during_validation")
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
	if not selection_locked or not watch_intro_button.disabled or not skip_to_game_button.disabled or not resume_game_button.disabled or not settings_button.disabled:
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
	for cue_id in ActionAudioScript.CUE_PATHS:
		var cue_path: String = ActionAudioScript.CUE_PATHS[cue_id]
		if not ResourceLoader.exists(cue_path, "AudioStream"):
			failures.append("action_cue_missing_%s" % cue_id)
		if not _packed_import_exists(packed_imports, cue_path):
			failures.append("action_cue_import_missing_%s" % cue_id)
	if not ResourceLoader.exists("res://scenes/CampaignEnding.tscn", "PackedScene"):
		failures.append("campaign_ending_scene_missing")
	if not ResourceLoader.exists(EXPORTED_CAMPAIGN_ROUTE_PATH, "Script"):
		failures.append("exported_campaign_route_missing")
	if not ResourceLoader.exists(EXPORTED_PERF_STRESS_PATH, "Script"):
		failures.append("exported_perf_stress_route_missing")
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
		print("RELEASE_CONTENT_OK: startup art, title music, active CC0 model, 24 barks, %d exact recorded cue mappings, and campaign ending present; inactive reference models excluded" % ActionAudioScript.CUE_PATHS.size())
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
