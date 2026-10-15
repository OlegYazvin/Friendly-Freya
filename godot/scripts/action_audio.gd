extends Node

## Recorded action cues only. Every ID has one exact file; missing or invalid
## files cause silence. No generated sound, alternate file, or fallback pool.

const CUE_PATHS := {
	"dog_run": "res://assets/audio/actions/dog_paws_skitter_208654.ogg",
	"dog_sniff": "res://assets/audio/actions/dog_sniff_pant_784915.ogg",
	"dog_whine": "res://assets/audio/actions/dog_whine_462660.ogg",
	"recruit": "res://assets/audio/actions/collar_jingle_611827.ogg",
	"door": "res://assets/audio/actions/home_door_683434.ogg",
	"kennel_gate": "res://assets/audio/actions/metal_gate_411884.ogg",
	"medicine": "res://assets/audio/actions/medicine_bottle_460153.ogg",
	"clinic_care": "res://assets/audio/actions/clinic_fabric_rustle.ogg",
	"armor": "res://assets/audio/actions/armor_velcro_267713.ogg",
	"stick_pickup": "res://assets/audio/actions/stick_pickup_qubodup_wobble2.ogg",
	"stick_drop": "res://assets/audio/actions/stick_drop_593178.ogg",
	"dumpster": "res://assets/audio/actions/dumpster_lid_254982.ogg",
	"alien_interrupt": "res://assets/audio/actions/suction_pop_386885.ogg",
	"alien_emerge": "res://assets/audio/actions/slime_squelch_433839.ogg",
	"alien_warning": "res://assets/audio/actions/electric_arc_367456.ogg",
	"button": "res://assets/audio/actions/button_click_622060.ogg",
	"claim": "res://assets/audio/actions/bubble_pop_669918.ogg",
	"family_laugh": "res://assets/audio/actions/family_group_giggling.ogg",
	"family_pills_revealed": "res://assets/audio/actions/medicine_bottle_460153.ogg",
	"family_abduction_beam": "res://assets/audio/actions/electric_arc_367456.ogg",
	"family_pills_landed": "res://assets/audio/actions/medicine_bottle_460153.ogg",
	"family_parents_vanish": "res://assets/audio/actions/suction_pop_386885.ogg",
	"family_ryah_beam": "res://assets/audio/actions/electric_arc_367456.ogg",
	"family_ryah_beam_break": "res://assets/audio/actions/suction_pop_386885.ogg",
	"family_pills_eaten": "res://assets/audio/eat/dog_chewing_crunchy_456376.mp3",
	"family_convulsion": "res://assets/audio/actions/collar_jingle_611827.ogg",
	"first_exit_abduction_beam": "res://assets/audio/actions/electric_arc_367456.ogg",
	"first_exit_walkers_vanish": "res://assets/audio/actions/suction_pop_386885.ogg",
	"first_exit_dog_possession": "res://assets/audio/actions/slime_squelch_433839.ogg",
	"first_exit_freya_target": "res://assets/audio/actions/electric_arc_367456.ogg",
	"first_exit_immunity_bounce": "res://assets/audio/actions/suction_pop_386885.ogg"
}

var _players: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("server") or DisplayServer.get_name() == "headless":
		return
	for cue_id in CUE_PATHS:
		var stream := _load_exact_stream(str(CUE_PATHS[cue_id]))
		if stream == null:
			continue
		var player := AudioStreamPlayer.new()
		player.name = "Recorded_%s" % str(cue_id)
		player.stream = stream
		player.bus = "Master"
		add_child(player)
		_players[cue_id] = player


func _load_exact_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path, "AudioStream"):
		return null
	var resource := ResourceLoader.load(path, "AudioStream")
	if resource is AudioStream:
		return resource as AudioStream
	return null


func play(cue_id: String, volume_db: float = 0.0) -> void:
	var player: AudioStreamPlayer = _players.get(cue_id, null)
	if player == null or not is_instance_valid(player):
		return
	player.volume_db = volume_db
	player.stop()
	player.play()


func play_persistent(cue_id: String, volume_db: float = 0.0) -> void:
	if OS.has_feature("server") or DisplayServer.get_name() == "headless":
		return
	var source: AudioStreamPlayer = _players.get(cue_id, null)
	if source == null or not is_instance_valid(source) or source.stream == null:
		return
	var scene_root := get_tree().root
	if scene_root == null:
		return
	var player := AudioStreamPlayer.new()
	player.name = "RecordedPersistent_%s" % cue_id
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.stream = source.stream
	player.bus = source.bus
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)
	scene_root.add_child(player)
	player.play()
	if not player.playing:
		player.queue_free()


func play_cue(cue_id: String, volume_db: float = 0.0) -> void:
	play(cue_id, volume_db)


func stop_cue(cue_id: String) -> void:
	var player: AudioStreamPlayer = _players.get(cue_id, null)
	if player != null and is_instance_valid(player):
		player.stop()


func is_available(cue_id: String) -> bool:
	return _players.has(cue_id)


func unavailable_cue_ids() -> Array[String]:
	var missing: Array[String] = []
	for cue_id in CUE_PATHS:
		if not _players.has(cue_id):
			missing.append(str(cue_id))
	return missing
