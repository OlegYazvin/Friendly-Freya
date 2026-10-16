extends CanvasLayer

## A paused, self-contained campaign epilogue. It can be a standalone scene
## after the final story objective or an overlay attached to Main. In standalone
## mode, Keep Exploring resumes the latest valid save; as an overlay it resumes
## the same world. Replay starts the existing intro route and a fresh game.

signal keep_exploring_requested
signal replay_requested

const ActionAudioScript = preload("res://scripts/action_audio.gd")
const GameSaveScript = preload("res://scripts/game_save.gd")
const FreshStartPromptScript = preload("res://scripts/fresh_start_prompt.gd")
const INTRO_SCENE_PATH := "res://scenes/IntroCutscene.tscn"
const MAIN_SCENE_PATH := "res://scenes/Main.tscn"
const SUMMARY_META := "friendly_freya_ending_summary"
const KEEP_EXPLORING_META := "friendly_freya_ending_keep_exploring"

const PAGES := [
	{
		"heading": "The signal breaks",
		"body": "The last alien source falls silent. Above Northbrook, the captive beam unwinds and a transport door opens in the night. Gene and Zoe stumble onto the street: shaken, grumbling, and very much alive.\n\nFreya stays between the fading light and Ryah until it is gone."
	},
	{
		"heading": "Home, together",
		"body": "Ryah runs into Gene and Zoe's arms. They were held aboard the ship while Freya kept their daughter safe below.\n\nZoe sees the muddy dogs gathered behind Freya. \"Did you make all these friends?\"\n\nFreya thinks, \"Most of them. A few took convincing.\""
	},
	{
		"heading": "A good dog's work",
		"body": "The Dog Lodge gates are open. The rescued dogs have their own paths home, and Freya's pack can finally rest.\n\nGene kneels beside her. \"You saved Ryah. You brought us back.\"\n\nFreya thinks, \"Yes. Dinner would also be nice.\"\n\nRyah scratches behind her ear. For tonight, everyone is home."
	},
	{
		"heading": "Thank you for playing",
		"body": "FRIENDLY FREYA\nA neighborhood adventure about a very brave dog.\n\nStory and game: the Friendly Freya project\nFreya dog model: Quaternius, Cube World Kit (CC0)\nRecorded dog barks: Brandon Morris and pauliuw (CC0)\nFood recording: Geoff Bremner (CC BY 4.0)\nRyah cry performance: mvVoiceActing (CC0)\nPlastic bottle Foley: WarcakeStudios (CC0)\nAdditional recorded sounds: see AUDIO_ATTRIBUTION.md for creators, sources, and licenses\n\nThank you for helping Freya bring her family home."
	}
]

@onready var heading: Label = %Heading
@onready var body: RichTextLabel = %Body
@onready var progress: Label = %Progress
@onready var status: Label = %Status
@onready var back_button: Button = %BackButton
@onready var next_button: Button = %NextButton
@onready var skip_button: Button = %SkipButton
@onready var explore_button: Button = %ExploreButton
@onready var replay_button: Button = %ReplayButton
@onready var story_panel: PanelContainer = $Screen/StoryPanel

var _page := 0
var _was_paused := false
var _owns_pause := false
var _routing := false
var _action_audio: Node
var _summary: Dictionary = {}
var resume_save_path: String = GameSaveScript.SAVE_PATH
var replay_prompt
var replay_prompt_return_button: Button


func _ready() -> void:
	if get_tree().has_meta(SUMMARY_META):
		var metadata = get_tree().get_meta(SUMMARY_META)
		if metadata is Dictionary:
			_summary = (metadata as Dictionary).duplicate(true)
		get_tree().remove_meta(SUMMARY_META)
	_was_paused = get_tree().paused
	get_tree().paused = true
	_owns_pause = true
	_action_audio = ActionAudioScript.new()
	add_child(_action_audio)
	back_button.pressed.connect(_on_back_pressed)
	next_button.pressed.connect(_on_next_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	explore_button.pressed.connect(_on_explore_pressed)
	replay_button.pressed.connect(_on_replay_pressed)
	replay_prompt = FreshStartPromptScript.new()
	replay_prompt.name = "ReplayStoryPrompt"
	replay_prompt.handle_escape = false
	$Screen.add_child(replay_prompt)
	replay_prompt.accepted.connect(_on_replay_confirmed)
	replay_prompt.canceled.connect(_on_replay_canceled)
	_show_page(_capture_page_index())
	if OS.get_environment("FREYA_ENDING_VIEW").strip_edges().to_lower() == "replay_confirm":
		call_deferred("_capture_replay_confirmation")


func configure_summary(summary: Dictionary) -> void:
	## Optional keys: chapters_secured, allied_dogs, rescued_dogs, claimed_sites.
	_summary = summary.duplicate(true)
	if is_node_ready():
		_show_page(_page)


func _exit_tree() -> void:
	if _owns_pause:
		get_tree().paused = _was_paused
		_owns_pause = false


func _input(event: InputEvent) -> void:
	if _routing or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if replay_prompt != null and replay_prompt.visible:
		if key_event.keycode == KEY_ESCAPE:
			replay_prompt.cancel_prompt()
			get_viewport().set_input_as_handled()
		return
	match key_event.keycode:
		KEY_RIGHT:
			if _page < PAGES.size() - 1:
				_on_next_pressed()
				get_viewport().set_input_as_handled()
		KEY_LEFT:
			if _page > 0:
				_on_back_pressed()
				get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			if _page < PAGES.size() - 1:
				_on_skip_pressed()
			else:
				_on_explore_pressed()
			get_viewport().set_input_as_handled()
		KEY_SPACE:
			if _page < PAGES.size() - 1:
				_on_next_pressed()
				get_viewport().set_input_as_handled()


func _show_page(index: int) -> void:
	_page = clampi(index, 0, PAGES.size() - 1)
	var page: Dictionary = PAGES[_page]
	heading.text = str(page["heading"])
	body.text = str(page["body"])
	if _page == PAGES.size() - 1:
		var summary_text := _format_summary()
		if not summary_text.is_empty():
			body.text = "YOUR STORY\n%s\n\n%s" % [summary_text, body.text]
	status.visible = false
	status.text = ""
	back_button.visible = _page > 0
	var at_credits := _page == PAGES.size() - 1
	if at_credits:
		progress.text = "%d / %d  |  Scroll: read credits  |  Tab: choose  |  Esc: explore" % [_page + 1, PAGES.size()]
	else:
		progress.text = "%d / %d  |  Space / Right: next  |  Left: back  |  Esc: credits" % [_page + 1, PAGES.size()]
	next_button.visible = not at_credits
	skip_button.visible = not at_credits
	explore_button.visible = at_credits
	replay_button.visible = at_credits
	if at_credits:
		explore_button.grab_focus()
	else:
		next_button.grab_focus()


func _on_back_pressed() -> void:
	if _page <= 0 or _routing:
		return
	_play_button()
	_show_page(_page - 1)


func _on_next_pressed() -> void:
	if _page >= PAGES.size() - 1 or _routing:
		return
	_play_button()
	_show_page(_page + 1)


func _on_skip_pressed() -> void:
	if _routing:
		return
	_play_button()
	_show_page(PAGES.size() - 1)


func _on_explore_pressed() -> void:
	if _routing or replay_prompt.visible:
		return
	if get_tree().current_scene == self:
		var slots: Dictionary = GameSaveScript.inspect_slots(resume_save_path)
		if bool(slots.get("incompatible", false)):
			replay_prompt_return_button = explore_button
			_show_incompatible_save_notice(slots)
			return
		var result: Dictionary = GameSaveScript.read_save(resume_save_path)
		if not bool(result.get("ok", false)):
			status.text = "The saved neighborhood could not be loaded. Replay Story is available."
			status.visible = true
			return
		get_tree().set_meta(GameSaveScript.RESUME_META, result["state"])
		get_tree().set_meta(KEEP_EXPLORING_META, true)
	_routing = true
	_action_audio.play_persistent("button", -11.0)
	keep_exploring_requested.emit()
	if get_tree().current_scene == self:
		get_tree().paused = false
		_owns_pause = false
		call_deferred("_open_saved_game")
	else:
		get_tree().paused = _was_paused
		_owns_pause = false
		queue_free()


func _on_replay_pressed() -> void:
	if _routing or replay_prompt.visible:
		return
	var slots: Dictionary = GameSaveScript.inspect_slots(resume_save_path)
	replay_prompt_return_button = replay_button
	if bool(slots.get("incompatible", false)):
		_show_incompatible_save_notice(slots)
		return
	_show_replay_decision(bool(slots.get("has_valid_save", false)))


func _capture_replay_confirmation() -> void:
	# Preview a saved-campaign warning without reading the local player's files.
	replay_prompt_return_button = replay_button
	_show_replay_decision(true)


func _show_replay_decision(has_valid_save: bool) -> void:
	story_panel.hide()
	var detail = "Replaying begins a new game. Its next save will replace your completed campaign. Choose Keep Exploring to stay with your dogs." if has_valid_save else "Replaying begins a new game and leaves this completed story. Cancel to stay at the credits."
	replay_prompt.show_decision("Replay from the beginning?", detail, "Replay Story", "Keep Credits")
	_play_button()


func _show_incompatible_save_notice(slots: Dictionary) -> void:
	story_panel.hide()
	replay_prompt.show_notice("Save from another version", FreshStartPromptScript.incompatible_save_detail(resume_save_path, bool(slots.get("newer", false))))
	_play_button()


func _on_replay_canceled() -> void:
	story_panel.show()
	if replay_prompt_return_button != null:
		replay_prompt_return_button.grab_focus()
	_play_button()


func _on_replay_confirmed() -> void:
	var slots: Dictionary = GameSaveScript.inspect_slots(resume_save_path)
	if bool(slots.get("incompatible", false)):
		_show_incompatible_save_notice(slots)
		return
	_routing = true
	_action_audio.play_persistent("button", -11.0)
	get_tree().paused = false
	_owns_pause = false
	replay_requested.emit()
	call_deferred("_open_new_game")


func _open_new_game() -> void:
	var error := get_tree().change_scene_to_file(INTRO_SCENE_PATH)
	if error != OK:
		push_error("Could not start a new game from the ending (error %d)." % error)
		_routing = false
		_owns_pause = true
		get_tree().paused = true
		status.text = "The story could not restart. Please try again."
		status.visible = true


func _open_saved_game() -> void:
	var error := get_tree().change_scene_to_file(MAIN_SCENE_PATH)
	if error != OK:
		get_tree().remove_meta(GameSaveScript.RESUME_META)
		get_tree().remove_meta(KEEP_EXPLORING_META)
		push_error("Could not return to the saved neighborhood (error %d)." % error)
		_routing = false
		_owns_pause = true
		get_tree().paused = true
		status.text = "The saved neighborhood could not open. Please try again."
		status.visible = true


func _play_button() -> void:
	_action_audio.play("button", -11.0)


func _format_summary() -> String:
	var lines: Array[String] = []
	if _summary.has("chapters_secured"):
		lines.append("Chapters secured: %d" % maxi(0, int(_summary["chapters_secured"])))
	if _summary.has("allied_dogs"):
		lines.append("Pack allies: %d" % maxi(0, int(_summary["allied_dogs"])))
	if _summary.has("rescued_dogs"):
		lines.append("Lodge dogs rescued: %d" % maxi(0, int(_summary["rescued_dogs"])))
	if _summary.has("claimed_sites"):
		lines.append("Sites claimed: %d" % maxi(0, int(_summary["claimed_sites"])))
	return "  |  ".join(lines)


func _capture_page_index() -> int:
	match OS.get_environment("FREYA_ENDING_VIEW").strip_edges().to_lower():
		"return":
			return 0
		"reunion":
			return 1
		"freya":
			return 2
		"credits":
			return 3
		"replay_confirm":
			return 3
	return 0
