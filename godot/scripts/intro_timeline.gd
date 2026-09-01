extends RefCounted

## Editable, absolute-time definition of the Friendly Freya intro.
##
## Keep the scene IDs synchronized with ../INTRO_CUTSCENE.md. The renderer seeks
## this data directly, which makes captures and future Codex edits deterministic.

const TOTAL_DURATION = 25.5
const FLEET_SHIP_COUNT = 8

const SCENES = [
	{
		"id": "scene_01_bridge_establishing",
		"start": 0.0,
		"end": 2.8,
		"shot": "interior",
		"speaker_id": "",
		"runes": "",
		"english": "",
		"rune_duration": 0.0,
		"morph_duration": 0.0
	},
	{
		"id": "scene_02_alien_a_question",
		"start": 2.8,
		"end": 8.0,
		"shot": "interior",
		"speaker_id": "AlienA",
		"speaker_label": "ALIEN A",
		"runes": "|<[]> /\\ <>{} ^|?#",
		"english": "So this is the place?",
		"rune_duration": 1.1,
		"morph_duration": 1.4
	},
	{
		"id": "scene_03_alien_b_answer",
		"start": 8.0,
		"end": 15.0,
		"shot": "interior",
		"speaker_id": "AlienB",
		"speaker_label": "ALIEN B",
		"runes": "^><, ][|/\\ {}[]^ ><\\/\\'? ##|<>{}|<>{}?",
		"english": "Yes, the planet that can't get its shit together.",
		"rune_duration": 1.1,
		"morph_duration": 1.6
	},
	{
		"id": "scene_04_alien_a_command",
		"start": 15.0,
		"end": 19.4,
		"shot": "interior",
		"speaker_id": "AlienA",
		"speaker_label": "ALIEN A",
		"runes": "<|^'[] /\\>{}|<",
		"english": "Let's begin",
		"rune_duration": 1.0,
		"morph_duration": 1.3
	},
	{
		"id": "scene_05_fleet_reveal",
		"start": 19.4,
		"end": TOTAL_DURATION,
		"shot": "fleet",
		"speaker_id": "",
		"runes": "",
		"english": "",
		"rune_duration": 0.0,
		"morph_duration": 0.0
	}
]

const VIEW_TIMES = {
	"establishing": 1.4,
	"a_question_runes": 3.35,
	"a_question_morph": 4.6,
	"a_question_english": 6.4,
	"b_answer_runes": 8.55,
	"b_answer_english": 12.0,
	"a_command_runes": 15.5,
	"a_command_english": 17.8,
	"fleet": 24.6
}

static func scene_for_time(time_seconds: float) -> Dictionary:
	var clamped_time = clampf(time_seconds, 0.0, TOTAL_DURATION)
	for scene in SCENES:
		if clamped_time >= float(scene["start"]) and clamped_time < float(scene["end"]):
			return scene
	return SCENES[SCENES.size() - 1]

static func dialogue_scenes() -> Array:
	var lines: Array = []
	for scene in SCENES:
		if not str(scene.get("speaker_id", "")).is_empty():
			lines.append(scene)
	return lines

static func time_for_view(view_id: String) -> float:
	return float(VIEW_TIMES.get(view_id.strip_edges().to_lower(), -1.0))
