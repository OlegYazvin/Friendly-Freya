extends Node3D

const IntroTimeline = preload("res://scripts/intro_timeline.gd")
const AlienVisualFactory = preload("res://scripts/alien_visual_factory.gd")
const UFOVisualFactory = preload("res://scripts/ufo_visual_factory.gd")

const GAME_SCENE_PATH = "res://scenes/Main.tscn"
const FAMILY_INTRO_TREE_META = "friendly_freya_family_intro_pending"
const RUNE_AUDIO_PATH = "res://assets/audio/intro/rune_reveal.ogg"
const TRANSLATION_AUDIO_PATH = "res://assets/audio/intro/translation_resolve.ogg"
const ALIEN_VISUAL_SCALE = 0.84
const BUBBLE_SIZE = Vector2(570.0, 152.0)

var intro_camera: Camera3D
var interior_shot: Node3D
var fleet_shot: Node3D
var alien_cast: Node3D
var crew: Dictionary = {}
var crew_phases: Dictionary = {}
var fleet_root: Node3D
var fleet_ships: Array[Node3D] = []

var cutscene_ui: CanvasLayer
var speech_bubble: Panel
var speech_tail: Polygon2D
var speech_speaker_label: Label
var speech_phase_label: Label
var speech_text_label: Label
var skip_button: Button
var scene_id_label: Label
var transition_overlay: ColorRect

var rune_audio_player: AudioStreamPlayer
var translation_audio_player: AudioStreamPlayer
var rune_audio_stream: AudioStream
var translation_audio_stream: AudioStream

var timeline_time := 0.0
var static_view := false
var transition_started := false
var played_audio_events: Dictionary = {}
var current_scene_id := ""
var materials: Dictionary = {}
var alien_palettes: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_materials()
	_create_space_environment()
	_create_starfield()
	_create_interior_shot()
	_create_fleet_shot()
	_create_cutscene_ui()
	_create_audio_players()

	var requested_view = OS.get_environment("FREYA_INTRO_VIEW").strip_edges().to_lower()
	if not requested_view.is_empty():
		var requested_time = IntroTimeline.time_for_view(requested_view)
		if requested_time >= 0.0:
			timeline_time = requested_time
			static_view = true
			skip_button.visible = false
		else:
			push_warning("Unknown FREYA_INTRO_VIEW '%s'; playing the intro normally." % requested_view)

	_apply_timeline_time(timeline_time)
	_update_alien_idle_poses(0.0)

	if OS.get_environment("FREYA_INTRO_VALIDATE") == "1":
		static_view = true
		_run_intro_validation()


func _process(delta: float) -> void:
	if transition_started:
		return
	if not static_view:
		var previous_time = timeline_time
		timeline_time = minf(IntroTimeline.TOTAL_DURATION, timeline_time + delta)
		_fire_crossed_audio_events(previous_time, timeline_time)
	_apply_timeline_time(timeline_time)
	_update_alien_idle_poses(delta)
	_update_fleet_hover(timeline_time)
	_update_speech_bubble_anchor()
	if not static_view and timeline_time >= IntroTimeline.TOTAL_DURATION:
		_finish_to_game(true)


func _unhandled_input(event: InputEvent) -> void:
	if static_view or transition_started:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_ESCAPE]:
			get_viewport().set_input_as_handled()
			_finish_to_game()


func _create_materials() -> void:
	materials = {
		"hull": _material(Color8(61, 51, 94), 0.35, 0.38),
		"hull_dark": _material(Color8(29, 25, 49), 0.45, 0.3),
		"floor": _material(Color8(45, 56, 72), 0.28, 0.58),
		"trim": _material(Color8(129, 116, 159), 0.52, 0.26),
		"console": _material(Color8(35, 42, 61), 0.32, 0.48),
		"screen": _emissive_material(Color8(28, 88, 105), Color8(47, 219, 230), 1.65),
		"light_a": _emissive_material(Color8(72, 221, 231), Color8(72, 221, 231), 2.2),
		"light_b": _emissive_material(Color8(235, 76, 187), Color8(235, 76, 187), 2.0),
		"dome": _emissive_material(Color8(63, 50, 107), Color8(91, 66, 148), 0.35),
		"core": _emissive_material(Color8(121, 43, 151), Color8(191, 61, 234), 1.4),
		"earth_water": _material(Color8(35, 101, 178), 0.08, 0.62),
		"earth_land": _material(Color8(71, 145, 77), 0.02, 0.88),
		"earth_land_light": _material(Color8(116, 166, 89), 0.01, 0.9),
		"earth_ice": _material(Color8(219, 235, 238), 0.01, 0.76),
		"earth_atmosphere": _transparent_emissive_material(Color(0.22, 0.58, 0.95, 0.12), Color(0.12, 0.42, 0.86), 0.5)
	}
	# Continent silhouettes are thin curved surfaces and must remain visible from
	# both sides at the edge of the globe.
	(materials["earth_land"] as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	(materials["earth_land_light"] as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	(materials["earth_land"] as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	(materials["earth_land_light"] as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	(materials["earth_ice"] as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for color in [Color8(150, 224, 255), Color8(224, 205, 255), Color8(255, 235, 181)]:
		materials["star_%d" % materials.size()] = _emissive_material(color, color, 2.4)

	alien_palettes = [
		{
			"body": _material(Color8(94, 24, 116), 0.02, 0.73),
			"face": _material(Color8(156, 55, 163), 0.01, 0.68),
			"horn": _material(Color8(20, 15, 26), 0.04, 0.78),
			"eye": _emissive_material(Color8(54, 244, 236), Color8(54, 244, 236), 2.4),
			"fang": _material(Color8(230, 226, 214), 0.0, 0.72)
		},
		{
			"body": _material(Color8(54, 30, 112), 0.02, 0.73),
			"face": _material(Color8(117, 49, 149), 0.01, 0.68),
			"horn": _material(Color8(17, 13, 29), 0.04, 0.78),
			"eye": _emissive_material(Color8(255, 91, 183), Color8(255, 91, 183), 2.4),
			"fang": _material(Color8(230, 226, 214), 0.0, 0.72)
		},
		{
			"body": _material(Color8(111, 30, 72), 0.02, 0.73),
			"face": _material(Color8(155, 56, 100), 0.01, 0.68),
			"horn": _material(Color8(24, 12, 22), 0.04, 0.78),
			"eye": _emissive_material(Color8(248, 202, 69), Color8(248, 202, 69), 2.35),
			"fang": _material(Color8(230, 226, 214), 0.0, 0.72)
		}
	]


func _material(color: Color, metallic: float = 0.0, roughness: float = 0.7) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _emissive_material(color: Color, emission_color: Color, energy: float) -> StandardMaterial3D:
	var material = _material(color, 0.02, 0.42)
	material.emission_enabled = true
	material.emission = emission_color
	material.emission_energy_multiplier = energy
	return material


func _transparent_emissive_material(color: Color, emission_color: Color, energy: float) -> StandardMaterial3D:
	var material = _emissive_material(color, emission_color, energy)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	return material


func _create_space_environment() -> void:
	var world_environment = WorldEnvironment.new()
	world_environment.name = "SpaceEnvironment"
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.002, 0.003, 0.014)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.2, 0.24, 0.38)
	environment.ambient_light_energy = 0.72
	environment.glow_enabled = false
	world_environment.environment = environment
	add_child(world_environment)

	var key_light = DirectionalLight3D.new()
	key_light.name = "AlienKeyLight"
	key_light.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	key_light.light_color = Color(0.76, 0.84, 1.0)
	key_light.light_energy = 1.45
	key_light.shadow_enabled = false
	add_child(key_light)

	var rim_light = DirectionalLight3D.new()
	rim_light.name = "EarthRimLight"
	rim_light.rotation_degrees = Vector3(28.0, 154.0, 0.0)
	rim_light.light_color = Color(0.52, 0.29, 0.78)
	rim_light.light_energy = 0.72
	rim_light.shadow_enabled = false
	add_child(rim_light)

	intro_camera = Camera3D.new()
	intro_camera.name = "IntroCamera"
	intro_camera.current = true
	intro_camera.fov = 42.0
	intro_camera.near = 0.08
	intro_camera.far = 320.0
	add_child(intro_camera)


func _create_starfield() -> void:
	var starfield = Node3D.new()
	starfield.name = "Starfield"
	add_child(starfield)
	var star_rng = RandomNumberGenerator.new()
	star_rng.seed = 17012026
	var star_materials: Array[Material] = []
	for key in materials.keys():
		if str(key).begins_with("star_"):
			star_materials.append(materials[key])
	for star_index in range(155):
		var star = MeshInstance3D.new()
		star.name = "Star%03d" % star_index
		var mesh = SphereMesh.new()
		var radius = star_rng.randf_range(0.025, 0.085)
		mesh.radius = radius
		mesh.height = radius * 2.0
		mesh.radial_segments = 6
		mesh.rings = 3
		star.mesh = mesh
		star.position = Vector3(
			star_rng.randf_range(-52.0, 52.0),
			star_rng.randf_range(-24.0, 34.0),
			star_rng.randf_range(-88.0, -15.0)
		)
		star.material_override = star_materials[star_index % star_materials.size()]
		star.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		starfield.add_child(star, true)


func _create_interior_shot() -> void:
	interior_shot = Node3D.new()
	interior_shot.name = "InteriorShot"
	add_child(interior_shot)
	_create_earth(interior_shot, "InteriorEarth", Vector3(0.0, -4.1, -24.0), 8.5)

	var bridge = UFOVisualFactory.create_bridge_interior(materials)
	interior_shot.add_child(bridge)

	alien_cast = Node3D.new()
	alien_cast.name = "AlienCast"
	bridge.add_child(alien_cast)
	var cast_ids = ["AlienA", "AlienB", "AlienC"]
	var positions = [
		Vector3(-1.5, 0.03, -0.28),
		Vector3(1.5, 0.03, -0.28),
		Vector3(0.0, 0.03, -1.72)
	]
	for cast_index in range(cast_ids.size()):
		var alien = AlienVisualFactory.create_imp(alien_palettes[cast_index], ALIEN_VISUAL_SCALE)
		alien.name = cast_ids[cast_index]
		alien.position = positions[cast_index]
		alien.rotation.y = PI
		alien.set_meta("cast_id", cast_ids[cast_index])
		alien_cast.add_child(alien, true)
		crew[cast_ids[cast_index]] = alien
		crew_phases[cast_ids[cast_index]] = 0.35 + cast_index * 1.7


func _create_fleet_shot() -> void:
	fleet_shot = Node3D.new()
	fleet_shot.name = "FleetShot"
	add_child(fleet_shot)
	_create_earth(fleet_shot, "FleetEarth", Vector3(0.0, -17.0, -35.0), 16.5)

	fleet_root = Node3D.new()
	fleet_root.name = "FleetRoot"
	fleet_shot.add_child(fleet_root)
	var positions = [
		Vector3(0.0, 2.1, 0.0),
		Vector3(-5.4, 3.2, -5.5),
		Vector3(5.8, 2.8, -6.5),
		Vector3(-9.8, 0.1, -12.0),
		Vector3(9.8, 0.7, -13.2),
		Vector3(-4.7, -2.1, -18.2),
		Vector3(4.8, -1.8, -19.4),
		Vector3(0.0, 6.5, -21.5)
	]
	var scales = [1.15, 0.92, 0.98, 0.86, 0.9, 0.78, 0.82, 0.76]
	for ship_index in range(IntroTimeline.FLEET_SHIP_COUNT):
		var ship = UFOVisualFactory.create_opaque_exterior(materials, ship_index)
		ship.position = positions[ship_index]
		ship.scale = Vector3.ONE * float(scales[ship_index])
		ship.rotation_degrees = Vector3(
			-3.0 + ship_index % 3 * 3.0,
			ship_index * 23.0,
			-4.0 + ship_index % 4 * 2.5
		)
		ship.set_meta("base_position", positions[ship_index])
		fleet_root.add_child(ship, true)
		fleet_ships.append(ship)
	fleet_shot.visible = false


func _create_earth(parent: Node3D, node_name: String, position: Vector3, radius: float) -> Node3D:
	var earth = Node3D.new()
	earth.name = node_name
	earth.position = position
	parent.add_child(earth, true)

	var water = _sphere_mesh("WaterSphere", radius, materials["earth_water"])
	earth.add_child(water)
	var atmosphere = _sphere_mesh("Atmosphere", radius * 1.035, materials["earth_atmosphere"])
	atmosphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	earth.add_child(atmosphere)

	# Simplified recognizable silhouettes on the globe-facing map plane. Unlike
	# the former BoxMesh tiles these have coastlines and cannot read as a floor.
	var continents = [
		["NorthAmerica", PackedVector2Array([Vector2(-0.78, 0.34), Vector2(-0.66, 0.52), Vector2(-0.45, 0.50), Vector2(-0.34, 0.39), Vector2(-0.18, 0.32), Vector2(-0.29, 0.19), Vector2(-0.42, 0.13), Vector2(-0.45, -0.02), Vector2(-0.56, 0.07), Vector2(-0.63, 0.21)]), materials["earth_land"]],
		["SouthAmerica", PackedVector2Array([Vector2(-0.45, 0.08), Vector2(-0.29, 0.12), Vector2(-0.16, 0.02), Vector2(-0.14, -0.14), Vector2(-0.22, -0.36), Vector2(-0.32, -0.61), Vector2(-0.39, -0.42), Vector2(-0.40, -0.21), Vector2(-0.49, -0.04)]), materials["earth_land_light"]],
		["Eurasia", PackedVector2Array([Vector2(-0.13, 0.31), Vector2(0.02, 0.45), Vector2(0.18, 0.48), Vector2(0.29, 0.43), Vector2(0.42, 0.47), Vector2(0.67, 0.35), Vector2(0.78, 0.20), Vector2(0.62, 0.10), Vector2(0.47, 0.16), Vector2(0.36, 0.05), Vector2(0.25, 0.12), Vector2(0.16, 0.04), Vector2(0.08, 0.18), Vector2(-0.04, 0.18)]), materials["earth_land_light"]],
		["Africa", PackedVector2Array([Vector2(-0.03, 0.16), Vector2(0.17, 0.17), Vector2(0.31, 0.05), Vector2(0.28, -0.17), Vector2(0.15, -0.43), Vector2(0.04, -0.33), Vector2(-0.04, -0.10)]), materials["earth_land"]],
		["Australia", PackedVector2Array([Vector2(0.48, -0.34), Vector2(0.66, -0.31), Vector2(0.77, -0.41), Vector2(0.68, -0.53), Vector2(0.51, -0.49), Vector2(0.44, -0.40)]), materials["earth_land_light"]],
		["Greenland", PackedVector2Array([Vector2(-0.30, 0.58), Vector2(-0.17, 0.67), Vector2(-0.08, 0.59), Vector2(-0.15, 0.47), Vector2(-0.28, 0.48)]), materials["earth_ice"]],
		["Antarctica", PackedVector2Array([Vector2(-0.55, -0.72), Vector2(-0.30, -0.79), Vector2(0.02, -0.76), Vector2(0.31, -0.80), Vector2(0.59, -0.71), Vector2(0.40, -0.64), Vector2(0.10, -0.67), Vector2(-0.20, -0.64)]), materials["earth_ice"]]
	]
	for continent_data in continents:
		var continent = _earth_landmass_patch(str(continent_data[0]), continent_data[1], radius, continent_data[2])
		earth.add_child(continent, true)
	return earth


func _earth_landmass_patch(node_name: String, outline: PackedVector2Array, radius: float, material: Material) -> MeshInstance3D:
	var patch = MeshInstance3D.new()
	patch.name = node_name
	var polygon_indices = Geometry2D.triangulate_polygon(outline)
	var triangles: Array[PackedVector2Array] = []
	for index_offset in range(0, polygon_indices.size(), 3):
		triangles.append(PackedVector2Array([
			outline[polygon_indices[index_offset]],
			outline[polygon_indices[index_offset + 1]],
			outline[polygon_indices[index_offset + 2]]
		]))
	# Subdivision keeps every triangle close enough to the spherical surface that
	# the ocean cannot occlude its center, even near the edge of the globe.
	for subdivision in range(3):
		var refined: Array[PackedVector2Array] = []
		for triangle in triangles:
			var a = triangle[0]
			var b = triangle[1]
			var c = triangle[2]
			var ab = (a + b) * 0.5
			var bc = (b + c) * 0.5
			var ca = (c + a) * 0.5
			refined.append(PackedVector2Array([a, ab, ca]))
			refined.append(PackedVector2Array([ab, b, bc]))
			refined.append(PackedVector2Array([ca, bc, c]))
			refined.append(PackedVector2Array([ab, bc, ca]))
		triangles = refined
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	for triangle in triangles:
		for point in triangle:
			var px = radius * point.x
			var py = radius * point.y
			var pz = sqrt(maxf(0.0, radius * radius - px * px - py * py)) + radius * 0.008
			var vertex = Vector3(px, py, pz)
			vertices.append(vertex)
			normals.append(vertex.normalized())
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var patch_mesh = ArrayMesh.new()
	patch_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	patch.mesh = patch_mesh
	patch.material_override = material
	patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return patch


func _sphere_mesh(node_name: String, radius: float, material: Material) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.name = node_name
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 48
	mesh.rings = 24
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


func _create_cutscene_ui() -> void:
	cutscene_ui = CanvasLayer.new()
	cutscene_ui.name = "CutsceneUI"
	cutscene_ui.layer = 20
	add_child(cutscene_ui)
	var root = Control.new()
	root.name = "CutsceneOverlay"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cutscene_ui.add_child(root)

	for is_top in [true, false]:
		var bar = ColorRect.new()
		bar.name = "TopLetterbox" if is_top else "BottomLetterbox"
		bar.color = Color(0.0, 0.0, 0.0, 0.97)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.anchor_right = 1.0
		bar.anchor_bottom = 0.0 if is_top else 1.0
		bar.anchor_top = 0.0 if is_top else 1.0
		bar.offset_bottom = 54.0 if is_top else 0.0
		bar.offset_top = 0.0 if is_top else -54.0
		root.add_child(bar)

	skip_button = Button.new()
	skip_button.name = "SkipIntroButton"
	skip_button.text = "SKIP INTRO  [SPACE / ESC]"
	skip_button.anchor_left = 1.0
	skip_button.anchor_right = 1.0
	skip_button.offset_left = -262.0
	skip_button.offset_right = -24.0
	skip_button.offset_top = 12.0
	skip_button.offset_bottom = 46.0
	skip_button.focus_mode = Control.FOCUS_ALL
	skip_button.pressed.connect(_finish_to_game)
	root.add_child(skip_button)

	scene_id_label = Label.new()
	scene_id_label.name = "SceneIdLabel"
	scene_id_label.position = Vector2(22.0, 14.0)
	scene_id_label.size = Vector2(520.0, 32.0)
	scene_id_label.add_theme_color_override("font_color", Color(0.56, 0.82, 0.78, 0.86))
	scene_id_label.add_theme_font_size_override("font_size", 16)
	scene_id_label.visible = OS.get_environment("FREYA_INTRO_SHOW_SCENE_ID") == "1"
	root.add_child(scene_id_label)

	speech_tail = Polygon2D.new()
	speech_tail.name = "SpeechBubbleTail"
	speech_tail.polygon = PackedVector2Array([Vector2(-17.0, 0.0), Vector2(17.0, 0.0), Vector2(0.0, 25.0)])
	speech_tail.color = Color(0.055, 0.075, 0.13, 0.98)
	root.add_child(speech_tail)

	speech_bubble = Panel.new()
	speech_bubble.name = "SpeechBubble"
	speech_bubble.size = BUBBLE_SIZE
	var bubble_style = StyleBoxFlat.new()
	bubble_style.bg_color = Color(0.055, 0.075, 0.13, 0.98)
	bubble_style.border_color = Color(0.42, 0.94, 0.81, 0.96)
	bubble_style.set_border_width_all(3)
	bubble_style.set_corner_radius_all(16)
	bubble_style.shadow_color = Color(0.0, 0.0, 0.0, 0.54)
	bubble_style.shadow_size = 9
	speech_bubble.add_theme_stylebox_override("panel", bubble_style)
	root.add_child(speech_bubble)

	speech_speaker_label = Label.new()
	speech_speaker_label.name = "Speaker"
	speech_speaker_label.position = Vector2(22.0, 13.0)
	speech_speaker_label.size = Vector2(220.0, 26.0)
	speech_speaker_label.add_theme_color_override("font_color", Color(0.48, 1.0, 0.84))
	speech_speaker_label.add_theme_font_size_override("font_size", 18)
	speech_bubble.add_child(speech_speaker_label)

	speech_phase_label = Label.new()
	speech_phase_label.name = "TranslationPhase"
	speech_phase_label.position = Vector2(BUBBLE_SIZE.x - 190.0, 14.0)
	speech_phase_label.size = Vector2(166.0, 24.0)
	speech_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	speech_phase_label.add_theme_color_override("font_color", Color(0.72, 0.64, 0.94))
	speech_phase_label.add_theme_font_size_override("font_size", 14)
	speech_bubble.add_child(speech_phase_label)

	speech_text_label = Label.new()
	speech_text_label.name = "Text"
	speech_text_label.position = Vector2(22.0, 44.0)
	speech_text_label.size = Vector2(BUBBLE_SIZE.x - 44.0, BUBBLE_SIZE.y - 58.0)
	speech_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speech_text_label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	speech_text_label.add_theme_font_size_override("font_size", 25)
	speech_bubble.add_child(speech_text_label)

	transition_overlay = ColorRect.new()
	transition_overlay.name = "ShotTransition"
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(transition_overlay)
	speech_bubble.visible = false
	speech_tail.visible = false


func _create_audio_players() -> void:
	rune_audio_player = AudioStreamPlayer.new()
	rune_audio_player.name = "RuneReveal"
	rune_audio_player.bus = "Master"
	rune_audio_player.volume_db = -8.0
	rune_audio_stream = _load_exact_audio_stream(RUNE_AUDIO_PATH)
	rune_audio_player.stream = rune_audio_stream
	add_child(rune_audio_player)

	translation_audio_player = AudioStreamPlayer.new()
	translation_audio_player.name = "TranslationResolve"
	translation_audio_player.bus = "Master"
	translation_audio_player.volume_db = -7.0
	translation_audio_stream = _load_exact_audio_stream(TRANSLATION_AUDIO_PATH)
	translation_audio_player.stream = translation_audio_stream
	add_child(translation_audio_player)


func _load_exact_audio_stream(path: String) -> AudioStream:
	# Audio policy: the exact mapped clip either loads or this event stays silent.
	# This function intentionally has no candidate list and no fallback stream.
	if path.is_empty():
		return null
	if FileAccess.file_exists(path):
		if path.to_lower().ends_with(".ogg") or path.to_lower().ends_with(".oga"):
			var ogg := AudioStreamOggVorbis.load_from_file(path)
			if ogg != null:
				return ogg
		elif path.to_lower().ends_with(".wav"):
			var wav := AudioStreamWAV.load_from_file(path)
			if wav != null:
				return wav
		elif path.to_lower().ends_with(".mp3"):
			var mp3 := AudioStreamMP3.load_from_file(path)
			if mp3 != null:
				return mp3
	# Exported PCKs store the imported form of this same exact resource. Loading
	# it through ResourceLoader is not a substitute or fallback clip.
	if ResourceLoader.exists(path):
		var imported_stream = load(path)
		if imported_stream is AudioStream:
			return imported_stream as AudioStream
	return null


func _fire_crossed_audio_events(previous_time: float, new_time: float) -> void:
	for scene in IntroTimeline.dialogue_scenes():
		var scene_id = str(scene["id"])
		var rune_time = float(scene["start"])
		var translation_time = rune_time + float(scene["rune_duration"])
		if previous_time < rune_time and new_time >= rune_time:
			_play_intro_audio_event(scene_id + ":rune", rune_audio_player, rune_audio_stream)
		if previous_time < translation_time and new_time >= translation_time:
			_play_intro_audio_event(scene_id + ":translation", translation_audio_player, translation_audio_stream)


func _play_intro_audio_event(event_id: String, player: AudioStreamPlayer, stream: AudioStream) -> void:
	if played_audio_events.has(event_id):
		return
	played_audio_events[event_id] = true
	if player == null or not is_instance_valid(player) or stream == null:
		return
	# Headless checks validate real stream loading and event scheduling without
	# creating device-less Vorbis playback objects that survive immediate exit.
	if OS.has_feature("server") or DisplayServer.get_name() == "headless":
		return
	player.stop()
	player.stream = stream
	player.pitch_scale = 1.0
	player.play()


func _apply_timeline_time(time_seconds: float) -> void:
	var scene: Dictionary = IntroTimeline.scene_for_time(time_seconds)
	current_scene_id = str(scene["id"])
	if scene_id_label != null:
		scene_id_label.text = current_scene_id
	var fleet_mode = str(scene["shot"]) == "fleet"
	interior_shot.visible = not fleet_mode
	fleet_shot.visible = fleet_mode

	if fleet_mode:
		_apply_fleet_camera(time_seconds, scene)
	else:
		_apply_interior_camera(time_seconds)
	_update_speech_bubble(time_seconds, scene)
	_update_transition_overlay(time_seconds)


func _apply_interior_camera(time_seconds: float) -> void:
	var normalized = clampf(time_seconds / 15.8, 0.0, 1.0)
	intro_camera.position = Vector3(
		sin(time_seconds * 0.32) * 0.16,
		3.35 + sin(time_seconds * 0.21) * 0.06,
		7.85 - normalized * 0.38
	)
	intro_camera.fov = 41.5 - normalized * 1.4
	intro_camera.look_at(Vector3(0.0, 1.02, -0.82), Vector3.UP)


func _apply_fleet_camera(time_seconds: float, scene: Dictionary) -> void:
	var raw_progress = inverse_lerp(float(scene["start"]), float(scene["end"]), time_seconds)
	var progress = _smoothstep(clampf(raw_progress, 0.0, 1.0))
	var camera_start = Vector3(0.0, 4.8, 11.2)
	var camera_end = Vector3(0.0, 15.8, 42.0)
	var target_start = Vector3(0.0, 1.0, -0.5)
	var target_end = Vector3(0.0, -5.2, -14.0)
	intro_camera.position = camera_start.lerp(camera_end, progress)
	intro_camera.fov = lerpf(37.0, 52.0, progress)
	intro_camera.look_at(target_start.lerp(target_end, progress), Vector3.UP)


func _smoothstep(value: float) -> float:
	return value * value * (3.0 - 2.0 * value)


func _update_transition_overlay(time_seconds: float) -> void:
	if transition_overlay == null:
		return
	var fleet_start = float(IntroTimeline.SCENES[IntroTimeline.SCENES.size() - 1]["start"])
	var distance = absf(time_seconds - fleet_start)
	var alpha = 1.0 - clampf(distance / 0.32, 0.0, 1.0)
	transition_overlay.color = Color(0.0, 0.0, 0.0, alpha)


func _update_speech_bubble(time_seconds: float, scene: Dictionary) -> void:
	var speaker_id = str(scene.get("speaker_id", ""))
	if speaker_id.is_empty() or not crew.has(speaker_id):
		speech_bubble.visible = false
		speech_tail.visible = false
		return
	var local_time = maxf(0.0, time_seconds - float(scene["start"]))
	var rune_duration = maxf(0.01, float(scene["rune_duration"]))
	var morph_duration = maxf(0.01, float(scene["morph_duration"]))
	var rune_text = str(scene["runes"])
	var english_text = str(scene["english"])

	speech_bubble.visible = true
	speech_tail.visible = true
	speech_speaker_label.text = str(scene.get("speaker_label", speaker_id))
	if local_time < rune_duration:
		var reveal_progress = clampf(local_time / rune_duration, 0.0, 1.0)
		var visible_characters = clampi(int(ceil(reveal_progress * rune_text.length())), 1, rune_text.length())
		speech_text_label.text = rune_text.substr(0, visible_characters)
		speech_text_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.83))
		speech_phase_label.text = "ALIEN TRANSMISSION"
	elif local_time < rune_duration + morph_duration:
		var morph_progress = clampf((local_time - rune_duration) / morph_duration, 0.0, 1.0)
		speech_text_label.text = _morph_runes_to_english(rune_text, english_text, morph_progress)
		speech_text_label.add_theme_color_override("font_color", Color(0.72, 0.85, 1.0))
		speech_phase_label.text = "TRANSLATING..."
	else:
		speech_text_label.text = english_text
		speech_text_label.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0))
		speech_phase_label.text = "TRANSLATED"
	_update_speech_bubble_anchor(speaker_id)


func _morph_runes_to_english(runes: String, english: String, progress: float) -> String:
	if progress >= 0.999:
		return english
	var resolved_count = clampi(int(floor(progress * english.length())), 0, english.length())
	var output = english.substr(0, resolved_count)
	var rune_alphabet = runes.replace(" ", "")
	if rune_alphabet.is_empty():
		rune_alphabet = "|<>[]{}^#"
	var scramble_step = int(floor(progress * 12.0))
	for character_index in range(resolved_count, english.length()):
		if english[character_index] == " ":
			output += " "
		else:
			output += rune_alphabet[(character_index * 5 + scramble_step * 3) % rune_alphabet.length()]
	return output


func _update_speech_bubble_anchor(speaker_id_override: String = "") -> void:
	if speech_bubble == null or not speech_bubble.visible:
		return
	var speaker_id = speaker_id_override
	if speaker_id.is_empty():
		var scene = IntroTimeline.scene_for_time(timeline_time)
		speaker_id = str(scene.get("speaker_id", ""))
	var speaker: Node3D = crew.get(speaker_id, null)
	if speaker == null or not is_instance_valid(speaker):
		speech_bubble.visible = false
		speech_tail.visible = false
		return
	var anchor_world = speaker.global_position + Vector3(0.0, 1.48, 0.0)
	if intro_camera.is_position_behind(anchor_world):
		speech_bubble.visible = false
		speech_tail.visible = false
		return
	var screen_position = intro_camera.unproject_position(anchor_world)
	var viewport_size = get_viewport().get_visible_rect().size
	var desired = Vector2(screen_position.x - BUBBLE_SIZE.x * 0.5, screen_position.y - BUBBLE_SIZE.y - 36.0)
	desired.x = clampf(desired.x, 18.0, maxf(18.0, viewport_size.x - BUBBLE_SIZE.x - 18.0))
	desired.y = clampf(desired.y, 68.0, maxf(68.0, viewport_size.y - BUBBLE_SIZE.y - 88.0))
	speech_bubble.position = desired
	var tail_x = clampf(screen_position.x, desired.x + 34.0, desired.x + BUBBLE_SIZE.x - 34.0)
	speech_tail.position = Vector2(tail_x, desired.y + BUBBLE_SIZE.y - 2.0)


func _update_alien_idle_poses(delta: float) -> void:
	for cast_id in crew.keys():
		var alien: Node3D = crew[cast_id]
		var phase = float(crew_phases.get(cast_id, 0.0))
		phase = AlienVisualFactory.update_pose(alien, maxf(delta, 0.0001), Vector3.ZERO, 0.0, phase, timeline_time)
		crew_phases[cast_id] = phase


func _update_fleet_hover(time_seconds: float) -> void:
	for ship_index in range(fleet_ships.size()):
		var ship: Node3D = fleet_ships[ship_index]
		var base: Vector3 = ship.get_meta("base_position", ship.position)
		ship.position = base + Vector3(0.0, sin(time_seconds * 0.72 + ship_index * 0.83) * 0.12, 0.0)


func _finish_to_game(play_family_sequence: bool = false) -> void:
	if transition_started:
		return
	transition_started = true
	if rune_audio_player != null:
		rune_audio_player.stop()
	if translation_audio_player != null:
		translation_audio_player.stop()
	if skip_button != null:
		skip_button.disabled = true
	if play_family_sequence:
		# Main consumes and removes this one-shot flag after it builds the actual
		# map home. Skipping never leaves a stale family-intro request behind.
		get_tree().set_meta(FAMILY_INTRO_TREE_META, true)
	elif get_tree().has_meta(FAMILY_INTRO_TREE_META):
		get_tree().remove_meta(FAMILY_INTRO_TREE_META)
	var error = get_tree().change_scene_to_file(GAME_SCENE_PATH)
	if error != OK:
		push_error("Could not start Friendly Freya gameplay after intro (error %d)." % error)


func _run_intro_validation() -> void:
	var failures: Array[String] = []
	_validate_timeline(failures)
	_validate_cast(failures)
	_validate_earth_geometry(failures)
	_validate_audio(failures)
	_validate_fleet(failures)
	_validate_seekable_bubbles(failures)
	_validate_camera_pullback(failures)
	if GAME_SCENE_PATH != "res://scenes/Main.tscn" or not ResourceLoader.exists(GAME_SCENE_PATH):
		failures.append("completion_route_missing")

	if failures.is_empty():
		print("INTRO_OK: 5 scenes, 3 aliens, rune translations, 6 authored SFX cues, Earth orbit, and 8-ship pullback validated")
		call_deferred("_quit_after_validation", 0)
	else:
		push_error("INTRO_FAIL: " + ", ".join(failures))
		call_deferred("_quit_after_validation", 1)


func _quit_after_validation(exit_code: int) -> void:
	get_tree().quit(exit_code)


func _validate_timeline(failures: Array[String]) -> void:
	var expected_ids = [
		"scene_01_bridge_establishing",
		"scene_02_alien_a_question",
		"scene_03_alien_b_answer",
		"scene_04_alien_a_command",
		"scene_05_fleet_reveal"
	]
	if IntroTimeline.SCENES.size() != expected_ids.size():
		failures.append("scene_count_%d" % IntroTimeline.SCENES.size())
		return
	var previous_end = 0.0
	for scene_index in range(IntroTimeline.SCENES.size()):
		var scene: Dictionary = IntroTimeline.SCENES[scene_index]
		if str(scene.get("id", "")) != expected_ids[scene_index]:
			failures.append("scene_id_bad_%d" % scene_index)
		if absf(float(scene.get("start", -1.0)) - previous_end) > 0.001:
			failures.append("scene_timeline_gap_%d" % scene_index)
		if float(scene.get("end", -1.0)) <= float(scene.get("start", 0.0)):
			failures.append("scene_duration_bad_%d" % scene_index)
		previous_end = float(scene.get("end", 0.0))
	if absf(previous_end - IntroTimeline.TOTAL_DURATION) > 0.001:
		failures.append("total_duration_bad")
	if FAMILY_INTRO_TREE_META != "friendly_freya_family_intro_pending":
		failures.append("family_handoff_key_bad")

	var dialogue = IntroTimeline.dialogue_scenes()
	var expected_speakers = ["AlienA", "AlienB", "AlienA"]
	var expected_english = [
		"So this is the place?",
		"Yes, the planet that can't get its shit together.",
		"Let's begin"
	]
	if dialogue.size() != 3:
		failures.append("dialogue_count_%d" % dialogue.size())
		return
	for line_index in range(dialogue.size()):
		var line: Dictionary = dialogue[line_index]
		if str(line.get("speaker_id", "")) != expected_speakers[line_index]:
			failures.append("dialogue_speaker_bad_%d" % line_index)
		if str(line.get("english", "")) != expected_english[line_index]:
			failures.append("dialogue_english_bad_%d" % line_index)
		if str(line.get("runes", "")).is_empty() or str(line.get("runes", "")) == str(line.get("english", "")):
			failures.append("dialogue_runes_bad_%d" % line_index)
		if float(line.get("rune_duration", 0.0)) <= 0.0 or float(line.get("morph_duration", 0.0)) <= 0.0:
			failures.append("dialogue_progression_duration_bad_%d" % line_index)


func _validate_cast(failures: Array[String]) -> void:
	if alien_cast == null or alien_cast.get_child_count() != 3 or crew.size() != 3:
		failures.append("alien_cast_count_bad")
		return
	for cast_id in ["AlienA", "AlienB", "AlienC"]:
		var alien: Node3D = crew.get(cast_id, null)
		if alien == null or alien.get_node_or_null("AlienRig") == null:
			failures.append("alien_cast_member_missing_%s" % cast_id)
	for dialogue_scene in IntroTimeline.dialogue_scenes():
		if str(dialogue_scene.get("speaker_id", "")) == "AlienC":
			failures.append("alien_c_must_remain_silent")
	if interior_shot.get_node_or_null("InteriorEarth") == null:
		failures.append("interior_earth_missing")


func _validate_earth_geometry(failures: Array[String]) -> void:
	var expected_landmasses = ["NorthAmerica", "SouthAmerica", "Eurasia", "Africa", "Australia", "Greenland", "Antarctica"]
	for earth_path in ["InteriorEarth", "FleetEarth"]:
		var shot = interior_shot if earth_path == "InteriorEarth" else fleet_shot
		var earth: Node3D = shot.get_node_or_null(earth_path)
		if earth == null:
			continue
		if earth.find_child("PolarCap", true, false) != null:
			failures.append("earth_box_cap_present_%s" % earth_path)
		for landmass_name in expected_landmasses:
			var landmass: MeshInstance3D = earth.get_node_or_null(landmass_name)
			if landmass == null or not (landmass.mesh is ArrayMesh):
				failures.append("earth_landmass_missing_%s_%s" % [earth_path, landmass_name])


func _validate_audio(failures: Array[String]) -> void:
	if not ResourceLoader.exists(RUNE_AUDIO_PATH) or rune_audio_stream == null:
		failures.append("rune_audio_missing_or_invalid")
	if not ResourceLoader.exists(TRANSLATION_AUDIO_PATH) or translation_audio_stream == null:
		failures.append("translation_audio_missing_or_invalid")
	var event_keys: Array[String] = []
	for scene in IntroTimeline.dialogue_scenes():
		event_keys.append(str(scene["id"]) + ":rune")
		event_keys.append(str(scene["id"]) + ":translation")
	if event_keys.size() != 6:
		failures.append("speech_audio_cue_count_%d" % event_keys.size())
	var saved_events = played_audio_events.duplicate()
	played_audio_events.clear()
	_fire_crossed_audio_events(0.0, IntroTimeline.TOTAL_DURATION)
	for event_key in event_keys:
		if not played_audio_events.has(event_key):
			failures.append("speech_audio_event_unscheduled_%s" % event_key)
	played_audio_events = saved_events
	if rune_audio_player != null:
		rune_audio_player.stop()
	if translation_audio_player != null:
		translation_audio_player.stop()


func _validate_fleet(failures: Array[String]) -> void:
	if fleet_root == null or fleet_root.get_child_count() != IntroTimeline.FLEET_SHIP_COUNT or fleet_ships.size() != 8:
		failures.append("fleet_ship_count_bad")
		return
	for ship_index in range(fleet_ships.size()):
		var ship: Node3D = fleet_ships[ship_index]
		if str(ship.get_meta("visual_signature", "")) != "friendly_freya_opaque_ufo_v1":
			failures.append("fleet_ship_signature_bad_%d" % ship_index)
		if not bool(ship.get_meta("opaque_exterior", false)) or ship.find_child("*Interior*", true, false) != null:
			failures.append("fleet_ship_interior_exposed_%d" % ship_index)
		if not _all_mesh_materials_opaque(ship):
			failures.append("fleet_ship_transparency_bad_%d" % ship_index)
	if fleet_shot.get_node_or_null("FleetEarth") == null:
		failures.append("fleet_earth_missing")


func _all_mesh_materials_opaque(root: Node) -> bool:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node = stack.pop_back()
		if node is MeshInstance3D:
			var material = (node as MeshInstance3D).material_override
			if material is BaseMaterial3D:
				var base_material = material as BaseMaterial3D
				if base_material.albedo_color.a < 0.999 or base_material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					return false
		for child in node.get_children():
			stack.append(child)
	return true


func _validate_seekable_bubbles(failures: Array[String]) -> void:
	for dialogue_scene in IntroTimeline.dialogue_scenes():
		var scene_id = str(dialogue_scene["id"])
		var scene_start = float(dialogue_scene["start"])
		var rune_duration = float(dialogue_scene["rune_duration"])
		var morph_duration = float(dialogue_scene["morph_duration"])
		var runes = str(dialogue_scene["runes"])
		var english = str(dialogue_scene["english"])
		var rune_checkpoint = scene_start + rune_duration * 0.5
		var morph_checkpoint = scene_start + rune_duration + morph_duration * 0.5
		var english_checkpoint = scene_start + rune_duration + morph_duration + 0.12

		_apply_timeline_time(rune_checkpoint)
		var rune_output = speech_text_label.text
		if not speech_bubble.visible or rune_output.is_empty() or rune_output == english or not runes.begins_with(rune_output):
			failures.append("bubble_rune_stage_bad_%s" % scene_id)

		_apply_timeline_time(morph_checkpoint)
		var morph_output = speech_text_label.text
		if not speech_bubble.visible or morph_output.is_empty() or morph_output == runes or morph_output == english or not english.begins_with(morph_output.substr(0, 1)):
			failures.append("bubble_morph_stage_bad_%s" % scene_id)

		_apply_timeline_time(english_checkpoint)
		if not speech_bubble.visible or speech_text_label.text != english:
			failures.append("bubble_english_not_locked_%s" % scene_id)
		else:
			var speaker: Node3D = crew.get(str(dialogue_scene["speaker_id"]), null)
			var projected_head = intro_camera.unproject_position(speaker.global_position + Vector3(0.0, 1.48, 0.0))
			if absf(speech_tail.position.x - projected_head.x) > BUBBLE_SIZE.x * 0.46 or speech_tail.position.y >= projected_head.y:
				failures.append("bubble_not_anchored_over_speaker_%s" % scene_id)
	_apply_timeline_time(timeline_time)


func _validate_camera_pullback(failures: Array[String]) -> void:
	var fleet_scene: Dictionary = IntroTimeline.SCENES[IntroTimeline.SCENES.size() - 1]
	_apply_fleet_camera(float(fleet_scene["start"]) + 0.001, fleet_scene)
	# Measure the literal dolly away from the hero UFO that fills the first
	# fleet-reveal frame. The camera also retargets toward the whole formation.
	var hero_position: Vector3 = fleet_ships[0].get_meta("base_position", Vector3.ZERO)
	var start_distance = intro_camera.position.distance_to(hero_position)
	_apply_fleet_camera(float(fleet_scene["end"]) - 0.001, fleet_scene)
	var end_distance = intro_camera.position.distance_to(hero_position)
	if end_distance <= start_distance * 3.0:
		failures.append("fleet_camera_pullback_too_small_%.2f" % (end_distance / maxf(start_distance, 0.001)))
	_apply_timeline_time(IntroTimeline.time_for_view("fleet"))
	if not fleet_shot.visible or interior_shot.visible or speech_bubble.visible:
		failures.append("fleet_final_visibility_bad")
	var viewport_rect = get_viewport().get_visible_rect().grow(-8.0)
	for ship_index in range(fleet_ships.size()):
		var ship = fleet_ships[ship_index]
		var screen_position = intro_camera.unproject_position(ship.global_position)
		if intro_camera.is_position_behind(ship.global_position) or not viewport_rect.has_point(screen_position):
			failures.append("fleet_ship_out_of_final_frame_%d" % ship_index)
	var fleet_earth: Node3D = fleet_shot.get_node_or_null("FleetEarth")
	if fleet_earth == null or intro_camera.is_position_behind(fleet_earth.global_position) or not viewport_rect.has_point(intro_camera.unproject_position(fleet_earth.global_position)):
		failures.append("fleet_earth_out_of_final_frame")
	_apply_timeline_time(timeline_time)
