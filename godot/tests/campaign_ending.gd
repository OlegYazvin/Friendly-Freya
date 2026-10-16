extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(1280, 720)
	var packed := load("res://scenes/CampaignEnding.tscn") as PackedScene
	if packed == null:
		push_error("ENDING_FAIL: scene_missing")
		quit(1)
		return
	set_meta("friendly_freya_ending_summary", {
		"chapters_secured": 3,
		"allied_dogs": 4,
		"rescued_dogs": 6
	})
	var ending := packed.instantiate()
	root.add_child(ending)
	if not paused:
		failures.append("game_not_paused")
	if (ending.get_node("Screen/StoryPanel/Margin/Contents/Heading") as Label).text != "The signal breaks":
		failures.append("first_beat_missing")
	ending.get_node("Screen/StoryPanel/Margin/Contents/Navigation/NextButton").pressed.emit()
	if (ending.get_node("Screen/StoryPanel/Margin/Contents/Heading") as Label).text != "Home, together":
		failures.append("next_navigation_failed")
	ending.get_node("Screen/StoryPanel/Margin/Contents/Navigation/SkipButton").pressed.emit()
	var credits := ending.get_node("Screen/StoryPanel/Margin/Contents/Body") as RichTextLabel
	if not credits.text.contains("Gene") and not credits.text.contains("Quaternius"):
		failures.append("credits_missing")
	if not credits.text.contains("Geoff Bremner (CC BY 4.0)") or not credits.text.contains("mvVoiceActing (CC0)") or not credits.text.contains("WarcakeStudios (CC0)") or not credits.text.contains("AUDIO_ATTRIBUTION.md"):
		failures.append("recorded_sound_credits_missing")
	if not credits.text.contains("Chapters secured: 3") or not credits.text.contains("Pack allies: 4") or not credits.text.contains("Lodge dogs rescued: 6"):
		failures.append("summary_missing")
	if not (ending.get_node("Screen/StoryPanel/Margin/Contents/Choices/ExploreButton") as Button).visible:
		failures.append("explore_choice_missing")
	if not (ending.get_node("Screen/StoryPanel/Margin/Contents/Choices/ReplayButton") as Button).visible:
		failures.append("replay_choice_missing")
	await process_frame
	var screen := ending.get_node("Screen") as Control
	var panel := ending.get_node("Screen/StoryPanel") as PanelContainer
	var choices := ending.get_node("Screen/StoryPanel/Margin/Contents/Choices") as VBoxContainer
	if panel.get_global_rect().end.y > screen.size.y + 1.0:
		failures.append("ending_panel_offscreen")
	if choices.get_global_rect().end.y > panel.get_global_rect().end.y - 8.0:
		failures.append("ending_choices_offscreen")
	root.size = Vector2i(960, 540)
	await process_frame
	if panel.get_global_rect().end.y > screen.size.y + 1.0:
		failures.append("small_window_panel_offscreen")
	if choices.get_global_rect().end.y > panel.get_global_rect().end.y - 8.0:
		failures.append("small_window_choices_offscreen")
	root.size = Vector2i(1280, 720)
	await process_frame
	ending.resume_save_path = "user://campaign_ending_validation_missing_save.json"
	current_scene = ending
	ending.get_node("Screen/StoryPanel/Margin/Contents/Choices/ExploreButton").pressed.emit()
	var status := ending.get_node("Screen/StoryPanel/Margin/Contents/Status") as Label
	if not status.visible or not status.text.contains("could not be loaded"):
		failures.append("missing_save_not_explained")
	current_scene = null
	var signals := {"keep": false}
	ending.keep_exploring_requested.connect(func() -> void: signals["keep"] = true)
	ending.get_node("Screen/StoryPanel/Margin/Contents/Choices/ExploreButton").pressed.emit()
	await process_frame
	if not signals["keep"]:
		failures.append("continue_signal_missing")
	if paused:
		failures.append("pause_not_restored")
	var replay_scene := packed.instantiate()
	root.add_child(replay_scene)
	current_scene = replay_scene
	replay_scene.resume_save_path = "user://campaign_ending_validation_missing_save.json"
	replay_scene.get_node("Screen/StoryPanel/Margin/Contents/Navigation/SkipButton").pressed.emit()
	var signals_replay := {"requested": false}
	replay_scene.replay_requested.connect(func() -> void: signals_replay["requested"] = true)
	replay_scene.get_node("Screen/StoryPanel/Margin/Contents/Choices/ReplayButton").pressed.emit()
	if not replay_scene.replay_prompt.visible or not replay_scene.replay_prompt.cancel_button.has_focus():
		failures.append("replay_confirmation_missing_or_cancel_not_focused")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	replay_scene._input(escape)
	if replay_scene.replay_prompt.visible or not paused or current_scene != replay_scene or signals_replay["requested"] or not replay_scene.replay_button.has_focus():
		failures.append("replay_escape_did_not_keep_credits")
	replay_scene.get_node("Screen/StoryPanel/Margin/Contents/Choices/ReplayButton").pressed.emit()
	replay_scene.replay_prompt.confirm_button.pressed.emit()
	for frame in range(4):
		await process_frame
	if not signals_replay["requested"]:
		failures.append("replay_signal_missing")
	if paused:
		failures.append("replay_left_game_paused")
	if current_scene == null or current_scene.scene_file_path != "res://scenes/IntroCutscene.tscn":
		failures.append("replay_did_not_open_intro")
	# The exact recorded button cue uses a short persistent player while a scene
	# switches. Let that real clip finish before Godot's leak check runs.
	await create_timer(1.2).timeout
	if not failures.is_empty():
		push_error("ENDING_FAIL: %s" % ", ".join(failures))
		quit(1)
		return
	print("ENDING_OK: four story beats, credits, summary, both choices, missing-save handling, pause restoration, and confirmed replay route")
	quit()
