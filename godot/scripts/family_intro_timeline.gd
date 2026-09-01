extends RefCounted

## Absolute-time definition for the family half of the Friendly Freya intro.
##
## This sequence is rendered by Main.gd inside the actual procedurally selected
## Freya home. Keeping the writing here makes dialogue and regression views
## editable without duplicating the gameplay house.

const TOTAL_DURATION = 53.0

const SCENES = [
	{"id": "family_00_home_establishing", "start": 0.0, "end": 2.0, "speaker": "", "text": "", "event": "establishing"},
	{"id": "family_01_zoe_last_day", "start": 2.0, "end": 6.5, "speaker": "ZOE", "text": "Congrats on your last day! I'm so glad you'll be able to work from home now.", "event": "dialogue"},
	{"id": "family_02_gene_new_job", "start": 6.5, "end": 13.0, "speaker": "GENE", "text": "Who knew that Elon Musk would need a licensed pharmacist for his new company that lets guys suck their own dicks?", "event": "dialogue"},
	{"id": "family_03_zoe_drug", "start": 13.0, "end": 20.0, "speaker": "ZOE", "text": "I mean, it's incredible. The drug loosens your joints, eliminates pain, AND makes you really want to suck your own dick!", "event": "dialogue"},
	{"id": "family_04_gene_last_part", "start": 20.0, "end": 23.0, "speaker": "GENE", "text": "Didn't know Elon needed that last part", "event": "dialogue"},
	{"id": "family_05_laugh", "start": 23.0, "end": 25.0, "speaker": "GENE & ZOE", "text": "Ha, ha, ha", "event": "laugh"},
	{"id": "family_06_zoe_gift", "start": 25.0, "end": 28.4, "speaker": "ZOE", "text": "Anyways, did you get our parting gift?", "event": "dialogue"},
	{"id": "family_07_gene_pills", "start": 28.4, "end": 35.8, "speaker": "GENE", "text": "Yes! I was able to swipe these from the pharmacy when my manager wasn't looking. She'll get blamed for it, so it's all good.", "event": "pills"},
	{"id": "family_08_zoe_ryah", "start": 35.8, "end": 39.8, "speaker": "ZOE", "text": "But who will look after Ryah when we're celebrating?", "event": "dialogue"},
	{"id": "family_09_gene_freya", "start": 39.8, "end": 41.7, "speaker": "GENE", "text": "Freya will!", "event": "dialogue"},
	{"id": "family_10_freya_bark", "start": 41.7, "end": 43.0, "speaker": "FREYA", "text": "BARK!", "event": "bark"},
	{"id": "family_11_zoe_interrupted", "start": 43.0, "end": 45.0, "speaker": "ZOE", "text": "Okay, ope---", "event": "dialogue"},
	{"id": "family_12_parents_abducted", "start": 45.0, "end": 48.0, "speaker": "", "text": "", "event": "parents_abducted"},
	{"id": "family_13_ryah_targeted", "start": 48.0, "end": 50.0, "speaker": "", "text": "", "event": "ryah_targeted"},
	{"id": "family_14_freya_loud_bark", "start": 50.0, "end": 51.2, "speaker": "FREYA", "text": "BARK!", "event": "loud_bark"},
	{"id": "family_15_ryah_saved", "start": 51.2, "end": TOTAL_DURATION, "speaker": "", "text": "", "event": "ryah_saved"}
]

const VIEW_TIMES = {
	"family_home": 1.0,
	"family_gene": 11.0,
	"family_zoe": 18.0,
	"family_pills": 34.2,
	"family_abduction": 46.4,
	"family_ryah_targeted": 49.0,
	"family_loud_bark": 50.55,
	"family_ryah_saved": 52.0
}


static func scene_for_time(time_seconds: float) -> Dictionary:
	var clamped_time = clampf(time_seconds, 0.0, TOTAL_DURATION)
	for scene in SCENES:
		if clamped_time >= float(scene["start"]) and clamped_time < float(scene["end"]):
			return scene
	return SCENES[SCENES.size() - 1]


static func time_for_view(view_id: String) -> float:
	return float(VIEW_TIMES.get(view_id.strip_edges().to_lower(), -1.0))


static func dialogue_scenes() -> Array:
	var lines: Array = []
	for scene in SCENES:
		if not str(scene.get("speaker", "")).is_empty():
			lines.append(scene)
	return lines
