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
const STICK_MOUTH_FORWARD_OFFSET = 0.86
const STICK_MOUTH_UP_OFFSET = -0.03
const STICK_MOUTH_RIGHT_OFFSET = 0.0
const STICK_MOUTH_PITCH_DEG = 0.0
const OBJECTIVE_CLAIM_TARGET = 10
const CLAIM_TARGET_NONE = 0
const CLAIM_TARGET_LIGHT_POLE = 1
const CLAIM_TARGET_TREE = 2
const CLAIM_RANGE = 1.8
const CLAIM_FILL_TIME = 1.35
const CLAIM_RING_PULSE_SPEED = 4.1
const OCCLUSION_UPDATE_INTERVAL = 0.08
const OCCLUSION_MOVE_EPS = 0.08
const MINIMAP_UPDATE_INTERVAL = 0.08
const FREYA_COLLISION_RADIUS = 0.34
const DOG_COLLISION_RADIUS = 0.28
const DUMPSTER_COLLISION_RADIUS = 0.48
const STREET_POLE_COLLISION_RADIUS = 0.2
const STREET_POLE_SPACING = 10.8
const STREET_POLE_END_MARGIN = 2.6
const BUILDING_SIDEWALK_W = 0.95
const BUILDING_COLLISION_PAD = 0.02
const ROW_FRONT_SETBACK = 4.15
const ROW_SIDE_SETBACK = 0.72
const ALLEY_BUILDING_GAP = 0.2
const TREE_COLLISION_SCALE = 0.34
const STICK_PICKUP_RANGE = 1.55
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

var dogs: Array = []
var poops: Array = []
var sticks: Array = []
var dumpsters: Array = []
var street_poles: Array = []
var vomit_puddles: Array = []
var bark_pulses: Array = []

var dog_park = Rect2()
var freya
var freya_hunger = 34.0
var freya_vomit = 0.0
var freya_social = 24.0
var freya_vomit_timer = 0.0
var freya_move_dir = Vector3.ZERO
var camera_focus = Vector3.ZERO
var camera_orbit_angle = 0.0

var world_time = 0.0
var poop_spawn_timer = 4.1
var occlusion_update_timer = 0.0
var last_occlusion_cam_pos = Vector3(100000.0, 100000.0, 100000.0)
var last_occlusion_freya_pos = Vector3(-100000.0, -100000.0, -100000.0)
var minimap_update_timer = 0.0

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
var claim_ring_material: StandardMaterial3D
var vomit_material_a: StandardMaterial3D
var vomit_material_b: StandardMaterial3D

var freya_outline_material: ShaderMaterial
var object_outline_material: ShaderMaterial
var outlined_freya_meshes: Array[MeshInstance3D] = []
var outlined_object_meshes: Array[MeshInstance3D] = []

var freya_has_stick = false
var carried_stick: Node3D

var ui_layer: CanvasLayer
var hunger_bar: ProgressBar
var vomit_bar: ProgressBar
var social_bar: ProgressBar
var hunger_value_label: Label
var vomit_value_label: Label
var social_value_label: Label
var action_hint_label: Label
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

var minimap
var pause_menu_layer: CanvasLayer
var pause_menu_panel: Panel
var pause_menu_open = false
var bark_sfx_players: Array[AudioStreamPlayer] = []
var bark_sfx_streams: Array[AudioStreamWAV] = []
var bark_sfx_cursor = 0
var bark_sequences: Array = []

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
	_add_building_sidewalks()
	_spawn_street_poles()
	_spawn_alley_dumpsters()
	_populate_trees()
	_build_grass_spikes()
	_spawn_sticks(64)

	_spawn_freya_and_dogs()
	_seed_poops(20)
	_create_ui()
	_sync_minimap_static()
	_update_minimap_dynamic(0.0)

	camera_focus = freya.global_position + Vector3(0.0, 0.95, 0.0)
	_update_camera(0.0)
	_update_roof_occlusion(0.0)
	_update_ui()

	if OS.has_feature("server") or OS.get_environment("FREYA_SMOKE") == "1":
		_run_headless_smoke_checks()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		_toggle_pause_menu()
	if pause_menu_open:
		_hide_claim_meter()
		_update_objectives_overlay()
		return

	world_time += delta
	status_timer = max(0.0, status_timer - delta)
	if status_timer <= 0.0:
		status_label.text = ""

	_update_camera_orbit_input(delta)
	_update_freya(delta)
	_update_dogs(delta)
	_handle_actions()
	_update_carried_stick_pose()
	_update_poops(delta)
	_update_vomit_puddles(delta)
	_update_bark_sequences(delta)
	_update_bark_pulses(delta)
	_update_camera(delta)
	_update_claiming(delta)
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
		InputMap.action_add_event(name, ev)

func _action_has_key(name: String, keycode: int) -> bool:
	for ev in InputMap.action_get_events(name):
		if ev is InputEventKey and ev.physical_keycode == keycode:
			return true
	return false

func _remove_action_key(name: String, keycode: int) -> void:
	if not InputMap.has_action(name):
		return
	for ev in InputMap.action_get_events(name):
		if ev is InputEventKey and ev.physical_keycode == keycode:
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
	bark_sfx_streams.clear()
	bark_sfx_streams.append(_build_bark_stream(116.0, 0.34, 0.33))
	bark_sfx_streams.append(_build_bark_stream(124.0, 0.3, 0.3))
	bark_sfx_streams.append(_build_bark_stream(132.0, 0.28, 0.29))
	bark_sfx_streams.append(_build_bark_stream(142.0, 0.27, 0.27))
	bark_sfx_streams.append(_build_bark_stream(154.0, 0.24, 0.24))
	bark_sfx_streams.append(_build_bark_stream(166.0, 0.22, 0.22))
	bark_sfx_streams.append(_build_bark_stream(178.0, 0.2, 0.2))
	bark_sfx_streams.append(_build_bark_stream(188.0, 0.18, 0.19))

	for p in bark_sfx_players:
		if p != null:
			p.queue_free()
	bark_sfx_players.clear()

	for i in range(8):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = -13.0
		add_child(player)
		bark_sfx_players.append(player)
	bark_sfx_cursor = 0
	bark_sequences.clear()

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

func _play_bark_sound(is_freya_bark: bool) -> void:
	if bark_sfx_players.is_empty() or bark_sfx_streams.is_empty():
		return
	var idx: int = bark_sfx_cursor % bark_sfx_players.size()
	bark_sfx_cursor += 1
	var player: AudioStreamPlayer = bark_sfx_players[idx]
	if player == null:
		return

	var clip: AudioStreamWAV = bark_sfx_streams[rng.randi_range(0, bark_sfx_streams.size() - 1)]
	player.stop()
	player.stream = clip
	player.pitch_scale = rng.randf_range(0.91, 1.09) * (0.97 if is_freya_bark else 1.03)
	player.volume_db = -9.6 if is_freya_bark else -11.2
	player.play()

func _queue_bark_sequence(is_freya_bark: bool, barks: int) -> void:
	if barks <= 0:
		return
	if bark_sequences.size() > 28:
		return
	bark_sequences.append({
		"is_freya": is_freya_bark,
		"remaining": barks,
		"next": 0.0
	})

func _update_bark_sequences(delta: float) -> void:
	for i in range(bark_sequences.size() - 1, -1, -1):
		var seq: Dictionary = bark_sequences[i]
		seq["next"] = float(seq.get("next", 0.0)) - delta
		if float(seq["next"]) <= 0.0:
			var is_freya = bool(seq.get("is_freya", false))
			_play_bark_sound(is_freya)
			var remaining = int(seq.get("remaining", 0)) - 1
			if remaining <= 0:
				bark_sequences.remove_at(i)
				continue
			seq["remaining"] = remaining
			seq["next"] = rng.randf_range(0.15, 0.31)
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

	claim_ring_material = StandardMaterial3D.new()
	claim_ring_material.albedo_color = Color(0.22, 0.9, 0.33, 0.5)
	claim_ring_material.roughness = 0.35
	claim_ring_material.metallic = 0.0
	claim_ring_material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	claim_ring_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	claim_ring_material.cull_mode = StandardMaterial3D.CULL_DISABLED
	claim_ring_material.emission_enabled = true
	claim_ring_material.emission = Color(0.18, 0.7, 0.28)
	claim_ring_material.emission_energy_multiplier = 0.8

	stick_material_main = StandardMaterial3D.new()
	stick_material_main.albedo_color = Color8(132, 99, 62)
	stick_material_main.roughness = 0.88
	stick_material_main.metallic = 0.0

	stick_material_branch = StandardMaterial3D.new()
	stick_material_branch.albedo_color = Color8(114, 84, 53)
	stick_material_branch.roughness = 0.9
	stick_material_branch.metallic = 0.0

	vomit_material_a = StandardMaterial3D.new()
	vomit_material_a.albedo_color = Color8(145, 191, 88)
	vomit_material_a.roughness = 0.74
	vomit_material_a.metallic = 0.03

	vomit_material_b = StandardMaterial3D.new()
	vomit_material_b.albedo_color = Color8(112, 156, 62)
	vomit_material_b.roughness = 0.8
	vomit_material_b.metallic = 0.01

	freya_outline_material = _make_outline_material(Color(0.18, 0.96, 0.98, 1.0), 0.05)
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

	dog_park = Rect2(MAP_W - 26.0, 2.0, 22.0, 16.0)

	for cx in [24.0, 48.0, 72.0, 96.0, 120.0]:
		_add_road(Rect2(cx - ROAD_W * 0.5, 0.0, ROAD_W, MAP_H))

	for cz in [20.0, 44.0, 68.0, 92.0]:
		_add_road(Rect2(0.0, cz - ROAD_W * 0.5, MAP_W, ROAD_W))

	var x_intervals = _compute_non_road_intervals(true)
	var z_intervals = _compute_non_road_intervals(false)

	for xr in x_intervals:
		for zr in z_intervals:
			var parcel = Rect2(xr.x, zr.x, xr.y, zr.y)
			if parcel.size.x < 10.0 or parcel.size.y < 9.5:
				continue
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

		var alley_mid = float(layout["alley_mid"])
		var alley_z0 = float(layout["alley_z0"])
		var alley_z1 = float(layout["alley_z1"])
		var alley_gap = float(layout["alley_gap"])
		var x0 = float(layout["x0"])
		var x1 = float(layout["x1"])
		var run_w = float(layout["run_w"])
		var lot_count = max(3, int(floor(run_w / 5.9)))
		var lot_stride = run_w / float(lot_count)
		var north_depth = float(layout["north_depth"])
		var south_depth = float(layout["south_depth"])

		for i in range(lot_count):
			var bx = x0 + float(i) * lot_stride + 0.04
			var width = lot_stride - 0.08
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
				"radius": DUMPSTER_COLLISION_RADIUS
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

	var body = MeshInstance3D.new()
	var body_mesh = CylinderMesh.new()
	body_mesh.top_radius = 0.017
	body_mesh.bottom_radius = 0.021
	body_mesh.height = 0.58
	body.mesh = body_mesh
	body.rotation_degrees.z = 90.0
	body.position = Vector3(0.0, 0.05, 0.0)
	body.material_override = stick_material_main
	root.add_child(body)

	var branch = MeshInstance3D.new()
	var branch_mesh = CylinderMesh.new()
	branch_mesh.top_radius = 0.011
	branch_mesh.bottom_radius = 0.014
	branch_mesh.height = 0.24
	branch.mesh = branch_mesh
	branch.position = Vector3(0.09, 0.07, -0.02)
	branch.rotation_degrees = Vector3(36.0, 24.0, 90.0)
	branch.material_override = stick_material_branch
	root.add_child(branch)

	return root

func _spawn_freya_and_dogs() -> void:
	objective_puke_on_dog_complete = false
	var freya_model_paths = _animated_model_paths(FREYA_MODEL_CANDIDATES)
	if freya_model_paths.is_empty():
		freya_model_paths = _existing_model_paths(FREYA_MODEL_CANDIDATES)

	var npc_model_paths = _animated_model_paths(NPC_DOG_MODEL_CANDIDATES)
	var freya_model = freya_model_paths[0] if freya_model_paths.size() > 0 else ""
	if npc_model_paths.is_empty() and not freya_model.is_empty() and _model_has_walk_animation(freya_model):
		npc_model_paths = [freya_model]
	if npc_model_paths.is_empty():
		npc_model_paths = freya_model_paths.duplicate()

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

	for i in range(total_dogs):
		var dog = DogAgentScript.new()
		var dog_model = ""
		if npc_model_paths.size() > 0:
			dog_model = npc_model_paths[i % npc_model_paths.size()]
		var coat_options = [
			Color8(58, 48, 42),
			Color8(164, 126, 93),
			Color8(189, 175, 152),
			Color8(102, 94, 83),
			Color8(216, 206, 187)
		]
		dog.configure({
			"is_freya": false,
			"coat_color": coat_options[i % coat_options.size()],
			"speed": rng.randf_range(1.7, 2.6),
			"scene_path": dog_model,
			"model_scale": _npc_model_scale_for_path(dog_model)
		})
		dog.scale = Vector3.ONE
		var in_park = i < park_dogs
		var pos_idx = i if in_park else i - park_dogs
		if in_park and pos_idx < park_points.size():
			dog.position = park_points[pos_idx]
		elif (not in_park) and pos_idx < city_points.size():
			dog.position = city_points[pos_idx]
		else:
			dog.position = _random_walkable_point(true, DOG_COLLISION_RADIUS)
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
		_spawn_poop()

func _spawn_poop() -> void:
	var p3 = _random_walkable_point(true, 0.1)
	var p2 = Vector2(p3.x, p3.z)
	if _surface_at(p2) == "road":
		return
	for item in poops:
		var pos: Vector2 = item["pos"]
		if pos.distance_to(p2) < 1.2:
			return

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
	if _point_in_building(p, radius + BUILDING_COLLISION_PAD):
		return false
	if _point_in_tree_trunk(p, maxf(0.2, radius * 0.95)):
		return false
	if _point_in_dumpster(p, maxf(0.08, radius * 0.9)):
		return false
	if _point_in_street_pole(p, maxf(0.04, radius * 0.45)):
		return false
	return true

func _point_in_building(p: Vector2, pad: float) -> bool:
	for b in buildings:
		var rect: Rect2 = b.get("collision_rect", b["footprint"])
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
	return false

func _update_freya(delta: float) -> void:
	freya_hunger = clamp(freya_hunger + delta * 2.4, 0.0, 100.0)
	freya_social = clamp(freya_social - delta * 1.0, 0.0, 100.0)

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
			freya_social = clamp(freya_social + delta * 22.0, 0.0, 100.0)
			if float(state["bark"]) <= 0.0:
				_spawn_bark_pulse(dog.head_world_position(), Color(1.0, 1.0, 1.0, 0.82))
				_spawn_bark_pulse(freya.head_world_position(), Color(1.0, 0.9, 0.65, 0.84))
				_queue_bark_sequence(false, rng.randi_range(2, 4))
				_queue_bark_sequence(true, rng.randi_range(2, 3))
				state["bark"] = rng.randf_range(0.35, 0.68)

		dogs[i] = state

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

	return {"found": found, "type": best_type, "index": best_index}

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

func _create_claim_ring_node(radius: float) -> MeshInstance3D:
	var ring = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.025
	ring.mesh = mesh
	ring.position = Vector3(0.0, 0.03, 0.0)
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
	return freya.global_position + Vector3(0.0, 1.5, 0.0)

func _claim_progress_for_target(target_type: int, index: int) -> float:
	if target_type == CLAIM_TARGET_LIGHT_POLE and index >= 0 and index < street_poles.size():
		return clampf(float(street_poles[index].get("claim_progress", 0.0)), 0.0, 1.0)
	if target_type == CLAIM_TARGET_TREE and index >= 0 and index < trees.size():
		return clampf(float(trees[index].get("claim_progress", 0.0)), 0.0, 1.0)
	return 0.0

func _update_claiming(delta: float) -> void:
	var prev_type = active_claim_target_type
	var prev_index = active_claim_target_index

	if not Input.is_action_pressed("claim"):
		_reset_claim_progress(prev_type, prev_index)
		active_claim_target_type = CLAIM_TARGET_NONE
		active_claim_target_index = -1
		return

	var target = _find_nearest_claim_target()
	if not bool(target.get("found", false)):
		_reset_claim_progress(prev_type, prev_index)
		active_claim_target_type = CLAIM_TARGET_NONE
		active_claim_target_index = -1
		if Input.is_action_just_pressed("claim"):
			_show_status("No tree or light pole in range", 0.85)
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
	else:
		if _claimed_tree_count() >= OBJECTIVE_CLAIM_TARGET:
			_show_status("Objective complete: Claim 10 trees", 1.35)
		else:
			_show_status("Tree claimed!", 0.95)

func _update_claim_rings() -> void:
	var pulse_base = 0.91 + 0.13 * (0.5 + 0.5 * sin(world_time * CLAIM_RING_PULSE_SPEED))

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
		var pulse = pulse_base + 0.03 * sin(world_time * 2.2 + float(i) * 0.41)
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
		var pulse = pulse_base + 0.03 * sin(world_time * 2.0 + float(i) * 0.37)
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
	claim_meter_label.text = "Claiming Light Pole" if active_claim_target_type == CLAIM_TARGET_LIGHT_POLE else "Claiming Tree"
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

	var up := Vector3.UP
	var pitch := deg_to_rad(STICK_MOUTH_PITCH_DEG)
	var mouth_dir := (forward * cos(pitch) + up * sin(pitch)).normalized()
	var side_axis := up.cross(mouth_dir)
	if side_axis.length_squared() < 0.0001:
		side_axis = right
	side_axis = side_axis.normalized()
	var up_axis := mouth_dir.cross(side_axis).normalized()

	var mouth_pos = freya.head_world_position()
	mouth_pos += forward * STICK_MOUTH_FORWARD_OFFSET
	mouth_pos += right * STICK_MOUTH_RIGHT_OFFSET
	mouth_pos += up * STICK_MOUTH_UP_OFFSET

	carried_stick.global_transform = Transform3D(Basis(mouth_dir, up_axis, side_axis).orthonormalized(), mouth_pos)
	freya_has_stick = true

func _try_interact() -> void:
	if carried_stick != null and is_instance_valid(carried_stick):
		freya_has_stick = true
		if _try_eat_poop(false):
			return
		_drop_carried_stick()
		return
	freya_has_stick = false
	if _try_pickup_stick():
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
			_show_status("No poop or stick nearby", 0.9)
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

	var forward: Vector3 = -freya.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	forward = forward.normalized()

	var vomit_start = Vector2(freya.global_position.x, freya.global_position.z)
	var vomit_end = vomit_start + Vector2(forward.x, forward.z) * 1.45
	var hit_dog = _vomit_hits_any_dog(vomit_start, vomit_end)

	var puddle_pos = freya.global_position + forward * 0.95
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
	for i in range(4):
		var blob = MeshInstance3D.new()
		var mesh = SphereMesh.new()
		mesh.radius = rng.randf_range(0.1, 0.2)
		mesh.height = mesh.radius * 2.0
		blob.mesh = mesh
		blob.position = Vector3(rng.randf_range(-0.18, 0.18), 0.02, rng.randf_range(-0.15, 0.15))
		blob.scale = Vector3(rng.randf_range(1.2, 2.0), rng.randf_range(0.2, 0.36), rng.randf_range(1.2, 2.0))
		blob.material_override = vomit_material_a if i % 2 == 0 else vomit_material_b
		root.add_child(blob)
	return root

func _update_poops(delta: float) -> void:
	poop_spawn_timer -= delta
	if poop_spawn_timer <= 0.0:
		poop_spawn_timer = rng.randf_range(3.1, 6.2)
		if poops.size() < 22:
			_spawn_poop()

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
	var fp: Rect2 = building.get("collision_rect", building["footprint"])
	var expanded = fp.grow(0.04)
	var cam2 = Vector2(cam_pos.x, cam_pos.z)
	var freya2 = Vector2(freya_pos.x, freya_pos.z)
	var hit = _segment_rect_intersection_2d(cam2, freya2, expanded)
	if not bool(hit.get("hit", false)):
		return false
	var t_enter = float(hit.get("t_enter", 0.0))
	var t_exit = float(hit.get("t_exit", 0.0))
	if t_exit < 0.03 or t_enter > 0.98:
		return false
	if t_exit - t_enter < 0.01:
		return false

	var building_h = float(building.get("height", 8.0))
	var eye_y = cam_pos.y + 0.1
	var freya_target_y = freya_pos.y + 0.8
	var t_mid = (t_enter + t_exit) * 0.5
	var y_mid = lerpf(eye_y, freya_target_y, t_mid)
	return building_h >= y_mid - 0.02

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
	for d in dumpsters:
		var center: Vector2 = d.get("pos", Vector2.ZERO)
		var radius = float(d.get("radius", DUMPSTER_COLLISION_RADIUS))
		if _circle_blocks_view(center, radius, 1.15, cam_pos, freya_pos):
			return true
	return false

func _freya_occluded_from_camera(cam_pos: Vector3, freya_pos: Vector3) -> bool:
	for b in buildings:
		if _building_blocks_view(b, cam_pos, freya_pos):
			return true
	return _nonbuilding_blocks_view(cam_pos, freya_pos)

func _update_roof_occlusion(delta: float) -> void:
	var cam_pos = camera_node.global_position
	var freya_pos = freya.global_position
	if delta > 0.0:
		occlusion_update_timer = maxf(0.0, occlusion_update_timer - delta)
		var cam_moved = cam_pos.distance_squared_to(last_occlusion_cam_pos) >= OCCLUSION_MOVE_EPS * OCCLUSION_MOVE_EPS
		var freya_moved = freya_pos.distance_squared_to(last_occlusion_freya_pos) >= OCCLUSION_MOVE_EPS * OCCLUSION_MOVE_EPS
		if occlusion_update_timer > 0.0 and (not cam_moved) and (not freya_moved):
			return
		occlusion_update_timer = OCCLUSION_UPDATE_INTERVAL
	last_occlusion_cam_pos = cam_pos
	last_occlusion_freya_pos = freya_pos

	for b in buildings:
		var roof_parts: Array = b["roof_parts"]
		var hide_roof = _building_blocks_view(b, cam_pos, freya_pos)

		for part in roof_parts:
			(part as Node3D).visible = not hide_roof

	_clear_occlusion_outlines()
	var occluded = _freya_occluded_from_camera(cam_pos, freya_pos)
	if occluded:
		_apply_outline_recursive(freya, freya_outline_material, outlined_freya_meshes)
		_apply_nearby_object_outlines(3.0)

func _create_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(16, 16)
	panel.size = Vector2(370, 160)
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

	action_hint_label = Label.new()
	action_hint_label.position = Vector2(18, 136)
	action_hint_label.add_theme_font_size_override("font_size", 14)
	panel.add_child(action_hint_label)

	status_label = Label.new()
	status_label.position = Vector2(16, 188)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.98, 0.95))
	ui_layer.add_child(status_label)

	claim_meter_panel = Panel.new()
	claim_meter_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	claim_meter_panel.size = Vector2(182.0, 54.0)
	var claim_style = StyleBoxFlat.new()
	claim_style.bg_color = Color(0.05, 0.1, 0.08, 0.9)
	claim_style.border_color = Color(0.6, 0.9, 0.62, 0.84)
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
	claim_bg.bg_color = Color(0.08, 0.14, 0.1, 0.9)
	claim_bg.corner_radius_top_left = 4
	claim_bg.corner_radius_top_right = 4
	claim_bg.corner_radius_bottom_left = 4
	claim_bg.corner_radius_bottom_right = 4
	claim_meter_bar.add_theme_stylebox_override("background", claim_bg)
	var claim_fill = StyleBoxFlat.new()
	claim_fill.bg_color = Color(0.36, 0.9, 0.35, 0.95)
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
	minimap_panel.offset_left = -316.0
	minimap_panel.offset_top = 16.0
	minimap_panel.offset_right = -16.0
	minimap_panel.offset_bottom = 226.0
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
	mini_title.add_theme_font_size_override("font_size", 16)
	minimap_panel.add_child(mini_title)

	minimap = MiniMapScript.new()
	minimap.anchor_left = 0.0
	minimap.anchor_top = 0.0
	minimap.anchor_right = 1.0
	minimap.anchor_bottom = 1.0
	minimap.offset_left = 10.0
	minimap.offset_top = 34.0
	minimap.offset_right = -10.0
	minimap.offset_bottom = -10.0
	minimap_panel.add_child(minimap)

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
	return (
		"- %s Puke on another dog\n" % puke_state
		+ "- %s Claim 10 light poles (%d/%d)\n" % [poles_state, poles_claimed, OBJECTIVE_CLAIM_TARGET]
		+ "- %s Claim 10 trees (%d/%d)" % [trees_state, trees_claimed, OBJECTIVE_CLAIM_TARGET]
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

func _create_pause_menu() -> void:
	pause_menu_layer = CanvasLayer.new()
	pause_menu_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_menu_layer)

	pause_menu_panel = Panel.new()
	pause_menu_panel.anchor_left = 0.5
	pause_menu_panel.anchor_top = 0.5
	pause_menu_panel.anchor_right = 0.5
	pause_menu_panel.anchor_bottom = 0.5
	pause_menu_panel.offset_left = -240.0
	pause_menu_panel.offset_top = -175.0
	pause_menu_panel.offset_right = 240.0
	pause_menu_panel.offset_bottom = 175.0
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

	var controls = Label.new()
	controls.text = "Controls:\nWASD / Arrows: Move\nShift: Run\nQ / E: Rotate camera\nF: Eat poop / Pick up stick\nV: Drop carried stick\nHold R: Pee and claim trees/poles\nSpace: Vomit (when full)\nTab (hold): Objectives\nEsc: Toggle menu"
	controls.position = Vector2(22, 58)
	controls.size = Vector2(436, 172)
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD
	controls.add_theme_font_size_override("font_size", 16)
	pause_menu_panel.add_child(controls)

	var resume_btn = Button.new()
	resume_btn.text = "Resume"
	resume_btn.position = Vector2(22, 262)
	resume_btn.size = Vector2(210, 44)
	resume_btn.pressed.connect(_on_pause_resume_pressed)
	pause_menu_panel.add_child(resume_btn)

	var exit_btn = Button.new()
	exit_btn.text = "Exit Game"
	exit_btn.position = Vector2(248, 262)
	exit_btn.size = Vector2(210, 44)
	exit_btn.pressed.connect(_on_pause_exit_pressed)
	pause_menu_panel.add_child(exit_btn)

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
	get_tree().paused = open

func _on_pause_resume_pressed() -> void:
	_toggle_pause_menu(0)

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

	hunger_value_label.text = "%d%%" % int(round(freya_hunger))
	vomit_value_label.text = "%d%%" % int(round(freya_vomit))
	social_value_label.text = "%d%%" % int(round(freya_social))

	if freya_vomit >= 100.0:
		action_hint_label.text = "Press SPACE to vomit | Hold R to claim"
		action_hint_label.add_theme_color_override("font_color", Color(0.83, 0.95, 0.69, 0.98))
	elif freya_has_stick:
		action_hint_label.text = "Press V to drop stick | Press F to eat nearby poop | Hold R to claim"
		action_hint_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.76, 0.98))
	else:
		action_hint_label.text = "Press F to eat poop or pick up a stick | Hold R to claim"
		action_hint_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8, 0.96))

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
	for b in buildings:
		building_rects.append(b["footprint"])
	minimap.buildings = building_rects
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
