extends Node3D

const DogAgentScript = preload("res://scripts/dog_agent.gd")
const BuildingFactoryScript = preload("res://scripts/building_factory.gd")
const TreeFactoryScript = preload("res://scripts/tree_factory.gd")
const MiniMapScript = preload("res://scripts/minimap.gd")

const MAP_W = 144.0
const MAP_H = 118.0
const ROAD_W = 4.2
const SIDEWALK_W = 1.15
const ALLEY_W = 2.25

const FREYA_BASE_SPEED = 4.6
const FREYA_RUN_MULT = 1.55
const FREYA_STICK_RUN_MULT = 1.36
const CAMERA_ORBIT_SPEED = 1.95
const STICK_VISUAL_SCALE = 1.2
const STICK_THICKNESS_MULT = 1.45
const STICK_MOUTH_FORWARD_OFFSET = -0.08
const STICK_MOUTH_UP_OFFSET = -0.02
const STICK_MOUTH_RIGHT_OFFSET = 0.0
const STICK_MOUTH_PITCH_DEG = -2.0
const BARK_PRIMARY_SOURCE = "res://assets/audio/dog_barking.wav"
const BARK_PASSIVE_SAMPLE_CANDIDATES = [
	"res://assets/audio/barks/bark_real_01.wav",
	"res://assets/audio/barks/bark_real_02.wav",
	"res://assets/audio/barks/bark_real_03.wav",
	"res://assets/audio/barks/bark_real_04.wav",
	"res://assets/audio/barks/bark_real_05.wav",
	"res://assets/audio/barks/bark_real_06.wav",
	"res://assets/audio/barks/bark_real_07.wav",
	"res://assets/audio/barks/bark_real_08.wav"
]
const BARK_AGGRESSIVE_SAMPLE_CANDIDATES = [
	"res://assets/audio/barks/aggressive_bark_01.wav",
	"res://assets/audio/barks/aggressive_bark_02.wav",
	"res://assets/audio/barks/aggressive_bark_03.wav",
	"res://assets/audio/barks/aggressive_bark_04.wav",
	"res://assets/audio/barks/aggressive_bark_05.wav",
	"res://assets/audio/barks/aggressive_bark_06.wav"
]
const OBJECTIVE_CLAIM_TARGET = 10
const OBJECTIVE_HYDRANT_TARGET = 8
const CLAIM_TARGET_NONE = 0
const CLAIM_TARGET_LIGHT_POLE = 1
const CLAIM_TARGET_TREE = 2
const CLAIM_TARGET_FIRE_HYDRANT = 3
const CLAIM_RANGE = 1.8
const CLAIM_FILL_TIME = 2.75
const CLAIM_RING_PULSE_SPEED = 4.1
const CLAIM_PEE_SOURCE_BACK_OFFSET = 0.34
const CLAIM_PEE_SOURCE_UP_OFFSET = 0.34
const CLAIM_PEE_SOURCE_RIGHT_OFFSET = 0.0
const CLAIM_PEE_STREAM_RADIUS = 0.028
const CLAIM_PEE_TARGET_POLE_HEIGHT = 0.44
const CLAIM_PEE_TARGET_TREE_HEIGHT = 0.56
const OCCLUSION_UPDATE_INTERVAL = 0.04
const OCCLUSION_MOVE_EPS = 0.04
const MINIMAP_UPDATE_INTERVAL = 0.08
const FREYA_COLLISION_RADIUS = 0.34
const DOG_COLLISION_RADIUS = 0.28
const DUMPSTER_COLLISION_RADIUS = 0.48
const STREET_POLE_COLLISION_RADIUS = 0.2
const FIRE_HYDRANT_COLLISION_RADIUS = 0.18
const FIRE_HYDRANT_SPACING = 17.0
const STREET_POLE_SPACING = 10.8
const STREET_POLE_END_MARGIN = 2.6
const MINIMAP_ZOOM_STEP = 0.3
const BUILDING_SIDEWALK_W = 0.95
const BUILDING_COLLISION_PAD = 0.02
const ROW_FRONT_SETBACK = 3.25
const ROW_SIDE_SETBACK = 0.72
const ALLEY_BUILDING_GAP = 0.2
const STORE_WALL_THICKNESS = 0.28
const STORE_DOOR_HALF_WIDTH = 1.1
const STORE_DOOR_DEPTH = 0.86
const STORE_INTERIOR_MARGIN = 0.34
const STORE_INTERIOR_WALL_HEIGHT = 2.55
const STORE_FOCUS_UPDATE_INTERVAL = 0.03
const TREE_COLLISION_SCALE = 0.34
const STICK_PICKUP_RANGE = 1.55
const BONE_PICKUP_RANGE = 1.55
const FREYA_PRIMARY_MODEL = "res://assets/models/freya_portuguese_water_dog.glb"
const FREYA_MODEL_CANDIDATES = [
	"res://assets/models/freya_portuguese_water_dog.glb",
	"res://assets/models/freya_black_lab.glb",
	"res://assets/models/freya_dog.glb"
]
const NPC_DOG_MODEL_CANDIDATES = [
	"res://assets/models/dog_labrador.glb",
	"res://assets/models/dog_golden.glb",
	"res://assets/models/dog_husky.glb",
	"res://assets/models/dog_neighbor_01.glb",
	"res://assets/models/dog_neighbor_02.glb"
]
const NPC_DOG_COUNT = 24
const DOG_PARK_NPC_COUNT = 10
const NPC_SIDEWALK_PREF_CHANCE = 0.82
const FREYA_OCCLUSION_SAMPLE_BLOCK_THRESHOLD = 4
const FREYA_SOCIAL_DANCE_RADIUS = 0.58
const FREYA_SOCIAL_DANCE_SPEED = 2.15
const FREYA_SOCIAL_DANCE_SPIN_SPEED = 6.7
const NPC_MODEL_SCALE_OVERRIDES = {
	"res://assets/models/dog_husky.glb": 0.76
}

var rng = RandomNumberGenerator.new()

var world_root: Node3D
var static_root: Node3D
var dynamic_root: Node3D
var camera_node: Camera3D

var roads: Array[Rect2] = []
var sidewalks: Array[Rect2] = []
var alleys: Array[Rect2] = []
var alley_shoulders: Array[Rect2] = []
var block_parcels: Array[Rect2] = []
var buildings: Array = []
var trees: Array = []
var fire_hydrants: Array = []

var dogs: Array = []
var poops: Array = []
var sticks: Array = []
var dumpsters: Array = []
var bones: Array = []
var store_foods: Array = []
var street_poles: Array = []
var vomit_puddles: Array = []
var bark_pulses: Array = []
var store_entry_indicators: Array = []
var store_interior_nodes: Array[Node3D] = []
var store_building_indices: Array[int] = []
var blocking_building_rects: Array[Rect2] = []
var store_walk_blockers: Array[Rect2] = []

var dog_park = Rect2()
var freya
var freya_hunger = 34.0
var freya_vomit = 0.0
var freya_social = 24.0
var freya_strength = 0.0
var freya_vomit_timer = 0.0
var freya_move_dir = Vector3.ZERO
var freya_social_dance_phase = 0.0
var camera_focus = Vector3.ZERO
var camera_orbit_angle = 0.0

var world_time = 0.0
var poop_spawn_timer = 4.1
var occlusion_update_timer = 0.0
var last_occlusion_cam_pos = Vector3(100000.0, 100000.0, 100000.0)
var last_occlusion_freya_pos = Vector3(-100000.0, -100000.0, -100000.0)
var minimap_update_timer = 0.0
var store_focus_timer = 0.0
var active_store_index = -1

var grass_material: Material
var road_material: Material
var sidewalk_material: Material
var alley_material: Material
var dog_park_material: Material

var poop_material: StandardMaterial3D
var stick_material_main: StandardMaterial3D
var stick_material_branch: StandardMaterial3D
var dumpster_body_materials: Array[StandardMaterial3D] = []
var dumpster_lid_material: StandardMaterial3D
var dumpster_trim_material: StandardMaterial3D
var pole_metal_material: StandardMaterial3D
var pole_base_material: StandardMaterial3D
var pole_lamp_material: StandardMaterial3D
var fire_hydrant_body_material: StandardMaterial3D
var fire_hydrant_cap_material: StandardMaterial3D
var claim_ring_material: StandardMaterial3D
var claim_pee_stream_material: StandardMaterial3D
var claim_pee_splash_material: StandardMaterial3D
var vomit_material_a: StandardMaterial3D
var vomit_material_b: StandardMaterial3D
var bone_material: StandardMaterial3D
var store_food_materials: Array[StandardMaterial3D] = []

var freya_outline_material: ShaderMaterial
var freya_ghost_material: ShaderMaterial
var object_outline_material: ShaderMaterial
var outlined_freya_meshes: Array[MeshInstance3D] = []
var outlined_object_meshes: Array[MeshInstance3D] = []

var freya_has_stick = false
var carried_stick: Node3D

var ui_layer: CanvasLayer
var hunger_bar: ProgressBar
var vomit_bar: ProgressBar
var social_bar: ProgressBar
var strength_bar: ProgressBar
var hunger_value_label: Label
var vomit_value_label: Label
var social_value_label: Label
var strength_value_label: Label
var status_label: Label
var status_timer = 0.0
var objectives_panel: Panel
var objectives_list_label: Label
var objective_puke_on_dog_complete = false
var claim_meter_panel: Panel
var claim_meter_label: Label
var claim_meter_bar: ProgressBar
var active_claim_target_type = CLAIM_TARGET_NONE
var active_claim_target_index = -1
var claim_pee_stream_node: Node3D
var claim_pee_stream_segments: Array[MeshInstance3D] = []
var claim_pee_splash_node: MeshInstance3D

var minimap
var minimap_zoom_slider: HSlider
var store_focus_layer: CanvasLayer
var store_focus_overlay: ColorRect
var pause_menu_layer: CanvasLayer
var pause_menu_panel: Panel
var pause_menu_open = false
var bark_sfx_players: Array[AudioStreamPlayer] = []
var bark_sfx_streams_passive: Array[AudioStream] = []
var bark_sfx_streams_aggressive: Array[AudioStream] = []
var bark_sfx_cursor = 0
var bark_last_clip_idx = -1
var bark_sequences: Array = []
var aggressive_bark_pressure = 0.0
var aggressive_bark_nearby_count = 0
var pause_controls_button: Button
var pause_howto_button: Button
var pause_controls_panel: Panel
var pause_howto_panel: Panel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	_configure_input()
	_create_render_setup()
	_create_world_roots()
	_create_audio_setup()
	_create_prop_materials()

	_generate_city_layout()
	_create_ground_materials()
	_build_ground_meshes()
	_build_dog_park()
	_build_city_buildings()
	_mark_store_buildings()
	_add_building_sidewalks()
	_spawn_street_poles()
	_spawn_fire_hydrants()
	_spawn_alley_dumpsters()
	_populate_trees()
	_build_grass_spikes()
	_spawn_sticks(64)
	_populate_store_foods()

	_spawn_freya_and_dogs()
	_seed_poops(30)
	_create_ui()
	_sync_minimap_static()
	_update_minimap_dynamic(0.0)

	camera_focus = freya.global_position + Vector3(0.0, 0.95, 0.0)
	_update_camera(0.0)
	_update_roof_occlusion(0.0)
	_update_ui()

	if OS.has_feature("server") or OS.get_environment("FREYA_SMOKE") == "1":
		_run_headless_smoke_checks()
	if OS.get_environment("FREYA_VALIDATE") == "1":
		_run_targeted_validation_checks()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		_toggle_pause_menu()
	if pause_menu_open:
		_hide_claim_meter()
		_hide_claim_pee_effect()
		_update_objectives_overlay()
		return

	world_time += delta
	status_timer = max(0.0, status_timer - delta)
	if status_timer <= 0.0:
		status_label.text = ""

	_update_camera_orbit_input(delta)
	_update_freya(delta)
	_update_store_focus(delta)
	_update_dogs(delta)
	_handle_actions()
	_update_carried_stick_pose()
	_update_poops(delta)
	_update_vomit_puddles(delta)
	_update_bark_sequences(delta)
	_update_bark_pulses(delta)
	_update_store_entry_indicators(delta)
	_update_camera(delta)
	_update_claiming(delta)
	_update_claim_pee_effect(delta)
	_update_claim_rings()
	_update_roof_occlusion(delta)
	_update_ui()
	_update_objectives_overlay()
	_update_minimap_dynamic(delta)

func _configure_input() -> void:
	_ensure_action("move_left", [Key.KEY_A, Key.KEY_LEFT])
	_ensure_action("move_right", [Key.KEY_D, Key.KEY_RIGHT])
	_ensure_action("move_up", [Key.KEY_W, Key.KEY_UP])
	_ensure_action("move_down", [Key.KEY_S, Key.KEY_DOWN])
	_ensure_action("run", [Key.KEY_SHIFT])
	_remove_action_key("eat", int(Key.KEY_E))
	_ensure_action("eat", [Key.KEY_F])
	_ensure_action("camera_rotate_ccw", [Key.KEY_Q])
	_ensure_action("camera_rotate_cw", [Key.KEY_E])
	_ensure_action("vomit", [Key.KEY_SPACE])
	_ensure_action("drop_stick", [Key.KEY_V])
	_ensure_action("claim", [Key.KEY_R])
	_ensure_action("aggressive_social", [Key.KEY_X])
	_ensure_action("objectives", [Key.KEY_TAB])
	_ensure_action("menu", [Key.KEY_ESCAPE])

func _ensure_action(name: String, keys: Array) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name)
	for k in keys:
		if _action_has_key(name, int(k)):
			continue
		var ev = InputEventKey.new()
		ev.physical_keycode = int(k)
		ev.keycode = int(k)
		InputMap.action_add_event(name, ev)

func _action_has_key(name: String, keycode: int) -> bool:
	if not InputMap.has_action(name):
		return false
	for ev in InputMap.action_get_events(name):
		if ev is InputEventKey and (ev.physical_keycode == keycode or ev.keycode == keycode):
			return true
	return false

func _remove_action_key(name: String, keycode: int) -> void:
	if not InputMap.has_action(name):
		return
	for ev in InputMap.action_get_events(name):
		if ev is InputEventKey and (ev.physical_keycode == keycode or ev.keycode == keycode):
			InputMap.action_erase_event(name, ev)

func _create_render_setup() -> void:
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.67, 0.82, 0.95)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.81, 0.74)
	environment.ambient_light_energy = 1.2
	environment.ssao_enabled = false
	environment.ssil_enabled = false
	environment.glow_enabled = false
	env.environment = environment
	add_child(env)

	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -36.0, 0.0)
	sun.light_energy = 2.7
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 92.0
	add_child(sun)

	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-36.0, 144.0, 0.0)
	fill.light_energy = 0.62
	fill.light_color = Color(0.82, 0.9, 0.94)
	fill.shadow_enabled = false
	add_child(fill)

	camera_node = Camera3D.new()
	camera_node.fov = 40.0
	camera_node.near = 0.1
	camera_node.far = 220.0
	add_child(camera_node)

func _create_world_roots() -> void:
	world_root = Node3D.new()
	world_root.name = "World"
	add_child(world_root)

	static_root = Node3D.new()
	static_root.name = "Static"
	world_root.add_child(static_root)

	dynamic_root = Node3D.new()
	dynamic_root.name = "Dynamic"
	world_root.add_child(dynamic_root)

func _create_audio_setup() -> void:
	bark_sfx_streams_passive.clear()
	for stream in _load_bark_streams_from_files(BARK_PASSIVE_SAMPLE_CANDIDATES):
		bark_sfx_streams_passive.append(stream)
	if bark_sfx_streams_passive.is_empty():
		push_warning("Passive bark clips missing; using base dog bark source.")
		if FileAccess.file_exists(BARK_PRIMARY_SOURCE):
			var primary_stream = AudioStreamWAV.load_from_file(BARK_PRIMARY_SOURCE)
			if primary_stream != null:
				bark_sfx_streams_passive.append(primary_stream)

	bark_sfx_streams_aggressive.clear()
	for stream in _load_bark_streams_from_files(BARK_AGGRESSIVE_SAMPLE_CANDIDATES):
		bark_sfx_streams_aggressive.append(stream)
	if bark_sfx_streams_aggressive.is_empty():
		for stream in bark_sfx_streams_passive:
			bark_sfx_streams_aggressive.append(stream)
	if bark_sfx_streams_aggressive.is_empty():
		bark_sfx_streams_aggressive.append(_build_bark_stream(112.0, 0.43, 0.24))
		bark_sfx_streams_aggressive.append(_build_bark_stream(121.0, 0.46, 0.23))

	for p in bark_sfx_players:
		if p != null:
			p.queue_free()
	bark_sfx_players.clear()

	for i in range(14):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = -13.0
		add_child(player)
		bark_sfx_players.append(player)
	bark_sfx_cursor = 0
	bark_last_clip_idx = -1
	bark_sequences.clear()

func _load_bark_streams_from_files(candidates: Array) -> Array[AudioStream]:
	var out: Array[AudioStream] = []
	for path in candidates:
		if not FileAccess.file_exists(path):
			continue
		var lower = path.to_lower()
		var stream: AudioStream = null
		if lower.ends_with(".wav"):
			stream = AudioStreamWAV.load_from_file(path)
		elif lower.ends_with(".ogg"):
			stream = AudioStreamOggVorbis.load_from_file(path)
		if stream != null:
			out.append(stream)
	if out.is_empty() and FileAccess.file_exists(BARK_PRIMARY_SOURCE):
		var primary = AudioStreamWAV.load_from_file(BARK_PRIMARY_SOURCE)
		if primary != null:
			out.append(primary)
	return out

func _bark_pulse_envelope(t: float, start_t: float, attack_t: float, hold_t: float, release_t: float) -> float:
	var rel = t - start_t
	if rel < 0.0:
		return 0.0
	var attack = maxf(0.001, attack_t)
	var hold = maxf(0.0, hold_t)
	var release = maxf(0.001, release_t)
	if rel < attack:
		return rel / attack
	if rel < attack + hold:
		return 1.0
	var out = 1.0 - ((rel - attack - hold) / release)
	return clampf(out, 0.0, 1.0)

func _build_bark_stream(base_freq: float, roughness: float, duration: float) -> AudioStreamWAV:
	var sample_rate := 44100
	var sample_count := int(maxf(1.0, duration * float(sample_rate)))
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	var local_rng = RandomNumberGenerator.new()
	local_rng.seed = int(base_freq * 1000.0 + roughness * 10000.0)

	var phase_root := 0.0
	var phase_harm := 0.0
	var phase_air := 0.0
	var noise_lp := 0.0
	var noise_body := 0.0
	var second_start = duration * local_rng.randf_range(0.31, 0.44)
	var second_hold = duration * local_rng.randf_range(0.05, 0.09)
	var second_release = duration * local_rng.randf_range(0.17, 0.27)

	for i in range(sample_count):
		var t := float(i) / float(sample_rate)
		var tn := clampf(t / maxf(duration, 0.001), 0.0, 1.0)

		var env_main = _bark_pulse_envelope(
			t,
			0.0,
			duration * 0.038,
			duration * 0.09,
			duration * 0.42
		)
		var env_second = _bark_pulse_envelope(
			t,
			second_start,
			duration * 0.03,
			second_hold,
			second_release
		)
		var envelope = maxf(env_main, env_second * 0.68)
		envelope *= 1.0 - clampf((t - duration * 0.9) / maxf(0.01, duration * 0.12), 0.0, 1.0)

		var pitch_fall = lerpf(1.08, 0.72, pow(tn, 0.86))
		var vibrato = sin(TAU * (4.7 + roughness * 1.8) * t) * 0.012
		var f0 := maxf(72.0, base_freq * (pitch_fall + vibrato))
		phase_root += TAU * f0 / float(sample_rate)
		phase_harm += TAU * (f0 * 2.46) / float(sample_rate)
		phase_air += TAU * (f0 * 4.32) / float(sample_rate)

		var root = sin(phase_root)
		var chest = sin(phase_root * 0.5 + sin(phase_root * 0.19) * 0.62)
		var formant = sin(phase_harm + sin(phase_root) * 0.16) * 0.64 + sin(phase_air) * 0.24
		var raw_noise = local_rng.randf_range(-1.0, 1.0)
		noise_lp = lerpf(noise_lp, raw_noise, 0.08 + roughness * 0.08)
		noise_body = lerpf(noise_body, raw_noise, 0.02)
		var hiss = raw_noise - noise_lp
		var transient = hiss * _bark_pulse_envelope(t, 0.0, duration * 0.015, duration * 0.01, duration * 0.05)
		var breath = hiss * (0.2 + roughness * 0.44) + noise_body * 0.12

		var throat = root * 0.76 + chest * 0.31 + formant * 0.33
		var sample: float = throat + breath * 0.24 + transient * (0.22 + roughness * 0.18)
		sample = tanh(sample * (1.18 + roughness * 0.46))
		sample *= envelope * 0.92
		sample = clampf(sample, -1.0, 1.0)
		var int_sample := int(round(sample * 32767.0))
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _play_bark_sound(is_freya_bark: bool, aggressive: bool = false) -> void:
	var bark_pool = bark_sfx_streams_aggressive if aggressive else bark_sfx_streams_passive
	if bark_pool.is_empty():
		bark_pool = bark_sfx_streams_passive
	if bark_sfx_players.is_empty() or bark_pool.is_empty():
		return
	var idx: int = bark_sfx_cursor % bark_sfx_players.size()
	bark_sfx_cursor += 1
	var player: AudioStreamPlayer = bark_sfx_players[idx]
	if player == null:
		return

	var clip_idx = rng.randi_range(0, bark_pool.size() - 1)
	if bark_pool.size() > 1 and clip_idx == bark_last_clip_idx:
		clip_idx = (clip_idx + 1 + rng.randi_range(0, bark_pool.size() - 2)) % bark_pool.size()
	bark_last_clip_idx = clip_idx
	var clip: AudioStream = bark_pool[clip_idx]
	player.stop()
	player.stream = clip
	if aggressive:
		var crowd_gain = clampf((aggressive_bark_pressure - 1.0) * 1.0, 0.0, 5.5)
		player.pitch_scale = rng.randf_range(0.96, 1.04) * (0.99 if is_freya_bark else 1.0)
		player.volume_db = (-6.8 if is_freya_bark else -8.0) + crowd_gain
	else:
		player.pitch_scale = rng.randf_range(0.98, 1.03) * (0.995 if is_freya_bark else 1.0)
		player.volume_db = -7.8 if is_freya_bark else -9.0
	player.play()

func _queue_bark_sequence(is_freya_bark: bool, barks: int, aggressive: bool = false) -> void:
	if barks <= 0:
		return
	if bark_sequences.size() > 54:
		return
	bark_sequences.append({
		"is_freya": is_freya_bark,
		"aggressive": aggressive,
		"remaining": barks,
		"next": 0.0
	})

func _update_bark_sequences(delta: float) -> void:
	for i in range(bark_sequences.size() - 1, -1, -1):
		var seq: Dictionary = bark_sequences[i]
		seq["next"] = float(seq.get("next", 0.0)) - delta
		if float(seq["next"]) <= 0.0:
			var is_freya = bool(seq.get("is_freya", false))
			var aggressive = bool(seq.get("aggressive", false))
			_play_bark_sound(is_freya, aggressive)
			var remaining = int(seq.get("remaining", 0)) - 1
			if remaining <= 0:
				bark_sequences.remove_at(i)
				continue
			seq["remaining"] = remaining
			seq["next"] = rng.randf_range(0.18, 0.34) if aggressive else rng.randf_range(0.28, 0.52)
		bark_sequences[i] = seq

func _create_prop_materials() -> void:
	poop_material = StandardMaterial3D.new()
	poop_material.albedo_color = Color8(95, 63, 40)
	poop_material.roughness = 0.86

	dumpster_body_materials.clear()
	for c in [Color8(46, 96, 70), Color8(55, 86, 112), Color8(74, 87, 70)]:
		var body_mat = StandardMaterial3D.new()
		body_mat.albedo_color = c
		body_mat.roughness = 0.9
		body_mat.metallic = 0.06
		dumpster_body_materials.append(body_mat)

	dumpster_lid_material = StandardMaterial3D.new()
	dumpster_lid_material.albedo_color = Color8(58, 62, 64)
	dumpster_lid_material.roughness = 0.83
	dumpster_lid_material.metallic = 0.12

	dumpster_trim_material = StandardMaterial3D.new()
	dumpster_trim_material.albedo_color = Color8(30, 31, 33)
	dumpster_trim_material.roughness = 0.74
	dumpster_trim_material.metallic = 0.16

	pole_metal_material = StandardMaterial3D.new()
	pole_metal_material.albedo_color = Color8(69, 74, 80)
	pole_metal_material.roughness = 0.58
	pole_metal_material.metallic = 0.5

	pole_base_material = StandardMaterial3D.new()
	pole_base_material.albedo_color = Color8(104, 106, 110)
	pole_base_material.roughness = 0.9
	pole_base_material.metallic = 0.06

	pole_lamp_material = StandardMaterial3D.new()
	pole_lamp_material.albedo_color = Color8(231, 223, 198)
	pole_lamp_material.roughness = 0.28
	pole_lamp_material.metallic = 0.0
	pole_lamp_material.emission_enabled = true
	pole_lamp_material.emission = Color(0.22, 0.19, 0.1)
	pole_lamp_material.emission_energy_multiplier = 0.32

	fire_hydrant_body_material = StandardMaterial3D.new()
	fire_hydrant_body_material.albedo_color = Color8(196, 38, 37)
	fire_hydrant_body_material.roughness = 0.5
	fire_hydrant_body_material.metallic = 0.14
	fire_hydrant_body_material.emission_enabled = true
	fire_hydrant_body_material.emission = Color(0.52, 0.06, 0.05)
	fire_hydrant_body_material.emission_energy_multiplier = 0.22

	fire_hydrant_cap_material = StandardMaterial3D.new()
	fire_hydrant_cap_material.albedo_color = Color8(229, 214, 144)
	fire_hydrant_cap_material.roughness = 0.3
	fire_hydrant_cap_material.metallic = 0.16

	claim_ring_material = StandardMaterial3D.new()
	claim_ring_material.albedo_color = Color(0.93, 0.18, 0.96, 0.76)
	claim_ring_material.roughness = 0.14
	claim_ring_material.metallic = 0.0
	claim_ring_material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	claim_ring_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	claim_ring_material.cull_mode = StandardMaterial3D.CULL_DISABLED
	claim_ring_material.emission_enabled = true
	claim_ring_material.emission = Color(0.64, 0.08, 0.68)
	claim_ring_material.emission_energy_multiplier = 1.8

	claim_pee_stream_material = StandardMaterial3D.new()
	claim_pee_stream_material.albedo_color = Color(1.0, 0.95, 0.24, 0.82)
	claim_pee_stream_material.roughness = 0.12
	claim_pee_stream_material.metallic = 0.0
	claim_pee_stream_material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	claim_pee_stream_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	claim_pee_stream_material.cull_mode = StandardMaterial3D.CULL_DISABLED
	claim_pee_stream_material.emission_enabled = true
	claim_pee_stream_material.emission = Color(0.97, 0.83, 0.12)
	claim_pee_stream_material.emission_energy_multiplier = 0.92

	claim_pee_splash_material = StandardMaterial3D.new()
	claim_pee_splash_material.albedo_color = Color(1.0, 0.95, 0.3, 0.78)
	claim_pee_splash_material.roughness = 0.16
	claim_pee_splash_material.metallic = 0.0
	claim_pee_splash_material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	claim_pee_splash_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	claim_pee_splash_material.cull_mode = StandardMaterial3D.CULL_DISABLED
	claim_pee_splash_material.emission_enabled = true
	claim_pee_splash_material.emission = Color(0.95, 0.82, 0.14)
	claim_pee_splash_material.emission_energy_multiplier = 1.05

	stick_material_main = StandardMaterial3D.new()
	stick_material_main.albedo_color = Color8(132, 99, 62)
	stick_material_main.roughness = 0.88
	stick_material_main.metallic = 0.0

	stick_material_branch = StandardMaterial3D.new()
	stick_material_branch.albedo_color = Color8(114, 84, 53)
	stick_material_branch.roughness = 0.9
	stick_material_branch.metallic = 0.0

	vomit_material_a = StandardMaterial3D.new()
	vomit_material_a.albedo_color = Color8(167, 151, 92)
	vomit_material_a.roughness = 0.88
	vomit_material_a.metallic = 0.0

	vomit_material_b = StandardMaterial3D.new()
	vomit_material_b.albedo_color = Color8(126, 104, 64)
	vomit_material_b.roughness = 0.94
	vomit_material_b.metallic = 0.0

	bone_material = StandardMaterial3D.new()
	bone_material.albedo_color = Color8(231, 224, 198)
	bone_material.roughness = 0.7
	bone_material.metallic = 0.0

	store_food_materials.clear()
	for c in [Color8(223, 137, 77), Color8(199, 170, 76), Color8(173, 92, 58), Color8(214, 98, 74)]:
		var m = StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.72
		m.metallic = 0.0
		store_food_materials.append(m)

	freya_outline_material = _make_outline_material(Color(0.18, 0.96, 0.98, 1.0), 0.05)
	freya_ghost_material = _make_ghost_material(Color(0.72, 0.96, 1.0, 0.72))
	object_outline_material = _make_outline_material(Color(0.98, 0.92, 0.42, 0.96), 0.036)

func _make_outline_material(color: Color, thickness: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, blend_mix;

uniform vec4 outline_color : source_color = vec4(0.0, 1.0, 1.0, 0.9);
uniform float outline_width = 0.03;
uniform float fill_alpha = 0.18;

void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	float rim = pow(1.0 - abs(dot(n, v)), 2.2);
	float edge = smoothstep(max(0.02, 0.32 - outline_width * 2.0), 1.0, rim);
	float alpha = clamp(fill_alpha + edge * 0.82, 0.0, 1.0);
	ALBEDO = outline_color.rgb;
	ALPHA = alpha * outline_color.a;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("outline_color", color)
	mat.set_shader_parameter("outline_width", thickness)
	mat.set_shader_parameter("fill_alpha", clampf(0.1 + thickness * 1.8, 0.12, 0.34))
	return mat

func _make_ghost_material(color: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded, depth_draw_never, depth_test_disabled;

uniform vec4 ghost_color : source_color = vec4(0.72, 0.96, 1.0, 0.72);

void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	float rim = pow(1.0 - abs(dot(n, v)), 1.8);
	vec3 rim_color = mix(ghost_color.rgb, vec3(1.0), rim * 0.58);
	ALBEDO = rim_color;
	ALPHA = clamp(ghost_color.a + rim * 0.22, 0.0, 1.0);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("ghost_color", color)
	return mat

func _create_ground_materials() -> void:
	var grass = StandardMaterial3D.new()
	grass.albedo_color = Color(0.24, 0.67, 0.22)
	grass.roughness = 0.97
	grass.metallic = 0.0
	grass_material = grass

	var road = StandardMaterial3D.new()
	road.albedo_color = Color(0.29, 0.31, 0.34)
	road.roughness = 0.98
	road.metallic = 0.0
	road_material = road

	var alley = StandardMaterial3D.new()
	alley.albedo_color = Color(0.35, 0.37, 0.4)
	alley.roughness = 0.97
	alley.metallic = 0.0
	alley_material = alley

	var sidewalk = StandardMaterial3D.new()
	sidewalk.albedo_color = Color(0.76, 0.77, 0.77)
	sidewalk.roughness = 0.94
	sidewalk.metallic = 0.0
	sidewalk_material = sidewalk

	var park_mat = StandardMaterial3D.new()
	park_mat.albedo_color = Color(0.32, 0.63, 0.31)
	park_mat.roughness = 0.88
	dog_park_material = park_mat

func _make_grass_material() -> Material:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 dark_color : source_color = vec3(0.13, 0.44, 0.12);
uniform vec3 mid_color : source_color = vec3(0.2, 0.6, 0.17);
uniform vec3 bright_color : source_color = vec3(0.34, 0.74, 0.25);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(11.3, 7.7);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 p = WORLD_POSITION.xz * 0.18;
	float n = fbm(p);
	float m = fbm(p * 2.6 + 13.2);
	vec3 c = mix(dark_color, mid_color, n);
	c = mix(c, bright_color, smoothstep(0.58, 0.9, m) * 0.6);
	ALBEDO = c;
	ROUGHNESS = 0.96;
	SPECULAR = 0.08;
}
"""
	var mat = ShaderMaterial.new()
	mat.shader = shader
	return mat

func _make_road_material(base_color: Color, patch_color: Color) -> Material:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color;
uniform vec3 patch_color : source_color;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(78.23, 29.13))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec2 p = WORLD_POSITION.xz * 0.42;
	float n = noise(p);
	float grit = noise(p * 3.1 + 17.4);
	vec3 c = mix(base_color, patch_color, smoothstep(0.45, 0.86, n));
	c += vec3(grit * 0.05 - 0.02);
	ALBEDO = c;
	ROUGHNESS = 0.98;
	SPECULAR = 0.04;
}
"""
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("base_color", base_color)
	mat.set_shader_parameter("patch_color", patch_color)
	return mat

func _generate_city_layout() -> void:
	roads.clear()
	sidewalks.clear()
	alleys.clear()
	alley_shoulders.clear()
	block_parcels.clear()

	for cx in [24.0, 48.0, 72.0, 96.0, 120.0]:
		_add_road(Rect2(cx - ROAD_W * 0.5, 0.0, ROAD_W, MAP_H))

	for cz in [20.0, 44.0, 68.0, 92.0]:
		_add_road(Rect2(0.0, cz - ROAD_W * 0.5, MAP_W, ROAD_W))

	var x_intervals = _compute_non_road_intervals(true)
	var z_intervals = _compute_non_road_intervals(false)
	var parcel_candidates: Array[Rect2] = []

	for xr in x_intervals:
		for zr in z_intervals:
			var parcel = Rect2(xr.x, zr.x, xr.y, zr.y)
			if parcel.size.x < 10.0 or parcel.size.y < 9.5:
				continue
			parcel_candidates.append(parcel)

	var map_center = Vector2(MAP_W * 0.5, MAP_H * 0.5)
	var park_parcel = Rect2(MAP_W * 0.5 - 8.0, MAP_H * 0.5 - 7.0, 16.0, 14.0)
	if not parcel_candidates.is_empty():
		parcel_candidates.sort_custom(func(a: Rect2, b: Rect2):
			var ac = a.position + a.size * 0.5
			var bc = b.position + b.size * 0.5
			return ac.distance_squared_to(map_center) < bc.distance_squared_to(map_center)
		)
		var pick_pool = mini(4, parcel_candidates.size())
		park_parcel = parcel_candidates[rng.randi_range(0, pick_pool - 1)]

	var park_size = Vector2(
		clampf(minf(16.4, park_parcel.size.x - 0.9), 9.6, 17.0),
		clampf(minf(13.9, park_parcel.size.y - 0.9), 8.8, 15.2)
	)
	var parcel_center = park_parcel.position + park_parcel.size * 0.5
	var center_pull = (map_center - parcel_center) * 0.14
	var jitter = Vector2(rng.randf_range(-0.45, 0.45), rng.randf_range(-0.34, 0.34))
	var park_origin = parcel_center - park_size * 0.5 + center_pull + jitter
	park_origin.x = clampf(park_origin.x, park_parcel.position.x + 0.28, park_parcel.position.x + park_parcel.size.x - park_size.x - 0.28)
	park_origin.y = clampf(park_origin.y, park_parcel.position.y + 0.28, park_parcel.position.y + park_parcel.size.y - park_size.y - 0.28)
	dog_park = Rect2(park_origin, park_size)

	for parcel in parcel_candidates:
		block_parcels.append(parcel)
		if parcel.intersects(dog_park.grow(0.4)):
			continue
		_add_block_alleys(parcel)

func _add_road(rect: Rect2) -> void:
	if not _rect_valid(rect):
		return
	roads.append(rect)
	_add_sidewalk_bands_for_street(rect)

func _add_sidewalk_bands_for_street(rect: Rect2) -> void:
	if rect.size.x > rect.size.y:
		var top = Rect2(rect.position.x, rect.position.y - SIDEWALK_W, rect.size.x, SIDEWALK_W)
		var bottom = Rect2(rect.position.x, rect.position.y + rect.size.y, rect.size.x, SIDEWALK_W)
		if _rect_valid(top):
			sidewalks.append(top)
		if _rect_valid(bottom):
			sidewalks.append(bottom)
	else:
		var left = Rect2(rect.position.x - SIDEWALK_W, rect.position.y, SIDEWALK_W, rect.size.y)
		var right = Rect2(rect.position.x + rect.size.x, rect.position.y, SIDEWALK_W, rect.size.y)
		if _rect_valid(left):
			sidewalks.append(left)
		if _rect_valid(right):
			sidewalks.append(right)

func _compute_non_road_intervals(along_x: bool) -> Array:
	var lane_rects: Array = []
	for r in roads:
		if along_x and r.size.x < r.size.y:
			lane_rects.append(r)
		elif (not along_x) and r.size.y < r.size.x:
			lane_rects.append(r)

	lane_rects.sort_custom(func(a, b):
		if along_x:
			return a.position.x < b.position.x
		return a.position.y < b.position.y
	)

	var intervals: Array = []
	var cursor = 0.0
	for lane in lane_rects:
		var start: float = lane.position.x if along_x else lane.position.y
		if start - cursor > 6.0:
			intervals.append(Vector2(cursor, start - cursor))
		cursor = start + (lane.size.x if along_x else lane.size.y)

	var max_len = MAP_W if along_x else MAP_H
	if max_len - cursor > 6.0:
		intervals.append(Vector2(cursor, max_len - cursor))
	return intervals

func _compute_row_alley_layout(parcel: Rect2) -> Dictionary:
	var alley_mid = parcel.position.y + parcel.size.y * 0.5
	var alley_z0 = alley_mid - ALLEY_W * 0.5
	var alley_z1 = alley_mid + ALLEY_W * 0.5
	var alley_gap = ALLEY_BUILDING_GAP
	var x0 = parcel.position.x + ROW_SIDE_SETBACK
	var x1 = parcel.position.x + parcel.size.x - ROW_SIDE_SETBACK
	var run_w = x1 - x0
	var north_front = parcel.position.y + ROW_FRONT_SETBACK
	var south_front = parcel.position.y + parcel.size.y - ROW_FRONT_SETBACK
	var north_depth = alley_z0 - north_front - alley_gap
	var south_depth = south_front - alley_z1 - alley_gap
	var valid = run_w >= 10.4 and north_depth >= 3.3 and south_depth >= 3.3
	return {
		"valid": valid,
		"alley_mid": alley_mid,
		"alley_z0": alley_z0,
		"alley_z1": alley_z1,
		"alley_gap": alley_gap,
		"x0": x0,
		"x1": x1,
		"run_w": run_w,
		"north_depth": north_depth,
		"south_depth": south_depth
	}

func _add_block_alleys(parcel: Rect2) -> void:
	var layout = _compute_row_alley_layout(parcel)
	if not bool(layout.get("valid", false)):
		return

	var mid_z = float(layout.get("alley_mid", parcel.position.y + parcel.size.y * 0.5))
	var main = Rect2(parcel.position.x + 0.35, mid_z - ALLEY_W * 0.5, parcel.size.x - 0.7, ALLEY_W)
	_add_alley(main)

	var connector_h = 1.2
	var connector_w = 0.95
	var left_connector = Rect2(parcel.position.x, mid_z - connector_h * 0.5, connector_w, connector_h)
	var right_connector = Rect2(parcel.position.x + parcel.size.x - connector_w, mid_z - connector_h * 0.5, connector_w, connector_h)
	_add_alley(left_connector)
	_add_alley(right_connector)

func _add_alley(rect: Rect2) -> void:
	if not _rect_valid(rect):
		return
	alleys.append(rect)
	var shoulder = 0.24
	if rect.size.x > rect.size.y:
		var top = Rect2(rect.position.x, rect.position.y - shoulder, rect.size.x, shoulder)
		var bottom = Rect2(rect.position.x, rect.position.y + rect.size.y, rect.size.x, shoulder)
		if _rect_valid(top):
			alley_shoulders.append(top)
		if _rect_valid(bottom):
			alley_shoulders.append(bottom)
	else:
		var left = Rect2(rect.position.x - shoulder, rect.position.y, shoulder, rect.size.y)
		var right = Rect2(rect.position.x + rect.size.x, rect.position.y, shoulder, rect.size.y)
		if _rect_valid(left):
			alley_shoulders.append(left)
		if _rect_valid(right):
			alley_shoulders.append(right)

func _rect_valid(rect: Rect2) -> bool:
	return rect.size.x > 0.05 and rect.size.y > 0.05

func _build_ground_meshes() -> void:
	var grass = MeshInstance3D.new()
	var grass_mesh = PlaneMesh.new()
	grass_mesh.size = Vector2(MAP_W, MAP_H)
	grass.mesh = grass_mesh
	grass.position = Vector3(MAP_W * 0.5, 0.0, MAP_H * 0.5)
	grass.material_override = grass_material
	static_root.add_child(grass)

	for s in sidewalks:
		_add_ground_rect(s, 0.01, sidewalk_material)

	for s in alley_shoulders:
		_add_ground_rect(s, 0.012, sidewalk_material)

	for r in roads:
		_add_ground_rect(r, 0.018, road_material)

	for a in alleys:
		_add_ground_rect(a, 0.02, alley_material)

func _add_ground_rect(rect: Rect2, y: float, material: Material) -> void:
	var m = MeshInstance3D.new()
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(rect.size.x, rect.size.y)
	m.mesh = mesh
	m.position = Vector3(rect.position.x + rect.size.x * 0.5, y, rect.position.y + rect.size.y * 0.5)
	m.material_override = material
	static_root.add_child(m)

func _build_dog_park() -> void:
	_add_ground_rect(dog_park, 0.03, dog_park_material)

	var fence_mat = StandardMaterial3D.new()
	fence_mat.albedo_color = Color8(134, 141, 136)
	fence_mat.roughness = 0.86

	var step = 1.4
	var x0 = dog_park.position.x
	var z0 = dog_park.position.y
	var x1 = dog_park.position.x + dog_park.size.x
	var z1 = dog_park.position.y + dog_park.size.y

	for x in range(int(floor(x0 * 10.0)), int(ceil(x1 * 10.0)), int(step * 10.0)):
		_add_fence_post(float(x) / 10.0, z0, fence_mat)
		_add_fence_post(float(x) / 10.0, z1, fence_mat)

	for z in range(int(floor(z0 * 10.0)), int(ceil(z1 * 10.0)), int(step * 10.0)):
		_add_fence_post(x0, float(z) / 10.0, fence_mat)
		_add_fence_post(x1, float(z) / 10.0, fence_mat)

	_add_fence_rail(Vector3((x0 + x1) * 0.5, 0.95, z0), Vector3(x1 - 0.6, 0.95, z0), fence_mat)
	_add_fence_rail(Vector3(x0 + 0.6, 0.95, z0), Vector3((x0 + x1) * 0.5 - 1.8, 0.95, z0), fence_mat)
	_add_fence_rail(Vector3(x0, 0.95, (z0 + z1) * 0.5), Vector3(x0, 0.95, z1), fence_mat)
	_add_fence_rail(Vector3(x1, 0.95, z0), Vector3(x1, 0.95, z1), fence_mat)
	_add_fence_rail(Vector3(x0, 0.95, z0), Vector3(x1, 0.95, z0), fence_mat)

func _add_fence_post(x: float, z: float, material: Material) -> void:
	var post = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.08, 1.1, 0.08)
	post.mesh = mesh
	post.position = Vector3(x, 0.55, z)
	post.material_override = material
	static_root.add_child(post)

func _add_fence_rail(a: Vector3, b: Vector3, material: Material) -> void:
	var rail = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	var len = a.distance_to(b)
	mesh.size = Vector3(0.06, 0.06, len)
	rail.mesh = mesh
	rail.position = (a + b) * 0.5
	static_root.add_child(rail)
	rail.look_at(b, Vector3.UP, true)
	rail.rotation_degrees.x = 90.0
	rail.material_override = material

func _build_city_buildings() -> void:
	buildings.clear()
	for parcel in block_parcels:
		if parcel.intersects(dog_park.grow(0.3)):
			continue

		var layout = _compute_row_alley_layout(parcel)
		if not bool(layout.get("valid", false)):
			continue

		var alley_z0 = float(layout["alley_z0"])
		var alley_z1 = float(layout["alley_z1"])
		var alley_gap = float(layout["alley_gap"])
		var x0 = float(layout["x0"])
		var run_w = float(layout["run_w"])
		var lot_count = max(2, int(floor(run_w / 8.6)))
		var lot_stride = run_w / float(maxi(1, lot_count))
		var north_depth = maxf(4.2, float(layout["north_depth"]))
		var south_depth = maxf(4.2, float(layout["south_depth"]))

		for i in range(lot_count):
			var bx = x0 + float(i) * lot_stride + 0.03
			var width = lot_stride - 0.06
			var by_n = alley_z0 - north_depth - alley_gap
			var by_s = alley_z1 + alley_gap
			_add_building(Rect2(bx, by_n, width, north_depth), 3, false)
			_add_building(Rect2(bx, by_s, width, south_depth), 3, true)

	if buildings.is_empty():
		# Fallback so the map never renders as an empty block-only scene.
		_add_building(Rect2(9.0, 8.0, 5.8, 4.9), 3, true)
		_add_building(Rect2(17.0, 8.2, 5.2, 4.5), 3, true)
		_add_building(Rect2(33.0, 27.0, 6.1, 5.0), 3, false)
		_add_building(Rect2(58.0, 50.0, 5.9, 4.8), 3, true)
	_rebuild_walkability_cache()

func _mark_store_buildings() -> void:
	_clear_store_entry_indicators()
	_clear_store_interiors()
	store_building_indices.clear()
	active_store_index = -1
	if buildings.is_empty():
		_rebuild_walkability_cache()
		return
	var candidates: Array[int] = []
	for i in range(buildings.size()):
		var b: Dictionary = buildings[i]
		b["is_store"] = false
		b["enterable"] = false
		b["store_food_slots"] = 0
		b["entry_pos"] = Vector2(-1.0, -1.0)
		b["store_walk_blockers"] = []
		b["store_interior_rect"] = Rect2()
		b["store_interior_root"] = null
		buildings[i] = b

		var fp: Rect2 = b["footprint"]
		if fp.size.x < 6.0 or fp.size.y < 4.4:
			continue
		var center_x = fp.position.x + fp.size.x * 0.5
		var front_is_south = bool(b.get("front_is_south", true))
		var dir = 1.0 if front_is_south else -1.0
		var front_z = fp.position.y + fp.size.y if front_is_south else fp.position.y
		var sidewalk_probe = Vector2(center_x, front_z + dir * (BUILDING_SIDEWALK_W * 0.45))
		var road_probe = Vector2(center_x, front_z + dir * (ROW_FRONT_SETBACK + ROAD_W * 0.3))
		if _surface_at(sidewalk_probe) != "sidewalk":
			continue
		if _surface_at(road_probe) != "road":
			continue
		candidates.append(i)

	# Fallback: if strict frontage checks fail on a generated block, still designate
	# obvious larger buildings as stores so the feature is always present.
	if candidates.is_empty():
		for i in range(buildings.size()):
			var b: Dictionary = buildings[i]
			var fp: Rect2 = b["footprint"]
			if fp.size.x >= 5.6 and fp.size.y >= 4.2:
				candidates.append(i)

	if candidates.is_empty():
		_rebuild_walkability_cache()
		_apply_store_focus_visuals()
		return

	var target_count = clampi(int(round(float(candidates.size()) * 0.28)), 4, 12)
	target_count = mini(target_count, candidates.size())
	for n in range(target_count):
		var pick = rng.randi_range(0, candidates.size() - 1)
		var idx = candidates[pick]
		candidates.remove_at(pick)
		var store: Dictionary = buildings[idx]
		store["is_store"] = true
		store["enterable"] = true
		var fp_store: Rect2 = store.get("footprint", Rect2())
		store["store_food_slots"] = clampi(int(round(fp_store.size.x * fp_store.size.y * 0.32)), 10, 26)
		_decorate_storefront(store)
		_create_store_entry_indicator(store)
		buildings[idx] = store
		store_building_indices.append(idx)
	_build_store_interiors()
	_rebuild_walkability_cache()
	_apply_store_focus_visuals()

func _decorate_storefront(building: Dictionary) -> void:
	var node: Node3D = building.get("node", null)
	if node == null or not is_instance_valid(node):
		return
	var fp: Rect2 = building.get("footprint", Rect2())
	var half_w = fp.size.x * 0.5
	var half_d = fp.size.y * 0.5
	var front_is_south = bool(building.get("front_is_south", true))
	var front_sign = 1.0 if front_is_south else -1.0
	var front_local_z = half_d if front_is_south else -half_d

	var sign_mat = StandardMaterial3D.new()
	sign_mat.albedo_color = Color8(238, 213, 109)
	sign_mat.roughness = 0.28
	sign_mat.metallic = 0.08
	sign_mat.emission_enabled = true
	sign_mat.emission = Color(0.5, 0.44, 0.18)
	sign_mat.emission_energy_multiplier = 0.62

	var sign = MeshInstance3D.new()
	var sign_mesh = BoxMesh.new()
	sign_mesh.size = Vector3(clampf(fp.size.x * 0.5, 2.0, 3.8), 0.42, 0.08)
	sign.mesh = sign_mesh
	sign.position = Vector3(0.0, 2.2, front_local_z + front_sign * 0.07)
	sign.material_override = sign_mat
	node.add_child(sign)

	var awning = MeshInstance3D.new()
	var awning_mesh = BoxMesh.new()
	awning_mesh.size = Vector3(clampf(fp.size.x * 0.56, 2.2, 4.2), 0.07, 0.58)
	awning.mesh = awning_mesh
	awning.position = Vector3(0.0, 1.62, front_local_z + front_sign * 0.31)
	awning.material_override = pole_base_material
	node.add_child(awning)

func _clear_store_entry_indicators() -> void:
	for item in store_entry_indicators:
		var n: Node3D = item.get("node", null)
		if n != null and is_instance_valid(n):
			n.queue_free()
	store_entry_indicators.clear()

func _clear_store_interiors() -> void:
	for n in store_interior_nodes:
		if n != null and is_instance_valid(n):
			n.queue_free()
	store_interior_nodes.clear()
	store_walk_blockers.clear()
	for i in range(buildings.size()):
		var b: Dictionary = buildings[i]
		b["store_walk_blockers"] = []
		b["store_interior_rect"] = Rect2()
		b["store_interior_root"] = null
		buildings[i] = b

func _add_store_wall_box(parent: Node3D, wall_rect: Rect2, material: Material, height: float = STORE_INTERIOR_WALL_HEIGHT) -> void:
	if wall_rect.size.x <= 0.03 or wall_rect.size.y <= 0.03:
		return
	var wall = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(wall_rect.size.x, height, wall_rect.size.y)
	wall.mesh = mesh
	wall.position = Vector3(
		wall_rect.position.x + wall_rect.size.x * 0.5,
		height * 0.5,
		wall_rect.position.y + wall_rect.size.y * 0.5
	)
	wall.material_override = material
	parent.add_child(wall)

func _add_store_stand(
	parent: Node3D,
	fixture_rect: Rect2,
	frame_material: Material,
	top_material: Material,
	top_y: float = 1.0
) -> void:
	if fixture_rect.size.x < 0.16 or fixture_rect.size.y < 0.16:
		return
	var center = Vector3(
		fixture_rect.position.x + fixture_rect.size.x * 0.5,
		0.0,
		fixture_rect.position.y + fixture_rect.size.y * 0.5
	)

	var top = MeshInstance3D.new()
	var top_mesh = BoxMesh.new()
	top_mesh.size = Vector3(fixture_rect.size.x, 0.08, fixture_rect.size.y)
	top.mesh = top_mesh
	top.position = center + Vector3(0.0, top_y, 0.0)
	top.material_override = top_material
	parent.add_child(top)

	var shelf = MeshInstance3D.new()
	var shelf_mesh = BoxMesh.new()
	shelf_mesh.size = Vector3(maxf(0.08, fixture_rect.size.x - 0.08), 0.06, maxf(0.08, fixture_rect.size.y - 0.08))
	shelf.mesh = shelf_mesh
	shelf.position = center + Vector3(0.0, top_y * 0.56, 0.0)
	shelf.material_override = frame_material
	parent.add_child(shelf)

	var leg_h = maxf(0.26, top_y - 0.06)
	for dx in [-1.0, 1.0]:
		for dz in [-1.0, 1.0]:
			var leg = MeshInstance3D.new()
			var leg_mesh = BoxMesh.new()
			leg_mesh.size = Vector3(0.06, leg_h, 0.06)
			leg.mesh = leg_mesh
			leg.position = Vector3(
				center.x + dx * (fixture_rect.size.x * 0.5 - 0.05),
				leg_h * 0.5,
				center.z + dz * (fixture_rect.size.y * 0.5 - 0.05)
			)
			leg.material_override = frame_material
			parent.add_child(leg)

func _add_store_wall_band(
	parent: Node3D,
	wall_rect: Rect2,
	material: Material,
	y: float,
	band_h: float = 0.07
) -> void:
	if wall_rect.size.x <= 0.03 or wall_rect.size.y <= 0.03:
		return
	var band = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(wall_rect.size.x, band_h, wall_rect.size.y)
	band.mesh = mesh
	band.position = Vector3(
		wall_rect.position.x + wall_rect.size.x * 0.5,
		y,
		wall_rect.position.y + wall_rect.size.y * 0.5
	)
	band.material_override = material
	parent.add_child(band)

func _add_bodega_stock_to_fixture(
	parent: Node3D,
	fixture_rect: Rect2,
	top_y: float,
	materials: Array,
	slab_mode: bool = false
) -> void:
	if fixture_rect.size.x < 0.1 or fixture_rect.size.y < 0.1:
		return
	if materials.is_empty():
		return
	var area = fixture_rect.size.x * fixture_rect.size.y
	var count = clampi(int(round(area * 15.0)), 5, 30)
	for i in range(count):
		var item = MeshInstance3D.new()
		if slab_mode and i % 4 == 0:
			var slab = BoxMesh.new()
			slab.size = Vector3(
				rng.randf_range(0.07, 0.13),
				rng.randf_range(0.03, 0.055),
				rng.randf_range(0.08, 0.14)
			)
			item.mesh = slab
		else:
			var produce = SphereMesh.new()
			produce.radius = rng.randf_range(0.024, 0.056)
			produce.height = produce.radius * 2.0
			item.mesh = produce
			item.scale = Vector3(
				rng.randf_range(0.8, 1.2),
				rng.randf_range(0.7, 1.16),
				rng.randf_range(0.8, 1.2)
			)
		item.material_override = materials[rng.randi_range(0, materials.size() - 1)]
		item.position = Vector3(
			rng.randf_range(fixture_rect.position.x + 0.05, fixture_rect.position.x + fixture_rect.size.x - 0.05),
			top_y + rng.randf_range(0.01, 0.06),
			rng.randf_range(fixture_rect.position.y + 0.05, fixture_rect.position.y + fixture_rect.size.y - 0.05)
		)
		parent.add_child(item)

func _build_store_interiors() -> void:
	_clear_store_interiors()
	if store_building_indices.is_empty():
		return

	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color8(206, 206, 198)
	floor_mat.roughness = 0.92
	floor_mat.metallic = 0.0

	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color8(228, 223, 214)
	wall_mat.roughness = 0.88
	wall_mat.metallic = 0.02
	wall_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var wall_trim_mat = StandardMaterial3D.new()
	wall_trim_mat.albedo_color = Color8(176, 162, 145)
	wall_trim_mat.roughness = 0.82
	wall_trim_mat.metallic = 0.01

	var wall_band_mat = StandardMaterial3D.new()
	wall_band_mat.albedo_color = Color8(190, 176, 158)
	wall_band_mat.roughness = 0.78
	wall_band_mat.metallic = 0.0

	var poster_mat = StandardMaterial3D.new()
	poster_mat.albedo_color = Color8(223, 205, 166)
	poster_mat.roughness = 0.52
	poster_mat.metallic = 0.0

	var shelf_mat = StandardMaterial3D.new()
	shelf_mat.albedo_color = Color8(169, 145, 118)
	shelf_mat.roughness = 0.84
	shelf_mat.metallic = 0.0

	var ceiling_mat = StandardMaterial3D.new()
	ceiling_mat.albedo_color = Color8(230, 229, 224)
	ceiling_mat.roughness = 0.92
	ceiling_mat.metallic = 0.0

	var light_mat = StandardMaterial3D.new()
	light_mat.albedo_color = Color8(244, 234, 202)
	light_mat.roughness = 0.22
	light_mat.emission_enabled = true
	light_mat.emission = Color(1.0, 0.93, 0.74)
	light_mat.emission_energy_multiplier = 1.1

	var fridge_mat = StandardMaterial3D.new()
	fridge_mat.albedo_color = Color8(172, 179, 186)
	fridge_mat.roughness = 0.55
	fridge_mat.metallic = 0.18

	var produce_mats: Array = []
	for c in [
		Color8(201, 53, 47),
		Color8(236, 144, 43),
		Color8(219, 191, 65),
		Color8(121, 172, 62),
		Color8(78, 147, 66),
		Color8(164, 105, 61)
	]:
		var m = StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.76
		m.metallic = 0.0
		produce_mats.append(m)

	var meat_mats: Array = []
	for c in [Color8(161, 66, 61), Color8(188, 84, 74), Color8(145, 54, 58)]:
		var m = StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.64
		m.metallic = 0.03
		meat_mats.append(m)

	for idx in store_building_indices:
		if idx < 0 or idx >= buildings.size():
			continue
		var b: Dictionary = buildings[idx]
		var fp: Rect2 = b.get("footprint", Rect2())
		var x0 = fp.position.x + STORE_INTERIOR_MARGIN
		var x1 = fp.position.x + fp.size.x - STORE_INTERIOR_MARGIN
		var z0 = fp.position.y + STORE_INTERIOR_MARGIN
		var z1 = fp.position.y + fp.size.y - STORE_INTERIOR_MARGIN
		var inner_w = x1 - x0
		var inner_d = z1 - z0
		if inner_w < 2.2 or inner_d < 2.2:
			continue

		var interior_root = Node3D.new()
		interior_root.name = "StoreInterior"
		interior_root.visible = false
		static_root.add_child(interior_root)
		store_interior_nodes.append(interior_root)

		var floor = MeshInstance3D.new()
		var floor_mesh = PlaneMesh.new()
		floor_mesh.size = Vector2(inner_w, inner_d)
		floor.mesh = floor_mesh
		floor.position = Vector3(x0 + inner_w * 0.5, 0.032, z0 + inner_d * 0.5)
		floor.material_override = floor_mat
		interior_root.add_child(floor)

		var ceiling = MeshInstance3D.new()
		var ceiling_mesh = BoxMesh.new()
		ceiling_mesh.size = Vector3(inner_w, 0.05, inner_d)
		ceiling.mesh = ceiling_mesh
		ceiling.position = Vector3(x0 + inner_w * 0.5, STORE_INTERIOR_WALL_HEIGHT + 0.02, z0 + inner_d * 0.5)
		ceiling.material_override = ceiling_mat
		interior_root.add_child(ceiling)

		var light_count = clampi(int(round(inner_w / 2.3)), 2, 4)
		for li in range(light_count):
			var t = (float(li) + 0.5) / float(light_count)
			var bulb = MeshInstance3D.new()
			var bulb_mesh = SphereMesh.new()
			bulb_mesh.radius = 0.08
			bulb_mesh.height = 0.16
			bulb.mesh = bulb_mesh
			bulb.position = Vector3(lerpf(x0 + 0.8, x1 - 0.8, t), STORE_INTERIOR_WALL_HEIGHT - 0.26, z0 + inner_d * 0.5)
			bulb.material_override = light_mat
			interior_root.add_child(bulb)

		var wall_t = STORE_WALL_THICKNESS
		var door_half = minf(STORE_DOOR_HALF_WIDTH, inner_w * 0.24)
		var center_x = x0 + inner_w * 0.5
		var front_is_south = bool(b.get("front_is_south", true))
		var blockers: Array[Rect2] = []
		var wall_visuals: Array[Rect2] = []
		var produce_fixtures: Array[Rect2] = []
		var meat_fixtures: Array[Rect2] = []

		var left_wall = Rect2(x0, z0, wall_t, inner_d)
		var right_wall = Rect2(x1 - wall_t, z0, wall_t, inner_d)
		blockers.append(left_wall)
		blockers.append(right_wall)
		wall_visuals.append(left_wall)
		wall_visuals.append(right_wall)

		if front_is_south:
			var back_wall = Rect2(x0, z0, inner_w, wall_t)
			blockers.append(back_wall)
			wall_visuals.append(back_wall)
			var front_left_w = maxf(0.0, center_x - door_half - x0)
			var front_right_x = center_x + door_half
			var front_right_w = maxf(0.0, x1 - front_right_x)
			if front_left_w > 0.05:
				var front_left_wall = Rect2(x0, z1 - wall_t, front_left_w, wall_t)
				blockers.append(front_left_wall)
				wall_visuals.append(front_left_wall)
			if front_right_w > 0.05:
				var front_right_wall = Rect2(front_right_x, z1 - wall_t, front_right_w, wall_t)
				blockers.append(front_right_wall)
				wall_visuals.append(front_right_wall)
			var jamb_d = maxf(0.14, STORE_DOOR_DEPTH - wall_t)
			var jamb_l = Rect2(center_x - door_half - wall_t * 0.5, z1 - STORE_DOOR_DEPTH, wall_t, jamb_d)
			var jamb_r = Rect2(center_x + door_half - wall_t * 0.5, z1 - STORE_DOOR_DEPTH, wall_t, jamb_d)
			wall_visuals.append(jamb_l)
			wall_visuals.append(jamb_r)
		else:
			var back_wall_north = Rect2(x0, z1 - wall_t, inner_w, wall_t)
			blockers.append(back_wall_north)
			wall_visuals.append(back_wall_north)
			var front_left_w_n = maxf(0.0, center_x - door_half - x0)
			var front_right_x_n = center_x + door_half
			var front_right_w_n = maxf(0.0, x1 - front_right_x_n)
			if front_left_w_n > 0.05:
				var front_left_wall_n = Rect2(x0, z0, front_left_w_n, wall_t)
				blockers.append(front_left_wall_n)
				wall_visuals.append(front_left_wall_n)
			if front_right_w_n > 0.05:
				var front_right_wall_n = Rect2(front_right_x_n, z0, front_right_w_n, wall_t)
				blockers.append(front_right_wall_n)
				wall_visuals.append(front_right_wall_n)
			var jamb_d_n = maxf(0.14, STORE_DOOR_DEPTH - wall_t)
			var jamb_n_l = Rect2(center_x - door_half - wall_t * 0.5, z0 + wall_t, wall_t, jamb_d_n)
			var jamb_n_r = Rect2(center_x + door_half - wall_t * 0.5, z0 + wall_t, wall_t, jamb_d_n)
			wall_visuals.append(jamb_n_l)
			wall_visuals.append(jamb_n_r)

		if inner_d > 3.2:
			var side_depth = inner_d - 1.9
			var fixture_l = Rect2(x0 + wall_t + 0.16, z0 + 0.92, 0.5, side_depth)
			var fixture_r = Rect2(x1 - wall_t - 0.66, z0 + 0.92, 0.5, side_depth)
			if fixture_l.size.y > 1.0:
				blockers.append(fixture_l)
				produce_fixtures.append(fixture_l)
			if fixture_r.size.y > 1.0:
				blockers.append(fixture_r)
				produce_fixtures.append(fixture_r)

		if inner_w > 6.2 and inner_d > 4.0:
			var aisle_depth = clampf(inner_d * 0.44, 1.9, inner_d - 1.2)
			var aisle_z = z0 + (inner_d - aisle_depth) * 0.5
			var aisle_a = Rect2(x0 + inner_w * 0.33 - 0.18, aisle_z, 0.36, aisle_depth)
			var aisle_b = Rect2(x0 + inner_w * 0.67 - 0.18, aisle_z, 0.36, aisle_depth)
			blockers.append(aisle_a)
			blockers.append(aisle_b)
			produce_fixtures.append(aisle_a)
			produce_fixtures.append(aisle_b)

		var meat_counter_w = clampf(inner_w * 0.46, 1.3, inner_w - 1.1)
		var meat_counter_x = x0 + (inner_w - meat_counter_w) * 0.5
		var meat_counter = Rect2(
			meat_counter_x,
			(z0 + wall_t + 0.26) if front_is_south else (z1 - wall_t - 0.74),
			meat_counter_w,
			0.48
		)
		blockers.append(meat_counter)
		meat_fixtures.append(meat_counter)

		if inner_w > 4.2 and inner_d > 3.4:
			var island_w = clampf(inner_w * 0.24, 0.82, 1.5)
			var island_d = clampf(inner_d * 0.2, 0.88, 1.6)
			var island = Rect2(
				x0 + inner_w * 0.5 - island_w * 0.5,
				z0 + inner_d * 0.54 - island_d * 0.5,
				island_w,
				island_d
			)
			blockers.append(island)
			produce_fixtures.append(island)

		if inner_w > 7.2 and inner_d > 4.2:
			var island2_w = clampf(inner_w * 0.2, 0.76, 1.3)
			var island2_d = clampf(inner_d * 0.16, 0.82, 1.28)
			var island2 = Rect2(
				x0 + inner_w * 0.28 - island2_w * 0.5,
				z0 + inner_d * 0.46 - island2_d * 0.5,
				island2_w,
				island2_d
			)
			blockers.append(island2)
			produce_fixtures.append(island2)

		for wall_rect in wall_visuals:
			_add_store_wall_box(interior_root, wall_rect, wall_mat, STORE_INTERIOR_WALL_HEIGHT)
			var trim_rect = wall_rect.grow(-0.02)
			if trim_rect.size.x > 0.03 and trim_rect.size.y > 0.03:
				_add_store_wall_box(interior_root, trim_rect, wall_trim_mat, 0.11)
			_add_store_wall_band(interior_root, wall_rect, wall_band_mat, 0.58, 0.08)
			_add_store_wall_band(interior_root, wall_rect, wall_trim_mat, 1.74, 0.06)

		var poster_count = clampi(int(round(inner_w / 2.8)), 1, 3)
		for pi in range(poster_count):
			var poster = MeshInstance3D.new()
			var poster_mesh = BoxMesh.new()
			poster_mesh.size = Vector3(0.52, 0.66, 0.02)
			poster.mesh = poster_mesh
			var t = (float(pi) + 0.5) / float(poster_count)
			var poster_x = lerpf(x0 + 0.75, x1 - 0.75, t)
			var poster_z = z0 + wall_t * 0.45 if front_is_south else z1 - wall_t * 0.45
			poster.position = Vector3(poster_x, 1.42, poster_z)
			poster.material_override = poster_mat
			interior_root.add_child(poster)

		for fixture in produce_fixtures:
			_add_store_stand(interior_root, fixture, shelf_mat, wall_trim_mat, 1.02)
			_add_bodega_stock_to_fixture(interior_root, fixture.grow(-0.02), 1.06, produce_mats, false)

		for fixture in meat_fixtures:
			_add_store_stand(interior_root, fixture, shelf_mat, wall_trim_mat, 0.88)
			_add_bodega_stock_to_fixture(interior_root, fixture.grow(-0.02), 0.92, meat_mats, true)

		var fridge_count = clampi(int(round(inner_w / 3.2)), 1, 3)
		for fi in range(fridge_count):
			var t = (float(fi) + 0.5) / float(fridge_count)
			var fridge = MeshInstance3D.new()
			var fridge_mesh = BoxMesh.new()
			fridge_mesh.size = Vector3(0.46, 1.85, 0.34)
			fridge.mesh = fridge_mesh
			fridge.position = Vector3(lerpf(x0 + 0.85, x1 - 0.85, t), 0.93, z0 + 0.54 if front_is_south else z1 - 0.54)
			fridge.material_override = fridge_mat
			interior_root.add_child(fridge)

		b["store_walk_blockers"] = blockers
		b["store_interior_rect"] = Rect2(x0 + wall_t, z0 + wall_t, inner_w - wall_t * 2.0, inner_d - wall_t * 2.0)
		b["store_interior_root"] = interior_root
		buildings[idx] = b

func _rebuild_walkability_cache() -> void:
	blocking_building_rects.clear()
	store_walk_blockers.clear()
	for b in buildings:
		var rect: Rect2 = b.get("collision_rect", b["footprint"])
		if not bool(b.get("enterable", false)):
			blocking_building_rects.append(rect)
		var blockers = b.get("store_walk_blockers", [])
		if blockers is Array:
			for wall in blockers:
				if wall is Rect2:
					store_walk_blockers.append(wall)

func _create_store_entry_indicator(building: Dictionary) -> void:
	var node: Node3D = building.get("node", null)
	if node == null or not is_instance_valid(node):
		return
	var fp: Rect2 = building.get("footprint", Rect2())
	if fp.size.x <= 0.0 or fp.size.y <= 0.0:
		return

	var front_is_south = bool(building.get("front_is_south", true))
	var front_sign = 1.0 if front_is_south else -1.0
	var half_d = fp.size.y * 0.5
	var front_local_z = half_d if front_is_south else -half_d

	var marker = Node3D.new()
	marker.name = "StoreEntryArrow"
	var base_local = Vector3(0.0, 0.26, front_local_z + front_sign * 0.66)
	marker.position = base_local
	node.add_child(marker)

	var border_mat = StandardMaterial3D.new()
	border_mat.albedo_color = Color(0.01, 0.01, 0.01, 0.97)
	border_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	border_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	border_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	border_mat.no_depth_test = true

	var arrow_mat = StandardMaterial3D.new()
	arrow_mat.albedo_color = Color(1.0, 0.31, 0.06, 0.99)
	arrow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arrow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arrow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	arrow_mat.no_depth_test = true
	arrow_mat.emission_enabled = true
	arrow_mat.emission = Color(1.0, 0.44, 0.05)
	arrow_mat.emission_energy_multiplier = 2.12

	var core_mat = StandardMaterial3D.new()
	core_mat.albedo_color = Color(1.0, 0.97, 0.38, 0.98)
	core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	core_mat.no_depth_test = true
	core_mat.emission_enabled = true
	core_mat.emission = Color(1.0, 0.95, 0.4)
	core_mat.emission_energy_multiplier = 1.25

	var backplate = MeshInstance3D.new()
	var backplate_mesh = BoxMesh.new()
	backplate_mesh.size = Vector3(0.38, 0.075, 0.74)
	backplate.mesh = backplate_mesh
	backplate.position = Vector3(0.0, -0.015, -front_sign * 0.1)
	backplate.material_override = border_mat
	marker.add_child(backplate)

	var stem_border = MeshInstance3D.new()
	var stem_border_mesh = BoxMesh.new()
	stem_border_mesh.size = Vector3(0.14, 0.055, 0.34)
	stem_border.mesh = stem_border_mesh
	stem_border.position = Vector3(0.0, 0.0, front_sign * 0.09)
	stem_border.material_override = border_mat
	marker.add_child(stem_border)

	var shaft = MeshInstance3D.new()
	var shaft_mesh = BoxMesh.new()
	shaft_mesh.size = Vector3(0.09, 0.045, 0.29)
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0.0, 0.008, front_sign * 0.1)
	shaft.material_override = arrow_mat
	marker.add_child(shaft)

	var head_border = MeshInstance3D.new()
	var head_border_mesh = BoxMesh.new()
	head_border_mesh.size = Vector3(0.2, 0.055, 0.18)
	head_border.mesh = head_border_mesh
	head_border.position = Vector3(0.0, 0.0, -front_sign * 0.17)
	head_border.material_override = border_mat
	marker.add_child(head_border)

	var head = MeshInstance3D.new()
	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(0.15, 0.045, 0.14)
	head.mesh = head_mesh
	head.position = Vector3(0.0, 0.008, -front_sign * 0.17)
	head.material_override = arrow_mat
	marker.add_child(head)

	for side in [-1.0, 1.0]:
		var wing_border = MeshInstance3D.new()
		var wing_border_mesh = BoxMesh.new()
		wing_border_mesh.size = Vector3(0.13, 0.055, 0.29)
		wing_border.mesh = wing_border_mesh
		wing_border.position = Vector3(side * 0.101, 0.0, -front_sign * 0.255)
		wing_border.rotation_degrees.y = side * 50.0
		wing_border.material_override = border_mat
		marker.add_child(wing_border)

		var wing = MeshInstance3D.new()
		var wing_mesh = BoxMesh.new()
		wing_mesh.size = Vector3(0.087, 0.045, 0.24)
		wing.mesh = wing_mesh
		wing.position = Vector3(side * 0.094, 0.008, -front_sign * 0.255)
		wing.rotation_degrees.y = side * 50.0
		wing.material_override = arrow_mat
		marker.add_child(wing)

	var core = MeshInstance3D.new()
	var core_mesh = BoxMesh.new()
	core_mesh.size = Vector3(0.04, 0.035, 0.2)
	core.mesh = core_mesh
	core.position = Vector3(0.0, 0.012, -front_sign * 0.06)
	core.material_override = core_mat
	marker.add_child(core)

	var entry_center = Vector2(fp.position.x + fp.size.x * 0.5, fp.position.y + (fp.size.y if front_is_south else 0.0))
	var entry_dir = Vector2(0.0, -front_sign)
	building["entry_pos"] = entry_center + entry_dir * 0.45
	store_entry_indicators.append({
		"node": marker,
		"base": base_local,
		"front_sign": front_sign,
		"phase": rng.randf_range(0.0, TAU)
	})

func _populate_store_foods() -> void:
	for item in store_foods:
		var n: Node3D = item.get("node", null)
		if n != null and is_instance_valid(n):
			n.queue_free()
	store_foods.clear()

	for b in buildings:
		if not bool(b.get("is_store", false)):
			continue
		var count = int(b.get("store_food_slots", 3))
		for i in range(count):
			_spawn_store_food_in_building(b)

func _spawn_store_food_in_building(building: Dictionary) -> bool:
	var fp: Rect2 = building.get("footprint", Rect2())
	if fp.size.x < 1.6 or fp.size.y < 1.6:
		return false
	var interior_rect: Rect2 = building.get("store_interior_rect", fp.grow(-0.42))
	if interior_rect.size.x < 0.8 or interior_rect.size.y < 0.8:
		interior_rect = fp.grow(-0.42)
	for attempt in range(24):
		var p = Vector2(
			rng.randf_range(interior_rect.position.x, interior_rect.position.x + interior_rect.size.x),
			rng.randf_range(interior_rect.position.y, interior_rect.position.y + interior_rect.size.y)
		)
		if not _is_walkable(p.x, p.y, 0.12):
			continue
		var too_close = false
		for f in store_foods:
			var existing: Vector2 = f.get("pos", Vector2.ZERO)
			if existing.distance_to(p) < 0.62:
				too_close = true
				break
		if too_close:
			continue
		var node = _create_store_food_node()
		node.position = Vector3(p.x, 0.04, p.y)
		dynamic_root.add_child(node)
		store_foods.append({"node": node, "pos": p})
		return true
	return false

func _create_store_food_node() -> Node3D:
	var root = Node3D.new()
	root.name = "StoreFood"

	var tray_mat = StandardMaterial3D.new()
	tray_mat.albedo_color = Color8(186, 166, 138)
	tray_mat.roughness = 0.82
	tray_mat.metallic = 0.02

	var tray = MeshInstance3D.new()
	var tray_mesh = BoxMesh.new()
	tray_mesh.size = Vector3(0.26, 0.04, 0.2)
	tray.mesh = tray_mesh
	tray.position = Vector3(0.0, 0.02, 0.0)
	tray.material_override = tray_mat
	root.add_child(tray)

	var style = rng.randi_range(0, 2)
	if style == 2:
		var meat_mat = StandardMaterial3D.new()
		meat_mat.albedo_color = Color8(173, 72, 68)
		meat_mat.roughness = 0.63
		meat_mat.metallic = 0.02
		var slab_count = rng.randi_range(2, 4)
		for i in range(slab_count):
			var slab = MeshInstance3D.new()
			var slab_mesh = BoxMesh.new()
			slab_mesh.size = Vector3(
				rng.randf_range(0.06, 0.11),
				rng.randf_range(0.028, 0.05),
				rng.randf_range(0.07, 0.11)
			)
			slab.mesh = slab_mesh
			slab.material_override = meat_mat
			slab.position = Vector3(
				rng.randf_range(-0.08, 0.08),
				0.055 + rng.randf_range(0.0, 0.018),
				rng.randf_range(-0.055, 0.055)
			)
			root.add_child(slab)
	else:
		var produce_count = rng.randi_range(3, 6)
		for i in range(produce_count):
			var produce = MeshInstance3D.new()
			var produce_mesh = SphereMesh.new()
			produce_mesh.radius = rng.randf_range(0.03, 0.052)
			produce_mesh.height = produce_mesh.radius * 2.0
			produce.mesh = produce_mesh
			produce.scale = Vector3(
				rng.randf_range(0.82, 1.18),
				rng.randf_range(0.74, 1.15),
				rng.randf_range(0.82, 1.18)
			)
			if store_food_materials.is_empty():
				produce.material_override = poop_material
			else:
				produce.material_override = store_food_materials[rng.randi_range(0, store_food_materials.size() - 1)]
			produce.position = Vector3(
				rng.randf_range(-0.085, 0.085),
				0.06 + rng.randf_range(0.0, 0.026),
				rng.randf_range(-0.06, 0.06)
			)
			root.add_child(produce)
	return root

func _clip_rect_to_map(rect: Rect2) -> Rect2:
	var map_rect = Rect2(0.0, 0.0, MAP_W, MAP_H)
	return rect.intersection(map_rect)

func _append_building_sidewalk_patch(rect: Rect2) -> void:
	var clipped = _clip_rect_to_map(rect)
	if not _rect_valid(clipped):
		return
	sidewalks.append(clipped)
	_add_ground_rect(clipped, 0.013, sidewalk_material)

func _add_building_sidewalks() -> void:
	for b in buildings:
		var fp: Rect2 = b["footprint"]
		var w = BUILDING_SIDEWALK_W
		_append_building_sidewalk_patch(Rect2(fp.position.x - w, fp.position.y - w, fp.size.x + w * 2.0, w))
		_append_building_sidewalk_patch(Rect2(fp.position.x - w, fp.position.y + fp.size.y, fp.size.x + w * 2.0, w))
		_append_building_sidewalk_patch(Rect2(fp.position.x - w, fp.position.y, w, fp.size.y))
		_append_building_sidewalk_patch(Rect2(fp.position.x + fp.size.x, fp.position.y, w, fp.size.y))

func _spawn_street_poles() -> void:
	for item in street_poles:
		var node: Node3D = item.get("node", null)
		if node != null and is_instance_valid(node):
			node.queue_free()
	street_poles.clear()

	var placed_points: Array = []
	for r in roads:
		if r.size.x > r.size.y:
			var lane_center = r.position.y + r.size.y * 0.5
			var side_coords = [
				r.position.y - SIDEWALK_W * 0.5,
				r.position.y + r.size.y + SIDEWALK_W * 0.5
			]
			var x = r.position.x + STREET_POLE_END_MARGIN
			var x_end = r.position.x + r.size.x - STREET_POLE_END_MARGIN
			while x <= x_end + 0.001:
				for side_z in side_coords:
					var p = Vector2(
						x + rng.randf_range(-0.2, 0.2),
						float(side_z) + rng.randf_range(-0.06, 0.06)
					)
					if not _street_pole_candidate_ok(p, placed_points):
						continue
					var pole = _create_street_pole_node()
					pole.position = Vector3(p.x, 0.0, p.y)
					if p.y > lane_center:
						pole.rotation.y = PI
					static_root.add_child(pole)
					placed_points.append(p)
					street_poles.append({
						"node": pole,
						"pos": p,
						"radius": STREET_POLE_COLLISION_RADIUS,
						"claimed": false,
						"claim_progress": 0.0,
						"claim_ring": null
					})
				x += STREET_POLE_SPACING
		else:
			var lane_center = r.position.x + r.size.x * 0.5
			var side_coords = [
				r.position.x - SIDEWALK_W * 0.5,
				r.position.x + r.size.x + SIDEWALK_W * 0.5
			]
			var z = r.position.y + STREET_POLE_END_MARGIN
			var z_end = r.position.y + r.size.y - STREET_POLE_END_MARGIN
			while z <= z_end + 0.001:
				for side_x in side_coords:
					var p = Vector2(
						float(side_x) + rng.randf_range(-0.06, 0.06),
						z + rng.randf_range(-0.2, 0.2)
					)
					if not _street_pole_candidate_ok(p, placed_points):
						continue
					var pole = _create_street_pole_node()
					pole.position = Vector3(p.x, 0.0, p.y)
					pole.rotation.y = PI * 0.5 if p.x < lane_center else -PI * 0.5
					static_root.add_child(pole)
					placed_points.append(p)
					street_poles.append({
						"node": pole,
						"pos": p,
						"radius": STREET_POLE_COLLISION_RADIUS,
						"claimed": false,
						"claim_progress": 0.0,
						"claim_ring": null
					})
				z += STREET_POLE_SPACING

func _spawn_fire_hydrants() -> void:
	for item in fire_hydrants:
		var node: Node3D = item.get("node", null)
		if node != null and is_instance_valid(node):
			node.queue_free()
	fire_hydrants.clear()

	var placed_points: Array[Vector2] = []
	for r in roads:
		if r.size.x > r.size.y:
			var side_coords = [
				r.position.y - SIDEWALK_W * 0.34,
				r.position.y + r.size.y + SIDEWALK_W * 0.34
			]
			var x = r.position.x + STREET_POLE_END_MARGIN + 1.2
			var x_end = r.position.x + r.size.x - STREET_POLE_END_MARGIN - 1.2
			while x <= x_end + 0.001:
				if rng.randf() < 0.58:
					for side_z in side_coords:
						var p = Vector2(
							x + rng.randf_range(-0.22, 0.22),
							float(side_z) + rng.randf_range(-0.08, 0.08)
						)
						if not _fire_hydrant_candidate_ok(p, placed_points):
							continue
						var hydrant = _create_fire_hydrant_node()
						hydrant.position = Vector3(p.x, 0.0, p.y)
						static_root.add_child(hydrant)
						placed_points.append(p)
						fire_hydrants.append({
							"node": hydrant,
							"pos": p,
							"radius": FIRE_HYDRANT_COLLISION_RADIUS,
							"claimed": false,
							"claim_progress": 0.0,
							"claim_ring": null
						})
				x += FIRE_HYDRANT_SPACING
		else:
			var side_coords = [
				r.position.x - SIDEWALK_W * 0.34,
				r.position.x + r.size.x + SIDEWALK_W * 0.34
			]
			var z = r.position.y + STREET_POLE_END_MARGIN + 1.2
			var z_end = r.position.y + r.size.y - STREET_POLE_END_MARGIN - 1.2
			while z <= z_end + 0.001:
				if rng.randf() < 0.58:
					for side_x in side_coords:
						var p = Vector2(
							float(side_x) + rng.randf_range(-0.08, 0.08),
							z + rng.randf_range(-0.22, 0.22)
						)
						if not _fire_hydrant_candidate_ok(p, placed_points):
							continue
						var hydrant = _create_fire_hydrant_node()
						hydrant.position = Vector3(p.x, 0.0, p.y)
						static_root.add_child(hydrant)
						placed_points.append(p)
						fire_hydrants.append({
							"node": hydrant,
							"pos": p,
							"radius": FIRE_HYDRANT_COLLISION_RADIUS,
							"claimed": false,
							"claim_progress": 0.0,
							"claim_ring": null
						})
				z += FIRE_HYDRANT_SPACING

func _fire_hydrant_candidate_ok(p: Vector2, existing_points: Array) -> bool:
	if not _point_in_map(p):
		return false
	if dog_park.grow(0.4).has_point(p):
		return false
	if _surface_at(p) != "sidewalk":
		return false
	if _point_in_building(p, 0.18):
		return false
	for ep in existing_points:
		var existing: Vector2 = ep
		if existing.distance_to(p) < 5.9:
			return false
	for pole in street_poles:
		var pos: Vector2 = pole.get("pos", Vector2.ZERO)
		if pos.distance_to(p) < 1.45:
			return false
	return true

func _create_fire_hydrant_node() -> Node3D:
	var root = Node3D.new()
	root.name = "FireHydrant"

	var base = MeshInstance3D.new()
	var base_mesh = CylinderMesh.new()
	base_mesh.top_radius = 0.13
	base_mesh.bottom_radius = 0.16
	base_mesh.height = 0.16
	base.mesh = base_mesh
	base.position = Vector3(0.0, 0.08, 0.0)
	base.material_override = fire_hydrant_body_material
	root.add_child(base)

	var body = MeshInstance3D.new()
	var body_mesh = CylinderMesh.new()
	body_mesh.top_radius = 0.11
	body_mesh.bottom_radius = 0.13
	body_mesh.height = 0.52
	body.mesh = body_mesh
	body.position = Vector3(0.0, 0.36, 0.0)
	body.material_override = fire_hydrant_body_material
	root.add_child(body)

	var dome = MeshInstance3D.new()
	var dome_mesh = SphereMesh.new()
	dome_mesh.radius = 0.13
	dome_mesh.height = 0.26
	dome.mesh = dome_mesh
	dome.position = Vector3(0.0, 0.67, 0.0)
	dome.material_override = fire_hydrant_body_material
	root.add_child(dome)

	for side in [-1.0, 1.0]:
		var arm = MeshInstance3D.new()
		var arm_mesh = CylinderMesh.new()
		arm_mesh.top_radius = 0.04
		arm_mesh.bottom_radius = 0.04
		arm_mesh.height = 0.22
		arm.mesh = arm_mesh
		arm.rotation_degrees.z = 90.0
		arm.position = Vector3(side * 0.16, 0.43, 0.0)
		arm.material_override = fire_hydrant_cap_material
		root.add_child(arm)

	var cap = MeshInstance3D.new()
	var cap_mesh = CylinderMesh.new()
	cap_mesh.top_radius = 0.06
	cap_mesh.bottom_radius = 0.07
	cap_mesh.height = 0.11
	cap.mesh = cap_mesh
	cap.position = Vector3(0.0, 0.78, 0.0)
	cap.material_override = fire_hydrant_cap_material
	root.add_child(cap)

	return root

func _street_pole_candidate_ok(p: Vector2, existing_points: Array) -> bool:
	if not _point_in_map(p):
		return false
	if dog_park.grow(0.35).has_point(p):
		return false
	for alley in alleys:
		if alley.grow(1.2).has_point(p):
			return false
	if _surface_at(p) != "sidewalk":
		return false
	if _point_in_building(p, 0.2):
		return false
	for ep in existing_points:
		var existing: Vector2 = ep
		if existing.distance_to(p) < 3.4:
			return false
	return true

func _create_street_pole_node() -> Node3D:
	var root = Node3D.new()
	root.name = "StreetPole"

	var footing = MeshInstance3D.new()
	var footing_mesh = CylinderMesh.new()
	footing_mesh.top_radius = 0.13
	footing_mesh.bottom_radius = 0.16
	footing_mesh.height = 0.18
	footing.mesh = footing_mesh
	footing.position = Vector3(0.0, 0.09, 0.0)
	footing.material_override = pole_base_material
	root.add_child(footing)

	var shaft = MeshInstance3D.new()
	var shaft_mesh = CylinderMesh.new()
	shaft_mesh.top_radius = 0.045
	shaft_mesh.bottom_radius = 0.058
	shaft_mesh.height = 4.4
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0.0, 2.27, 0.0)
	shaft.material_override = pole_metal_material
	root.add_child(shaft)

	var arm = MeshInstance3D.new()
	var arm_mesh = BoxMesh.new()
	arm_mesh.size = Vector3(0.055, 0.055, 0.68)
	arm.mesh = arm_mesh
	arm.position = Vector3(0.0, 4.38, 0.34)
	arm.material_override = pole_metal_material
	root.add_child(arm)

	var lamp_housing = MeshInstance3D.new()
	var housing_mesh = BoxMesh.new()
	housing_mesh.size = Vector3(0.2, 0.1, 0.32)
	lamp_housing.mesh = housing_mesh
	lamp_housing.position = Vector3(0.0, 4.33, 0.55)
	lamp_housing.material_override = pole_metal_material
	root.add_child(lamp_housing)

	var lamp_glass = MeshInstance3D.new()
	var glass_mesh = SphereMesh.new()
	glass_mesh.radius = 0.075
	glass_mesh.height = 0.15
	lamp_glass.mesh = glass_mesh
	lamp_glass.position = Vector3(0.0, 4.27, 0.58)
	lamp_glass.material_override = pole_lamp_material
	root.add_child(lamp_glass)

	return root

func _spawn_alley_dumpsters() -> void:
	for item in dumpsters:
		var node: Node3D = item.get("node", null)
		if node != null and is_instance_valid(node):
			node.queue_free()
	dumpsters.clear()

	for alley in alleys:
		if alley.size.x <= alley.size.y or alley.size.x < 9.0:
			continue

		var lane_center_z = alley.position.y + alley.size.y * 0.5
		var half_w = alley.size.y * 0.5
		var count = maxi(1, int(floor(alley.size.x / 10.5)))
		count += rng.randi_range(0, 1)
		for i in range(count):
			var t = (float(i) + 0.5) / float(count)
			var px = lerp(alley.position.x + 0.95, alley.position.x + alley.size.x - 0.95, t)
			px += rng.randf_range(-0.85, 0.85)
			var side = -1.0 if (i % 2 == 0) else 1.0
			if rng.randf() < 0.42:
				side = -side
			var pz = lane_center_z + side * (half_w - 0.36)
			var p = Vector2(px, pz)
			if not _point_in_map(p):
				continue
			if _surface_at(p) != "road":
				continue
			if _point_in_building(p, 0.22):
				continue

			var too_close = false
			for other in dumpsters:
				var op: Vector2 = other.get("pos", Vector2.ZERO)
				if op.distance_to(p) < 1.3:
					too_close = true
					break
			if too_close:
				continue

			var dumpster = _create_dumpster_node()
			dumpster.position = Vector3(p.x, 0.02, p.y)
			dumpster.rotation.y = (-PI * 0.5 if side > 0.0 else PI * 0.5) + rng.randf_range(-0.2, 0.2)
			static_root.add_child(dumpster)
			dumpsters.append({
				"node": dumpster,
				"pos": p,
				"radius": DUMPSTER_COLLISION_RADIUS,
				"has_bone": rng.randf() < 0.5,
				"searched": false
			})

func _create_dumpster_node() -> Node3D:
	var root = Node3D.new()
	root.name = "Dumpster"

	var body = MeshInstance3D.new()
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(1.18, 0.95, 0.68)
	body.mesh = body_mesh
	body.position = Vector3(0.0, 0.48, 0.0)
	body.material_override = dumpster_body_materials[rng.randi_range(0, dumpster_body_materials.size() - 1)]
	root.add_child(body)

	var lid_left = MeshInstance3D.new()
	var lid_mesh = BoxMesh.new()
	lid_mesh.size = Vector3(0.56, 0.06, 0.7)
	lid_left.mesh = lid_mesh
	lid_left.position = Vector3(-0.3, 0.98, 0.0)
	lid_left.rotation_degrees.z = rng.randf_range(-12.0, -4.0)
	lid_left.material_override = dumpster_lid_material
	root.add_child(lid_left)

	var lid_right = MeshInstance3D.new()
	lid_right.mesh = lid_mesh
	lid_right.position = Vector3(0.3, 0.98, 0.0)
	lid_right.rotation_degrees.z = rng.randf_range(4.0, 12.0)
	lid_right.material_override = dumpster_lid_material
	root.add_child(lid_right)

	var stripe = MeshInstance3D.new()
	var stripe_mesh = BoxMesh.new()
	stripe_mesh.size = Vector3(1.0, 0.12, 0.03)
	stripe.mesh = stripe_mesh
	stripe.position = Vector3(0.0, 0.56, 0.355)
	stripe.material_override = dumpster_trim_material
	root.add_child(stripe)

	for sx in [-0.44, 0.44]:
		var wheel = MeshInstance3D.new()
		var wheel_mesh = CylinderMesh.new()
		wheel_mesh.top_radius = 0.06
		wheel_mesh.bottom_radius = 0.06
		wheel_mesh.height = 0.07
		wheel.mesh = wheel_mesh
		wheel.position = Vector3(sx, 0.08, 0.26)
		wheel.rotation_degrees.x = 90.0
		wheel.material_override = dumpster_trim_material
		root.add_child(wheel)

	return root

func _pick_floors(seed_value: int) -> int:
	if seed_value % 4 == 0:
		return 1
	if seed_value % 3 == 0:
		return 3
	var roll = rng.randf()
	if roll < 0.28:
		return 1
	if roll < 0.46:
		return 2
	return 3

func _add_building(footprint: Rect2, floors: int, front_is_south: bool) -> void:
	if footprint.size.x < 3.5 or footprint.size.y < 3.3:
		return
	if footprint.intersects(dog_park.grow(0.4)):
		return

	for alley in alleys:
		if footprint.intersects(alley.grow(0.03)):
			return

	var created = BuildingFactoryScript.create_building(footprint, floors, front_is_south, rng)
	created["floors"] = floors
	var shrink = minf(0.24, minf(footprint.size.x, footprint.size.y) * 0.06)
	created["collision_rect"] = footprint.grow(-shrink)
	created["is_store"] = false
	created["enterable"] = false
	created["store_food_slots"] = 0
	created["store_walk_blockers"] = []
	created["store_interior_rect"] = Rect2()
	created["store_interior_root"] = null
	var node: Node3D = created["node"]
	static_root.add_child(node)
	buildings.append(created)

func _point_in_street_grass_band(p: Vector2) -> bool:
	for b in buildings:
		var fp: Rect2 = b["footprint"]
		var min_x = fp.position.x + 0.2
		var max_x = fp.position.x + fp.size.x - 0.2
		if p.x < min_x or p.x > max_x:
			continue

		var front_is_south = bool(b.get("front_is_south", true))
		var front_z = fp.position.y + fp.size.y if front_is_south else fp.position.y
		var near_building = front_z + (BUILDING_SIDEWALK_W + 0.12) * (1.0 if front_is_south else -1.0)
		var near_street = front_z + (ROW_FRONT_SETBACK - SIDEWALK_W - 0.12) * (1.0 if front_is_south else -1.0)
		var z0 = minf(near_building, near_street)
		var z1 = maxf(near_building, near_street)
		if p.y >= z0 and p.y <= z1:
			return true
	return false

func _try_add_tree_at(p: Vector2, street_band_only: bool) -> bool:
	if _surface_at(p) != "grass":
		return false
	if dog_park.grow(0.6).has_point(p):
		return false
	if _point_in_building(p, 0.9):
		return false
	if street_band_only and not _point_in_street_grass_band(p):
		return false
	var hardscape_margin = 0.2 if street_band_only else 0.48
	if _point_near_hardscape(p, hardscape_margin):
		return false
	for existing in trees:
		var ep: Vector2 = existing.get("pos", Vector2.ZERO)
		if ep.distance_to(p) < (1.55 if street_band_only else 1.9):
			return false

	var tree_scale = rng.randf_range(0.9, 1.3)
	var tree = TreeFactoryScript.create_tree(Vector3(p.x, 0.0, p.y), tree_scale, rng)
	static_root.add_child(tree)
	trees.append({
		"node": tree,
		"pos": p,
		"radius": TREE_COLLISION_SCALE * tree_scale,
		"height": 3.65 * tree_scale,
		"claimed": false,
		"claim_progress": 0.0,
		"claim_ring": null
	})
	return true

func _populate_trees() -> void:
	for item in trees:
		var node: Node3D = item.get("node", null)
		if node != null and is_instance_valid(node):
			node.queue_free()
	trees.clear()
	var street_band_target = 220
	for i in range(street_band_target):
		for try_i in range(26):
			var p = Vector2(rng.randf_range(1.0, MAP_W - 1.0), rng.randf_range(1.0, MAP_H - 1.0))
			if _try_add_tree_at(p, true):
				break

	var total_target = 300
	var remaining = max(0, total_target - trees.size())
	for i in range(remaining):
		for try_i in range(18):
			var p = Vector2(rng.randf_range(1.0, MAP_W - 1.0), rng.randf_range(1.0, MAP_H - 1.0))
			if _try_add_tree_at(p, false):
				break

func _build_grass_spikes() -> void:
	var blade_mesh = BoxMesh.new()
	blade_mesh.size = Vector3(0.03, 0.36, 0.03)

	var blade_mat = StandardMaterial3D.new()
	blade_mat.vertex_color_use_as_albedo = true
	blade_mat.roughness = 0.95
	blade_mat.metallic = 0.0
	blade_mat.cull_mode = StandardMaterial3D.CULL_DISABLED

	var points: Array = []
	for i in range(6200):
		var p = Vector2(rng.randf_range(0.6, MAP_W - 0.6), rng.randf_range(0.6, MAP_H - 0.6))
		if _surface_at(p) != "grass":
			continue
		if dog_park.grow(0.4).has_point(p):
			continue
		if _point_in_building(p, 0.15):
			continue
		if _point_near_hardscape(p, 0.22):
			continue
		points.append(p)
		if points.size() >= 3100:
			break

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = blade_mesh
	mm.instance_count = points.size()

	for i in range(points.size()):
		var p: Vector2 = points[i]
		var angle = rng.randf_range(0.0, TAU)
		var scale_vec = Vector3(
			rng.randf_range(0.75, 1.35),
			rng.randf_range(0.75, 1.5),
			rng.randf_range(0.75, 1.35)
		)
		var basis = Basis(Vector3.UP, angle).scaled(scale_vec)
		var xf = Transform3D(basis, Vector3(p.x, 0.18, p.y))
		mm.set_instance_transform(i, xf)
		var tone = rng.randf_range(0.0, 0.16)
		mm.set_instance_color(i, Color(0.2 + tone, 0.62 + tone * 0.7, 0.17 + tone * 0.5, 1.0))

	var spike_instance = MultiMeshInstance3D.new()
	spike_instance.multimesh = mm
	spike_instance.material_override = blade_mat
	spike_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	static_root.add_child(spike_instance)

func _spawn_sticks(count: int) -> void:
	for item in sticks:
		var n: Node3D = item.get("node", null)
		if n != null:
			n.queue_free()
	sticks.clear()
	if carried_stick != null and is_instance_valid(carried_stick):
		carried_stick.queue_free()
	carried_stick = null
	freya_has_stick = false

	if trees.is_empty():
		return

	var target = maxi(12, count)
	for i in range(target):
		var placed = false
		for attempt in range(16):
			var tree = trees[rng.randi_range(0, trees.size() - 1)]
			var tree_pos: Vector2 = tree.get("pos", Vector2.ZERO)
			var ang = rng.randf_range(0.0, TAU)
			var radius = rng.randf_range(0.72, 1.75)
			var p = tree_pos + Vector2(cos(ang), sin(ang)) * radius
			if not _point_in_map(p):
				continue
			if _surface_at(p) != "grass":
				continue
			if _point_in_building(p, 0.2):
				continue
			if _point_near_hardscape(p, 0.22):
				continue
			var too_close = false
			for existing in sticks:
				var ep: Vector2 = existing.get("pos", Vector2.ZERO)
				if ep.distance_to(p) < 0.95:
					too_close = true
					break
			if too_close:
				continue
			var node = _create_stick_node()
			node.position = Vector3(p.x, 0.03, p.y)
			node.rotation.y = rng.randf_range(0.0, TAU)
			dynamic_root.add_child(node)
			sticks.append({"node": node, "pos": p})
			placed = true
			break
		if not placed:
			continue

func _create_stick_node() -> Node3D:
	var root = Node3D.new()
	root.name = "Stick"
	root.scale = Vector3.ONE * STICK_VISUAL_SCALE

	var body = MeshInstance3D.new()
	var body_mesh = CylinderMesh.new()
	body_mesh.top_radius = 0.017 * STICK_THICKNESS_MULT
	body_mesh.bottom_radius = 0.021 * STICK_THICKNESS_MULT
	body_mesh.height = 0.58
	body.mesh = body_mesh
	body.rotation_degrees.z = 90.0
	body.position = Vector3(0.0, 0.05, 0.0)
	body.material_override = stick_material_main
	root.add_child(body)

	var branch = MeshInstance3D.new()
	var branch_mesh = CylinderMesh.new()
	branch_mesh.top_radius = 0.011 * STICK_THICKNESS_MULT
	branch_mesh.bottom_radius = 0.014 * STICK_THICKNESS_MULT
	branch_mesh.height = 0.24
	branch.mesh = branch_mesh
	branch.position = Vector3(0.09, 0.07, -0.02)
	branch.rotation_degrees = Vector3(36.0, 24.0, 90.0)
	branch.material_override = stick_material_branch
	root.add_child(branch)

	return root

func _create_bone_node() -> Node3D:
	var root = Node3D.new()
	root.name = "Bone"

	var shaft = MeshInstance3D.new()
	var shaft_mesh = CylinderMesh.new()
	shaft_mesh.top_radius = 0.04
	shaft_mesh.bottom_radius = 0.04
	shaft_mesh.height = 0.46
	shaft.mesh = shaft_mesh
	shaft.rotation_degrees.z = 90.0
	shaft.position = Vector3(0.0, 0.05, 0.0)
	shaft.material_override = bone_material
	root.add_child(shaft)

	for end_x in [-0.21, 0.21]:
		var lobe_a = MeshInstance3D.new()
		var lobe_mesh_a = SphereMesh.new()
		lobe_mesh_a.radius = 0.055
		lobe_mesh_a.height = 0.11
		lobe_a.mesh = lobe_mesh_a
		lobe_a.position = Vector3(end_x, 0.075, 0.06)
		lobe_a.material_override = bone_material
		root.add_child(lobe_a)

		var lobe_b = MeshInstance3D.new()
		var lobe_mesh_b = SphereMesh.new()
		lobe_mesh_b.radius = 0.055
		lobe_mesh_b.height = 0.11
		lobe_b.mesh = lobe_mesh_b
		lobe_b.position = Vector3(end_x, 0.075, -0.06)
		lobe_b.material_override = bone_material
		root.add_child(lobe_b)
	return root

func _spawn_freya_and_dogs() -> void:
	objective_puke_on_dog_complete = false
	var freya_model = ""
	if FileAccess.file_exists(FREYA_PRIMARY_MODEL) or ResourceLoader.exists(FREYA_PRIMARY_MODEL):
		freya_model = FREYA_PRIMARY_MODEL
	else:
		var freya_model_paths = _existing_model_paths(FREYA_MODEL_CANDIDATES)
		freya_model = freya_model_paths[0] if freya_model_paths.size() > 0 else ""

	var npc_model_paths = _animated_model_paths(NPC_DOG_MODEL_CANDIDATES)
	if npc_model_paths.is_empty() and not freya_model.is_empty() and _model_has_walk_animation(freya_model):
		npc_model_paths = [freya_model]
	if npc_model_paths.is_empty():
		npc_model_paths = _existing_model_paths(NPC_DOG_MODEL_CANDIDATES)

	freya = DogAgentScript.new()
	freya.configure({
		"is_freya": true,
		"coat_color": Color(0.07, 0.07, 0.07),
		"speed": FREYA_BASE_SPEED,
		"scene_path": freya_model,
		"model_scale": 1.0
	})
	freya.position = _random_walkable_point(true, FREYA_COLLISION_RADIUS)
	dynamic_root.add_child(freya)

	dogs.clear()
	var total_dogs = NPC_DOG_COUNT
	var park_dogs = mini(DOG_PARK_NPC_COUNT, total_dogs)
	var city_dogs = max(0, total_dogs - park_dogs)
	var city_points = _spawn_points_even(city_dogs, "sidewalk")
	var park_points = _spawn_points_in_rect(dog_park.grow(-0.45), park_dogs, "grass")
	var coat_options = [
		Color8(58, 48, 42),
		Color8(92, 80, 70),
		Color8(120, 93, 70),
		Color8(164, 126, 93),
		Color8(188, 159, 118),
		Color8(205, 192, 171),
		Color8(216, 206, 187),
		Color8(178, 140, 102),
		Color8(76, 78, 84),
		Color8(132, 127, 120),
		Color8(37, 34, 33),
		Color8(228, 220, 206)
	]
	var breed_profiles = [
		"retriever",
		"shepherd",
		"husky",
		"terrier",
		"hound",
		"bulldog",
		"poodle",
		"mixed"
	]

	for i in range(total_dogs):
		var dog = DogAgentScript.new()
		var cosmetic_rng = RandomNumberGenerator.new()
		cosmetic_rng.seed = int(146959810 + i * 2654435761)
		var in_park = i < park_dogs
		var pos_idx = i if in_park else i - park_dogs
		var spawn_pos = Vector3.ZERO
		if in_park and pos_idx < park_points.size():
			spawn_pos = park_points[pos_idx]
		elif (not in_park) and pos_idx < city_points.size():
			spawn_pos = city_points[pos_idx]
		else:
			spawn_pos = _random_walkable_point(true, DOG_COLLISION_RADIUS)
		dog.position = spawn_pos

		var zone_x = clampi(int(floor(spawn_pos.x / maxf(0.001, MAP_W / 4.0))), 0, 3)
		var zone_z = clampi(int(floor(spawn_pos.z / maxf(0.001, MAP_H / 4.0))), 0, 3)
		var zone_idx = zone_z * 4 + zone_x
		var breed = breed_profiles[posmod(i + zone_idx * 3 + (2 if in_park else 0), breed_profiles.size())]
		var coat = coat_options[posmod(i * 2 + zone_idx + (3 if in_park else 0), coat_options.size())]
		var dog_model = ""
		if npc_model_paths.size() > 0:
			dog_model = npc_model_paths[posmod(i + zone_idx + (1 if in_park else 0), npc_model_paths.size())]
			rng.randi_range(0, npc_model_paths.size() - 1)
		var dog_speed = rng.randf_range(1.7, 2.6)
		var model_scale = _npc_model_scale_for_path(dog_model) * cosmetic_rng.randf_range(0.84, 1.2)
		rng.randi_range(0, coat_options.size() - 1)
		rng.randf_range(0.84, 1.2)
		rng.randi_range(0, breed_profiles.size() - 1)
		rng.randi()
		dog.configure({
			"is_freya": false,
			"coat_color": coat,
			"speed": dog_speed,
			"scene_path": dog_model,
			"model_scale": model_scale,
			"breed_profile": breed,
			"variant_seed": int(cosmetic_rng.randi())
		})
		dog.scale = Vector3.ONE
		dynamic_root.add_child(dog)
		var pref_surface = _pick_dog_pref_surface(in_park)
		dogs.append({
			"node": dog,
			"dir": _random_dir(),
			"speed": rng.randf_range(1.7, 2.6),
			"wander": rng.randf_range(0.6, 2.0),
			"bark": rng.randf_range(0.4, 1.2),
			"park": in_park,
			"pref_surface": pref_surface,
			"pref_timer": rng.randf_range(1.2, 3.6)
		})

func _existing_model_paths(candidates: Array) -> Array:
	var out: Array = []
	for p in candidates:
		var path = str(p)
		if FileAccess.file_exists(path) or ResourceLoader.exists(path):
			out.append(path)
	return out

func _spawn_points_in_rect(rect: Rect2, count: int, preferred_surface: String) -> Array:
	var points: Array = []
	if count <= 0:
		return points

	for i in range(count):
		var placed = false
		for attempt in range(90):
			var p = Vector2(
				rng.randf_range(rect.position.x + 0.25, rect.position.x + rect.size.x - 0.25),
				rng.randf_range(rect.position.y + 0.25, rect.position.y + rect.size.y - 0.25)
			)
			if not _is_walkable(p.x, p.y, DOG_COLLISION_RADIUS):
				continue
			var surf = _surface_at(p)
			if surf == "road":
				continue
			if not preferred_surface.is_empty() and surf != preferred_surface and rng.randf() < 0.82:
				continue
			var too_close = false
			for existing in points:
				var e: Vector3 = existing
				if Vector2(e.x, e.z).distance_to(p) < 1.1:
					too_close = true
					break
			if too_close:
				continue
			points.append(Vector3(p.x, 0.0, p.y))
			placed = true
			break
		if not placed:
			points.append(_random_walkable_point(true, DOG_COLLISION_RADIUS))
	return points

func _spawn_points_even(count: int, preferred_surface: String) -> Array:
	var points: Array = []
	if count <= 0:
		return points

	var cols = maxi(1, int(ceil(sqrt(float(count) * (MAP_W / MAP_H)))))
	var rows = maxi(1, int(ceil(float(count) / float(cols))))
	var cell_w = MAP_W / float(cols)
	var cell_h = MAP_H / float(rows)

	for r in range(rows):
		for c in range(cols):
			if points.size() >= count:
				break
			var cell = Rect2(c * cell_w, r * cell_h, cell_w, cell_h)
			var p = _sample_point_in_cell(cell, preferred_surface, points)
			if p.y >= -0.01:
				points.append(p)
		if points.size() >= count:
			break

	while points.size() < count:
		points.append(_random_walkable_point(true, DOG_COLLISION_RADIUS))
	return points

func _sample_point_in_cell(cell: Rect2, preferred_surface: String, existing_points: Array) -> Vector3:
	for attempt in range(50):
		var p = Vector2(
			rng.randf_range(cell.position.x + 0.35, cell.position.x + cell.size.x - 0.35),
			rng.randf_range(cell.position.y + 0.35, cell.position.y + cell.size.y - 0.35)
		)
		if dog_park.grow(0.5).has_point(p):
			continue
		if not _is_walkable(p.x, p.y, DOG_COLLISION_RADIUS):
			continue
		var surf = _surface_at(p)
		if surf == "road":
			continue
		if not preferred_surface.is_empty() and surf != preferred_surface and rng.randf() < 0.86:
			continue
		var too_close = false
		for e in existing_points:
			var ep: Vector3 = e
			if Vector2(ep.x, ep.z).distance_to(p) < 1.7:
				too_close = true
				break
		if too_close:
			continue
		return Vector3(p.x, 0.0, p.y)
	return Vector3(0.0, -1.0, 0.0)

func _pick_dog_pref_surface(in_park: bool) -> String:
	if in_park:
		return "grass" if rng.randf() < 0.9 else "sidewalk"
	return "sidewalk" if rng.randf() < NPC_SIDEWALK_PREF_CHANCE else "grass"

func _choose_dog_direction(origin: Vector3, preferred_surface: String, in_park: bool) -> Vector3:
	var best_dir = _random_dir()
	var best_score = -1000000.0
	for i in range(18):
		var dir = _random_dir()
		var probe = origin + dir * rng.randf_range(1.1, 2.8)
		var probe2 = Vector2(probe.x, probe.z)
		if not _is_walkable(probe2.x, probe2.y, DOG_COLLISION_RADIUS):
			continue
		var surf = _surface_at(probe2)
		if surf == "road":
			continue

		var score = rng.randf_range(-0.15, 0.15)
		if preferred_surface == "sidewalk":
			score += 2.6 if surf == "sidewalk" else 0.75
		else:
			score += 2.4 if surf == "grass" else 0.7

		if in_park:
			score += 1.2 if dog_park.grow(0.2).has_point(probe2) else -1.3
		else:
			if dog_park.grow(0.35).has_point(probe2):
				score -= 1.3

		if score > best_score:
			best_score = score
			best_dir = dir
	return best_dir

func _animated_model_paths(candidates: Array) -> Array:
	var out: Array = []
	for path in _existing_model_paths(candidates):
		var p = str(path)
		if _model_has_walk_animation(p):
			out.append(p)
	return out

func _model_has_walk_animation(path: String) -> bool:
	if path.is_empty():
		return false
	if not FileAccess.file_exists(path) and not ResourceLoader.exists(path):
		return false
	var res = load(path)
	if not (res is PackedScene):
		return false
	var node = (res as PackedScene).instantiate()
	if node == null:
		return false
	var names = _collect_animation_names(node)
	if node is Node:
		(node as Node).free()
	for name in names:
		var lname = str(name).to_lower()
		if lname.contains("walk") or lname.contains("run") or lname.contains("trot") or lname.contains("gallop"):
			return true
	return false

func _collect_animation_names(root: Node) -> PackedStringArray:
	var names := PackedStringArray()
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is AnimationPlayer:
			var player := n as AnimationPlayer
			for anim_name in player.get_animation_list():
				names.append(str(anim_name))
		for c in n.get_children():
			stack.append(c)
	return names

func _npc_model_scale_for_path(path: String) -> float:
	if path.is_empty():
		return 1.0
	return float(NPC_MODEL_SCALE_OVERRIDES.get(path, 1.0))

func _random_dir() -> Vector3:
	var d = Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0))
	if d.length_squared() < 0.0001:
		return Vector3.FORWARD
	return d.normalized()

func _seed_poops(count: int) -> void:
	for i in range(count):
		_spawn_poop(rng.randf() < 0.5)

func _spawn_poop(prefer_dog_park: bool = false) -> void:
	var p2 = Vector2.ZERO
	var found = false
	if prefer_dog_park:
		for attempt in range(40):
			var candidate = Vector2(
				rng.randf_range(dog_park.position.x + 0.5, dog_park.position.x + dog_park.size.x - 0.5),
				rng.randf_range(dog_park.position.y + 0.5, dog_park.position.y + dog_park.size.y - 0.5)
			)
			if not _is_walkable(candidate.x, candidate.y, 0.1):
				continue
			p2 = candidate
			found = true
			break
	if not found:
		var p3 = _random_walkable_point(true, 0.1)
		p2 = Vector2(p3.x, p3.z)
	if _surface_at(p2) == "road":
		return
	for item in poops:
		var pos: Vector2 = item["pos"]
		if pos.distance_to(p2) < 1.2:
			return
	var p3 = Vector3(p2.x, 0.0, p2.y)

	var root = Node3D.new()
	root.position = p3

	for blob in [Vector3(0.0, 0.08, 0.0), Vector3(-0.11, 0.05, 0.08), Vector3(0.1, 0.05, 0.08)]:
		var m = MeshInstance3D.new()
		var mesh = SphereMesh.new()
		mesh.radius = 0.08
		mesh.height = 0.16
		m.mesh = mesh
		m.position = blob
		m.scale = Vector3(1.0, 0.7, 1.0)
		m.material_override = poop_material
		root.add_child(m)

	dynamic_root.add_child(root)
	poops.append({"node": root, "pos": p2})

func _random_walkable_point(avoid_roads: bool, radius: float = 0.22) -> Vector3:
	for i in range(420):
		var p = Vector2(rng.randf_range(0.9, MAP_W - 0.9), rng.randf_range(0.9, MAP_H - 0.9))
		if not _is_walkable(p.x, p.y, radius):
			continue
		if avoid_roads and _surface_at(p) == "road":
			continue
		return Vector3(p.x, 0.0, p.y)
	return Vector3(MAP_W * 0.5, 0.0, MAP_H * 0.5)

func _is_walkable(x: float, z: float, radius: float = 0.22) -> bool:
	if x < radius or z < radius or x > MAP_W - radius or z > MAP_H - radius:
		return false
	var p = Vector2(x, z)
	if _point_in_blocking_building(p, radius + BUILDING_COLLISION_PAD):
		return false
	if _point_in_store_wall(p, maxf(0.02, radius * 0.56)):
		return false
	if _point_in_tree_trunk(p, maxf(0.2, radius * 0.95)):
		return false
	if _point_in_dumpster(p, maxf(0.08, radius * 0.9)):
		return false
	if _point_in_street_pole(p, maxf(0.04, radius * 0.45)):
		return false
	if _point_in_fire_hydrant(p, maxf(0.04, radius * 0.45)):
		return false
	return true

func _point_in_building(p: Vector2, pad: float) -> bool:
	for b in buildings:
		var rect: Rect2 = b.get("collision_rect", b["footprint"])
		if rect.grow(pad).has_point(p):
			return true
	return false

func _point_in_blocking_building(p: Vector2, pad: float) -> bool:
	for rect in blocking_building_rects:
		if rect.grow(pad).has_point(p):
			return true
	return false

func _point_in_store_wall(p: Vector2, pad: float) -> bool:
	for rect in store_walk_blockers:
		if rect.grow(pad).has_point(p):
			return true
	return false

func _point_in_tree_trunk(p: Vector2, extra_radius: float) -> bool:
	for t in trees:
		var center: Vector2 = t.get("pos", Vector2.ZERO)
		var tree_radius = float(t.get("radius", TREE_COLLISION_SCALE))
		if center.distance_to(p) <= tree_radius + extra_radius:
			return true
	return false

func _point_in_dumpster(p: Vector2, extra_radius: float) -> bool:
	for d in dumpsters:
		var center: Vector2 = d.get("pos", Vector2.ZERO)
		var dumpster_radius = float(d.get("radius", DUMPSTER_COLLISION_RADIUS))
		if center.distance_to(p) <= dumpster_radius + extra_radius:
			return true
	return false

func _point_in_street_pole(p: Vector2, extra_radius: float) -> bool:
	for pole in street_poles:
		var center: Vector2 = pole.get("pos", Vector2.ZERO)
		var pole_radius = float(pole.get("radius", STREET_POLE_COLLISION_RADIUS))
		if center.distance_to(p) <= pole_radius + extra_radius:
			return true
	return false

func _point_in_fire_hydrant(p: Vector2, extra_radius: float) -> bool:
	for hydrant in fire_hydrants:
		var center: Vector2 = hydrant.get("pos", Vector2.ZERO)
		var radius = float(hydrant.get("radius", FIRE_HYDRANT_COLLISION_RADIUS))
		if center.distance_to(p) <= radius + extra_radius:
			return true
	return false

func _in_any_rect(rects: Array[Rect2], p: Vector2) -> bool:
	for r in rects:
		if r.has_point(p):
			return true
	return false

func _surface_at(p: Vector2) -> String:
	if _in_any_rect(roads, p) or _in_any_rect(alleys, p):
		return "road"
	if _in_any_rect(sidewalks, p) or _in_any_rect(alley_shoulders, p):
		return "sidewalk"
	return "grass"

func _point_near_hardscape(p: Vector2, margin: float) -> bool:
	for r in roads:
		if r.grow(margin).has_point(p):
			return true
	for a in alleys:
		if a.grow(margin).has_point(p):
			return true
	for s in sidewalks:
		if s.grow(margin).has_point(p):
			return true
	for s in alley_shoulders:
		if s.grow(margin).has_point(p):
			return true
	for b in buildings:
		var fp: Rect2 = b["footprint"]
		if fp.grow(margin).has_point(p):
			return true
	for pole in street_poles:
		var center: Vector2 = pole.get("pos", Vector2.ZERO)
		var pole_radius = float(pole.get("radius", STREET_POLE_COLLISION_RADIUS))
		if center.distance_to(p) <= pole_radius + margin:
			return true
	for hydrant in fire_hydrants:
		var center: Vector2 = hydrant.get("pos", Vector2.ZERO)
		var hydrant_radius = float(hydrant.get("radius", FIRE_HYDRANT_COLLISION_RADIUS))
		if center.distance_to(p) <= hydrant_radius + margin:
			return true
	return false

func _update_freya(delta: float) -> void:
	freya_hunger = clamp(freya_hunger + delta * 1.25, 0.0, 100.0)
	freya_social = clamp(freya_social - delta * 1.0, 0.0, 100.0)
	freya_vomit = clamp(freya_vomit - delta * 1.15, 0.0, 100.0)

	if freya_vomit_timer > 0.0:
		freya_vomit_timer = max(0.0, freya_vomit_timer - delta)
		freya.update_motion(delta, Vector3.ZERO, false, true)
		return

	var input_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var input_y = Input.get_action_strength("move_up") - Input.get_action_strength("move_down")
	var moving = Vector2(input_x, input_y)

	if moving.length_squared() < 0.0001:
		freya_move_dir = Vector3.ZERO
		freya.update_motion(delta, Vector3.ZERO, false, false)
		return

	var cam_forward = -camera_node.global_transform.basis.z
	cam_forward.y = 0.0
	cam_forward = cam_forward.normalized()
	var cam_right = camera_node.global_transform.basis.x
	cam_right.y = 0.0
	cam_right = cam_right.normalized()

	var move_dir = (cam_right * input_x + cam_forward * input_y)
	if move_dir.length_squared() < 0.0001:
		freya_move_dir = Vector3.ZERO
		freya.update_motion(delta, Vector3.ZERO, false, false)
		return
	move_dir = move_dir.normalized()
	freya_move_dir = move_dir

	var running = Input.is_action_pressed("run")
	var speed = _compute_freya_move_speed(running)

	var next: Vector3 = freya.global_position + move_dir * speed * delta
	if _is_walkable(next.x, freya.global_position.z, FREYA_COLLISION_RADIUS):
		freya.global_position.x = next.x
	if _is_walkable(freya.global_position.x, next.z, FREYA_COLLISION_RADIUS):
		freya.global_position.z = next.z

	freya.update_motion(delta, move_dir, running, false)

func _compute_freya_move_speed(running: bool) -> float:
	var speed_penalty = freya_hunger * 0.0043
	var speed = FREYA_BASE_SPEED * (1.0 - speed_penalty)
	if running:
		speed *= FREYA_RUN_MULT
		if freya_has_stick and carried_stick != null and is_instance_valid(carried_stick):
			speed *= FREYA_STICK_RUN_MULT
	return maxf(1.7, speed)

func _update_dogs(delta: float) -> void:
	var aggressive_social = Input.is_action_pressed("aggressive_social")
	aggressive_bark_nearby_count = 0
	var passive_social_target = Vector3.ZERO
	var passive_social_target_dist = 1000000.0
	var has_passive_social_target = false
	if aggressive_social:
		for d in dogs:
			var dn: Node3D = d.get("node", null)
			if dn == null or not is_instance_valid(dn):
				continue
			if dn.global_position.distance_to(freya.global_position) < 4.25:
				aggressive_bark_nearby_count += 1
	if aggressive_social:
		var pack_target = float(max(1, aggressive_bark_nearby_count))
		aggressive_bark_pressure = lerpf(aggressive_bark_pressure, pack_target, clampf(delta * 7.0, 0.0, 1.0))
	else:
		aggressive_bark_pressure = maxf(1.0, aggressive_bark_pressure - delta * 2.4)

	for i in range(dogs.size()):
		var state: Dictionary = dogs[i]
		var dog = state["node"]
		state["wander"] = float(state["wander"]) - delta
		state["bark"] = float(state["bark"]) - delta
		state["pref_timer"] = float(state.get("pref_timer", 1.5)) - delta

		var in_park = bool(state.get("park", false))
		var pref_surface = str(state.get("pref_surface", "sidewalk"))
		if float(state["pref_timer"]) <= 0.0:
			pref_surface = _pick_dog_pref_surface(in_park)
			state["pref_surface"] = pref_surface
			state["pref_timer"] = rng.randf_range(1.4, 4.2)
			state["wander"] = 0.0

		var dir: Vector3 = state["dir"]
		if float(state["wander"]) <= 0.0:
			var drive_surface = pref_surface
			if (not in_park) and pref_surface == "sidewalk" and rng.randf() < 0.36:
				drive_surface = "grass"
			dir = _choose_dog_direction(dog.global_position, drive_surface, in_park)
			state["wander"] = rng.randf_range(0.8, 2.6)

		var speed = float(state["speed"])
		var next: Vector3 = dog.global_position + dir * speed * delta
		var next_surface = _surface_at(Vector2(next.x, next.z))
		if _is_walkable(next.x, next.z, DOG_COLLISION_RADIUS) and next_surface != "road":
			dog.global_position = Vector3(next.x, 0.0, next.z)
		else:
			var moved = false
			var step_x = Vector3(next.x, dog.global_position.y, dog.global_position.z)
			var step_z = Vector3(dog.global_position.x, dog.global_position.y, next.z)
			if _is_walkable(step_x.x, step_x.z, DOG_COLLISION_RADIUS) and _surface_at(Vector2(step_x.x, step_x.z)) != "road":
				dog.global_position.x = step_x.x
				moved = true
			if _is_walkable(step_z.x, step_z.z, DOG_COLLISION_RADIUS) and _surface_at(Vector2(step_z.x, step_z.z)) != "road":
				dog.global_position.z = step_z.z
				moved = true
			if not moved:
				dir = _choose_dog_direction(dog.global_position, pref_surface, in_park)
				state["wander"] = 0.3

		if not in_park and pref_surface == "sidewalk":
			var current_surface = _surface_at(Vector2(dog.global_position.x, dog.global_position.z))
			if current_surface == "grass":
				state["wander"] = minf(float(state["wander"]), 0.35)

		dog.update_motion(delta, dir, false, false)
		state["dir"] = dir

		var near: float = dog.global_position.distance_to(freya.global_position)
		if near < 4.2:
			freya_social = clamp(freya_social + delta * (31.0 if aggressive_social else 22.0), 0.0, 100.0)
			if (not aggressive_social) and near < 3.4 and near < passive_social_target_dist:
				passive_social_target = dog.global_position
				passive_social_target_dist = near
				has_passive_social_target = true
			if float(state["bark"]) <= 0.0:
				if aggressive_social:
					var pack = max(1, aggressive_bark_nearby_count)
					var pulse_hot = clampf(0.64 + float(pack) * 0.05, 0.64, 1.0)
					_spawn_bark_pulse(dog.head_world_position(), Color(1.0, 0.74, 0.7, 0.9))
					_spawn_bark_pulse(freya.head_world_position(), Color(1.0, pulse_hot, 0.48, 0.96))
					var bark_burst = rng.randi_range(2, 3)
					if pack >= 5 and rng.randf() < 0.5:
						bark_burst += 1
					_queue_bark_sequence(false, bark_burst, true)
					_queue_bark_sequence(true, bark_burst, true)
					var cooldown_scale = clampf(1.0 - (float(pack - 1) * 0.07), 0.45, 1.0)
					state["bark"] = rng.randf_range(0.21, 0.43) * cooldown_scale
				else:
					_spawn_bark_pulse(dog.head_world_position(), Color(1.0, 1.0, 1.0, 0.82))
					_spawn_bark_pulse(freya.head_world_position(), Color(1.0, 0.9, 0.65, 0.84))
					_queue_bark_sequence(false, rng.randi_range(1, 2), false)
					_queue_bark_sequence(true, rng.randi_range(1, 2), false)
					state["bark"] = rng.randf_range(0.52, 0.96)

		dogs[i] = state

	_update_passive_social_dance(delta, aggressive_social, has_passive_social_target, passive_social_target)

func _freya_is_idle_for_social_dance() -> bool:
	if freya == null:
		return false
	if freya_vomit_timer > 0.0:
		return false
	if Input.is_action_pressed("claim"):
		return false
	var input_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var input_y = Input.get_action_strength("move_up") - Input.get_action_strength("move_down")
	return Vector2(input_x, input_y).length_squared() < 0.0001

func _update_passive_social_dance(delta: float, aggressive_social: bool, has_target: bool, target_pos: Vector3) -> void:
	if freya == null:
		freya_social_dance_phase = 0.0
		return
	if aggressive_social or (not has_target) or (not _freya_is_idle_for_social_dance()):
		freya_social_dance_phase = fposmod(freya_social_dance_phase, TAU)
		return

	freya_social_dance_phase = fposmod(freya_social_dance_phase + delta * FREYA_SOCIAL_DANCE_SPIN_SPEED, TAU)
	var center = Vector2(target_pos.x, target_pos.z)
	var freya_pos2 = Vector2(freya.global_position.x, freya.global_position.z)
	var radius = FREYA_SOCIAL_DANCE_RADIUS + 0.06 * sin(world_time * 2.2)
	var orbit_offset = Vector2(cos(freya_social_dance_phase), sin(freya_social_dance_phase)) * radius
	var desired = center + orbit_offset
	var catchup = desired - freya_pos2
	var tangent = Vector2(-sin(freya_social_dance_phase), cos(freya_social_dance_phase))
	var drive = tangent * 0.72 + catchup * 1.05
	if drive.length_squared() < 0.0001:
		return
	var move2 = drive.normalized()
	var move3 = Vector3(move2.x, 0.0, move2.y)

	var next = freya.global_position + move3 * FREYA_SOCIAL_DANCE_SPEED * delta
	var moved = false
	if _is_walkable(next.x, freya.global_position.z, FREYA_COLLISION_RADIUS):
		freya.global_position.x = next.x
		moved = true
	if _is_walkable(freya.global_position.x, next.z, FREYA_COLLISION_RADIUS):
		freya.global_position.z = next.z
		moved = true
	if not moved:
		return

	freya_move_dir = move3
	freya.update_motion(delta, move3, false, false)
	var spin_dir = Vector3(tangent.x, 0.0, tangent.y)
	if freya.has_method("force_face_direction"):
		freya.call("force_face_direction", spin_dir, delta * 6.0)

func _spawn_bark_pulse(pos: Vector3, color: Color) -> void:
	var node = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.22
	torus.outer_radius = 0.31
	node.mesh = torus
	node.position = pos + Vector3(0.0, 0.18, 0.0)
	node.rotation_degrees.x = 90.0

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	mat.cull_mode = StandardMaterial3D.CULL_DISABLED
	node.material_override = mat

	dynamic_root.add_child(node)
	bark_pulses.append({"node": node, "mat": mat, "age": 0.0, "ttl": 0.72})

func _handle_actions() -> void:
	if Input.is_action_just_pressed("eat"):
		_try_interact()
	if Input.is_action_just_pressed("vomit"):
		_try_vomit()
	if Input.is_action_just_pressed("drop_stick"):
		if carried_stick != null and is_instance_valid(carried_stick):
			_drop_carried_stick()
		else:
			_show_status("No stick to drop", 0.55)

func _find_nearest_claim_target() -> Dictionary:
	var found := false
	var best_dist_sq := CLAIM_RANGE * CLAIM_RANGE
	var best_type := CLAIM_TARGET_NONE
	var best_index := -1
	var freya_pos = Vector2(freya.global_position.x, freya.global_position.z)

	for i in range(street_poles.size()):
		var pole: Dictionary = street_poles[i]
		if bool(pole.get("claimed", false)):
			continue
		var pos: Vector2 = pole.get("pos", Vector2.ZERO)
		var dist_sq = freya_pos.distance_squared_to(pos)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_type = CLAIM_TARGET_LIGHT_POLE
			best_index = i
			found = true

	for i in range(trees.size()):
		var tree: Dictionary = trees[i]
		if bool(tree.get("claimed", false)):
			continue
		var pos: Vector2 = tree.get("pos", Vector2.ZERO)
		var dist_sq = freya_pos.distance_squared_to(pos)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_type = CLAIM_TARGET_TREE
			best_index = i
			found = true

	for i in range(fire_hydrants.size()):
		var hydrant: Dictionary = fire_hydrants[i]
		if bool(hydrant.get("claimed", false)):
			continue
		var pos: Vector2 = hydrant.get("pos", Vector2.ZERO)
		var dist_sq = freya_pos.distance_squared_to(pos)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_type = CLAIM_TARGET_FIRE_HYDRANT
			best_index = i
			found = true

	return {"found": found, "type": best_type, "index": best_index, "dist_sq": best_dist_sq}

func _find_nearest_dumpster_index(max_range: float = CLAIM_RANGE + 0.35) -> int:
	var best_idx = -1
	var best_dist_sq = max_range * max_range
	var freya_pos = Vector2(freya.global_position.x, freya.global_position.z)
	for i in range(dumpsters.size()):
		var d: Dictionary = dumpsters[i]
		var pos: Vector2 = d.get("pos", Vector2.ZERO)
		var dist_sq = freya_pos.distance_squared_to(pos)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_idx = i
	return best_idx

func _try_search_dumpster(dumpster_index: int) -> bool:
	if dumpster_index < 0 or dumpster_index >= dumpsters.size():
		return false
	var d: Dictionary = dumpsters[dumpster_index]
	if bool(d.get("searched", false)):
		_show_status("Already searched this dumpster", 0.85)
		return true
	d["searched"] = true
	var found_bone = bool(d.get("has_bone", false))
	d["has_bone"] = false
	dumpsters[dumpster_index] = d
	if not found_bone:
		_show_status("Dumpster searched: just trash", 0.9)
		return true

	var base_pos: Vector2 = d.get("pos", Vector2.ZERO)
	var spawn_pos = base_pos + Vector2(rng.randf_range(-0.52, 0.52), rng.randf_range(-0.52, 0.52))
	if not _is_walkable(spawn_pos.x, spawn_pos.y, 0.12):
		var fallback = freya.global_position + Vector3(rng.randf_range(-0.65, 0.65), 0.0, rng.randf_range(-0.65, 0.65))
		spawn_pos = Vector2(fallback.x, fallback.z)
	var bone = _create_bone_node()
	bone.position = Vector3(spawn_pos.x, 0.03, spawn_pos.y)
	bone.rotation.y = rng.randf_range(0.0, TAU)
	dynamic_root.add_child(bone)
	bones.append({"node": bone, "pos": spawn_pos})
	_show_status("Found a bone in the dumpster!", 1.05)
	return true

func _reset_claim_progress(target_type: int, index: int) -> void:
	if index < 0:
		return
	if target_type == CLAIM_TARGET_LIGHT_POLE:
		if index >= street_poles.size():
			return
		var pole: Dictionary = street_poles[index]
		if not bool(pole.get("claimed", false)):
			pole["claim_progress"] = 0.0
			street_poles[index] = pole
		return
	if target_type == CLAIM_TARGET_TREE:
		if index >= trees.size():
			return
		var tree: Dictionary = trees[index]
		if not bool(tree.get("claimed", false)):
			tree["claim_progress"] = 0.0
			trees[index] = tree
		return
	if target_type == CLAIM_TARGET_FIRE_HYDRANT:
		if index >= fire_hydrants.size():
			return
		var hydrant: Dictionary = fire_hydrants[index]
		if not bool(hydrant.get("claimed", false)):
			hydrant["claim_progress"] = 0.0
			fire_hydrants[index] = hydrant

func _create_claim_ring_node(radius: float) -> MeshInstance3D:
	var ring = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.04
	ring.mesh = mesh
	ring.position = Vector3(0.0, 0.045, 0.0)
	ring.material_override = claim_ring_material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.visible = false
	return ring

func _ensure_claim_ring_for_target(target_type: int, index: int) -> void:
	if index < 0:
		return
	if target_type == CLAIM_TARGET_LIGHT_POLE:
		if index >= street_poles.size():
			return
		var pole: Dictionary = street_poles[index]
		var existing = pole.get("claim_ring", null)
		if existing != null and is_instance_valid(existing):
			return
		var node: Node3D = pole.get("node", null)
		if node == null or not is_instance_valid(node):
			return
		var ring = _create_claim_ring_node(0.28)
		node.add_child(ring)
		pole["claim_ring"] = ring
		street_poles[index] = pole
		return
	if target_type == CLAIM_TARGET_TREE:
		if index >= trees.size():
			return
		var tree: Dictionary = trees[index]
		var existing = tree.get("claim_ring", null)
		if existing != null and is_instance_valid(existing):
			return
		var node: Node3D = tree.get("node", null)
		if node == null or not is_instance_valid(node):
			return
		var ring_radius = clampf(float(tree.get("radius", TREE_COLLISION_SCALE)) * 1.9, 0.32, 0.55)
		var ring = _create_claim_ring_node(ring_radius)
		node.add_child(ring)
		tree["claim_ring"] = ring
		trees[index] = tree
		return
	if target_type == CLAIM_TARGET_FIRE_HYDRANT:
		if index >= fire_hydrants.size():
			return
		var hydrant: Dictionary = fire_hydrants[index]
		var existing = hydrant.get("claim_ring", null)
		if existing != null and is_instance_valid(existing):
			return
		var node: Node3D = hydrant.get("node", null)
		if node == null or not is_instance_valid(node):
			return
		var ring = _create_claim_ring_node(0.24)
		node.add_child(ring)
		hydrant["claim_ring"] = ring
		fire_hydrants[index] = hydrant

func _claim_target_world_position(target_type: int, index: int) -> Vector3:
	if target_type == CLAIM_TARGET_LIGHT_POLE and index >= 0 and index < street_poles.size():
		var pole: Dictionary = street_poles[index]
		var node: Node3D = pole.get("node", null)
		if node != null and is_instance_valid(node):
			return node.global_position + Vector3(0.0, 4.9, 0.0)
		var p: Vector2 = pole.get("pos", Vector2.ZERO)
		return Vector3(p.x, 4.9, p.y)
	if target_type == CLAIM_TARGET_TREE and index >= 0 and index < trees.size():
		var tree: Dictionary = trees[index]
		var node: Node3D = tree.get("node", null)
		var h = float(tree.get("height", 3.6))
		if node != null and is_instance_valid(node):
			return node.global_position + Vector3(0.0, h + 0.7, 0.0)
		var p: Vector2 = tree.get("pos", Vector2.ZERO)
		return Vector3(p.x, h + 0.7, p.y)
	if target_type == CLAIM_TARGET_FIRE_HYDRANT and index >= 0 and index < fire_hydrants.size():
		var hydrant: Dictionary = fire_hydrants[index]
		var node: Node3D = hydrant.get("node", null)
		if node != null and is_instance_valid(node):
			return node.global_position + Vector3(0.0, 1.15, 0.0)
		var p: Vector2 = hydrant.get("pos", Vector2.ZERO)
		return Vector3(p.x, 1.15, p.y)
	return freya.global_position + Vector3(0.0, 1.5, 0.0)

func _claim_progress_for_target(target_type: int, index: int) -> float:
	if target_type == CLAIM_TARGET_LIGHT_POLE and index >= 0 and index < street_poles.size():
		return clampf(float(street_poles[index].get("claim_progress", 0.0)), 0.0, 1.0)
	if target_type == CLAIM_TARGET_TREE and index >= 0 and index < trees.size():
		return clampf(float(trees[index].get("claim_progress", 0.0)), 0.0, 1.0)
	if target_type == CLAIM_TARGET_FIRE_HYDRANT and index >= 0 and index < fire_hydrants.size():
		return clampf(float(fire_hydrants[index].get("claim_progress", 0.0)), 0.0, 1.0)
	return 0.0

func _claim_target_base_world_position(target_type: int, index: int) -> Vector3:
	if target_type == CLAIM_TARGET_LIGHT_POLE and index >= 0 and index < street_poles.size():
		var pole: Dictionary = street_poles[index]
		var node: Node3D = pole.get("node", null)
		if node != null and is_instance_valid(node):
			return node.global_position
		var p: Vector2 = pole.get("pos", Vector2.ZERO)
		return Vector3(p.x, 0.0, p.y)
	if target_type == CLAIM_TARGET_TREE and index >= 0 and index < trees.size():
		var tree: Dictionary = trees[index]
		var node: Node3D = tree.get("node", null)
		if node != null and is_instance_valid(node):
			return node.global_position
		var p: Vector2 = tree.get("pos", Vector2.ZERO)
		return Vector3(p.x, 0.0, p.y)
	if target_type == CLAIM_TARGET_FIRE_HYDRANT and index >= 0 and index < fire_hydrants.size():
		var hydrant: Dictionary = fire_hydrants[index]
		var node: Node3D = hydrant.get("node", null)
		if node != null and is_instance_valid(node):
			return node.global_position
		var p: Vector2 = hydrant.get("pos", Vector2.ZERO)
		return Vector3(p.x, 0.0, p.y)
	return freya.global_position

func _claim_target_pee_world_position(target_type: int, index: int) -> Vector3:
	var center = _claim_target_base_world_position(target_type, index)
	var toward_freya = Vector2(freya.global_position.x - center.x, freya.global_position.z - center.z)
	if toward_freya.length_squared() < 0.0001:
		toward_freya = Vector2.RIGHT
	toward_freya = toward_freya.normalized()

	if target_type == CLAIM_TARGET_LIGHT_POLE and index >= 0 and index < street_poles.size():
		var pole: Dictionary = street_poles[index]
		var radius = float(pole.get("radius", STREET_POLE_COLLISION_RADIUS))
		return Vector3(
			center.x + toward_freya.x * (radius + 0.03),
			center.y + CLAIM_PEE_TARGET_POLE_HEIGHT,
			center.z + toward_freya.y * (radius + 0.03)
		)
	if target_type == CLAIM_TARGET_TREE and index >= 0 and index < trees.size():
		var tree: Dictionary = trees[index]
		var radius = float(tree.get("radius", TREE_COLLISION_SCALE))
		return Vector3(
			center.x + toward_freya.x * (radius + 0.06),
			center.y + CLAIM_PEE_TARGET_TREE_HEIGHT,
			center.z + toward_freya.y * (radius + 0.06)
		)
	if target_type == CLAIM_TARGET_FIRE_HYDRANT and index >= 0 and index < fire_hydrants.size():
		var hydrant: Dictionary = fire_hydrants[index]
		var radius = float(hydrant.get("radius", FIRE_HYDRANT_COLLISION_RADIUS))
		return Vector3(
			center.x + toward_freya.x * (radius + 0.05),
			center.y + 0.4,
			center.z + toward_freya.y * (radius + 0.05)
		)
	return center + Vector3(0.0, 0.5, 0.0)

func _freya_pee_source_world_position() -> Vector3:
	var forward: Vector3 = -freya.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var right: Vector3 = freya.global_transform.basis.x
	right.y = 0.0
	if right.length_squared() < 0.0001:
		right = forward.cross(Vector3.UP)
	right = right.normalized()

	var back = -forward
	var sway = sin(world_time * 26.0) * 0.007
	return (
		freya.global_position
		+ back * (CLAIM_PEE_SOURCE_BACK_OFFSET + sway)
		+ right * CLAIM_PEE_SOURCE_RIGHT_OFFSET
		+ Vector3.UP * (CLAIM_PEE_SOURCE_UP_OFFSET + 0.008 * sin(world_time * 17.0))
	)

func _ensure_claim_pee_nodes() -> void:
	if dynamic_root == null:
		return
	if claim_pee_stream_node == null or not is_instance_valid(claim_pee_stream_node):
		claim_pee_stream_node = Node3D.new()
		claim_pee_stream_segments.clear()
		for i in range(7):
			var segment = MeshInstance3D.new()
			var stream_mesh := CylinderMesh.new()
			stream_mesh.top_radius = CLAIM_PEE_STREAM_RADIUS * 0.76
			stream_mesh.bottom_radius = CLAIM_PEE_STREAM_RADIUS
			stream_mesh.height = 0.26
			segment.mesh = stream_mesh
			segment.material_override = claim_pee_stream_material
			segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			segment.visible = false
			claim_pee_stream_node.add_child(segment)
			claim_pee_stream_segments.append(segment)
		claim_pee_stream_node.visible = false
		dynamic_root.add_child(claim_pee_stream_node)
	if claim_pee_splash_node == null or not is_instance_valid(claim_pee_splash_node):
		claim_pee_splash_node = MeshInstance3D.new()
		var splash_mesh := SphereMesh.new()
		splash_mesh.radius = 0.28
		splash_mesh.height = 0.56
		claim_pee_splash_node.mesh = splash_mesh
		claim_pee_splash_node.material_override = claim_pee_splash_material
		claim_pee_splash_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		claim_pee_splash_node.visible = false
		dynamic_root.add_child(claim_pee_splash_node)

func _hide_claim_pee_effect() -> void:
	if claim_pee_stream_node != null and is_instance_valid(claim_pee_stream_node):
		claim_pee_stream_node.visible = false
	for seg in claim_pee_stream_segments:
		if seg != null and is_instance_valid(seg):
			seg.visible = false
	if claim_pee_splash_node != null and is_instance_valid(claim_pee_splash_node):
		claim_pee_splash_node.visible = false

func _quadratic_point(a: Vector3, b: Vector3, c: Vector3, t: float) -> Vector3:
	var omt = 1.0 - t
	return a * omt * omt + b * 2.0 * omt * t + c * t * t

func _place_claim_pee_stream(start_pos: Vector3, end_pos: Vector3, radius: float) -> void:
	if claim_pee_stream_node == null or not is_instance_valid(claim_pee_stream_node):
		return
	if claim_pee_stream_segments.is_empty():
		claim_pee_stream_node.visible = false
		return

	var delta = end_pos - start_pos
	var planar = Vector2(delta.x, delta.z).length()
	if planar < 0.03:
		claim_pee_stream_node.visible = false
		for seg in claim_pee_stream_segments:
			if seg != null and is_instance_valid(seg):
				seg.visible = false
		return

	var apex_height = maxf(start_pos.y, end_pos.y) + 0.14 + planar * 0.23
	var control = (start_pos + end_pos) * 0.5 + Vector3.UP * (apex_height - ((start_pos.y + end_pos.y) * 0.5))
	var count = claim_pee_stream_segments.size()
	for i in range(count):
		var seg = claim_pee_stream_segments[i]
		if seg == null or not is_instance_valid(seg):
			continue
		var t0 = float(i) / float(count)
		var t1 = float(i + 1) / float(count)
		var p0 = _quadratic_point(start_pos, control, end_pos, t0)
		var p1 = _quadratic_point(start_pos, control, end_pos, t1)
		var segment = p1 - p0
		var length = segment.length()
		if length < 0.001:
			seg.visible = false
			continue
		var dir = segment / length
		var x_axis = Vector3.UP.cross(dir)
		if x_axis.length_squared() < 0.0001:
			x_axis = Vector3.RIGHT
		x_axis = x_axis.normalized()
		var z_axis = dir.cross(x_axis).normalized()
		var basis = Basis(x_axis, dir, z_axis).orthonormalized()
		seg.global_transform = Transform3D(basis, (p0 + p1) * 0.5)
		var cyl := seg.mesh as CylinderMesh
		if cyl != null:
			var taper = lerpf(1.0, 0.68, t0)
			cyl.height = length
			cyl.top_radius = radius * 0.74 * taper
			cyl.bottom_radius = radius * taper
		seg.visible = true
	claim_pee_stream_node.visible = true

func _update_claim_pee_effect(delta: float) -> void:
	var can_stream = (
		Input.is_action_pressed("claim")
		and active_claim_target_type != CLAIM_TARGET_NONE
		and active_claim_target_index >= 0
		and freya != null
	)
	if not can_stream:
		_hide_claim_pee_effect()
		return

	var impact_pos = _claim_target_pee_world_position(active_claim_target_type, active_claim_target_index)
	var to_target = Vector3(impact_pos.x - freya.global_position.x, 0.0, impact_pos.z - freya.global_position.z)
	if to_target.length_squared() < 0.0001:
		_hide_claim_pee_effect()
		return
	var face_away = -to_target.normalized()
	if freya.has_method("force_face_direction"):
		freya.call("force_face_direction", face_away, delta * 3.4)

	_ensure_claim_pee_nodes()
	if claim_pee_stream_node == null or claim_pee_splash_node == null:
		return

	var source_pos = _freya_pee_source_world_position()
	var flow_wobble = Vector3(
		sin(world_time * 33.0) * 0.012,
		sin(world_time * 29.0) * 0.005,
		cos(world_time * 31.0) * 0.012
	)
	var stream_end = impact_pos + flow_wobble
	var flow_radius = CLAIM_PEE_STREAM_RADIUS * (0.9 + 0.22 * (0.5 + 0.5 * sin(world_time * 37.0)))
	_place_claim_pee_stream(source_pos, stream_end, flow_radius)

	claim_pee_splash_node.global_position = impact_pos + Vector3(0.0, 0.015, 0.0)
	var splash_scale = 0.1 + 0.05 * (0.5 + 0.5 * sin(world_time * 24.0))
	claim_pee_splash_node.scale = Vector3(splash_scale, 0.15, splash_scale)
	claim_pee_splash_node.visible = true

func _update_claiming(delta: float) -> void:
	var prev_type = active_claim_target_type
	var prev_index = active_claim_target_index

	if not Input.is_action_pressed("claim"):
		_reset_claim_progress(prev_type, prev_index)
		active_claim_target_type = CLAIM_TARGET_NONE
		active_claim_target_index = -1
		return

	var target = _find_nearest_claim_target()
	if Input.is_action_just_pressed("claim"):
		var dumpster_idx = _find_nearest_dumpster_index()
		var claim_dist_sq = float(target.get("dist_sq", CLAIM_RANGE * CLAIM_RANGE + 1.0))
		if dumpster_idx >= 0:
			var dump_pos: Vector2 = dumpsters[dumpster_idx].get("pos", Vector2.ZERO)
			var freya_pos = Vector2(freya.global_position.x, freya.global_position.z)
			var dump_dist_sq = freya_pos.distance_squared_to(dump_pos)
			if (not bool(target.get("found", false))) or dump_dist_sq < claim_dist_sq:
				_reset_claim_progress(prev_type, prev_index)
				active_claim_target_type = CLAIM_TARGET_NONE
				active_claim_target_index = -1
				_try_search_dumpster(dumpster_idx)
				return

	if not bool(target.get("found", false)):
		_reset_claim_progress(prev_type, prev_index)
		active_claim_target_type = CLAIM_TARGET_NONE
		active_claim_target_index = -1
		if Input.is_action_just_pressed("claim"):
			_show_status("No tree, pole, hydrant, or dumpster in range", 0.95)
		return

	var target_type = int(target.get("type", CLAIM_TARGET_NONE))
	var target_index = int(target.get("index", -1))
	if prev_type != CLAIM_TARGET_NONE and (prev_type != target_type or prev_index != target_index):
		_reset_claim_progress(prev_type, prev_index)

	active_claim_target_type = target_type
	active_claim_target_index = target_index

	var claimed_now = false
	if target_type == CLAIM_TARGET_LIGHT_POLE:
		var pole: Dictionary = street_poles[target_index]
		var progress = clampf(float(pole.get("claim_progress", 0.0)) + delta / CLAIM_FILL_TIME, 0.0, 1.0)
		pole["claim_progress"] = progress
		if progress >= 1.0 and not bool(pole.get("claimed", false)):
			pole["claimed"] = true
			pole["claim_progress"] = 1.0
			claimed_now = true
		street_poles[target_index] = pole
	elif target_type == CLAIM_TARGET_TREE:
		var tree: Dictionary = trees[target_index]
		var progress = clampf(float(tree.get("claim_progress", 0.0)) + delta / CLAIM_FILL_TIME, 0.0, 1.0)
		tree["claim_progress"] = progress
		if progress >= 1.0 and not bool(tree.get("claimed", false)):
			tree["claimed"] = true
			tree["claim_progress"] = 1.0
			claimed_now = true
		trees[target_index] = tree
	elif target_type == CLAIM_TARGET_FIRE_HYDRANT:
		var hydrant: Dictionary = fire_hydrants[target_index]
		var progress = clampf(float(hydrant.get("claim_progress", 0.0)) + delta / CLAIM_FILL_TIME, 0.0, 1.0)
		hydrant["claim_progress"] = progress
		if progress >= 1.0 and not bool(hydrant.get("claimed", false)):
			hydrant["claimed"] = true
			hydrant["claim_progress"] = 1.0
			claimed_now = true
		fire_hydrants[target_index] = hydrant

	if not claimed_now:
		return

	_ensure_claim_ring_for_target(target_type, target_index)
	active_claim_target_type = CLAIM_TARGET_NONE
	active_claim_target_index = -1
	if target_type == CLAIM_TARGET_LIGHT_POLE:
		if _claimed_light_pole_count() >= OBJECTIVE_CLAIM_TARGET:
			_show_status("Objective complete: Claim 10 light poles", 1.35)
		else:
			_show_status("Light pole claimed!", 0.95)
	elif target_type == CLAIM_TARGET_TREE:
		if _claimed_tree_count() >= OBJECTIVE_CLAIM_TARGET:
			_show_status("Objective complete: Claim 10 trees", 1.35)
		else:
			_show_status("Tree claimed!", 0.95)
	else:
		if _claimed_fire_hydrant_count() >= OBJECTIVE_HYDRANT_TARGET:
			_show_status("Objective complete: Claim 8 fire hydrants", 1.35)
		else:
			_show_status("Fire hydrant claimed!", 0.95)

func _update_claim_rings() -> void:
	var pulse_base = 0.98 + 0.2 * (0.5 + 0.5 * sin(world_time * CLAIM_RING_PULSE_SPEED))

	for i in range(street_poles.size()):
		var pole: Dictionary = street_poles[i]
		var ring = pole.get("claim_ring", null)
		if ring == null or not is_instance_valid(ring):
			continue
		var ring_node := ring as Node3D
		var claimed = bool(pole.get("claimed", false))
		ring_node.visible = claimed
		if not claimed:
			continue
		var pulse = pulse_base + 0.09 * sin(world_time * 2.2 + float(i) * 0.41)
		ring_node.scale = Vector3(pulse, 1.0, pulse)

	for i in range(trees.size()):
		var tree: Dictionary = trees[i]
		var ring = tree.get("claim_ring", null)
		if ring == null or not is_instance_valid(ring):
			continue
		var ring_node := ring as Node3D
		var claimed = bool(tree.get("claimed", false))
		ring_node.visible = claimed
		if not claimed:
			continue
		var pulse = pulse_base + 0.09 * sin(world_time * 2.0 + float(i) * 0.37)
		ring_node.scale = Vector3(pulse, 1.0, pulse)

	for i in range(fire_hydrants.size()):
		var hydrant: Dictionary = fire_hydrants[i]
		var ring = hydrant.get("claim_ring", null)
		if ring == null or not is_instance_valid(ring):
			continue
		var ring_node := ring as Node3D
		var claimed = bool(hydrant.get("claimed", false))
		ring_node.visible = claimed
		if not claimed:
			continue
		var pulse = pulse_base + 0.1 * sin(world_time * 2.4 + float(i) * 0.35)
		ring_node.scale = Vector3(pulse, 1.0, pulse)

func _hide_claim_meter() -> void:
	if claim_meter_panel != null:
		claim_meter_panel.visible = false

func _update_claim_meter_overlay() -> void:
	if claim_meter_panel == null or claim_meter_label == null or claim_meter_bar == null:
		return
	if camera_node == null:
		_hide_claim_meter()
		return
	if active_claim_target_type == CLAIM_TARGET_NONE or active_claim_target_index < 0:
		_hide_claim_meter()
		return
	if not Input.is_action_pressed("claim"):
		_hide_claim_meter()
		return

	var target_world = _claim_target_world_position(active_claim_target_type, active_claim_target_index)
	if camera_node.is_position_behind(target_world):
		_hide_claim_meter()
		return

	var screen_pos = camera_node.unproject_position(target_world)
	var view_size = get_viewport().get_visible_rect().size
	var panel_size = claim_meter_panel.size
	claim_meter_panel.position = Vector2(
		clampf(screen_pos.x - panel_size.x * 0.5, 8.0, view_size.x - panel_size.x - 8.0),
		clampf(screen_pos.y - 58.0, 8.0, view_size.y - panel_size.y - 8.0)
	)
	claim_meter_bar.value = _claim_progress_for_target(active_claim_target_type, active_claim_target_index) * 100.0
	if active_claim_target_type == CLAIM_TARGET_LIGHT_POLE:
		claim_meter_label.text = "Claiming Light Pole"
	elif active_claim_target_type == CLAIM_TARGET_TREE:
		claim_meter_label.text = "Claiming Tree"
	else:
		claim_meter_label.text = "Claiming Fire Hydrant"
	claim_meter_panel.visible = true

func _remove_stick_entry_for_node(node: Node3D) -> void:
	if node == null:
		return
	for i in range(sticks.size() - 1, -1, -1):
		var item: Dictionary = sticks[i]
		if item.get("node", null) == node:
			sticks.remove_at(i)

func _update_carried_stick_pose() -> void:
	if carried_stick == null:
		freya_has_stick = false
		return
	if not is_instance_valid(carried_stick):
		carried_stick = null
		freya_has_stick = false
		return
	if freya == null:
		return

	if carried_stick.get_parent() != dynamic_root:
		carried_stick.reparent(dynamic_root, true)

	var move_forward: Vector3 = freya_move_dir
	move_forward.y = 0.0
	if move_forward.length_squared() < 0.0001:
		move_forward = -freya.global_transform.basis.z
		move_forward.y = 0.0
	if move_forward.length_squared() < 0.0001:
		move_forward = Vector3.FORWARD
	move_forward = move_forward.normalized()

	var move_right := move_forward.cross(Vector3.UP)
	if move_right.length_squared() < 0.0001:
		move_right = freya.global_transform.basis.x
		move_right.y = 0.0
	if move_right.length_squared() < 0.0001:
		move_right = Vector3.RIGHT
	move_right = move_right.normalized()

	var up := Vector3.UP
	var pitch := deg_to_rad(STICK_MOUTH_PITCH_DEG)
	var mouth_forward := (move_forward * cos(pitch) + up * sin(pitch)).normalized()

	# The stick mesh length is on local +X; align that axis side-to-side across the muzzle.
	var stick_axis := move_right
	var mouth_z_axis := -mouth_forward
	var mouth_up_axis := mouth_z_axis.cross(stick_axis)
	if mouth_up_axis.length_squared() < 0.0001:
		mouth_up_axis = up
	mouth_up_axis = mouth_up_axis.normalized()

	var mouth_pos = freya.head_world_position()
	if freya != null and freya.has_method("mouth_world_position"):
		mouth_pos = freya.call("mouth_world_position")
	mouth_pos += move_forward * STICK_MOUTH_FORWARD_OFFSET
	mouth_pos += move_right * STICK_MOUTH_RIGHT_OFFSET
	mouth_pos += up * STICK_MOUTH_UP_OFFSET

	carried_stick.global_transform = Transform3D(Basis(stick_axis, mouth_up_axis, mouth_z_axis).orthonormalized(), mouth_pos)
	freya_has_stick = true

func _try_interact() -> void:
	if carried_stick != null and is_instance_valid(carried_stick):
		freya_has_stick = true
		if _try_eat_bone(false):
			return
		if _try_eat_store_food(false):
			return
		if _try_eat_poop(false):
			return
		_drop_carried_stick()
		return
	freya_has_stick = false
	if _try_pickup_stick():
		return
	if _try_eat_bone(false):
		return
	if _try_eat_store_food(false):
		return
	_try_eat_poop(true)

func _try_pickup_stick() -> bool:
	if carried_stick != null and not is_instance_valid(carried_stick):
		carried_stick = null
		freya_has_stick = false
	if freya_has_stick or carried_stick != null:
		return false

	var best_idx = -1
	var best_d = 9999.0
	var freya_pos = Vector2(freya.global_position.x, freya.global_position.z)
	for i in range(sticks.size()):
		var item: Dictionary = sticks[i]
		var d = freya_pos.distance_to(item.get("pos", Vector2.ZERO))
		if d < best_d:
			best_d = d
			best_idx = i

	if best_idx < 0 or best_d > STICK_PICKUP_RANGE:
		return false

	var picked: Dictionary = sticks[best_idx]
	var node: Node3D = picked.get("node", null)
	sticks.remove_at(best_idx)
	if node == null:
		return false

	_remove_stick_entry_for_node(node)
	if node.get_parent() != dynamic_root:
		node.reparent(dynamic_root, true)
	carried_stick = node
	freya_has_stick = true
	_update_carried_stick_pose()
	_show_status("Picked up a stick in mouth", 0.8)
	return true

func _drop_carried_stick() -> bool:
	if carried_stick == null or not is_instance_valid(carried_stick):
		carried_stick = null
		freya_has_stick = false
		return false

	var forward: Vector3 = -freya.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	forward = forward.normalized()

	var drop_pos = freya.global_position + forward * 1.05
	if not _is_walkable(drop_pos.x, drop_pos.z, 0.1) or _surface_at(Vector2(drop_pos.x, drop_pos.z)) == "road":
		drop_pos = freya.global_position + Vector3(rng.randf_range(-0.65, 0.65), 0.0, rng.randf_range(-0.65, 0.65))

	_remove_stick_entry_for_node(carried_stick)
	if carried_stick.get_parent() != dynamic_root:
		carried_stick.reparent(dynamic_root, true)
	carried_stick.global_position = Vector3(drop_pos.x, 0.03, drop_pos.z)
	carried_stick.rotation_degrees = Vector3(rng.randf_range(-8.0, 8.0), rng.randf_range(0.0, 360.0), 90.0 + rng.randf_range(-7.0, 7.0))
	sticks.append({"node": carried_stick, "pos": Vector2(drop_pos.x, drop_pos.z)})
	carried_stick = null
	freya_has_stick = false
	_show_status("Dropped stick", 0.65)
	return true

func _try_eat_bone(show_fail_status: bool = false) -> bool:
	var best_idx = -1
	var best_d = 9999.0
	var freya_pos = Vector2(freya.global_position.x, freya.global_position.z)
	for i in range(bones.size()):
		var item: Dictionary = bones[i]
		var d = freya_pos.distance_to(item.get("pos", Vector2.ZERO))
		if d < best_d:
			best_d = d
			best_idx = i
	if best_idx < 0 or best_d > BONE_PICKUP_RANGE:
		if show_fail_status:
			_show_status("No bone nearby", 0.8)
		return false

	var eaten: Dictionary = bones[best_idx]
	var node: Node3D = eaten.get("node", null)
	if node != null and is_instance_valid(node):
		node.queue_free()
	bones.remove_at(best_idx)

	freya_strength = clamp(freya_strength + 18.0, 0.0, 100.0)
	freya_hunger = clamp(freya_hunger - 3.0, 0.0, 100.0)
	_show_status("Crunch! Strength increased", 0.95)
	return true

func _try_eat_store_food(show_fail_status: bool = false) -> bool:
	var best_idx = -1
	var best_d = 9999.0
	var freya_pos = Vector2(freya.global_position.x, freya.global_position.z)
	for i in range(store_foods.size()):
		var item: Dictionary = store_foods[i]
		var d = freya_pos.distance_to(item.get("pos", Vector2.ZERO))
		if d < best_d:
			best_d = d
			best_idx = i
	if best_idx < 0 or best_d > 1.55:
		if show_fail_status:
			_show_status("No food nearby", 0.75)
		return false

	var eaten: Dictionary = store_foods[best_idx]
	var node: Node3D = eaten.get("node", null)
	if node != null and is_instance_valid(node):
		node.queue_free()
	store_foods.remove_at(best_idx)

	freya_hunger = clamp(freya_hunger - rng.randf_range(9.0, 14.0), 0.0, 100.0)
	freya_vomit = clamp(freya_vomit + rng.randf_range(16.0, 30.0), 0.0, 100.0)
	_show_status("Ate random store food", 0.9)
	return true

func _try_eat_poop(show_fail_status: bool = true) -> bool:
	var best_idx = -1
	var best_d = 9999.0
	var freya_pos = Vector2(freya.global_position.x, freya.global_position.z)

	for i in range(poops.size()):
		var item: Dictionary = poops[i]
		var d = freya_pos.distance_to(item["pos"])
		if d < best_d:
			best_d = d
			best_idx = i

	if best_idx < 0 or best_d > 1.5:
		if show_fail_status:
			_show_status("No food, bone, or poop nearby", 0.95)
		return false

	var eaten: Dictionary = poops[best_idx]
	var node: Node3D = eaten["node"]
	node.queue_free()
	poops.remove_at(best_idx)

	freya_hunger = clamp(freya_hunger - 5.0, 0.0, 100.0)
	freya_vomit = clamp(freya_vomit + 22.0, 0.0, 100.0)
	_show_status("Yum...", 0.7)
	return true

func _try_vomit() -> void:
	if freya_vomit < 100.0:
		_show_status("Vomit meter not full", 0.9)
		return

	var vomit_data = _freya_vomit_origin_and_direction()
	var vomit_origin: Vector3 = vomit_data.get("origin", freya.global_position + Vector3(0.0, 0.38, 0.0))
	var forward: Vector3 = vomit_data.get("forward", Vector3.FORWARD)
	var vomit_start = Vector2(vomit_origin.x, vomit_origin.z)
	var vomit_end = vomit_start + Vector2(forward.x, forward.z) * 1.45
	var hit_dog = _vomit_hits_any_dog(vomit_start, vomit_end)

	var puddle_pos = vomit_origin + forward * 0.75
	if not _is_walkable(puddle_pos.x, puddle_pos.z, 0.08):
		puddle_pos = freya.global_position + forward * 0.85
	var puddle = _create_vomit_puddle_node()
	puddle.position = Vector3(puddle_pos.x, 0.02, puddle_pos.z)
	dynamic_root.add_child(puddle)
	vomit_puddles.append({"node": puddle, "pos": Vector2(puddle_pos.x, puddle_pos.z), "ttl": 24.0})

	freya_vomit = 0.0
	freya_vomit_timer = 0.65
	if hit_dog and not objective_puke_on_dog_complete:
		objective_puke_on_dog_complete = true
		_show_status("Objective complete: Puke on another dog", 1.4)
	elif hit_dog:
		_show_status("Direct hit!", 0.9)
	else:
		_show_status("Bleaaargh!", 1.0)

func _freya_vomit_origin_and_direction() -> Dictionary:
	var origin = freya.global_position + Vector3(0.0, 0.38, 0.0)
	var forward = -freya.global_transform.basis.z
	if freya != null and freya.has_method("mouth_world_position"):
		origin = freya.call("mouth_world_position")
	var head = origin - forward * 0.3
	if freya != null and freya.has_method("head_world_position"):
		head = freya.call("head_world_position")
	var mouth_forward = origin - head
	mouth_forward.y = 0.0
	if mouth_forward.length_squared() > 0.0001:
		forward = mouth_forward
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	return {"origin": origin, "forward": forward}

func _vomit_hits_any_dog(start: Vector2, stop: Vector2) -> bool:
	var hit_any = false
	for d in dogs:
		var dog = d.get("node", null)
		if dog == null:
			continue
		var center = Vector2(dog.global_position.x, dog.global_position.z)
		var hit = _segment_circle_intersection_2d(start, stop, center, 0.9)
		if bool(hit.get("hit", false)):
			hit_any = true
			_spawn_bark_pulse(dog.head_world_position(), Color(0.92, 0.97, 0.79, 0.84))
	return hit_any

func _create_vomit_puddle_node() -> Node3D:
	var root = Node3D.new()

	var smear = MeshInstance3D.new()
	var smear_mesh = CylinderMesh.new()
	smear_mesh.top_radius = rng.randf_range(0.16, 0.24)
	smear_mesh.bottom_radius = smear_mesh.top_radius * rng.randf_range(1.1, 1.35)
	smear_mesh.height = rng.randf_range(0.04, 0.07)
	smear.mesh = smear_mesh
	smear.position = Vector3(0.0, 0.012, 0.0)
	smear.scale = Vector3(rng.randf_range(1.15, 1.75), 1.0, rng.randf_range(0.92, 1.42))
	smear.material_override = vomit_material_a
	root.add_child(smear)

	var chunk_count = rng.randi_range(7, 11)
	for i in range(chunk_count):
		var chunk = MeshInstance3D.new()
		var chunk_mesh = SphereMesh.new()
		chunk_mesh.radius = rng.randf_range(0.04, 0.1)
		chunk_mesh.height = chunk_mesh.radius * 2.0
		chunk.mesh = chunk_mesh
		var dist = rng.randf_range(0.01, 0.24)
		var angle = rng.randf_range(0.0, TAU)
		chunk.position = Vector3(cos(angle) * dist, rng.randf_range(0.014, 0.052), sin(angle) * dist)
		chunk.scale = Vector3(rng.randf_range(0.75, 1.7), rng.randf_range(0.32, 1.0), rng.randf_range(0.75, 1.65))
		chunk.material_override = vomit_material_b if i % 3 == 0 else vomit_material_a
		root.add_child(chunk)
	return root

func _update_poops(delta: float) -> void:
	poop_spawn_timer -= delta
	if poop_spawn_timer <= 0.0:
		poop_spawn_timer = rng.randf_range(2.2, 4.8)
		if poops.size() < 34:
			_spawn_poop(rng.randf() < 0.62)

func _update_vomit_puddles(delta: float) -> void:
	for i in range(vomit_puddles.size() - 1, -1, -1):
		var p: Dictionary = vomit_puddles[i]
		p["ttl"] = float(p["ttl"]) - delta
		if float(p["ttl"]) <= 0.0:
			var node: Node3D = p["node"]
			node.queue_free()
			vomit_puddles.remove_at(i)
		else:
			vomit_puddles[i] = p

func _update_bark_pulses(delta: float) -> void:
	for i in range(bark_pulses.size() - 1, -1, -1):
		var pulse: Dictionary = bark_pulses[i]
		pulse["age"] = float(pulse["age"]) + delta
		var t = float(pulse["age"]) / float(pulse["ttl"])
		if t >= 1.0:
			var node: MeshInstance3D = pulse["node"]
			node.queue_free()
			bark_pulses.remove_at(i)
			continue

		var mesh: MeshInstance3D = pulse["node"]
		mesh.scale = Vector3.ONE * lerp(0.45, 2.0, t)
		mesh.position.y += delta * 0.15

		var mat: StandardMaterial3D = pulse["mat"]
		var c = mat.albedo_color
		c.a = 1.0 - t
		mat.albedo_color = c
		bark_pulses[i] = pulse

func _update_store_entry_indicators(delta: float = 0.016) -> void:
	if delta > 0.0 and int(world_time * 32.0) % 2 != 0:
		return
	for i in range(store_entry_indicators.size() - 1, -1, -1):
		var item: Dictionary = store_entry_indicators[i]
		var marker: Node3D = item.get("node", null)
		if marker == null or not is_instance_valid(marker):
			store_entry_indicators.remove_at(i)
			continue
		var base: Vector3 = item.get("base", Vector3.ZERO)
		var front_sign = float(item.get("front_sign", 1.0))
		var phase = float(item.get("phase", 0.0))
		var t = world_time * 2.4 + phase
		var bob = 0.06 * sin(t * 1.7)
		var glide = (0.5 + 0.5 * sin(t)) * 0.24
		marker.position = base + Vector3(0.0, bob, -front_sign * glide)

func _point_in_rect_list(rects: Array, p: Vector2, pad: float = 0.0) -> bool:
	for item in rects:
		if item is Rect2:
			var rect: Rect2 = item
			if rect.grow(pad).has_point(p):
				return true
	return false

func _is_inside_store_index(store_idx: int, p: Vector2) -> bool:
	if store_idx < 0 or store_idx >= buildings.size():
		return false
	var b: Dictionary = buildings[store_idx]
	var interior_rect: Rect2 = b.get("store_interior_rect", Rect2())
	if interior_rect.size.x > 0.0 and interior_rect.size.y > 0.0 and interior_rect.grow(0.18).has_point(p):
		return true
	var fp: Rect2 = b.get("footprint", Rect2())
	if fp.size.x <= 0.0 or fp.size.y <= 0.0:
		return false
	var entry_pos: Vector2 = b.get("entry_pos", Vector2(-1.0, -1.0))
	if (
		entry_pos.x >= 0.0
		and entry_pos.y >= 0.0
		and fp.grow(0.18).has_point(p)
		and p.distance_to(entry_pos) <= 1.7
	):
		return true
	if fp.grow(-0.08).has_point(p):
		var blockers = b.get("store_walk_blockers", [])
		return not _point_in_rect_list(blockers, p, 0.1)
	return false

func _is_inside_store_interior(store_idx: int, p: Vector2) -> bool:
	if store_idx < 0 or store_idx >= buildings.size():
		return false
	var b: Dictionary = buildings[store_idx]
	var interior_rect: Rect2 = b.get("store_interior_rect", Rect2())
	if interior_rect.size.x <= 0.0 or interior_rect.size.y <= 0.0:
		return false
	return interior_rect.grow(0.08).has_point(p)

func _store_index_for_interior_point(p: Vector2) -> int:
	if store_building_indices.is_empty():
		return -1
	for idx in store_building_indices:
		if idx < 0 or idx >= buildings.size():
			continue
		if _is_inside_store_interior(idx, p):
			return idx
	return -1

func _store_index_for_visual_focus(p: Vector2) -> int:
	var interior_idx = _store_index_for_interior_point(p)
	if interior_idx >= 0:
		return interior_idx
	if active_store_index >= 0 and active_store_index < buildings.size():
		var active_b: Dictionary = buildings[active_store_index]
		var fp: Rect2 = active_b.get("footprint", Rect2())
		if fp.size.x > 0.0 and fp.size.y > 0.0 and fp.grow(0.32).has_point(p):
			if _is_inside_store_index(active_store_index, p):
				return active_store_index
	return _store_index_containing_freya()

func _store_index_containing_freya() -> int:
	if freya == null or store_building_indices.is_empty():
		return -1
	var p = Vector2(freya.global_position.x, freya.global_position.z)
	var fallback_idx = -1
	var fallback_dist_sq = 1000000.0
	for idx in store_building_indices:
		if idx < 0 or idx >= buildings.size():
			continue
		if _is_inside_store_index(idx, p):
			return idx
		var b: Dictionary = buildings[idx]
		var fp: Rect2 = b.get("footprint", Rect2())
		if fp.size.x <= 0.0 or fp.size.y <= 0.0:
			continue
		var entry_pos: Vector2 = b.get("entry_pos", Vector2(-1.0, -1.0))
		var near_entry = (
			entry_pos.x >= 0.0
			and entry_pos.y >= 0.0
			and p.distance_to(entry_pos) <= 1.9
		)
		if fp.grow(-0.08).has_point(p):
			var blockers = b.get("store_walk_blockers", [])
			if (not _point_in_rect_list(blockers, p, 0.1)) or near_entry:
				return idx
			if entry_pos.x >= 0.0 and entry_pos.y >= 0.0:
				var d_sq = p.distance_squared_to(entry_pos)
				if d_sq < fallback_dist_sq:
					fallback_dist_sq = d_sq
					fallback_idx = idx
		if near_entry and fp.grow(0.22).has_point(p):
			var near_d_sq = p.distance_squared_to(entry_pos)
			if near_d_sq < fallback_dist_sq:
				fallback_dist_sq = near_d_sq
				fallback_idx = idx
	return fallback_idx

func _apply_store_focus_visuals() -> void:
	var inside_store = false
	var active_idx = -1
	if freya != null and active_store_index >= 0 and active_store_index < buildings.size():
		var p = Vector2(freya.global_position.x, freya.global_position.z)
		if _is_inside_store_index(active_store_index, p):
			inside_store = true
			active_idx = active_store_index
	if store_focus_overlay != null:
		store_focus_overlay.visible = inside_store
	for idx in store_building_indices:
		if idx < 0 or idx >= buildings.size():
			continue
		var b: Dictionary = buildings[idx]
		var shell: Node3D = b.get("node", null)
		var interior_root: Node3D = b.get("store_interior_root", null)
		var is_active = inside_store and idx == active_idx
		if shell != null and is_instance_valid(shell):
			shell.visible = not is_active
		var roof_parts: Array = b.get("roof_parts", [])
		for part in roof_parts:
			if part is Node3D and is_instance_valid(part as Node3D):
				(part as Node3D).visible = not is_active
		if interior_root != null and is_instance_valid(interior_root):
			interior_root.visible = is_active

func _update_store_focus(delta: float) -> void:
	var store_idx = -1
	if freya != null:
		var p = Vector2(freya.global_position.x, freya.global_position.z)
		store_idx = _store_index_for_visual_focus(p)
	if store_idx != active_store_index:
		active_store_index = store_idx
	_apply_store_focus_visuals()

func _has_back_alley_rowhouse_corridor() -> bool:
	for alley in alleys:
		if alley.size.x <= alley.size.y or alley.size.x < 10.0:
			continue

		var north_count = 0
		var south_count = 0
		var north_edge = alley.position.y
		var south_edge = alley.position.y + alley.size.y

		for b in buildings:
			var fp: Rect2 = b["footprint"]
			var overlap_x = min(fp.position.x + fp.size.x, alley.position.x + alley.size.x) - max(fp.position.x, alley.position.x)
			if overlap_x < 1.0:
				continue

			var north_back = fp.position.y + fp.size.y
			if absf(north_back - north_edge) <= 0.26 and not bool(b.get("front_is_south", true)):
				north_count += 1

			var south_back = fp.position.y
			if absf(south_back - south_edge) <= 0.26 and bool(b.get("front_is_south", false)):
				south_count += 1

			if north_count >= 3 and south_count >= 3:
				return true
	return false

func _aabb_corners(aabb: AABB) -> Array[Vector3]:
	var p = aabb.position
	var s = aabb.size
	return [
		p,
		p + Vector3(s.x, 0.0, 0.0),
		p + Vector3(0.0, s.y, 0.0),
		p + Vector3(0.0, 0.0, s.z),
		p + Vector3(s.x, s.y, 0.0),
		p + Vector3(s.x, 0.0, s.z),
		p + Vector3(0.0, s.y, s.z),
		p + s
	]

func _building_ground_alignment_ok() -> bool:
	for b in buildings:
		var node: Node3D = b.get("node", null)
		if node == null:
			continue

		var min_y = 1000000.0
		var has_mesh = false
		var stack: Array = [node]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			if n is MeshInstance3D:
				var mi = n as MeshInstance3D
				if mi.mesh != null:
					has_mesh = true
					var local_aabb: AABB = mi.mesh.get_aabb().merge(mi.get_aabb())
					for c in _aabb_corners(local_aabb):
						var wp = mi.global_transform * c
						min_y = minf(min_y, wp.y)
			for child in n.get_children():
				stack.append(child)

		if has_mesh and (min_y < -0.03 or min_y > 0.12):
			return false
	return true

func _alleys_only_between_rows_ok() -> bool:
	for alley in alleys:
		if alley.size.x > alley.size.y:
			# Main rowhouse alley corridor.
			if alley.size.y < ALLEY_W - 0.3 or alley.size.y > ALLEY_W + 0.5:
				return false
		else:
			# Only short street connectors are allowed on the vertical axis.
			if alley.size.y > 1.6 or alley.size.x > 1.2:
				return false
	return true

func _dumpsters_on_alleys_ok() -> bool:
	var long_alley_count = 0
	for alley in alleys:
		if alley.size.x > alley.size.y and alley.size.x >= 9.0:
			long_alley_count += 1
	if long_alley_count <= 0:
		return false
	if dumpsters.size() < long_alley_count:
		return false

	for d in dumpsters:
		var pos: Vector2 = d.get("pos", Vector2.ZERO)
		var on_alley = false
		for alley in alleys:
			if alley.has_point(pos):
				on_alley = true
				break
		if not on_alley:
			return false
	return true

func _building_sidewalk_coverage_ok() -> bool:
	for b in buildings:
		var fp: Rect2 = b["footprint"]
		var cx = fp.position.x + fp.size.x * 0.5
		var cz = fp.position.y + fp.size.y * 0.5
		var d = minf(0.5, BUILDING_SIDEWALK_W * 0.6)
		var probes = [
			Vector2(cx, fp.position.y - d),
			Vector2(cx, fp.position.y + fp.size.y + d),
			Vector2(fp.position.x - d, cz),
			Vector2(fp.position.x + fp.size.x + d, cz)
		]
		var hits = 0
		for p in probes:
			if not _point_in_map(p):
				continue
			if _surface_at(p) == "sidewalk":
				hits += 1
		if hits < 3:
			return false
	return true

func _street_poles_lining_streets_ok() -> bool:
	if street_poles.size() < 40:
		return false

	var road_targets = 0
	var road_hits = 0
	for r in roads:
		var lane_len = maxf(r.size.x, r.size.y)
		if lane_len < 18.0:
			continue
		road_targets += 1

		var count = 0
		for pole in street_poles:
			var pos: Vector2 = pole.get("pos", Vector2.ZERO)
			if r.grow(SIDEWALK_W + 0.45).has_point(pos):
				count += 1
		if count >= 2:
			road_hits += 1

	if road_targets > 0 and road_hits < maxi(4, int(ceil(float(road_targets) * 0.75))):
		return false

	for pole in street_poles:
		var pos: Vector2 = pole.get("pos", Vector2.ZERO)
		if _surface_at(pos) != "sidewalk":
			return false
		var near_road = false
		for r in roads:
			if r.grow(SIDEWALK_W + 0.55).has_point(pos):
				near_road = true
				break
		if not near_road:
			return false
	return true

func _building_front_buffer_order_ok() -> bool:
	var checked = 0
	var passed = 0
	for b in buildings:
		var fp: Rect2 = b["footprint"]
		var front_is_south = bool(b.get("front_is_south", true))
		var dir = 1.0 if front_is_south else -1.0
		var front_z = fp.position.y + fp.size.y if front_is_south else fp.position.y
		var cx = fp.position.x + fp.size.x * 0.5

		var p_sidewalk = Vector2(cx, front_z + dir * (BUILDING_SIDEWALK_W * 0.45))
		var p_grass = Vector2(cx, front_z + dir * (BUILDING_SIDEWALK_W + 0.5))
		var p_street_sidewalk = Vector2(cx, front_z + dir * (ROW_FRONT_SETBACK - SIDEWALK_W * 0.45))
		var p_road = Vector2(cx, front_z + dir * (ROW_FRONT_SETBACK + ROAD_W * 0.35))

		if not (_point_in_map(p_sidewalk) and _point_in_map(p_grass) and _point_in_map(p_street_sidewalk) and _point_in_map(p_road)):
			continue

		checked += 1
		var ok = _surface_at(p_sidewalk) == "sidewalk" and _surface_at(p_grass) == "grass" and _surface_at(p_street_sidewalk) == "sidewalk" and _surface_at(p_road) == "road"
		if ok:
			passed += 1

	if checked == 0:
		return true
	return float(passed) / float(checked) >= 0.75

func _alley_accessibility_ok() -> bool:
	for alley in alleys:
		if alley.size.x <= alley.size.y or alley.size.x < 9.0:
			continue
		var cz = alley.position.y + alley.size.y * 0.5
		var walkable_samples = 0
		for t in [0.15, 0.3, 0.5, 0.7, 0.85]:
			var px = alley.position.x + alley.size.x * float(t)
			if _is_walkable(px, cz, FREYA_COLLISION_RADIUS) and _surface_at(Vector2(px, cz)) == "road":
				walkable_samples += 1
		if walkable_samples < 3:
			return false

		var left_probe = Vector2(alley.position.x + 0.35, cz)
		var right_probe = Vector2(alley.position.x + alley.size.x - 0.35, cz)
		var end_ok = _in_any_rect(roads, left_probe) or _in_any_rect(roads, right_probe) or _surface_at(left_probe) == "road" or _surface_at(right_probe) == "road"
		if not end_ok:
			return false
	return true

func _point_in_map(p: Vector2) -> bool:
	return p.x >= 0.0 and p.y >= 0.0 and p.x <= MAP_W and p.y <= MAP_H

func _road_sidewalk_coverage_ok() -> bool:
	for r in roads:
		if r.size.x > r.size.y:
			var top_y = r.position.y - SIDEWALK_W * 0.5
			var bottom_y = r.position.y + r.size.y + SIDEWALK_W * 0.5
			for t in [0.1, 0.3, 0.5, 0.7, 0.9]:
				var x = r.position.x + r.size.x * float(t)
				var p_top = Vector2(x, top_y)
				var p_bottom = Vector2(x, bottom_y)
				if _point_in_map(p_top) and not _in_any_rect(roads, p_top) and not _in_any_rect(alleys, p_top) and _surface_at(p_top) != "sidewalk":
					return false
				if _point_in_map(p_bottom) and not _in_any_rect(roads, p_bottom) and not _in_any_rect(alleys, p_bottom) and _surface_at(p_bottom) != "sidewalk":
					return false
		else:
			var left_x = r.position.x - SIDEWALK_W * 0.5
			var right_x = r.position.x + r.size.x + SIDEWALK_W * 0.5
			for t in [0.1, 0.3, 0.5, 0.7, 0.9]:
				var z = r.position.y + r.size.y * float(t)
				var p_left = Vector2(left_x, z)
				var p_right = Vector2(right_x, z)
				if _point_in_map(p_left) and not _in_any_rect(roads, p_left) and not _in_any_rect(alleys, p_left) and _surface_at(p_left) != "sidewalk":
					return false
				if _point_in_map(p_right) and not _in_any_rect(roads, p_right) and not _in_any_rect(alleys, p_right) and _surface_at(p_right) != "sidewalk":
					return false
	return true

func _nonpark_dogs_distributed() -> bool:
	var quadrants = [0, 0, 0, 0]
	for d in dogs:
		if bool(d.get("park", false)):
			continue
		var dog_node = d["node"]
		if dog_node == null:
			continue
		var pos = dog_node.global_position
		var q = 0
		if pos.x >= MAP_W * 0.5:
			q += 1
		if pos.z >= MAP_H * 0.5:
			q += 2
		quadrants[q] += 1
	var occupied = 0
	for count in quadrants:
		if int(count) > 0:
			occupied += 1
	return occupied >= 3

func _count_mesh_instances(root: Node) -> int:
	if root == null:
		return 0
	var count = 0
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			count += 1
		for c in n.get_children():
			stack.append(c)
	return count

func _run_targeted_validation_checks() -> void:
	var failures: Array[String] = []
	var saved_pos = freya.global_position
	var saved_cam_pos = camera_node.global_position
	var saved_active = active_store_index
	var saved_timer = store_focus_timer

	if store_building_indices.is_empty():
		failures.append("target_no_store_buildings")
	else:
		var idx = store_building_indices[0]
		var b: Dictionary = buildings[idx]
		var interior_rect: Rect2 = b.get("store_interior_rect", Rect2())
		if interior_rect.size.x < 0.7 or interior_rect.size.y < 0.7:
			failures.append("target_store_interior_rect_invalid")
		else:
			var center = interior_rect.position + interior_rect.size * 0.5
			freya.global_position = Vector3(center.x, freya.global_position.y, center.y)
			active_store_index = -1
			store_focus_timer = 0.0
			_update_store_focus(0.2)
			if active_store_index != idx:
				failures.append("target_store_focus_not_entering")
			var shell: Node3D = b.get("node", null)
			var interior_root: Node3D = b.get("store_interior_root", null)
			if interior_root == null or not is_instance_valid(interior_root) or not interior_root.visible:
				failures.append("target_store_interior_not_visible")
			if shell == null or not is_instance_valid(shell):
				failures.append("target_store_shell_missing")
			elif shell.visible:
				failures.append("target_store_shell_not_hidden_inside")
			if store_focus_overlay == null or not store_focus_overlay.visible:
				failures.append("target_store_overlay_not_visible")
			if interior_root != null and is_instance_valid(interior_root):
				var mesh_count = _count_mesh_instances(interior_root)
				if mesh_count < 38:
					failures.append("target_store_mesh_count_low_%d" % mesh_count)
			var fp: Rect2 = b.get("footprint", Rect2())
			var entry_pos: Vector2 = b.get("entry_pos", fp.position + fp.size * 0.5)
			var outward = (entry_pos - (fp.position + fp.size * 0.5))
			if outward.length_squared() < 0.0001:
				outward = Vector2(0.0, 1.0)
			outward = outward.normalized()
			var outside = entry_pos + outward * 2.2
			if fp.grow(0.08).has_point(outside):
				outside = entry_pos - outward * 2.2
			if _is_walkable(outside.x, outside.y, FREYA_COLLISION_RADIUS):
				freya.global_position = Vector3(outside.x, freya.global_position.y, outside.y)
				store_focus_timer = 0.0
				_update_store_focus(0.2)
				if active_store_index == idx:
					failures.append("target_store_focus_not_exiting")
				if interior_root != null and is_instance_valid(interior_root) and interior_root.visible:
					failures.append("target_store_interior_still_visible_after_exit")
				if shell != null and is_instance_valid(shell) and not shell.visible:
					failures.append("target_store_shell_not_restored_after_exit")
				if store_focus_overlay != null and store_focus_overlay.visible:
					failures.append("target_store_overlay_still_visible_after_exit")

	var occlusion_test_idx = -1
	for i in range(buildings.size()):
		var b: Dictionary = buildings[i]
		if bool(b.get("is_store", false)):
			continue
		occlusion_test_idx = i
		break
	if occlusion_test_idx < 0 and buildings.size() > 0:
		occlusion_test_idx = 0
	if occlusion_test_idx < 0:
		failures.append("target_no_buildings_for_occlusion")
	else:
		var ob: Dictionary = buildings[occlusion_test_idx]
		var rect: Rect2 = ob.get("collision_rect", ob.get("footprint", Rect2()))
		var cx = rect.position.x + rect.size.x * 0.5
		var cz = rect.position.y + rect.size.y * 0.5
		var cam_pos = Vector3(cx, 9.6, rect.position.y - rect.size.y * 2.35)
		var blocked_pos = Vector3(cx, 0.0, rect.position.y + rect.size.y * 2.35)
		var clear_pos = Vector3(cam_pos.x + 0.15, 0.0, cam_pos.z + 0.2)
		if not _freya_occluded_by_buildings(cam_pos, blocked_pos):
			failures.append("target_ghost_not_blocked_when_hidden")
		if _freya_occluded_by_buildings(cam_pos, clear_pos):
			failures.append("target_ghost_blocked_when_clear")
		if _freya_occluded_by_buildings(cam_pos, Vector3(cx, 0.0, cz)) and rect.size.x < 4.0:
			failures.append("target_ghost_false_positive_small_building")

		camera_node.global_position = cam_pos
		freya.global_position = blocked_pos
		_update_roof_occlusion(0.0)
		if outlined_freya_meshes.is_empty():
			failures.append("target_ghost_outline_not_shown")
		freya.global_position = clear_pos
		_update_roof_occlusion(0.0)
		if not outlined_freya_meshes.is_empty():
			failures.append("target_ghost_outline_not_cleared")
		freya.global_position = blocked_pos
		_update_roof_occlusion(0.0)
		if outlined_freya_meshes.is_empty():
			failures.append("target_ghost_outline_not_restored")

	freya.global_position = saved_pos
	camera_node.global_position = saved_cam_pos
	active_store_index = saved_active
	store_focus_timer = saved_timer
	_apply_store_focus_visuals()

	if failures.is_empty():
		print("TARGET_OK: store+ghost validations passed")
	else:
		push_error("TARGET_FAIL: " + ", ".join(failures))

func _run_headless_smoke_checks() -> void:
	var failures: Array[String] = []

	# Poop-eating check
	var test_poop = Node3D.new()
	var poop_pos = Vector2(freya.global_position.x + 0.45, freya.global_position.z)
	test_poop.position = Vector3(poop_pos.x, 0.0, poop_pos.y)
	dynamic_root.add_child(test_poop)
	poops.append({"node": test_poop, "pos": poop_pos})

	freya_hunger = 60.0
	freya_vomit = 40.0
	var poops_before = poops.size()
	_try_eat_poop()
	if poops.size() != poops_before - 1:
		failures.append("poop_not_consumed")
	if freya_hunger > 55.05:
		failures.append("hunger_not_reduced")
	if freya_vomit < 61.95:
		failures.append("vomit_meter_not_increased")

	# Vomit check
	var vomit_before = vomit_puddles.size()
	freya_vomit = 100.0
	_try_vomit()
	if freya_vomit > 0.1:
		failures.append("vomit_meter_not_reset")
	if vomit_puddles.size() != vomit_before + 1:
		failures.append("vomit_puddle_not_spawned")

	# Stick interaction + speed boost check
	var base_run_speed: float
	freya_has_stick = false
	base_run_speed = _compute_freya_move_speed(true)
	var test_stick = _create_stick_node()
	var stick_pos = Vector3(freya.global_position.x + 0.55, 0.03, freya.global_position.z)
	test_stick.position = stick_pos
	dynamic_root.add_child(test_stick)
	sticks.append({"node": test_stick, "pos": Vector2(stick_pos.x, stick_pos.z)})
	if not _try_pickup_stick() or not freya_has_stick:
		failures.append("stick_pickup_failed")
	else:
		var boosted_speed = _compute_freya_move_speed(true)
		if boosted_speed <= base_run_speed + 0.05:
			failures.append("stick_run_boost_missing")
		var second_stick = _create_stick_node()
		var second_pos = Vector3(freya.global_position.x + 0.75, 0.03, freya.global_position.z + 0.15)
		second_stick.position = second_pos
		dynamic_root.add_child(second_stick)
		sticks.append({"node": second_stick, "pos": Vector2(second_pos.x, second_pos.z)})
		if _try_pickup_stick():
			failures.append("multiple_stick_pickup_allowed")
		_remove_stick_entry_for_node(second_stick)
		if is_instance_valid(second_stick):
			second_stick.queue_free()
	_drop_carried_stick()

	# Social + bark check
	if dogs.size() > 0:
		var state: Dictionary = dogs[0]
		var dog = state["node"]
		dog.global_position = freya.global_position + Vector3(1.15, 0.0, 0.0)
		state["dir"] = Vector3.ZERO
		state["speed"] = 0.0
		state["wander"] = 1.2
		state["bark"] = 0.0
		dogs[0] = state

		var social_before = freya_social
		var bark_before = bark_pulses.size()
		_update_dogs(0.2)
		if freya_social <= social_before:
			failures.append("social_not_increasing")
		if bark_pulses.size() <= bark_before:
			failures.append("bark_not_triggering")
	else:
		failures.append("no_dogs_spawned")

	# Layout checks
	var non_three_story = 0
	for b in buildings:
		if int(b.get("floors", 0)) != 3:
			non_three_story += 1
	if non_three_story > 0:
		failures.append("non_three_story_buildings_%d" % non_three_story)
	if not _has_back_alley_rowhouse_corridor():
		failures.append("rowhouse_alley_layout_missing")
	if not _building_ground_alignment_ok():
		failures.append("building_ground_alignment_bad")
	if not _alleys_only_between_rows_ok():
		failures.append("alley_layout_not_row_only")
	if not _dumpsters_on_alleys_ok():
		failures.append("dumpster_alley_placement_invalid")
	if not _building_sidewalk_coverage_ok():
		failures.append("building_sidewalk_coverage_incomplete")
	if not _street_poles_lining_streets_ok():
		failures.append("street_pole_layout_bad")
	if not _building_front_buffer_order_ok():
		failures.append("front_buffer_order_bad")
	if not _alley_accessibility_ok():
		failures.append("alley_accessibility_bad")

	# Dog animation checks
	if freya == null or not freya.has_method("has_move_animation") or not bool(freya.call("has_move_animation")):
		failures.append("freya_missing_walk_animation")
	var dogs_without_walk = 0
	for d in dogs:
		var dog_node = d["node"]
		if dog_node == null or not dog_node.has_method("has_move_animation") or not bool(dog_node.call("has_move_animation")):
			dogs_without_walk += 1
	if dogs_without_walk > 0:
		failures.append("npc_missing_walk_animation_%d" % dogs_without_walk)

	# Street + distribution checks
	if not _road_sidewalk_coverage_ok():
		failures.append("sidewalk_coverage_incomplete")
	var park_count = 0
	var nonpark_sidewalk_pref = 0
	var nonpark_total = 0
	for d in dogs:
		if bool(d.get("park", false)):
			park_count += 1
		else:
			nonpark_total += 1
			if str(d.get("pref_surface", "")) == "sidewalk":
				nonpark_sidewalk_pref += 1
	if park_count < DOG_PARK_NPC_COUNT:
		failures.append("dog_park_population_low_%d" % park_count)
	if nonpark_total > 0 and float(nonpark_sidewalk_pref) / float(nonpark_total) < 0.55:
		failures.append("sidewalk_pref_bias_low")
	var movement_sidewalk_samples = 0
	var movement_grass_samples = 0
	var movement_total_samples = 0
	for step in range(40):
		_update_dogs(0.2)
		for d in dogs:
			if bool(d.get("park", false)):
				continue
			var dog_node = d["node"]
			if dog_node == null:
				continue
			var surf = _surface_at(Vector2(dog_node.global_position.x, dog_node.global_position.z))
			if surf == "sidewalk":
				movement_sidewalk_samples += 1
			elif surf == "grass":
				movement_grass_samples += 1
			movement_total_samples += 1
	if movement_total_samples > 0:
		var sidewalk_ratio = float(movement_sidewalk_samples) / float(movement_total_samples)
		var grass_ratio = float(movement_grass_samples) / float(movement_total_samples)
		if sidewalk_ratio < 0.55:
			failures.append("nonpark_sidewalk_usage_low")
		if grass_ratio < 0.003:
			failures.append("nonpark_grass_venturing_low")
	if not _nonpark_dogs_distributed():
		failures.append("nonpark_distribution_uneven")

	# Pause menu check
	_toggle_pause_menu(1)
	if not get_tree().paused:
		failures.append("pause_menu_not_pausing")
	_toggle_pause_menu(0)
	if get_tree().paused:
		failures.append("pause_menu_not_resuming")
	if objectives_panel == null or objectives_list_label == null:
		failures.append("objectives_ui_missing")
	elif objectives_panel.visible:
		failures.append("objectives_panel_initial_visibility_bad")

	if failures.is_empty():
		print("SMOKE_OK: gameplay + layout + animation checks passed")
	else:
		push_error("SMOKE_FAIL: " + ", ".join(failures))

func _update_camera(delta: float) -> void:
	var look_ahead = freya_move_dir * 1.3
	var target: Vector3 = freya.global_position + Vector3(0.0, 1.0, 0.0) + look_ahead
	if delta <= 0.0:
		camera_focus = target
	else:
		camera_focus = camera_focus.lerp(target, clamp(delta * 5.2, 0.0, 1.0))

	var planar_offset = Vector3(-11.6, 0.0, 11.6).rotated(Vector3.UP, camera_orbit_angle)
	var offset = Vector3(planar_offset.x, 14.3, planar_offset.z)
	camera_node.global_position = camera_focus + offset
	camera_node.look_at(camera_focus + Vector3(0.0, -0.15, 0.0), Vector3.UP)

func _update_camera_orbit_input(delta: float) -> void:
	var rotate_dir = 0.0
	if Input.is_action_pressed("camera_rotate_ccw"):
		rotate_dir += 1.0
	if Input.is_action_pressed("camera_rotate_cw"):
		rotate_dir -= 1.0
	if absf(rotate_dir) > 0.0001:
		camera_orbit_angle = wrapf(camera_orbit_angle + rotate_dir * CAMERA_ORBIT_SPEED * delta, -PI, PI)

func _clear_occlusion_outlines() -> void:
	for m in outlined_freya_meshes:
		if m != null and is_instance_valid(m):
			m.material_overlay = null
	outlined_freya_meshes.clear()

	for m in outlined_object_meshes:
		if m != null and is_instance_valid(m):
			m.material_overlay = null
	outlined_object_meshes.clear()

func _apply_outline_recursive(root: Node, overlay: Material, out_list: Array[MeshInstance3D]) -> void:
	if root == null:
		return
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi = n as MeshInstance3D
			mi.material_overlay = overlay
			out_list.append(mi)
		for child in n.get_children():
			stack.append(child)

func _apply_nearby_object_outlines(radius: float) -> void:
	var center = Vector2(freya.global_position.x, freya.global_position.z)
	for p in poops:
		var pos: Vector2 = p.get("pos", Vector2.ZERO)
		if center.distance_to(pos) <= radius:
			_apply_outline_recursive(p.get("node", null), object_outline_material, outlined_object_meshes)
	for s in sticks:
		var pos: Vector2 = s.get("pos", Vector2.ZERO)
		if center.distance_to(pos) <= radius:
			_apply_outline_recursive(s.get("node", null), object_outline_material, outlined_object_meshes)
	for b in bones:
		var pos: Vector2 = b.get("pos", Vector2.ZERO)
		if center.distance_to(pos) <= radius:
			_apply_outline_recursive(b.get("node", null), object_outline_material, outlined_object_meshes)
	for f in store_foods:
		var pos: Vector2 = f.get("pos", Vector2.ZERO)
		if center.distance_to(pos) <= radius:
			_apply_outline_recursive(f.get("node", null), object_outline_material, outlined_object_meshes)
	for v in vomit_puddles:
		var pos: Vector2 = v.get("pos", Vector2.ZERO)
		if center.distance_to(pos) <= radius:
			_apply_outline_recursive(v.get("node", null), object_outline_material, outlined_object_meshes)

func _segment_rect_intersection_2d(a: Vector2, b: Vector2, rect: Rect2) -> Dictionary:
	var d = b - a
	var t_min = 0.0
	var t_max = 1.0
	var eps = 0.000001

	if absf(d.x) < eps:
		if a.x < rect.position.x or a.x > rect.position.x + rect.size.x:
			return {"hit": false}
	else:
		var inv_dx = 1.0 / d.x
		var tx1 = (rect.position.x - a.x) * inv_dx
		var tx2 = (rect.position.x + rect.size.x - a.x) * inv_dx
		var tx_min = minf(tx1, tx2)
		var tx_max = maxf(tx1, tx2)
		t_min = maxf(t_min, tx_min)
		t_max = minf(t_max, tx_max)
		if t_min > t_max:
			return {"hit": false}

	if absf(d.y) < eps:
		if a.y < rect.position.y or a.y > rect.position.y + rect.size.y:
			return {"hit": false}
	else:
		var inv_dy = 1.0 / d.y
		var ty1 = (rect.position.y - a.y) * inv_dy
		var ty2 = (rect.position.y + rect.size.y - a.y) * inv_dy
		var ty_min = minf(ty1, ty2)
		var ty_max = maxf(ty1, ty2)
		t_min = maxf(t_min, ty_min)
		t_max = minf(t_max, ty_max)
		if t_min > t_max:
			return {"hit": false}

	return {
		"hit": true,
		"t_enter": clampf(t_min, 0.0, 1.0),
		"t_exit": clampf(t_max, 0.0, 1.0)
	}

func _building_blocks_view(building: Dictionary, cam_pos: Vector3, freya_pos: Vector3) -> bool:
	return _building_blocks_view_to_target(building, cam_pos, freya_pos + Vector3(0.0, 0.8, 0.0))

func _building_blocks_view_to_target(building: Dictionary, cam_pos: Vector3, target_pos: Vector3) -> bool:
	var fp: Rect2 = building.get("collision_rect", building["footprint"])
	var expanded = fp.grow(0.01)
	var cam2 = Vector2(cam_pos.x, cam_pos.z)
	var target2 = Vector2(target_pos.x, target_pos.z)
	var hit = _segment_rect_intersection_2d(cam2, target2, expanded)
	if not bool(hit.get("hit", false)):
		return false
	var t_enter = float(hit.get("t_enter", 0.0))
	var t_exit = float(hit.get("t_exit", 0.0))
	if t_enter < 0.08 or t_exit > 0.94:
		return false
	if t_exit - t_enter < 0.07:
		return false

	var building_h = float(building.get("height", 8.0))
	var eye_y = cam_pos.y + 0.1
	var target_y = target_pos.y
	var t_mid = (t_enter + t_exit) * 0.5
	var y_mid = lerpf(eye_y, target_y, t_mid)
	return building_h >= y_mid + 0.08

func _segment_circle_intersection_2d(a: Vector2, b: Vector2, center: Vector2, radius: float) -> Dictionary:
	var d = b - a
	var f = a - center
	var qa = d.dot(d)
	if qa <= 0.0000001:
		return {"hit": false}
	var qb = 2.0 * f.dot(d)
	var qc = f.dot(f) - radius * radius
	var disc = qb * qb - 4.0 * qa * qc
	if disc < 0.0:
		return {"hit": false}

	var sqrt_disc = sqrt(disc)
	var t1 = (-qb - sqrt_disc) / (2.0 * qa)
	var t2 = (-qb + sqrt_disc) / (2.0 * qa)
	var t_enter = minf(t1, t2)
	var t_exit = maxf(t1, t2)
	if t_exit < 0.0 or t_enter > 1.0:
		return {"hit": false}
	return {
		"hit": true,
		"t_enter": clampf(t_enter, 0.0, 1.0),
		"t_exit": clampf(t_exit, 0.0, 1.0)
	}

func _circle_blocks_view(center: Vector2, radius: float, height: float, cam_pos: Vector3, freya_pos: Vector3) -> bool:
	var cam2 = Vector2(cam_pos.x, cam_pos.z)
	var freya2 = Vector2(freya_pos.x, freya_pos.z)
	var hit = _segment_circle_intersection_2d(cam2, freya2, center, radius)
	if not bool(hit.get("hit", false)):
		return false
	var t_enter = float(hit.get("t_enter", 0.0))
	var t_exit = float(hit.get("t_exit", 0.0))
	if t_exit < 0.03 or t_enter > 0.98:
		return false
	if t_exit - t_enter < 0.008:
		return false

	var eye_y = cam_pos.y + 0.1
	var freya_target_y = freya_pos.y + 0.8
	var t_mid = (t_enter + t_exit) * 0.5
	var y_mid = lerpf(eye_y, freya_target_y, t_mid)
	return height >= y_mid - 0.02

func _nonbuilding_blocks_view(cam_pos: Vector3, freya_pos: Vector3) -> bool:
	for t in trees:
		var center: Vector2 = t.get("pos", Vector2.ZERO)
		var radius = float(t.get("radius", TREE_COLLISION_SCALE))
		var height = float(t.get("height", 3.6))
		if _circle_blocks_view(center, radius, height, cam_pos, freya_pos):
			return true
	for pole in street_poles:
		var center: Vector2 = pole.get("pos", Vector2.ZERO)
		var radius = float(pole.get("radius", STREET_POLE_COLLISION_RADIUS))
		if _circle_blocks_view(center, radius, 4.55, cam_pos, freya_pos):
			return true
	for hydrant in fire_hydrants:
		var center: Vector2 = hydrant.get("pos", Vector2.ZERO)
		var radius = float(hydrant.get("radius", FIRE_HYDRANT_COLLISION_RADIUS))
		if _circle_blocks_view(center, radius, 0.95, cam_pos, freya_pos):
			return true
	for d in dumpsters:
		var center: Vector2 = d.get("pos", Vector2.ZERO)
		var radius = float(d.get("radius", DUMPSTER_COLLISION_RADIUS))
		if _circle_blocks_view(center, radius, 1.15, cam_pos, freya_pos):
			return true
	return false

func _freya_occluded_by_buildings(cam_pos: Vector3, freya_pos: Vector3) -> bool:
	var freya_pos_2d = Vector2(freya_pos.x, freya_pos.z)
	var inside_active_store = _is_inside_store_interior(active_store_index, freya_pos_2d)
	if inside_active_store:
		return false
	var samples: Array[Vector3] = [
		freya_pos + Vector3(0.0, 0.16, 0.0),
		freya_pos + Vector3(0.0, 0.54, 0.0),
		freya_pos + Vector3(0.0, 0.92, 0.0),
		freya_pos + Vector3(0.24, 0.62, 0.0),
		freya_pos + Vector3(-0.24, 0.62, 0.0),
		freya_pos + Vector3(0.0, 0.62, 0.24),
		freya_pos + Vector3(0.0, 0.62, -0.24)
	]
	var blocked_count = 0
	var clear_count = 0
	var torso_blocked = false
	var head_blocked = false
	var side_blocked = 0
	for sample_idx in range(samples.size()):
		var sample = samples[sample_idx]
		var blocked = false
		for b_idx in range(buildings.size()):
			if inside_active_store and active_store_index >= 0 and b_idx == active_store_index:
				continue
			var b: Dictionary = buildings[b_idx]
			if _building_blocks_view_to_target(b, cam_pos, sample):
				blocked = true
				break
		if blocked:
			blocked_count += 1
			if sample_idx == 1:
				torso_blocked = true
			elif sample_idx == 2:
				head_blocked = true
			elif sample_idx >= 3:
				side_blocked += 1
		else:
			clear_count += 1
	if blocked_count <= 2:
		return false
	if clear_count >= 5 and not torso_blocked:
		return false
	if torso_blocked and head_blocked and side_blocked >= 1:
		return true
	if torso_blocked and blocked_count >= 4:
		return true
	if head_blocked and side_blocked >= 2 and blocked_count >= 4:
		return true
	if blocked_count >= 6:
		return true
	return false

func _freya_occluded_from_camera(cam_pos: Vector3, freya_pos: Vector3) -> bool:
	return _freya_occluded_by_buildings(cam_pos, freya_pos)

func _update_roof_occlusion(delta: float) -> void:
	var cam_pos = camera_node.global_position
	var freya_pos = freya.global_position
	var freya_pos_2d = Vector2(freya_pos.x, freya_pos.z)
	var store_idx_now = _store_index_for_visual_focus(freya_pos_2d)
	if store_idx_now != active_store_index:
		active_store_index = store_idx_now
	_apply_store_focus_visuals()
	var inside_active_store = _is_inside_store_index(active_store_index, freya_pos_2d)
	last_occlusion_cam_pos = cam_pos
	last_occlusion_freya_pos = freya_pos

	for i in range(buildings.size()):
		var b: Dictionary = buildings[i]
		var roof_parts: Array = b["roof_parts"]
		var hide_roof = _building_blocks_view(b, cam_pos, freya_pos)
		if store_idx_now >= 0 and i == store_idx_now and bool(b.get("is_store", false)):
			hide_roof = inside_active_store or hide_roof

		for part in roof_parts:
			(part as Node3D).visible = not hide_roof

	_clear_occlusion_outlines()
	var occluded_building = _freya_occluded_by_buildings(cam_pos, freya_pos)
	var occluded_props = _nonbuilding_blocks_view(cam_pos, freya_pos)
	var ghost_freya = occluded_building
	if ghost_freya:
		_apply_outline_recursive(freya, freya_ghost_material, outlined_freya_meshes)
	if occluded_building or occluded_props:
		_apply_nearby_object_outlines(3.0)

func _create_ui() -> void:
	store_focus_layer = CanvasLayer.new()
	store_focus_layer.layer = 1
	add_child(store_focus_layer)

	store_focus_overlay = ColorRect.new()
	store_focus_overlay.anchor_right = 1.0
	store_focus_overlay.anchor_bottom = 1.0
	store_focus_overlay.color = Color(0.33, 0.35, 0.39, 0.58)
	store_focus_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	store_focus_overlay.visible = false
	store_focus_layer.add_child(store_focus_overlay)

	ui_layer = CanvasLayer.new()
	ui_layer.layer = 2
	add_child(ui_layer)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(16, 16)
	panel.size = Vector2(370, 176)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.08, 0.1, 0.72)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.74, 0.85, 0.82, 0.7)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	ui_layer.add_child(panel)

	var title = Label.new()
	title.text = "Friendly Freya"
	title.position = Vector2(14, 10)
	title.add_theme_font_size_override("font_size", 22)
	panel.add_child(title)

	hunger_bar = _make_meter(panel, "Hunger", Vector2(18, 46), Color(0.97, 0.44, 0.32))
	hunger_value_label = _make_value_label(panel, Vector2(316, 46))

	vomit_bar = _make_meter(panel, "Vomit", Vector2(18, 78), Color(0.66, 0.82, 0.39))
	vomit_value_label = _make_value_label(panel, Vector2(316, 78))

	social_bar = _make_meter(panel, "Social", Vector2(18, 110), Color(0.36, 0.66, 0.9))
	social_value_label = _make_value_label(panel, Vector2(316, 110))

	strength_bar = _make_meter(panel, "Strength", Vector2(18, 142), Color(0.92, 0.8, 0.36))
	strength_value_label = _make_value_label(panel, Vector2(316, 142))

	status_label = Label.new()
	status_label.position = Vector2(16, 205)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.98, 0.95))
	ui_layer.add_child(status_label)

	claim_meter_panel = Panel.new()
	claim_meter_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	claim_meter_panel.size = Vector2(182.0, 54.0)
	var claim_style = StyleBoxFlat.new()
	claim_style.bg_color = Color(0.09, 0.03, 0.1, 0.92)
	claim_style.border_color = Color(0.98, 0.3, 0.98, 0.95)
	claim_style.border_width_left = 2
	claim_style.border_width_top = 2
	claim_style.border_width_right = 2
	claim_style.border_width_bottom = 2
	claim_style.corner_radius_top_left = 6
	claim_style.corner_radius_top_right = 6
	claim_style.corner_radius_bottom_left = 6
	claim_style.corner_radius_bottom_right = 6
	claim_meter_panel.add_theme_stylebox_override("panel", claim_style)
	claim_meter_panel.visible = false
	ui_layer.add_child(claim_meter_panel)

	claim_meter_label = Label.new()
	claim_meter_label.position = Vector2(10.0, 6.0)
	claim_meter_label.size = Vector2(162.0, 18.0)
	claim_meter_label.add_theme_font_size_override("font_size", 13)
	claim_meter_panel.add_child(claim_meter_label)

	claim_meter_bar = ProgressBar.new()
	claim_meter_bar.position = Vector2(10.0, 30.0)
	claim_meter_bar.size = Vector2(162.0, 14.0)
	claim_meter_bar.min_value = 0.0
	claim_meter_bar.max_value = 100.0
	claim_meter_bar.step = 0.1
	claim_meter_bar.show_percentage = false
	var claim_bg = StyleBoxFlat.new()
	claim_bg.bg_color = Color(0.12, 0.07, 0.14, 0.9)
	claim_bg.corner_radius_top_left = 4
	claim_bg.corner_radius_top_right = 4
	claim_bg.corner_radius_bottom_left = 4
	claim_bg.corner_radius_bottom_right = 4
	claim_meter_bar.add_theme_stylebox_override("background", claim_bg)
	var claim_fill = StyleBoxFlat.new()
	claim_fill.bg_color = Color(1.0, 0.34, 0.96, 0.98)
	claim_fill.corner_radius_top_left = 4
	claim_fill.corner_radius_top_right = 4
	claim_fill.corner_radius_bottom_left = 4
	claim_fill.corner_radius_bottom_right = 4
	claim_meter_bar.add_theme_stylebox_override("fill", claim_fill)
	claim_meter_panel.add_child(claim_meter_bar)

	var minimap_panel = Panel.new()
	minimap_panel.anchor_left = 1.0
	minimap_panel.anchor_top = 0.0
	minimap_panel.anchor_right = 1.0
	minimap_panel.anchor_bottom = 0.0
	minimap_panel.offset_left = -350.0
	minimap_panel.offset_top = 8.0
	minimap_panel.offset_right = -10.0
	minimap_panel.offset_bottom = 258.0
	minimap_panel.clip_contents = true
	var mm_style = StyleBoxFlat.new()
	mm_style.bg_color = Color(0.05, 0.08, 0.11, 0.86)
	mm_style.border_color = Color(0.74, 0.85, 0.9, 0.75)
	mm_style.border_width_left = 2
	mm_style.border_width_top = 2
	mm_style.border_width_right = 2
	mm_style.border_width_bottom = 2
	mm_style.corner_radius_top_left = 8
	mm_style.corner_radius_top_right = 8
	mm_style.corner_radius_bottom_left = 8
	mm_style.corner_radius_bottom_right = 8
	minimap_panel.add_theme_stylebox_override("panel", mm_style)
	ui_layer.add_child(minimap_panel)

	var mini_title = Label.new()
	mini_title.text = "Minimap"
	mini_title.position = Vector2(12, 8)
	mini_title.size = Vector2(92, 20)
	mini_title.add_theme_font_size_override("font_size", 16)
	mini_title.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 0.98))
	minimap_panel.add_child(mini_title)

	var zoom_label = Label.new()
	zoom_label.text = "Zoom"
	zoom_label.position = Vector2(98, 10)
	zoom_label.size = Vector2(38, 18)
	zoom_label.add_theme_font_size_override("font_size", 13)
	zoom_label.add_theme_color_override("font_color", Color(0.9, 0.94, 0.97, 0.95))
	minimap_panel.add_child(zoom_label)

	var zoom_out_button = Button.new()
	zoom_out_button.text = "-"
	zoom_out_button.anchor_left = 0.0
	zoom_out_button.anchor_top = 0.0
	zoom_out_button.anchor_right = 0.0
	zoom_out_button.anchor_bottom = 0.0
	zoom_out_button.offset_left = 132.0
	zoom_out_button.offset_top = 7.0
	zoom_out_button.offset_right = 156.0
	zoom_out_button.offset_bottom = 31.0
	zoom_out_button.add_theme_font_size_override("font_size", 18)
	zoom_out_button.pressed.connect(_on_minimap_zoom_step.bind(-MINIMAP_ZOOM_STEP))
	minimap_panel.add_child(zoom_out_button)

	var zoom_in_button = Button.new()
	zoom_in_button.text = "+"
	zoom_in_button.anchor_left = 1.0
	zoom_in_button.anchor_top = 0.0
	zoom_in_button.anchor_right = 1.0
	zoom_in_button.anchor_bottom = 0.0
	zoom_in_button.offset_left = -30.0
	zoom_in_button.offset_top = 7.0
	zoom_in_button.offset_right = -6.0
	zoom_in_button.offset_bottom = 31.0
	zoom_in_button.add_theme_font_size_override("font_size", 18)
	zoom_in_button.pressed.connect(_on_minimap_zoom_step.bind(MINIMAP_ZOOM_STEP))
	minimap_panel.add_child(zoom_in_button)

	minimap_zoom_slider = HSlider.new()
	minimap_zoom_slider.anchor_left = 0.0
	minimap_zoom_slider.anchor_top = 0.0
	minimap_zoom_slider.anchor_right = 1.0
	minimap_zoom_slider.anchor_bottom = 0.0
	minimap_zoom_slider.offset_left = 162.0
	minimap_zoom_slider.offset_top = 10.0
	minimap_zoom_slider.offset_right = -36.0
	minimap_zoom_slider.offset_bottom = 28.0
	minimap_zoom_slider.min_value = 1.0
	minimap_zoom_slider.max_value = 4.5
	minimap_zoom_slider.step = 0.05
	minimap_zoom_slider.value = 2.6
	minimap_zoom_slider.value_changed.connect(_on_minimap_zoom_changed)
	minimap_panel.add_child(minimap_zoom_slider)

	minimap = MiniMapScript.new()
	minimap.anchor_left = 0.0
	minimap.anchor_top = 0.0
	minimap.anchor_right = 1.0
	minimap.anchor_bottom = 1.0
	minimap.offset_left = 10.0
	minimap.offset_top = 38.0
	minimap.offset_right = -10.0
	minimap.offset_bottom = -10.0
	minimap_panel.add_child(minimap)
	minimap.set_zoom(minimap_zoom_slider.value)

	_create_objectives_overlay()
	_create_pause_menu()

func _create_objectives_overlay() -> void:
	objectives_panel = Panel.new()
	objectives_panel.anchor_left = 0.5
	objectives_panel.anchor_top = 0.0
	objectives_panel.anchor_right = 0.5
	objectives_panel.anchor_bottom = 0.0
	objectives_panel.offset_left = -230.0
	objectives_panel.offset_top = 16.0
	objectives_panel.offset_right = 230.0
	objectives_panel.offset_bottom = 168.0
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.07, 0.1, 0.9)
	panel_style.border_color = Color(0.74, 0.86, 0.92, 0.75)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	objectives_panel.add_theme_stylebox_override("panel", panel_style)
	objectives_panel.visible = false
	ui_layer.add_child(objectives_panel)

	var title = Label.new()
	title.text = "Current Objectives"
	title.position = Vector2(14.0, 10.0)
	title.add_theme_font_size_override("font_size", 19)
	objectives_panel.add_child(title)

	objectives_list_label = Label.new()
	objectives_list_label.text = _objectives_text()
	objectives_list_label.position = Vector2(16.0, 42.0)
	objectives_list_label.size = Vector2(426.0, 112.0)
	objectives_list_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	objectives_list_label.add_theme_font_size_override("font_size", 15)
	objectives_panel.add_child(objectives_list_label)

func _update_objectives_overlay() -> void:
	if objectives_panel == null:
		return
	if objectives_list_label != null:
		objectives_list_label.text = _objectives_text()
	objectives_panel.visible = (not pause_menu_open) and Input.is_action_pressed("objectives")

func _objectives_text() -> String:
	var puke_state = "[DONE]" if objective_puke_on_dog_complete else "[ ]"
	var poles_claimed = _claimed_light_pole_count()
	var poles_done = poles_claimed >= OBJECTIVE_CLAIM_TARGET
	var poles_state = "[DONE]" if poles_done else "[ ]"
	var trees_claimed = _claimed_tree_count()
	var trees_done = trees_claimed >= OBJECTIVE_CLAIM_TARGET
	var trees_state = "[DONE]" if trees_done else "[ ]"
	var hydrants_claimed = _claimed_fire_hydrant_count()
	var hydrants_done = hydrants_claimed >= OBJECTIVE_HYDRANT_TARGET
	var hydrants_state = "[DONE]" if hydrants_done else "[ ]"
	return (
		"- %s Puke on another dog\n" % puke_state
		+ "- %s Claim 10 light poles (%d/%d)\n" % [poles_state, poles_claimed, OBJECTIVE_CLAIM_TARGET]
		+ "- %s Claim 10 trees (%d/%d)\n" % [trees_state, trees_claimed, OBJECTIVE_CLAIM_TARGET]
		+ "- %s Claim 8 fire hydrants (%d/%d)" % [hydrants_state, hydrants_claimed, OBJECTIVE_HYDRANT_TARGET]
	)

func _claimed_light_pole_count() -> int:
	var total = 0
	for pole in street_poles:
		if bool(pole.get("claimed", false)):
			total += 1
	return total

func _claimed_tree_count() -> int:
	var total = 0
	for tree in trees:
		if bool(tree.get("claimed", false)):
			total += 1
	return total

func _claimed_fire_hydrant_count() -> int:
	var total = 0
	for hydrant in fire_hydrants:
		if bool(hydrant.get("claimed", false)):
			total += 1
	return total

func _create_pause_menu() -> void:
	pause_menu_layer = CanvasLayer.new()
	pause_menu_layer.layer = 4
	pause_menu_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_menu_layer)

	pause_menu_panel = Panel.new()
	pause_menu_panel.anchor_left = 0.5
	pause_menu_panel.anchor_top = 0.5
	pause_menu_panel.anchor_right = 0.5
	pause_menu_panel.anchor_bottom = 0.5
	pause_menu_panel.offset_left = -285.0
	pause_menu_panel.offset_top = -210.0
	pause_menu_panel.offset_right = 285.0
	pause_menu_panel.offset_bottom = 210.0
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.07, 0.1, 0.92)
	panel_style.border_color = Color(0.78, 0.87, 0.92, 0.85)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	pause_menu_panel.add_theme_stylebox_override("panel", panel_style)
	pause_menu_layer.add_child(pause_menu_panel)

	var title = Label.new()
	title.text = "Menu"
	title.position = Vector2(20, 16)
	title.add_theme_font_size_override("font_size", 28)
	pause_menu_panel.add_child(title)

	var resume_btn = Button.new()
	resume_btn.text = "Resume"
	resume_btn.position = Vector2(22, 62)
	resume_btn.size = Vector2(124, 44)
	resume_btn.pressed.connect(_on_pause_resume_pressed)
	pause_menu_panel.add_child(resume_btn)

	pause_controls_button = Button.new()
	pause_controls_button.text = "Controls"
	pause_controls_button.position = Vector2(154, 62)
	pause_controls_button.size = Vector2(124, 44)
	pause_controls_button.pressed.connect(_on_pause_controls_pressed)
	pause_menu_panel.add_child(pause_controls_button)

	pause_howto_button = Button.new()
	pause_howto_button.text = "How To Play"
	pause_howto_button.position = Vector2(286, 62)
	pause_howto_button.size = Vector2(124, 44)
	pause_howto_button.pressed.connect(_on_pause_howto_pressed)
	pause_menu_panel.add_child(pause_howto_button)

	var exit_btn = Button.new()
	exit_btn.text = "Quit Game"
	exit_btn.position = Vector2(418, 62)
	exit_btn.size = Vector2(130, 44)
	exit_btn.pressed.connect(_on_pause_exit_pressed)
	pause_menu_panel.add_child(exit_btn)

	pause_controls_panel = Panel.new()
	pause_controls_panel.position = Vector2(22, 120)
	pause_controls_panel.size = Vector2(526, 262)
	var controls_bg = StyleBoxFlat.new()
	controls_bg.bg_color = Color(0.07, 0.11, 0.14, 0.92)
	controls_bg.border_color = Color(0.68, 0.79, 0.86, 0.7)
	controls_bg.border_width_left = 1
	controls_bg.border_width_top = 1
	controls_bg.border_width_right = 1
	controls_bg.border_width_bottom = 1
	controls_bg.corner_radius_top_left = 8
	controls_bg.corner_radius_top_right = 8
	controls_bg.corner_radius_bottom_left = 8
	controls_bg.corner_radius_bottom_right = 8
	pause_controls_panel.add_theme_stylebox_override("panel", controls_bg)
	pause_menu_panel.add_child(pause_controls_panel)

	var controls_title = Label.new()
	controls_title.text = "Controls"
	controls_title.position = Vector2(14, 10)
	controls_title.add_theme_font_size_override("font_size", 22)
	pause_controls_panel.add_child(controls_title)

	var controls_scroll = ScrollContainer.new()
	controls_scroll.position = Vector2(12, 44)
	controls_scroll.size = Vector2(502, 208)
	controls_scroll.follow_focus = true
	pause_controls_panel.add_child(controls_scroll)

	var controls = Label.new()
	controls.text = "WASD / Arrows: Move\nShift: Run\nQ / E: Rotate camera\nF: Eat poop / Pick up stick / Eat bone / Eat store food\nV: Drop carried stick\nHold R: Claim trees, poles, and fire hydrants\nHold R near dumpster: Search dumpster\nSpace: Vomit (when meter is full)\nHold X near other dogs: Aggressive social barking\nTab (hold): Objectives\nEsc: Pause / resume"
	controls.custom_minimum_size = Vector2(482, 420)
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD
	controls.add_theme_font_size_override("font_size", 16)
	controls_scroll.add_child(controls)

	pause_howto_panel = Panel.new()
	pause_howto_panel.position = Vector2(22, 120)
	pause_howto_panel.size = Vector2(526, 262)
	pause_howto_panel.add_theme_stylebox_override("panel", controls_bg.duplicate())
	pause_menu_panel.add_child(pause_howto_panel)

	var howto_title = Label.new()
	howto_title.text = "How To Play"
	howto_title.position = Vector2(14, 10)
	howto_title.add_theme_font_size_override("font_size", 22)
	pause_howto_panel.add_child(howto_title)

	var howto_scroll = ScrollContainer.new()
	howto_scroll.position = Vector2(12, 44)
	howto_scroll.size = Vector2(502, 208)
	howto_scroll.follow_focus = true
	pause_howto_panel.add_child(howto_scroll)

	var howto_text = Label.new()
	howto_text.text = "You are Freya, the world's best dog. You're on a mission to own this city block. You can claim trees, light poles, and fire hydrants by peeing on them. Other dogs may not be happy about you claiming the city, so it's your job to make friends and allies to make this city belong to Friendly Freya (Supreme Ruler)"
	howto_text.custom_minimum_size = Vector2(482, 420)
	howto_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	howto_text.add_theme_font_size_override("font_size", 16)
	howto_scroll.add_child(howto_text)

	pause_controls_panel.visible = false
	pause_howto_panel.visible = false
	pause_menu_panel.visible = false

func _toggle_pause_menu(force_state: int = -1) -> void:
	var open = not pause_menu_open
	if force_state >= 0:
		open = force_state > 0
	pause_menu_open = open
	if open:
		_hide_claim_meter()
	if pause_menu_panel != null:
		pause_menu_panel.visible = open
	if pause_controls_panel != null and not open:
		pause_controls_panel.visible = false
	if pause_howto_panel != null and not open:
		pause_howto_panel.visible = false
	if pause_controls_button != null and not open:
		pause_controls_button.text = "Controls"
	if pause_howto_button != null and not open:
		pause_howto_button.text = "How To Play"
	get_tree().paused = open

func _on_pause_resume_pressed() -> void:
	_toggle_pause_menu(0)

func _on_pause_controls_pressed() -> void:
	if pause_controls_panel == null:
		return
	pause_controls_panel.visible = not pause_controls_panel.visible
	if pause_howto_panel != null:
		pause_howto_panel.visible = false
	if pause_controls_button != null:
		pause_controls_button.text = "Hide Controls" if pause_controls_panel.visible else "Controls"
	if pause_howto_button != null:
		pause_howto_button.text = "How To Play"

func _on_pause_howto_pressed() -> void:
	if pause_howto_panel == null:
		return
	pause_howto_panel.visible = not pause_howto_panel.visible
	if pause_controls_panel != null:
		pause_controls_panel.visible = false
	if pause_howto_button != null:
		pause_howto_button.text = "Hide How To Play" if pause_howto_panel.visible else "How To Play"
	if pause_controls_button != null:
		pause_controls_button.text = "Controls"

func _on_pause_exit_pressed() -> void:
	get_tree().quit()

func _make_meter(panel: Panel, label_text: String, pos: Vector2, fill_color: Color) -> ProgressBar:
	var label = Label.new()
	label.text = label_text
	label.position = pos
	label.add_theme_font_size_override("font_size", 15)
	panel.add_child(label)

	var bar = ProgressBar.new()
	bar.position = Vector2(pos.x + 78, pos.y + 2)
	bar.size = Vector2(220, 18)
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 0.0
	bar.show_percentage = false

	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.11, 0.16, 0.18, 0.9)
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg)

	var fill = StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 4
	fill.corner_radius_top_right = 4
	fill.corner_radius_bottom_left = 4
	fill.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill)

	panel.add_child(bar)
	return bar

func _make_value_label(panel: Panel, pos: Vector2) -> Label:
	var l = Label.new()
	l.position = pos
	l.size = Vector2(48, 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.add_theme_font_size_override("font_size", 14)
	panel.add_child(l)
	return l

func _show_status(text: String, duration: float) -> void:
	status_label.text = text
	status_timer = duration

func _update_ui() -> void:
	hunger_bar.value = freya_hunger
	vomit_bar.value = freya_vomit
	social_bar.value = freya_social
	strength_bar.value = freya_strength

	hunger_value_label.text = "%d%%" % int(round(freya_hunger))
	vomit_value_label.text = "%d%%" % int(round(freya_vomit))
	social_value_label.text = "%d%%" % int(round(freya_social))
	strength_value_label.text = "%d%%" % int(round(freya_strength))

	_update_claim_meter_overlay()

func _sync_minimap_static() -> void:
	if minimap == null:
		return
	minimap.map_size = Vector2(MAP_W, MAP_H)
	minimap.roads = roads.duplicate()
	minimap.alleys = alleys.duplicate()
	minimap.sidewalks = sidewalks.duplicate()
	minimap.dog_park = dog_park
	var building_rects: Array[Rect2] = []
	var store_building_rects: Array[Rect2] = []
	var store_points = PackedVector2Array()
	var store_dirs = PackedVector2Array()
	for b in buildings:
		building_rects.append(b["footprint"])
		if bool(b.get("is_store", false)):
			var fp: Rect2 = b["footprint"]
			store_building_rects.append(fp)
			var center = fp.position + fp.size * 0.5
			var sp: Vector2 = b.get("entry_pos", Vector2(-1.0, -1.0))
			if sp.x >= 0.0 and sp.y >= 0.0:
				store_points.append(sp)
				store_dirs.append((center - sp).normalized())
			else:
				store_points.append(center)
				store_dirs.append(Vector2.ZERO)
	minimap.buildings = building_rects
	minimap.store_buildings = store_building_rects
	minimap.store_entries = store_points
	minimap.store_entry_dirs = store_dirs
	minimap.queue_redraw()

func _update_minimap_dynamic(delta: float) -> void:
	if minimap == null or freya == null:
		return
	if delta > 0.0:
		minimap_update_timer = maxf(0.0, minimap_update_timer - delta)
		if minimap_update_timer > 0.0:
			return
		minimap_update_timer = MINIMAP_UPDATE_INTERVAL

	var dog_points = PackedVector2Array()
	for d in dogs:
		var node = d["node"]
		dog_points.append(Vector2(node.global_position.x, node.global_position.z))

	var poop_points = PackedVector2Array()
	for p in poops:
		poop_points.append(p["pos"])

	var vomit_points = PackedVector2Array()
	for v in vomit_puddles:
		vomit_points.append(v["pos"])

	var map_forward = -camera_node.global_transform.basis.z
	map_forward.y = 0.0
	if map_forward.length_squared() < 0.000001:
		map_forward = Vector3(1.0, 0.0, -1.0)
	map_forward = map_forward.normalized()

	minimap.update_dynamic(
		Vector2(freya.global_position.x, freya.global_position.z),
		dog_points,
		poop_points,
		vomit_points,
		Vector2(map_forward.x, map_forward.z)
	)

func _on_minimap_zoom_changed(value: float) -> void:
	if minimap != null and minimap.has_method("set_zoom"):
		minimap.set_zoom(value)

func _on_minimap_zoom_step(delta_zoom: float) -> void:
	if minimap_zoom_slider == null:
		return
	minimap_zoom_slider.value = clampf(
		minimap_zoom_slider.value + delta_zoom,
		minimap_zoom_slider.min_value,
		minimap_zoom_slider.max_value
	)
