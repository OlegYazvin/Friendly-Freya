extends SceneTree

const GameSaveScript = preload("res://scripts/game_save.gd")
const TEST_PATH = "user://friendly_freya_ending_resume_test.json"
const MAIN_PATH = "res://scenes/Main.tscn"
const ENDING_PATH = "res://scenes/CampaignEnding.tscn"
const KEEP_EXPLORING_META = "friendly_freya_ending_keep_exploring"

var failures: Array[String] = []


func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	create_timer(90.0).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run")


func _on_watchdog_timeout() -> void:
	push_error("ENDING_RESUME_FAIL: test timed out")
	quit(1)


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
		push_error("ENDING_RESUME: " + description)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_cleanup()
	if change_scene_to_file(MAIN_PATH) != OK:
		push_error("ENDING_RESUME_FAIL: could not open initial Main")
		quit(1)
		return
	await scene_changed
	var main = current_scene
	main.set_process(false)
	main.campaign_chapter = 3
	main.campaign_complete = true
	main.chapter_complete = true
	main.chapter_result_dismissed = false
	var snapshot: Dictionary = main._snapshot_game_state()
	_check(GameSaveScript.write_save(snapshot, TEST_PATH), "could not write completed save")
	var result: Dictionary = GameSaveScript.read_save(TEST_PATH)
	_check(bool(result.get("ok", false)), "completed save could not be read")
	if not bool(result.get("ok", false)):
		_cleanup()
		quit(1)
		return

	# Resume before seeing the ending should still show the result and its N route.
	set_meta(GameSaveScript.RESUME_META, result["state"])
	_check(change_scene_to_file(MAIN_PATH) == OK, "could not resume before ending")
	await scene_changed
	main = current_scene
	main.set_process(false)
	_check(main.chapter_complete_panel.visible, "normal completed-game resume hid the result")
	_check(not main.chapter_result_dismissed, "normal completed-game resume marked result dismissed")
	_check((main.chapter_complete_panel.get_node("Content/ContinueStory") as Button).text.contains("[N]"), "normal resume lost ending route")

	# The ending's actual button must transfer the save and enter the world.
	_check(change_scene_to_file(ENDING_PATH) == OK, "could not open ending")
	await scene_changed
	var ending = current_scene
	ending.resume_save_path = TEST_PATH
	ending._on_skip_pressed()
	ending.get_node("Screen/StoryPanel/Margin/Contents/Choices/ExploreButton").pressed.emit()
	await scene_changed
	main = current_scene
	main.set_process(false)
	_check(main.scene_file_path == MAIN_PATH, "Keep Exploring did not open Main")
	_check(main.campaign_chapter == 3 and main.campaign_complete and main.chapter_complete, "Keep Exploring lost completed campaign")
	_check(main.chapter_result_dismissed, "Keep Exploring did not mark result dismissed")
	_check(not main.chapter_complete_panel.visible, "Keep Exploring reopened the result panel")
	_check(not paused, "Keep Exploring left the world paused")
	_check(not has_meta(KEEP_EXPLORING_META) and not has_meta(GameSaveScript.RESUME_META), "ending resume handoff was not consumed")

	# A later Save/Quit/Resume must preserve the player's dismissal choice.
	_check(GameSaveScript.write_save(main._snapshot_game_state(), TEST_PATH), "could not save explored world")
	result = GameSaveScript.read_save(TEST_PATH)
	_check(bool(result.get("ok", false)), "explored world save could not be read")
	if bool(result.get("ok", false)):
		_check(bool(result["state"]["campaign"].get("chapter_result_dismissed", false)), "dismissed result was not saved")
		set_meta(GameSaveScript.RESUME_META, result["state"])
		_check(change_scene_to_file(MAIN_PATH) == OK, "could not resume explored world")
		await scene_changed
		main = current_scene
		main.set_process(false)
		_check(main.campaign_complete and main.chapter_complete and main.chapter_result_dismissed, "saved explored-world progress was not restored")
		_check(not main.chapter_complete_panel.visible, "result panel returned after Save/Quit/Resume")
		_check(not has_meta(KEEP_EXPLORING_META), "ending handoff leaked into later resume")

	_cleanup()
	# Recorded button playback briefly outlives the ending scene.
	await create_timer(1.2).timeout
	if failures.is_empty():
		print("ENDING_RESUME_OK: direct resume retains result, ending Keep Exploring enters open world, and later save/resume stays open")
		quit()
	else:
		push_error("ENDING_RESUME_FAIL: " + ", ".join(failures))
		quit(1)


func _cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH + suffix))
