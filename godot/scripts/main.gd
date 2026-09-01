extends Node3D

const DogAgentScript = preload("res://scripts/dog_agent.gd")
const BuildingFactoryScript = preload("res://scripts/building_factory.gd")
const TreeFactoryScript = preload("res://scripts/tree_factory.gd")
const MiniMapScript = preload("res://scripts/minimap.gd")
const ClaimUtilsScript = preload("res://scripts/claim_utils.gd")
const AlienVisualFactoryScript = preload("res://scripts/alien_visual_factory.gd")
const FamilyIntroTimeline = preload("res://scripts/family_intro_timeline.gd")
const FamilyVisualFactory = preload("res://scripts/family_visual_factory.gd")

const INTRO_SCENE_PATH = "res://scenes/IntroCutscene.tscn"
const FAMILY_INTRO_TREE_META = "friendly_freya_family_intro_pending"
const FAMILY_BARK_AUDIO_PATH = "res://assets/audio/barks/bark_real_01.wav"
const FAMILY_LOUD_BARK_AUDIO_PATH = "res://assets/audio/barks/aggressive_bark_01.wav"
const FAMILY_PILL_REVEAL_POSITION = Vector3(0.0, 1.09, -0.4)
const FAMILY_PILL_REVEAL_BOB = 0.008

const MAP_W = 144.0
const MAP_H = 118.0
const ROAD_W = 4.2
const SIDEWALK_W = 1.15
const ALLEY_W = 2.25
const MAP_EDGE_FIELD_MARGIN = 64.0
const MAP_EDGE_ROAD_EXTENSION = 36.0
const MAP_EDGE_GROUND_Y = -0.03

const FREYA_BASE_SPEED = 4.6
const FREYA_RUN_MULT = 1.55
const FREYA_STICK_RUN_MULT = 1.36
const CAMERA_ORBIT_SPEED = 1.95
const CAMERA_PLANAR_BASE = 16.4
const CAMERA_HEIGHT_BASE = 14.3
const CAMERA_ZOOM_MIN = 8.6
const CAMERA_ZOOM_MAX = 24.5
const CAMERA_ZOOM_STEP = 1.0
const CAMERA_ZOOM_SMOOTH = 7.0
const STICK_VISUAL_SCALE = 1.2
const STICK_THICKNESS_MULT = 1.45
const STICK_MOUTH_FORWARD_OFFSET = -0.08
const STICK_MOUTH_UP_OFFSET = -0.02
const STICK_MOUTH_RIGHT_OFFSET = 0.0
const STICK_MOUTH_PITCH_DEG = -2.0
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
const PEE_SAMPLE_CANDIDATES = [
	"res://assets/audio/pee/dog_urination_stream_330024.mp3"
]
const PEE_WATER_LAYER_SAMPLE_CANDIDATES = [
	"res://assets/audio/pee/urinating_bathroom_17120.mp3"
]
const EAT_FOOD_SAMPLE_CANDIDATES = [
	"res://assets/audio/eat/dog_eating_dinner_760336.mp3"
]
const EAT_POOP_SAMPLE_CANDIDATES = [
	"res://assets/audio/eat/wet_sloppy_eating_382671.mp3",
	"res://assets/audio/eat/wet_sloppy_eating_alt_382673.mp3"
]
const EAT_BONE_SAMPLE_CANDIDATES = [
	"res://assets/audio/eat/dog_chewing_crunchy_456376.mp3"
]
const VOMIT_SAMPLE_CANDIDATES = [
	"res://assets/audio/vomit/dog_wheezing_coughing_825417.mp3"
]
const EAT_SOUND_START_OFFSET_SEC = 0.1
const EAT_BONE_SOUND_START_OFFSET_SEC = 0.05
const PEE_SOUND_START_OFFSET_SEC = 0.02
const PEE_DRIBBLE_OFFSET_JITTER_SEC = 0.16
const PEE_DRIBBLE_BURST_MIN_SEC = 0.14
const PEE_DRIBBLE_BURST_MAX_SEC = 0.34
const PEE_DRIBBLE_GAP_MIN_SEC = 0.02
const PEE_DRIBBLE_GAP_MAX_SEC = 0.08
const VOMIT_SOUND_START_OFFSET_SEC = 0.18
const FREYA_STRENGTH_MIN_LEVEL = 1
const FREYA_STRENGTH_MAX_LEVEL = 5
const OBJECTIVE_CLAIM_TARGET = 10
const OBJECTIVE_HYDRANT_TARGET = 8
const CLAIM_TARGET_NONE = 0
const CLAIM_TARGET_LIGHT_POLE = 1
const CLAIM_TARGET_TREE = 2
const CLAIM_TARGET_FIRE_HYDRANT = 3
const CLAIM_TARGET_ALIEN_BUILDING = 4
const CLAIM_TARGET_MAILBOX = 5
const CLAIM_OWNER_NONE = ClaimUtilsScript.OWNER_NONE
const CLAIM_OWNER_FREYA = ClaimUtilsScript.OWNER_FREYA
const CLAIM_OWNER_ENEMY = ClaimUtilsScript.OWNER_ENEMY
const CLAIM_RANGE = 1.8
const CLAIM_FILL_TIME = 2.75
const CLAIM_RING_PULSE_SPEED = 2.25
const CLAIM_PEE_SOURCE_BACK_OFFSET = 0.34
const CLAIM_PEE_SOURCE_UP_OFFSET = 0.34
const CLAIM_PEE_SOURCE_RIGHT_OFFSET = 0.0
const CLAIM_PEE_STREAM_RADIUS = 0.028
const CLAIM_PEE_TARGET_POLE_HEIGHT = 0.44
const CLAIM_PEE_TARGET_TREE_HEIGHT = 0.56
const SOCIALIZE_RANGE = 4.2
const DOG_ARMY_ALIGN_TIME = 4.0
const HUNGER_IDLE_PER_SEC = 0.025
const HUNGER_WALK_PER_SEC = 0.35
const HUNGER_RUN_PER_SEC = 0.85
const HUNGER_ACTIVE_ACTION_PER_SEC = 1.1
const SOCIALIZATION_HUNGER_PER_SEC = 6.5
const POSSESSED_SOCIAL_VOMIT_PER_SEC = 12.0
const DOG_WRONG_GUESS_FLEE_TIME = 3.2
const DOG_FLEE_SPEED_MULT = 1.65
const ALIEN_POSSESSION_CHANCE = 0.75
const ALIEN_DISCOMFORT_RADIUS = 5.4
const ALIEN_EXPEL_BARK_TIME = 0.68
const ALIEN_TRAVEL_SPEED = 5.8
const ALIEN_NEAREST_BUILDING_POOL = 3
const ALIEN_RYAH_REPEL_TIME = 0.72
const ALIEN_BUILDING_MIN_INTEGRITY = 0.08
const ALIEN_BUILDING_WEAKEN_TIME = 5.5
const ALIEN_STOREFRONT_REINFORCEMENT_RADIUS = 22.0
const ALIEN_STOREFRONT_REINFORCEMENT_PER_SOURCE = 0.35
const MAX_FREE_ALIENS = 8
const FREE_ALIEN_SPAWN_MIN_SEC = 10.0
const FREE_ALIEN_SPAWN_MAX_SEC = 17.0
const FREE_ALIEN_APPROACH_RADIUS = 5.4
const FREE_ALIEN_ROAM_RADIUS = 5.8
const FREE_ALIEN_ROAM_SPEED = 4.0
const ALIEN_VISUAL_SCALE = 0.84
const ALIEN_COLLISION_RADIUS = 0.27
const ALIEN_POSSESSION_REACH = 0.38
const ALIEN_MOVE_SUBSTEP = 0.14
const INTERACT_HIGHLIGHT_BOB_SPEED = 5.5
const INTERACT_HIGHLIGHT_BOB_AMPLITUDE = 0.03
const OCCLUSION_UPDATE_INTERVAL = 0.1
const OCCLUSION_MOVE_EPS = 0.12
const MINIMAP_UPDATE_INTERVAL = 0.08
const INTERACT_HIGHLIGHT_UPDATE_INTERVAL = 0.08
const HOME_DOG_BOWL_EAT_RANGE = 1.55
const CLAIM_RING_UPDATE_INTERVAL = 0.05
const HUD_UPDATE_INTERVAL = 0.08
const COLLISION_GRID_SIZE = 12.0
const STATIC_OBSTACLE_GRID_SIZE = 4.0
const FREYA_COLLISION_RADIUS = 0.34
const DOG_COLLISION_RADIUS = 0.28
const DUMPSTER_COLLISION_RADIUS = 0.48
const STREET_POLE_COLLISION_RADIUS = 0.2
const FIRE_HYDRANT_COLLISION_RADIUS = 0.18
const MAILBOX_COLLISION_RADIUS = 0.24
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
const HOME_PREFERRED_MIN_AREA = 68.0
const HOME_PREFERRED_MIN_SHORT_SIDE = 5.0
const HOME_MIN_USABLE_AREA = 42.0
const CITY_BLOCK_COLUMNS = 5
const CITY_BLOCK_ROWS = 5
const TREE_COLLISION_SCALE = 0.34
const STICK_PICKUP_RANGE = 1.55
const BONE_PICKUP_RANGE = 1.55
const FREYA_PRIMARY_MODEL = "res://assets/models/freya_portuguese_water_dog.glb"
const FREYA_MODEL_TARGET_LENGTH = 1.56
const FREYA_MODEL_TARGET_HEIGHT = 1.06
const FREYA_MODEL_CANDIDATES = [
	"res://assets/models/freya_portuguese_water_dog.glb"
]
const NPC_DOG_MODEL_CANDIDATES = [
	FREYA_PRIMARY_MODEL
]
const NPC_BREED_SEQUENCE = [
	"labrador",
	"pitbull",
	"boxer",
	"chihuahua",
	"retriever",
	"shepherd",
	"husky",
	"terrier",
	"hound",
	"bulldog",
	"poodle",
	"mixed"
]
const DOG_PARK_BREED_SEQUENCE = [
	"labrador",
	"retriever",
	"husky",
	"pitbull",
	"terrier",
	"poodle",
	"shepherd",
	"chihuahua"
]
const DOG_BREED_DEFINITIONS = {
	"labrador": {
		"display_name": "Labrador",
		"breed_profile": "labrador",
		"model_candidates": [
			FREYA_PRIMARY_MODEL
		],
		"coat_palette": [
			Color8(198, 169, 130),
			Color8(121, 98, 79),
			Color8(42, 39, 37)
		],
		"speed_range": Vector2(1.84, 2.48),
		"base_scale": 1.04,
		"scale_jitter": 0.08,
		"target_length_mult": 1.08,
		"target_height_mult": 1.03,
		"mixable": true
	},
	"pitbull": {
		"display_name": "Pitbull",
		"breed_profile": "pitbull",
		"model_candidates": [
			FREYA_PRIMARY_MODEL
		],
		"coat_palette": [
			Color8(144, 124, 107),
			Color8(86, 78, 74),
			Color8(193, 180, 169)
		],
		"speed_range": Vector2(1.76, 2.42),
		"base_scale": 0.95,
		"scale_jitter": 0.08,
		"target_length_mult": 0.9,
		"target_height_mult": 0.9,
		"mixable": true
	},
	"boxer": {
		"display_name": "Boxer",
		"breed_profile": "boxer",
		"model_candidates": [
			FREYA_PRIMARY_MODEL
		],
		"coat_palette": [
			Color8(170, 120, 90),
			Color8(124, 92, 72),
			Color8(62, 55, 50)
		],
		"speed_range": Vector2(1.9, 2.62),
		"base_scale": 0.98,
		"scale_jitter": 0.09,
		"target_length_mult": 0.96,
		"target_height_mult": 0.96,
		"mixable": true
	},
	"chihuahua": {
		"display_name": "Chihuahua",
		"breed_profile": "chihuahua",
		"model_candidates": [
			FREYA_PRIMARY_MODEL
		],
		"coat_palette": [
			Color8(194, 163, 128),
			Color8(160, 123, 92),
			Color8(80, 62, 50)
		],
		"speed_range": Vector2(2.06, 2.95),
		"base_scale": 0.9,
		"scale_jitter": 0.08,
		"target_length_mult": 0.78,
		"target_height_mult": 0.78,
		"mixable": true
	},
	"retriever": {
		"display_name": "Retriever",
		"breed_profile": "retriever",
		"model_candidates": [
			FREYA_PRIMARY_MODEL
		],
		"coat_palette": [
			Color8(195, 158, 120),
			Color8(166, 128, 94),
			Color8(225, 203, 170)
		],
		"speed_range": Vector2(1.9, 2.55),
		"base_scale": 1.02,
		"scale_jitter": 0.1,
		"target_length_mult": 1.01,
		"target_height_mult": 0.99,
		"mixable": true
	},
	"shepherd": {
		"display_name": "Shepherd",
		"breed_profile": "shepherd",
		"model_candidates": [
			FREYA_PRIMARY_MODEL
		],
		"coat_palette": [
			Color8(132, 101, 78),
			Color8(78, 70, 62),
			Color8(177, 142, 106)
		],
		"speed_range": Vector2(2.0, 2.7),
		"base_scale": 1.03,
		"scale_jitter": 0.11,
		"target_length_mult": 1.05,
		"target_height_mult": 1.03,
		"mixable": true
	},
	"husky": {
		"display_name": "Husky",
		"breed_profile": "husky",
		"model_candidates": [
			FREYA_PRIMARY_MODEL
		],
		"coat_palette": [
			Color8(98, 101, 112),
			Color8(138, 142, 149),
			Color8(211, 214, 218)
		],
		"speed_range": Vector2(2.05, 2.78),
		"base_scale": 0.93,
		"scale_jitter": 0.09,
		"target_length_mult": 0.96,
		"target_height_mult": 0.94,
		"mixable": true
	},
	"terrier": {
		"display_name": "Terrier",
		"breed_profile": "terrier",
		"model_candidates": [
			FREYA_PRIMARY_MODEL
		],
		"coat_palette": [
			Color8(116, 94, 76),
			Color8(208, 188, 168),
			Color8(68, 63, 58)
		],
		"speed_range": Vector2(1.85, 2.62),
		"base_scale": 0.9,
		"scale_jitter": 0.12,
		"target_length_mult": 0.84,
		"target_height_mult": 0.82,
		"mixable": true
	},
	"hound": {
		"display_name": "Hound",
		"breed_profile": "hound",
		"model_candidates": [
			FREYA_PRIMARY_MODEL
		],
		"coat_palette": [
			Color8(151, 111, 86),
			Color8(108, 86, 67),
			Color8(214, 197, 182)
		],
		"speed_range": Vector2(1.88, 2.52),
		"base_scale": 0.98,
		"scale_jitter": 0.1,
		"target_length_mult": 1.02,
		"target_height_mult": 0.96,
		"mixable": true
	},
	"bulldog": {
		"display_name": "Bulldog",
		"breed_profile": "bulldog",
		"model_candidates": [
			FREYA_PRIMARY_MODEL
		],
		"coat_palette": [
			Color8(172, 140, 116),
			Color8(196, 176, 153),
			Color8(122, 101, 84)
		],
		"speed_range": Vector2(1.65, 2.28),
		"base_scale": 0.94,
		"scale_jitter": 0.09,
		"target_length_mult": 1.04,
		"target_height_mult": 0.8,
		"mixable": true
	},
	"poodle": {
		"display_name": "Poodle",
		"breed_profile": "poodle",
		"model_candidates": [
			FREYA_PRIMARY_MODEL
		],
		"coat_palette": [
			Color8(38, 36, 35),
			Color8(226, 217, 206),
			Color8(167, 146, 123)
		],
		"speed_range": Vector2(1.92, 2.6),
		"base_scale": 0.92,
		"scale_jitter": 0.11,
		"target_length_mult": 0.9,
		"target_height_mult": 0.88,
		"mixable": true
	},
	"mixed": {
		"display_name": "Mixed Breed",
		"breed_profile": "mixed",
		"model_candidates": NPC_DOG_MODEL_CANDIDATES,
		"mix_components": [
			"labrador",
			"pitbull",
			"boxer",
			"chihuahua",
			"retriever",
			"shepherd",
			"husky",
			"terrier",
			"hound",
			"bulldog",
			"poodle"
		],
		"coat_palette": [
			Color8(84, 74, 66),
			Color8(132, 108, 86),
			Color8(189, 164, 141),
			Color8(214, 203, 190)
		],
		"speed_range": Vector2(1.8, 2.58),
		"base_scale": 0.97,
		"scale_jitter": 0.13,
		"target_length_mult": 0.95,
		"target_height_mult": 0.92,
		"mixable": false
	}
}
const NPC_DOG_COUNT = 24
const DOG_PARK_NPC_COUNT = 8
const NPC_SIDEWALK_PREF_CHANCE = 0.86
const FREYA_OCCLUSION_SAMPLE_BLOCK_THRESHOLD = 4
const FREYA_SOCIAL_DANCE_RADIUS = 0.58
const FREYA_SOCIAL_DANCE_SPEED = 2.15
const FREYA_SOCIAL_DANCE_SPIN_SPEED = 6.7
const NPC_MODEL_SCALE_OVERRIDES = {}

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
var city_blocks: Array[Dictionary] = []
var buildings: Array = []
var trees: Array = []
var fire_hydrants: Array = []
var mailboxes: Array = []

var dogs: Array = []
var alien_transfers: Array = []
var free_aliens: Array = []
var poops: Array = []
var sticks: Array = []
var dumpsters: Array = []
var bones: Array = []
var store_foods: Array = []
var street_poles: Array = []
var vomit_puddles: Array = []
var bark_pulses: Array = []
var vomit_sprays: Array = []
var store_entry_indicators: Array = []
var store_interior_nodes: Array[Node3D] = []
var store_shell_nodes: Array[Node3D] = []
var store_building_indices: Array[int] = []
var freya_home_index = -1
var freya_home_exterior_root: Node3D
var freya_home_interior_root: Node3D
var freya_home_bowl_node: Node3D
var freya_home_bowl_position = Vector2.ZERO
var suburban_yard_root: Node3D
var facade_clearance_rects: Array[Rect2] = []
var suburban_yard_detail_count = 0
var suburban_driveway_count = 0
var freya_home_backyard_detail_count = 0
var freya_inside_home = false
var ryah_diane_node: Node3D
var ryah_diane_left_leg: Node3D
var ryah_diane_right_leg: Node3D
var ryah_diane_left_arm: Node3D
var ryah_diane_right_arm: Node3D
var ryah_diane_waypoints = PackedVector2Array()
var ryah_diane_waypoint_index = 0
var ryah_diane_walk_phase = 0.0
var ryah_alien_cry_timer = 0.0
var ryah_alien_cry_visual_root: Node3D
var freya_alien_discomfort = 0.0
var alien_transfer_serial = 0
var alien_expulsion_count = 0
var alien_building_occupation_count = 0
var ryah_alien_defense_count = 0
var alien_model_preview_node: Node3D
var army_collar_preview_nodes: Array[Node3D] = []
var blocking_building_rects: Array[Rect2] = []
var blocking_building_grid: Dictionary = {}
var static_obstacle_grid: Dictionary = {}
var store_walk_blockers: Array[Rect2] = []

var dog_park = Rect2()
var freya
var freya_hunger = 34.0
var freya_vomit = 0.0
var freya_social = 24.0
var freya_strength = FREYA_STRENGTH_MIN_LEVEL
var freya_vomit_timer = 0.0
var freya_eat_timer = 0.0
var freya_move_dir = Vector3.ZERO
var freya_social_dance_phase = 0.0
var camera_focus = Vector3.ZERO
var camera_orbit_angle = 0.0
var camera_planar_distance = CAMERA_PLANAR_BASE
var camera_zoom_target = CAMERA_PLANAR_BASE

var world_time = 0.0
var poop_spawn_timer = 4.1
var occlusion_update_timer = 0.0
var last_occlusion_cam_pos = Vector3(100000.0, 100000.0, 100000.0)
var last_occlusion_freya_pos = Vector3(-100000.0, -100000.0, -100000.0)
var minimap_update_timer = 0.0
var store_focus_timer = 0.0
var interact_highlight_update_timer = 0.0
var claim_ring_update_timer = 0.0
var hud_update_timer = 0.0
var active_store_index = -1
var perf_benchmark_enabled = false
var perf_benchmark_warmup = 0.0
var perf_benchmark_elapsed = 0.0
var perf_benchmark_frames = 0
var perf_profile_gameplay = false
var perf_profile_frames = 0
var perf_profile_usec: Dictionary = {}

var grass_material: Material
var road_material: Material
var sidewalk_material: Material
var alley_material: Material
var dog_park_material: Material
var far_field_material: Material
var far_road_material: Material

var poop_material: StandardMaterial3D
var poop_blob_mesh: SphereMesh
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
var claim_ring_enemy_material: StandardMaterial3D
var claim_pee_stream_material: StandardMaterial3D
var claim_pee_splash_material: StandardMaterial3D
var alien_core_material: StandardMaterial3D
var alien_trail_material: StandardMaterial3D
var alien_body_material: StandardMaterial3D
var alien_face_material: StandardMaterial3D
var alien_horn_material: StandardMaterial3D
var alien_eye_material: StandardMaterial3D
var alien_fang_material: StandardMaterial3D
var alien_building_material: StandardMaterial3D
var alien_building_accent_material: StandardMaterial3D
var ryah_tear_material: StandardMaterial3D
var vomit_material_a: StandardMaterial3D
var vomit_material_b: StandardMaterial3D
var bone_material: StandardMaterial3D
var store_food_materials: Array[StandardMaterial3D] = []
var interact_highlight_material: StandardMaterial3D

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
var hunger_value_label: Label
var vomit_value_label: Label
var social_value_label: Label
var strength_value_label: Label
var unease_label: Label
var status_label: Label
var status_timer = 0.0
var objectives_panel: Panel
var objectives_list_label: Label
var stats_panel: Panel
var stats_list_label: Label
var objective_puke_on_dog_complete = false
var claim_meter_panel: Panel
var claim_meter_label: Label
var claim_meter_bar: TextureProgressBar
var active_claim_target_type = CLAIM_TARGET_NONE
var active_claim_target_index = -1
var claim_pee_stream_node: Node3D
var claim_pee_stream_segments: Array[MeshInstance3D] = []
var claim_pee_splash_node: MeshInstance3D
var claim_pee_audio_player: AudioStreamPlayer
var claim_pee_stream: AudioStream
var claim_pee_water_audio_player: AudioStreamPlayer
var claim_pee_water_stream: AudioStream
var claim_pee_burst_timer = 0.0
var claim_pee_gap_timer = 0.0
var interact_highlight_root: Node3D
var interact_highlights := {}

var minimap
var minimap_zoom_slider: HSlider
var store_focus_layer: CanvasLayer
var store_focus_overlay: ColorRect
var pause_menu_layer: CanvasLayer
var pause_menu_panel: Panel
var pause_menu_open = false
var pause_intro_button: Button
var bark_sfx_players: Array[AudioStreamPlayer] = []
var bark_sfx_streams_passive: Array[AudioStream] = []
var bark_sfx_streams_aggressive: Array[AudioStream] = []
var bark_sfx_cursor = 0
var bark_last_clip_idx = -1
var bark_sequences: Array = []
var eat_sfx_player: AudioStreamPlayer
var eat_sfx_streams_food: Array[AudioStream] = []
var eat_sfx_streams_poop: Array[AudioStream] = []
var eat_sfx_streams_bone: Array[AudioStream] = []
var vomit_sfx_player: AudioStreamPlayer
var vomit_sfx_streams: Array[AudioStream] = []
var aggressive_bark_pressure = 0.0
var aggressive_bark_nearby_count = 0
var pause_controls_button: Button
var pause_howto_button: Button
var pause_controls_panel: Panel
var pause_howto_panel: Panel
var storefront_texture_cache: Dictionary = {}

# The family prologue runs in this live gameplay scene so its house, furniture,
# Freya, and Ryah are the exact objects the player keeps after the final beat.
var family_intro_requested = false
var family_intro_active = false
var family_intro_static = false
var family_intro_time = 0.0
var family_intro_current_scene_id = ""
var family_intro_played_events: Dictionary = {}
var family_intro_root: Node3D
var family_far_wall: Node3D
var family_gene: Node3D
var family_zoe: Node3D
var family_gene_left_arm: Node3D
var family_gene_right_arm: Node3D
var family_pill_reveal: Node3D
var family_back_roof: MeshInstance3D
var family_gene_beam: Node3D
var family_zoe_beam: Node3D
var family_ryah_beam: Node3D
var family_bark_wave: Node3D
var family_loud_bark_wave: Node3D
var family_intro_layer: CanvasLayer
var family_dialogue_panel: Panel
var family_speaker_label: Label
var family_dialogue_label: Label
var family_skip_button: Button
var family_scene_id_label: Label
var family_bark_player: AudioStreamPlayer
var family_loud_bark_player: AudioStreamPlayer
var family_bark_stream: AudioStream
var family_loud_bark_stream: AudioStream
var family_focus_point = Vector3.ZERO
var family_front_sign = 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var family_view = OS.get_environment("FREYA_FAMILY_INTRO_VIEW").strip_edges().to_lower()
	var tree_requested_family_intro = bool(get_tree().get_meta(FAMILY_INTRO_TREE_META, false))
	if get_tree().has_meta(FAMILY_INTRO_TREE_META):
		# One-shot handoff: a later direct Main load must never replay stale state.
		get_tree().remove_meta(FAMILY_INTRO_TREE_META)
	family_intro_requested = tree_requested_family_intro or not family_view.is_empty()
	perf_benchmark_enabled = OS.get_environment("FREYA_PERF_BENCHMARK") == "1"
	perf_profile_gameplay = OS.get_environment("FREYA_PERF_PROFILE_GAMEPLAY") == "1"
	var run_headless_checks = OS.has_feature("server") or DisplayServer.get_name() == "headless"
	if perf_benchmark_enabled:
		print("PERF_BENCHMARK_ENABLED")
	if run_headless_checks or not OS.get_environment("FREYA_VISUAL_VIEW").is_empty() or not OS.get_environment("FREYA_ALIEN_VIEW").is_empty() or not family_view.is_empty():
		# Stable city generation makes automated checks and visual-regression
		# screenshots comparable instead of occasionally failing on a rare layout.
		rng.seed = 20260831
	else:
		rng.randomize()
	_configure_input()
	_create_render_setup()
	_create_world_roots()
	# Headless validation has no audio device. Leaving audio unloaded there avoids
	# decoder/playback resources surviving the test runner's immediate shutdown.
	if not run_headless_checks:
		_create_audio_setup()
	_create_prop_materials()

	_generate_city_layout()
	_create_ground_materials()
	_build_ground_meshes()
	_build_dog_park()
	_build_city_buildings()
	_mark_freya_home()
	_mark_store_buildings()
	_build_freya_home_interior()
	_build_suburban_yard_details()
	_batch_neighborhood_building_details()
	_add_building_sidewalks()
	_spawn_street_poles()
	_spawn_fire_hydrants()
	_spawn_alley_dumpsters()
	_populate_trees()
	_rebuild_static_obstacle_grid()
	_build_grass_spikes()
	_spawn_sticks(40)
	_populate_store_foods()

	_spawn_freya_and_dogs()
	_seed_poops(44)
	_create_ui()
	_configure_alien_visual_view()
	_sync_minimap_static()
	_update_minimap_dynamic(0.0)

	camera_focus = freya.global_position + Vector3(0.0, 0.95, 0.0)
	_update_camera(0.0)
	_update_roof_occlusion(0.0)
	_update_ui()
	if family_intro_requested:
		_begin_family_intro(family_view)

	var checks_failed = false
	if run_headless_checks or OS.get_environment("FREYA_SMOKE") == "1":
		if not _run_headless_smoke_checks():
			checks_failed = true
	if run_headless_checks or OS.get_environment("FREYA_VALIDATE") == "1":
		if not _run_targeted_validation_checks():
			checks_failed = true
	if run_headless_checks:
		if not family_intro_active:
			_begin_family_intro("family_home", true)
		if not _run_family_intro_validation():
			checks_failed = true
	if checks_failed:
		get_tree().quit(1)

func _configure_alien_visual_view() -> void:
	var visual_view = OS.get_environment("FREYA_VISUAL_VIEW").strip_edges().to_lower()
	if visual_view == "pause_menu":
		_toggle_pause_menu(1)
		return
	if visual_view == "dog_park_friendly" and freya != null:
		freya.global_position = Vector3(dog_park.get_center().x, 0.0, dog_park.get_center().y + 1.4)
		camera_orbit_angle = 0.18
		camera_zoom_target = 10.8
		var review_offsets = [
			Vector3(-2.7, 0.0, -1.4),
			Vector3(-0.9, 0.0, -1.4),
			Vector3(0.9, 0.0, -1.4),
			Vector3(2.7, 0.0, -1.4),
			Vector3(-2.7, 0.0, 1.4),
			Vector3(-0.9, 0.0, 1.4),
			Vector3(0.9, 0.0, 1.4),
			Vector3(2.7, 0.0, 1.4)
		]
		var park_visual_index = 0
		for dog_index in range(dogs.size()):
			var state: Dictionary = dogs[dog_index]
			if not bool(state.get("park", false)):
				continue
			var dog: Node3D = state.get("node", null)
			if dog == null or not is_instance_valid(dog):
				continue
			dog.global_position = freya.global_position + review_offsets[park_visual_index]
			if dog.has_method("force_face_direction"):
				dog.call("force_face_direction", Vector3(1.0, 0.0, 1.0).normalized(), 1.0)
			state["speed"] = 0.0
			state["dir"] = Vector3.ZERO
			state["wander"] = 999.0
			state["alien_possessed"] = false
			# Show the state on both an imported breed and a reshaped Freya-rig breed.
			if park_visual_index == 0 or park_visual_index == 4:
				state["army_aligned"] = true
				if dog.has_method("set_army_aligned"):
					dog.call("set_army_aligned", true)
			dogs[dog_index] = state
			park_visual_index += 1
			if park_visual_index >= review_offsets.size():
				break
		return
	if visual_view == "army_collars" and freya != null:
		var review_center = Vector3(dog_park.get_center().x, 0.0, dog_park.get_center().y)
		freya.global_position = review_center + Vector3(0.0, 0.0, 14.0)
		freya.visible = false
		if ui_layer != null:
			ui_layer.visible = false
		for state in dogs:
			var hidden_dog: Node3D = state.get("node", null)
			if hidden_dog != null and is_instance_valid(hidden_dog):
				hidden_dog.visible = false
		var target_breeds = ["labrador", "pitbull", "chihuahua", "poodle"]
		var review_offsets = [-2.55, -0.85, 0.85, 2.55]
		for breed_slot in range(target_breeds.size()):
			for dog_index in range(dogs.size()):
				var state: Dictionary = dogs[dog_index]
				if str(state.get("breed_id", "")) != target_breeds[breed_slot]:
					continue
				var dog: Node3D = state.get("node", null)
				if dog == null or not is_instance_valid(dog):
					continue
				dog.visible = true
				dog.global_position = review_center + Vector3(float(review_offsets[breed_slot]), 0.0, 0.12 * float(breed_slot % 2))
				if dog.has_method("force_face_direction"):
					var face = Vector3(-0.48 if breed_slot % 2 == 0 else 0.48, 0.0, -0.88).normalized()
					dog.call("force_face_direction", face, 1.0)
				state["army_aligned"] = true
				state["alien_possessed"] = false
				state["speed"] = 0.0
				state["dir"] = Vector3.ZERO
				state["wander"] = 999.0
				if dog.has_method("set_army_aligned"):
					dog.call("set_army_aligned", true)
				dogs[dog_index] = state
				army_collar_preview_nodes.append(dog)
				break
		return
	var view = OS.get_environment("FREYA_ALIEN_VIEW").strip_edges().to_lower()
	if view.is_empty() or freya == null:
		return
	if view == "model":
		freya.global_position = Vector3(dog_park.get_center().x, 0.0, dog_park.get_center().y)
		var model_preview = _create_alien_transfer_visual()
		dynamic_root.add_child(model_preview)
		model_preview.name = "AlienImpModelPreview"
		model_preview.global_position = freya.global_position + Vector3(1.15, 0.0, 0.18)
		_update_alien_character_pose(model_preview, 0.12, Vector3(-0.35, 0.0, -1.0).normalized(), 0.42, 0.45)
		alien_model_preview_node = model_preview
		if ui_layer != null:
			ui_layer.visible = false
		for preview_index in range(dogs.size()):
			var preview_state: Dictionary = dogs[preview_index]
			var preview_dog: Node3D = preview_state.get("node", null)
			if preview_dog != null and is_instance_valid(preview_dog):
				preview_dog.visible = false
			preview_state["alien_possessed"] = false
			dogs[preview_index] = preview_state
		return
	elif view == "occupied":
		var best_index = -1
		var best_distance = 1000000000.0
		var park_center = dog_park.get_center()
		for building_index in range(buildings.size()):
			var building: Dictionary = buildings[building_index]
			if bool(building.get("is_freya_home", false)) or bool(building.get("is_store", false)):
				continue
			var footprint: Rect2 = building.get("footprint", Rect2())
			var distance = footprint.get_center().distance_squared_to(park_center)
			if distance < best_distance:
				best_distance = distance
				best_index = building_index
		if best_index >= 0:
			_occupy_building_with_alien(best_index, 70001)
			var target: Dictionary = buildings[best_index]
			var fp: Rect2 = target.get("footprint", Rect2())
			var front_sign = 1.0 if bool(target.get("front_is_south", true)) else -1.0
			freya.global_position = Vector3(fp.get_center().x, 0.0, fp.get_center().y + front_sign * (fp.size.y * 0.5 + 2.3))
			camera_orbit_angle = -0.52 if front_sign > 0.0 else PI - 0.52
	elif view == "ryah_defense":
		if freya_home_index >= 0 and freya_home_index < buildings.size():
			var home: Dictionary = buildings[freya_home_index]
			var home_fp: Rect2 = home.get("footprint", Rect2())
			freya.global_position = Vector3(home_fp.get_center().x, 0.0, home_fp.get_center().y)
			_trigger_ryah_alien_defense()
			ryah_alien_cry_timer = 999.0
			camera_orbit_angle = -0.48
	elif view == "stronghold":
		if not store_building_indices.is_empty():
			var store_index = store_building_indices[0]
			_occupy_building_with_alien(store_index, 70003)
			var store: Dictionary = buildings[store_index]
			var fp: Rect2 = store.get("footprint", Rect2())
			var center = fp.get_center()
			var entry: Vector2 = store.get("entry_pos", center)
			var outward = entry - center
			if outward.length_squared() < 0.001:
				outward = Vector2.DOWN if bool(store.get("front_is_south", true)) else Vector2.UP
			outward = outward.normalized()
			freya.global_position = Vector3(entry.x + outward.x * 6.3, 0.0, entry.y + outward.y * 6.3)
			camera_orbit_angle = -0.52 if bool(store.get("front_is_south", true)) else PI - 0.52
			for spawn_index in range(3):
				store = buildings[store_index]
				store["alien_spawn_cooldown"] = 0.0
				buildings[store_index] = store
				_update_free_alien_generation(0.1)
			if not dogs.is_empty():
				var army_state: Dictionary = dogs[0]
				var army_dog: Node3D = army_state.get("node", null)
				if army_dog != null and is_instance_valid(army_dog):
					army_state["army_aligned"] = true
					army_state["alien_possessed"] = false
					army_state["speed"] = 0.0
					army_state["wander"] = 999.0
					army_dog.global_position = freya.global_position + Vector3(1.2, 0.0, 0.7)
					if army_dog.has_method("set_army_aligned"):
						army_dog.call("set_army_aligned", true)
					dogs[0] = army_state

	for dog_index in range(dogs.size()):
		var state: Dictionary = dogs[dog_index]
		if not bool(state.get("alien_possessed", false)):
			continue
		var dog: Node3D = state.get("node", null)
		if dog != null and is_instance_valid(dog):
			dog.global_position = freya.global_position + Vector3(1.55, 0.0, 0.45)
			state["speed"] = 0.0
			state["dir"] = Vector3.ZERO
			state["wander"] = 999.0
			dogs[dog_index] = state
			break

func _process(delta: float) -> void:
	_update_performance_benchmark(delta)
	if perf_benchmark_enabled:
		if perf_profile_gameplay:
			_profile_gameplay_update(delta)
		return
	if family_intro_active:
		if not family_intro_static and (Input.is_action_just_pressed("menu") or Input.is_action_just_pressed("vomit")):
			_finish_family_intro()
			return
		_update_family_intro(delta)
		return
	if Input.is_action_just_pressed("menu"):
		_toggle_pause_menu()
	if pause_menu_open:
		_hide_claim_meter()
		_hide_claim_pee_effect()
		_hide_interactable_highlights()
		_update_objectives_overlay()
		_update_stats_overlay()
		return

	world_time += delta
	status_timer = max(0.0, status_timer - delta)
	if status_timer <= 0.0:
		status_label.text = ""

	_update_camera_orbit_input(delta)
	_update_freya(delta)
	_update_store_focus(delta)
	_update_dogs(delta)
	_update_freya_alien_discomfort(delta)
	_update_alien_transfers(delta)
	_update_free_aliens(delta)
	_update_ryah_diane(delta)
	_update_ryah_alien_crying(delta)
	_update_alien_reinforcement_fields()
	_update_alien_building_visuals(delta)
	_handle_actions()
	_update_carried_stick_pose()
	_update_poops(delta)
	_update_vomit_puddles(delta)
	_update_bark_sequences(delta)
	_update_bark_pulses(delta)
	_update_vomit_sprays(delta)
	_update_store_entry_indicators(delta)
	_update_camera(delta)
	_update_claiming(delta)
	_update_claim_pee_effect(delta)
	_update_claim_rings()
	_update_interactable_highlights(delta)
	_update_roof_occlusion(delta)
	_update_ui()
	_update_objectives_overlay()
	_update_stats_overlay()
	_update_minimap_dynamic(delta)

func _profile_gameplay_update(delta: float) -> void:
	world_time += delta
	status_timer = max(0.0, status_timer - delta)
	var started = Time.get_ticks_usec()
	_update_camera_orbit_input(delta)
	_update_freya(delta)
	_update_store_focus(delta)
	_update_dogs(delta)
	_update_freya_alien_discomfort(delta)
	_update_alien_transfers(delta)
	_update_free_aliens(delta)
	_update_ryah_diane(delta)
	_update_ryah_alien_crying(delta)
	_update_alien_reinforcement_fields()
	_update_alien_building_visuals(delta)
	_perf_profile_mark("movement", started)

	started = Time.get_ticks_usec()
	_handle_actions()
	_update_carried_stick_pose()
	_update_poops(delta)
	_update_vomit_puddles(delta)
	_perf_profile_mark("interactions", started)

	started = Time.get_ticks_usec()
	_update_bark_sequences(delta)
	_update_bark_pulses(delta)
	_update_vomit_sprays(delta)
	_perf_profile_mark("effects", started)

	started = Time.get_ticks_usec()
	_update_store_entry_indicators(delta)
	_update_camera(delta)
	_update_claiming(delta)
	_update_claim_pee_effect(delta)
	_perf_profile_mark("world_state", started)

	started = Time.get_ticks_usec()
	_update_claim_rings()
	_update_interactable_highlights(delta)
	_update_roof_occlusion(delta)
	_perf_profile_mark("visibility", started)

	started = Time.get_ticks_usec()
	_update_ui()
	_update_objectives_overlay()
	_update_stats_overlay()
	_update_minimap_dynamic(delta)
	_perf_profile_mark("ui", started)
	perf_profile_frames += 1

func _perf_profile_mark(category: String, started_usec: int) -> void:
	perf_profile_usec[category] = int(perf_profile_usec.get(category, 0)) + Time.get_ticks_usec() - started_usec

func _update_performance_benchmark(delta: float) -> void:
	if not perf_benchmark_enabled:
		return
	if perf_benchmark_warmup < 2.5:
		perf_benchmark_warmup += delta
		return
	perf_benchmark_elapsed += delta
	perf_benchmark_frames += 1
	if perf_benchmark_elapsed < 5.0:
		return

	var node_count = 0
	var geometry_count = 0
	var visible_geometry_count = 0
	var multimesh_count = 0
	var stack: Array[Node] = [self]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		node_count += 1
		if node is GeometryInstance3D:
			geometry_count += 1
			if (node as GeometryInstance3D).is_visible_in_tree():
				visible_geometry_count += 1
		if node is MultiMeshInstance3D:
			multimesh_count += 1
		for child in node.get_children():
			stack.append(child)

	var average_fps = float(perf_benchmark_frames) / maxf(0.001, perf_benchmark_elapsed)
	var draw_calls = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var rendered_objects = int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	var rendered_primitives = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	print(
		"PERF_RESULT avg_fps=%.1f draw_calls=%d rendered_objects=%d rendered_primitives=%d nodes=%d geometry=%d visible_geometry=%d multimeshes=%d buildings=%d stores=%d"
		% [average_fps, draw_calls, rendered_objects, rendered_primitives, node_count, geometry_count, visible_geometry_count, multimesh_count, buildings.size(), store_building_indices.size()]
	)
	var static_counts = _performance_subtree_counts(static_root)
	var dynamic_counts = _performance_subtree_counts(dynamic_root)
	var building_counts = _performance_collection_counts(buildings, "node")
	var store_shell_counts = _performance_node_array_counts(store_shell_nodes)
	var store_interior_counts = _performance_node_array_counts(store_interior_nodes)
	var tree_counts = _performance_collection_counts(trees, "node")
	var dog_counts = _performance_collection_counts(dogs, "node")
	var pole_counts = _performance_collection_counts(street_poles, "node")
	var hydrant_counts = _performance_collection_counts(fire_hydrants, "node")
	var dumpster_counts = _performance_collection_counts(dumpsters, "node")
	print(
		"PERF_BREAKDOWN static=%s dynamic=%s buildings=%s store_shells=%s store_interiors=%s trees=%s dogs=%s poles=%s hydrants=%s dumpsters=%s"
		% [static_counts, dynamic_counts, building_counts, store_shell_counts, store_interior_counts, tree_counts, dog_counts, pole_counts, hydrant_counts, dumpster_counts]
	)
	if perf_profile_frames > 0:
		var timing_parts: Array[String] = []
		for category in perf_profile_usec.keys():
			var average_ms = float(perf_profile_usec[category]) / float(perf_profile_frames) / 1000.0
			timing_parts.append("%s_ms=%.3f" % [category, average_ms])
		print("PERF_TIMING %s" % " ".join(timing_parts))
	perf_benchmark_enabled = false
	get_tree().quit()

func _performance_subtree_counts(root: Node) -> Dictionary:
	var result = {"nodes": 0, "geometry": 0, "visible": 0}
	if root == null or not is_instance_valid(root):
		return result
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		result["nodes"] = int(result["nodes"]) + 1
		if node is GeometryInstance3D:
			result["geometry"] = int(result["geometry"]) + 1
			if (node as GeometryInstance3D).is_visible_in_tree():
				result["visible"] = int(result["visible"]) + 1
		for child in node.get_children():
			stack.append(child)
	return result

func _performance_collection_counts(items: Array, node_key: String) -> Dictionary:
	var result = {"nodes": 0, "geometry": 0, "visible": 0}
	for item in items:
		if not (item is Dictionary):
			continue
		var counts = _performance_subtree_counts((item as Dictionary).get(node_key, null))
		for key in result.keys():
			result[key] = int(result[key]) + int(counts.get(key, 0))
	return result

func _performance_node_array_counts(items: Array) -> Dictionary:
	var result = {"nodes": 0, "geometry": 0, "visible": 0}
	for node in items:
		if not (node is Node):
			continue
		var counts = _performance_subtree_counts(node as Node)
		for key in result.keys():
			result[key] = int(result[key]) + int(counts.get(key, 0))
	return result

func _configure_input() -> void:
	_ensure_action("move_left", [Key.KEY_A, Key.KEY_LEFT])
	_ensure_action("move_right", [Key.KEY_D, Key.KEY_RIGHT])
	_ensure_action("move_up", [Key.KEY_W, Key.KEY_UP])
	_ensure_action("move_down", [Key.KEY_S, Key.KEY_DOWN])
	_ensure_action("run", [Key.KEY_SHIFT])
	_remove_action_key("eat", int(Key.KEY_E))
	_ensure_action("eat", [Key.KEY_F])
	_remove_action_key("camera_rotate_ccw", int(Key.KEY_Q))
	_remove_action_key("camera_rotate_cw", int(Key.KEY_E))
	_ensure_action("camera_rotate_ccw", [Key.KEY_E])
	_ensure_action("camera_rotate_cw", [Key.KEY_Q])
	_ensure_action("vomit", [Key.KEY_SPACE])
	_ensure_action("drop_stick", [Key.KEY_V])
	_ensure_action("claim", [Key.KEY_R])
	_ensure_action("friendly_social", [Key.KEY_C])
	_ensure_action("aggressive_social", [Key.KEY_X])
	_ensure_action("objectives", [Key.KEY_TAB])
	_ensure_action("menu", [Key.KEY_ESCAPE])

func _unhandled_input(event: InputEvent) -> void:
	if pause_menu_open or family_intro_active:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed:
			return
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_camera_zoom(-CAMERA_ZOOM_STEP)
			get_viewport().set_input_as_handled()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_camera_zoom(CAMERA_ZOOM_STEP)
			get_viewport().set_input_as_handled()

func _adjust_camera_zoom(delta_distance: float) -> void:
	camera_zoom_target = clampf(camera_zoom_target + delta_distance, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX)

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
	environment.ambient_light_energy = 0.78
	environment.ssao_enabled = false
	environment.ssil_enabled = false
	environment.glow_enabled = false
	env.environment = environment
	add_child(env)

	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -36.0, 0.0)
	sun.light_energy = 1.55
	# Broad daylight and soft ambient light keep the scene readable without the
	# expensive full-neighborhood shadow pass on the compatibility renderer.
	sun.shadow_enabled = false
	add_child(sun)

	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-36.0, 144.0, 0.0)
	fill.light_energy = 0.34
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
		push_warning("Passive bark clips missing; bark playback disabled.")

	bark_sfx_streams_aggressive.clear()
	for stream in _load_bark_streams_from_files(BARK_AGGRESSIVE_SAMPLE_CANDIDATES):
		bark_sfx_streams_aggressive.append(stream)
	if bark_sfx_streams_aggressive.is_empty():
		push_warning("Aggressive bark clips missing; aggressive bark playback disabled.")

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

	if claim_pee_audio_player != null and is_instance_valid(claim_pee_audio_player):
		claim_pee_audio_player.queue_free()
	claim_pee_audio_player = AudioStreamPlayer.new()
	claim_pee_audio_player.bus = "Master"
	claim_pee_stream = _load_first_stream_from_candidates(PEE_SAMPLE_CANDIDATES)
	claim_pee_audio_player.volume_db = -12.8
	claim_pee_audio_player.stream = claim_pee_stream
	add_child(claim_pee_audio_player)

	if claim_pee_water_audio_player != null and is_instance_valid(claim_pee_water_audio_player):
		claim_pee_water_audio_player.queue_free()
	claim_pee_water_audio_player = AudioStreamPlayer.new()
	claim_pee_water_audio_player.bus = "Master"
	claim_pee_water_stream = _load_first_stream_from_candidates(PEE_WATER_LAYER_SAMPLE_CANDIDATES)
	claim_pee_water_audio_player.volume_db = -12.0
	claim_pee_water_audio_player.stream = claim_pee_water_stream
	add_child(claim_pee_water_audio_player)
	claim_pee_burst_timer = 0.0
	claim_pee_gap_timer = 0.0

	eat_sfx_streams_food.clear()
	for stream in _load_bark_streams_from_files(EAT_FOOD_SAMPLE_CANDIDATES):
		eat_sfx_streams_food.append(stream)
	if eat_sfx_streams_food.is_empty():
		push_warning("Dog eat(food) clips missing; eat-food playback disabled.")

	eat_sfx_streams_poop.clear()
	for stream in _load_bark_streams_from_files(EAT_POOP_SAMPLE_CANDIDATES):
		eat_sfx_streams_poop.append(stream)
	if eat_sfx_streams_poop.is_empty():
		push_warning("Dog eat(poop) clips missing; eat-poop playback disabled.")

	eat_sfx_streams_bone.clear()
	for stream in _load_bark_streams_from_files(EAT_BONE_SAMPLE_CANDIDATES):
		eat_sfx_streams_bone.append(stream)
	if eat_sfx_streams_bone.is_empty():
		push_warning("Dog eat(bone) clips missing; bone-eat playback disabled.")

	if eat_sfx_player != null and is_instance_valid(eat_sfx_player):
		eat_sfx_player.queue_free()
	eat_sfx_player = AudioStreamPlayer.new()
	eat_sfx_player.bus = "Master"
	eat_sfx_player.volume_db = -10.4
	add_child(eat_sfx_player)

	vomit_sfx_streams.clear()
	for stream in _load_bark_streams_from_files(VOMIT_SAMPLE_CANDIDATES):
		vomit_sfx_streams.append(stream)
	if vomit_sfx_streams.is_empty():
		push_warning("Dog vomit clips missing; vomit playback disabled.")

	if vomit_sfx_player != null and is_instance_valid(vomit_sfx_player):
		vomit_sfx_player.queue_free()
	vomit_sfx_player = AudioStreamPlayer.new()
	vomit_sfx_player.bus = "Master"
	vomit_sfx_player.volume_db = -10.2
	add_child(vomit_sfx_player)

func _load_audio_stream_from_file(path: String) -> AudioStream:
	if path.is_empty():
		return null
	var lower = path.to_lower()
	if FileAccess.file_exists(path):
		if lower.ends_with(".wav"):
			var wav = AudioStreamWAV.load_from_file(path)
			if wav != null:
				return wav
		elif lower.ends_with(".ogg") or lower.ends_with(".oga"):
			var ogg = AudioStreamOggVorbis.load_from_file(path)
			if ogg != null:
				return ogg
		elif lower.ends_with(".mp3"):
			var mp3 = AudioStreamMP3.load_from_file(path)
			if mp3 != null:
				return mp3
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			return res as AudioStream
	return null

func _load_first_stream_from_candidates(candidates: Array) -> AudioStream:
	for path in candidates:
		var stream = _load_audio_stream_from_file(str(path))
		if stream != null:
			return stream
	return null

func _load_bark_streams_from_files(candidates: Array) -> Array[AudioStream]:
	var out: Array[AudioStream] = []
	for path in candidates:
		var stream: AudioStream = _load_audio_stream_from_file(str(path))
		if stream != null:
			out.append(stream)
	return out

func _play_bark_sound(is_freya_bark: bool, aggressive: bool = false) -> void:
	var bark_pool = bark_sfx_streams_aggressive if aggressive else bark_sfx_streams_passive
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

func _play_claim_pee_sound(start_offset_sec: float = PEE_SOUND_START_OFFSET_SEC) -> void:
	if claim_pee_audio_player == null or not is_instance_valid(claim_pee_audio_player):
		return
	if claim_pee_stream == null:
		claim_pee_stream = _load_first_stream_from_candidates(PEE_SAMPLE_CANDIDATES)
		claim_pee_audio_player.stream = claim_pee_stream
	if claim_pee_stream == null:
		return
	claim_pee_audio_player.stop()
	claim_pee_audio_player.pitch_scale = rng.randf_range(0.97, 1.03)
	claim_pee_audio_player.volume_db = -12.6 + rng.randf_range(-0.45, 0.3)
	claim_pee_audio_player.play(maxf(0.0, start_offset_sec))
	if claim_pee_water_audio_player != null and is_instance_valid(claim_pee_water_audio_player):
		if claim_pee_water_stream == null:
			claim_pee_water_stream = _load_first_stream_from_candidates(PEE_WATER_LAYER_SAMPLE_CANDIDATES)
			claim_pee_water_audio_player.stream = claim_pee_water_stream
		if claim_pee_water_stream != null:
			claim_pee_water_audio_player.stop()
			claim_pee_water_audio_player.pitch_scale = rng.randf_range(0.98, 1.02)
			claim_pee_water_audio_player.volume_db = -11.3 + rng.randf_range(-0.45, 0.35)
			var water_offset = start_offset_sec + rng.randf_range(0.01, 0.08)
			claim_pee_water_audio_player.play(maxf(0.0, water_offset))

func _stop_claim_pee_audio() -> void:
	claim_pee_burst_timer = 0.0
	claim_pee_gap_timer = 0.0
	if claim_pee_audio_player != null and is_instance_valid(claim_pee_audio_player):
		claim_pee_audio_player.stop()
	if claim_pee_water_audio_player != null and is_instance_valid(claim_pee_water_audio_player):
		claim_pee_water_audio_player.stop()

func _update_claim_pee_dribble(delta: float) -> void:
	if claim_pee_audio_player == null or not is_instance_valid(claim_pee_audio_player):
		return
	if claim_pee_stream == null:
		claim_pee_stream = _load_first_stream_from_candidates(PEE_SAMPLE_CANDIDATES)
		claim_pee_audio_player.stream = claim_pee_stream
	if claim_pee_stream == null:
		return

	claim_pee_burst_timer = maxf(0.0, claim_pee_burst_timer - delta)
	claim_pee_gap_timer = maxf(0.0, claim_pee_gap_timer - delta)

	if claim_pee_audio_player.playing and claim_pee_burst_timer <= 0.0:
		claim_pee_audio_player.stop()
		claim_pee_gap_timer = rng.randf_range(PEE_DRIBBLE_GAP_MIN_SEC, PEE_DRIBBLE_GAP_MAX_SEC)

	if (not claim_pee_audio_player.playing) and claim_pee_gap_timer <= 0.0:
		var start_offset = PEE_SOUND_START_OFFSET_SEC + rng.randf_range(0.0, PEE_DRIBBLE_OFFSET_JITTER_SEC)
		_play_claim_pee_sound(start_offset)
		claim_pee_burst_timer = rng.randf_range(PEE_DRIBBLE_BURST_MIN_SEC, PEE_DRIBBLE_BURST_MAX_SEC)

func _play_random_clip(
	player: AudioStreamPlayer,
	pool: Array[AudioStream],
	pitch_min: float,
	pitch_max: float,
	base_volume_db: float,
	volume_jitter_db: float,
	start_offset_sec: float = 0.0
) -> void:
	if player == null or not is_instance_valid(player) or pool.is_empty():
		return
	var clip_idx = rng.randi_range(0, pool.size() - 1)
	var clip: AudioStream = pool[clip_idx]
	player.stop()
	player.stream = clip
	player.pitch_scale = rng.randf_range(pitch_min, pitch_max)
	player.volume_db = base_volume_db + rng.randf_range(-absf(volume_jitter_db), absf(volume_jitter_db))
	player.play(maxf(0.0, start_offset_sec))

func _play_eat_sound(kind: String) -> void:
	var pool: Array[AudioStream] = eat_sfx_streams_food
	match kind:
		"poop":
			pool = eat_sfx_streams_poop
		"bone":
			pool = eat_sfx_streams_bone
		_:
			pool = eat_sfx_streams_food
	var start_offset = EAT_BONE_SOUND_START_OFFSET_SEC if kind == "bone" else EAT_SOUND_START_OFFSET_SEC
	_play_random_clip(eat_sfx_player, pool, 0.96, 1.04, -10.4, 0.6, start_offset)

func _play_vomit_sound() -> void:
	_play_random_clip(vomit_sfx_player, vomit_sfx_streams, 0.98, 1.01, -10.2, 0.35, VOMIT_SOUND_START_OFFSET_SEC)

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
	poop_blob_mesh = SphereMesh.new()
	poop_blob_mesh.radius = 0.08
	poop_blob_mesh.height = 0.16
	poop_blob_mesh.radial_segments = 8
	poop_blob_mesh.rings = 4

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
	claim_ring_material.albedo_color = Color(1.0, 0.86, 0.42, 0.74)
	claim_ring_material.roughness = 0.24
	claim_ring_material.metallic = 0.03
	claim_ring_material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	claim_ring_material.shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL
	claim_ring_material.cull_mode = StandardMaterial3D.CULL_DISABLED
	claim_ring_material.emission_enabled = true
	claim_ring_material.emission = Color(0.98, 0.8, 0.26)
	claim_ring_material.emission_energy_multiplier = 0.9

	claim_ring_enemy_material = StandardMaterial3D.new()
	claim_ring_enemy_material.albedo_color = Color(0.92, 0.34, 0.3, 0.76)
	claim_ring_enemy_material.roughness = 0.24
	claim_ring_enemy_material.metallic = 0.02
	claim_ring_enemy_material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	claim_ring_enemy_material.shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL
	claim_ring_enemy_material.cull_mode = StandardMaterial3D.CULL_DISABLED
	claim_ring_enemy_material.emission_enabled = true
	claim_ring_enemy_material.emission = Color(0.9, 0.28, 0.25)
	claim_ring_enemy_material.emission_energy_multiplier = 0.95

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

	alien_core_material = StandardMaterial3D.new()
	alien_core_material.albedo_color = Color(0.34, 0.02, 0.46, 0.9)
	alien_core_material.roughness = 0.18
	alien_core_material.metallic = 0.12
	alien_core_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	alien_core_material.emission_enabled = true
	alien_core_material.emission = Color(0.74, 0.08, 0.94)
	alien_core_material.emission_energy_multiplier = 2.25

	alien_trail_material = StandardMaterial3D.new()
	alien_trail_material.albedo_color = Color(0.16, 0.94, 0.76, 0.66)
	alien_trail_material.roughness = 0.1
	alien_trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	alien_trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	alien_trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	alien_trail_material.emission_enabled = true
	alien_trail_material.emission = Color(0.08, 0.86, 0.62)
	alien_trail_material.emission_energy_multiplier = 1.75

	# The roaming alien is a solid voxel character. Bright alien colors are kept
	# to small facial/rune accents so its silhouette remains readable in daylight.
	alien_body_material = StandardMaterial3D.new()
	alien_body_material.albedo_color = Color(0.255, 0.045, 0.31)
	alien_body_material.roughness = 0.78
	alien_body_material.metallic = 0.0

	alien_face_material = StandardMaterial3D.new()
	alien_face_material.albedo_color = Color(0.49, 0.085, 0.48)
	alien_face_material.roughness = 0.7
	alien_face_material.metallic = 0.0

	alien_horn_material = StandardMaterial3D.new()
	alien_horn_material.albedo_color = Color(0.065, 0.028, 0.085)
	alien_horn_material.roughness = 0.88
	alien_horn_material.metallic = 0.0

	alien_eye_material = StandardMaterial3D.new()
	alien_eye_material.albedo_color = Color(0.12, 0.96, 0.67)
	alien_eye_material.roughness = 0.2
	alien_eye_material.emission_enabled = true
	alien_eye_material.emission = Color(0.06, 0.82, 0.48)
	alien_eye_material.emission_energy_multiplier = 1.65

	alien_fang_material = StandardMaterial3D.new()
	alien_fang_material.albedo_color = Color(0.82, 0.86, 0.72)
	alien_fang_material.roughness = 0.72
	alien_fang_material.metallic = 0.0

	alien_building_material = StandardMaterial3D.new()
	alien_building_material.albedo_color = Color(0.11, 0.015, 0.18, 0.62)
	alien_building_material.roughness = 0.44
	alien_building_material.metallic = 0.18
	alien_building_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	alien_building_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	alien_building_material.emission_enabled = true
	alien_building_material.emission = Color(0.2, 0.01, 0.32)
	alien_building_material.emission_energy_multiplier = 0.95

	alien_building_accent_material = StandardMaterial3D.new()
	alien_building_accent_material.albedo_color = Color(0.08, 0.96, 0.69, 0.88)
	alien_building_accent_material.roughness = 0.15
	alien_building_accent_material.metallic = 0.08
	alien_building_accent_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	alien_building_accent_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	alien_building_accent_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	alien_building_accent_material.emission_enabled = true
	alien_building_accent_material.emission = Color(0.04, 0.92, 0.61)
	alien_building_accent_material.emission_energy_multiplier = 2.4

	ryah_tear_material = StandardMaterial3D.new()
	ryah_tear_material.albedo_color = Color(0.36, 0.78, 1.0, 0.84)
	ryah_tear_material.roughness = 0.08
	ryah_tear_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ryah_tear_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ryah_tear_material.emission_enabled = true
	ryah_tear_material.emission = Color(0.18, 0.56, 1.0)
	ryah_tear_material.emission_energy_multiplier = 1.45

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

	interact_highlight_material = StandardMaterial3D.new()
	interact_highlight_material.albedo_color = Color(1.0, 0.95, 0.56, 0.9)
	interact_highlight_material.roughness = 0.1
	interact_highlight_material.metallic = 0.0
	interact_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	interact_highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	interact_highlight_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	interact_highlight_material.no_depth_test = true
	interact_highlight_material.emission_enabled = true
	interact_highlight_material.emission = Color(1.0, 0.9, 0.44)
	interact_highlight_material.emission_energy_multiplier = 1.7

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
	grass.albedo_color = Color(0.25, 0.52, 0.23)
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
	park_mat.albedo_color = Color(0.29, 0.51, 0.27)
	park_mat.roughness = 0.88
	dog_park_material = park_mat

	far_field_material = _make_far_field_material(
		Color(0.26, 0.49, 0.26),
		Color(0.34, 0.57, 0.35)
	)
	far_road_material = _make_far_road_material(
		Color(0.35, 0.36, 0.38),
		Color(0.41, 0.42, 0.44)
	)

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

func _make_far_field_material(base_color: Color, patch_color: Color) -> Material:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color;
uniform vec3 patch_color : source_color;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.83, 289.91))) * 43758.5453);
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
	vec2 p = UV * 8.0;
	float n = noise(p);
	float n2 = noise(p * 0.56 + vec2(7.2, 12.1));
	float blend = smoothstep(0.22, 0.86, n * 0.74 + n2 * 0.26);
	vec3 c = mix(base_color, patch_color, blend);
	ALBEDO = c;
	ROUGHNESS = 0.99;
	SPECULAR = 0.02;
}
"""
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("base_color", base_color)
	mat.set_shader_parameter("patch_color", patch_color)
	return mat

func _make_far_road_material(base_color: Color, patch_color: Color) -> Material:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color;
uniform vec3 patch_color : source_color;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(91.8, 12.7))) * 43758.5453);
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
	vec2 p = UV * 9.2;
	float n = noise(p);
	float n2 = noise(p * 0.43 + vec2(5.1, 9.8));
	float blend = smoothstep(0.3, 0.9, n * 0.6 + n2 * 0.4);
	vec3 c = mix(base_color, patch_color, blend);
	ALBEDO = c;
	ROUGHNESS = 0.995;
	SPECULAR = 0.01;
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
	city_blocks.clear()

	for cx in _road_centers_for_block_axis(MAP_W, CITY_BLOCK_COLUMNS):
		_add_road(Rect2(float(cx) - ROAD_W * 0.5, 0.0, ROAD_W, MAP_H))

	for cz in _road_centers_for_block_axis(MAP_H, CITY_BLOCK_ROWS):
		_add_road(Rect2(0.0, float(cz) - ROAD_W * 0.5, MAP_W, ROAD_W))

	var x_intervals = _compute_non_road_intervals(true)
	var z_intervals = _compute_non_road_intervals(false)
	for xi in range(x_intervals.size()):
		var xr: Vector2 = x_intervals[xi]
		for zi in range(z_intervals.size()):
			var zr: Vector2 = z_intervals[zi]
			var parcel = Rect2(xr.x, zr.x, xr.y, zr.y)
			if parcel.size.x < 10.0 or parcel.size.y < 9.5:
				continue
			block_parcels.append(parcel)
			city_blocks.append({
				"index": city_blocks.size(),
				"col": xi,
				"row": zi,
				"rect": parcel,
				"center": parcel.position + parcel.size * 0.5
			})

	var map_center = Vector2(MAP_W * 0.5, MAP_H * 0.5)
	var park_parcel = Rect2(MAP_W * 0.5 - 8.0, MAP_H * 0.5 - 7.0, 16.0, 14.0)
	if not city_blocks.is_empty():
		var center_col = clampi(int(floor(float(x_intervals.size()) * 0.5)), 0, maxi(0, x_intervals.size() - 1))
		var center_row = clampi(int(floor(float(z_intervals.size()) * 0.5)), 0, maxi(0, z_intervals.size() - 1))
		var found_center = false
		for block in city_blocks:
			if int(block.get("col", -1)) == center_col and int(block.get("row", -1)) == center_row:
				park_parcel = block.get("rect", park_parcel)
				found_center = true
				break
		if not found_center:
			var nearest_idx = 0
			var nearest_dist = 1000000000.0
			for i in range(city_blocks.size()):
				var center: Vector2 = city_blocks[i].get("center", map_center)
				var dist_sq = center.distance_squared_to(map_center)
				if dist_sq < nearest_dist:
					nearest_dist = dist_sq
					nearest_idx = i
			park_parcel = city_blocks[nearest_idx].get("rect", park_parcel)

	var park_size = Vector2(
		clampf(minf(16.4, park_parcel.size.x - 1.4), 9.6, 17.0),
		clampf(minf(13.9, park_parcel.size.y - 1.4), 8.8, 15.2)
	)
	var park_origin = park_parcel.position + (park_parcel.size - park_size) * 0.5
	dog_park = Rect2(park_origin, park_size)

	for parcel in block_parcels:
		if parcel.intersects(dog_park.grow(0.4)):
			continue
		_add_block_alleys(parcel)

func _road_centers_for_block_axis(axis_size: float, block_count: int) -> Array:
	var centers: Array = []
	if block_count <= 1:
		return centers
	var road_count = block_count - 1
	var block_span = (axis_size - float(road_count) * ROAD_W) / float(block_count)
	if block_span <= 0.5:
		return centers
	for i in range(road_count):
		var center = float(i + 1) * block_span + float(i) * ROAD_W + ROAD_W * 0.5
		centers.append(center)
	return centers

func _city_center_block() -> Dictionary:
	if city_blocks.is_empty():
		return {}
	var target_col = int(floor(float(CITY_BLOCK_COLUMNS) * 0.5))
	var target_row = int(floor(float(CITY_BLOCK_ROWS) * 0.5))
	for block in city_blocks:
		if int(block.get("col", -1)) == target_col and int(block.get("row", -1)) == target_row:
			return block
	var map_center = Vector2(MAP_W * 0.5, MAP_H * 0.5)
	var best_idx = 0
	var best_dist = 1000000000.0
	for i in range(city_blocks.size()):
		var center: Vector2 = city_blocks[i].get("center", map_center)
		var dist_sq = center.distance_squared_to(map_center)
		if dist_sq < best_dist:
			best_dist = dist_sq
			best_idx = i
	return city_blocks[best_idx]

func _city_block_for_point(p: Vector2) -> Dictionary:
	for block in city_blocks:
		var rect: Rect2 = block.get("rect", Rect2())
		if rect.size.x > 0.0 and rect.size.y > 0.0 and rect.has_point(p):
			return block
	return {}

func _city_block_index_for_point(p: Vector2) -> int:
	var block = _city_block_for_point(p)
	if block.is_empty():
		return -1
	return int(block.get("index", -1))

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
	_build_map_edge_backdrop()

	var grass = MeshInstance3D.new()
	var grass_mesh = PlaneMesh.new()
	grass_mesh.size = Vector2(MAP_W, MAP_H)
	grass.mesh = grass_mesh
	grass.position = Vector3(MAP_W * 0.5, 0.0, MAP_H * 0.5)
	grass.material_override = grass_material
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	static_root.add_child(grass)

	for s in sidewalks:
		_add_ground_rect(s, 0.01, sidewalk_material)

	for s in alley_shoulders:
		_add_ground_rect(s, 0.012, sidewalk_material)

	for r in roads:
		_add_ground_rect(r, 0.018, road_material)

	for a in alleys:
		_add_ground_rect(a, 0.02, alley_material)

func _build_map_edge_backdrop() -> void:
	var far_field = MeshInstance3D.new()
	var field_mesh = PlaneMesh.new()
	field_mesh.size = Vector2(
		MAP_W + MAP_EDGE_FIELD_MARGIN * 2.0,
		MAP_H + MAP_EDGE_FIELD_MARGIN * 2.0
	)
	far_field.mesh = field_mesh
	far_field.position = Vector3(MAP_W * 0.5, MAP_EDGE_GROUND_Y, MAP_H * 0.5)
	far_field.material_override = far_field_material if far_field_material != null else grass_material
	far_field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	static_root.add_child(far_field)

	var road_mat = far_road_material if far_road_material != null else road_material
	for r in roads:
		if r.size.x < r.size.y:
			var top_ext = Rect2(r.position.x, -MAP_EDGE_ROAD_EXTENSION, r.size.x, MAP_EDGE_ROAD_EXTENSION + 0.24)
			var bottom_ext = Rect2(r.position.x, MAP_H - 0.24, r.size.x, MAP_EDGE_ROAD_EXTENSION + 0.24)
			_add_ground_rect(top_ext, MAP_EDGE_GROUND_Y + 0.004, road_mat)
			_add_ground_rect(bottom_ext, MAP_EDGE_GROUND_Y + 0.004, road_mat)
		else:
			var left_ext = Rect2(-MAP_EDGE_ROAD_EXTENSION, r.position.y, MAP_EDGE_ROAD_EXTENSION + 0.24, r.size.y)
			var right_ext = Rect2(MAP_W - 0.24, r.position.y, MAP_EDGE_ROAD_EXTENSION + 0.24, r.size.y)
			_add_ground_rect(left_ext, MAP_EDGE_GROUND_Y + 0.004, road_mat)
			_add_ground_rect(right_ext, MAP_EDGE_GROUND_Y + 0.004, road_mat)

func _add_ground_rect(rect: Rect2, y: float, material: Material) -> void:
	var m = MeshInstance3D.new()
	m.name = "GroundPatch"
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(rect.size.x, rect.size.y)
	m.mesh = mesh
	m.position = Vector3(rect.position.x + rect.size.x * 0.5, y, rect.position.y + rect.size.y * 0.5)
	m.material_override = material
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
	for parcel_index in range(block_parcels.size()):
		var parcel: Rect2 = block_parcels[parcel_index]
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
		# Every third block gets one broader, centered lot per street face. This
		# opens up the neighborhood without turning every house into a mansion.
		var lot_count = 1 if parcel_index % 3 == 0 else max(2, int(floor(run_w / 8.6)))
		var lot_stride = run_w / float(maxi(1, lot_count))
		var north_depth = maxf(4.2, float(layout["north_depth"]))
		var south_depth = maxf(4.2, float(layout["south_depth"]))

		for i in range(lot_count):
			# Detached Northbrook lots: leave meaningful side yards between homes.
			var side_yard = clampf(lot_stride * (0.25 if lot_count == 1 else 0.17), 0.78, 4.3)
			var bx = x0 + float(i) * lot_stride + side_yard
			var width = lot_stride - side_yard * 2.0
			var by_n = alley_z0 - north_depth - alley_gap
			var by_s = alley_z1 + alley_gap
			_add_building(Rect2(bx, by_n, width, north_depth), _pick_floors(buildings.size() + i), false)
			_add_building(Rect2(bx, by_s, width, south_depth), _pick_floors(buildings.size() + i + 17), true)

	if buildings.is_empty():
		# Fallback so the map never renders as an empty block-only scene.
		_add_building(Rect2(9.0, 8.0, 5.8, 4.9), 1, true)
		_add_building(Rect2(17.0, 8.2, 5.2, 4.5), 2, true)
		_add_building(Rect2(33.0, 27.0, 6.1, 5.0), 1, false)
		_add_building(Rect2(58.0, 50.0, 5.9, 4.8), 2, true)
	_rebuild_walkability_cache()

func _mark_freya_home() -> void:
	freya_home_index = -1
	var park_center = dog_park.get_center()
	var selected_tier: Dictionary = {}
	# A four-zone family interior needs a broad detached-house footprint. Search
	# the nearest scale-suitable one-story home first, then relax only if city
	# generation ever produces no such candidate.
	var selection_tiers = [
		{"min_area": HOME_PREFERRED_MIN_AREA, "min_short_side": HOME_PREFERRED_MIN_SHORT_SIDE, "one_story": true},
		{"min_area": HOME_PREFERRED_MIN_AREA, "min_short_side": HOME_PREFERRED_MIN_SHORT_SIDE, "one_story": false},
		{"min_area": HOME_MIN_USABLE_AREA, "min_short_side": 4.15, "one_story": true},
		{"min_area": 28.0, "min_short_side": 3.8, "one_story": false}
	]
	for tier in selection_tiers:
		var best_distance_sq = INF
		for i in range(buildings.size()):
			var building: Dictionary = buildings[i]
			if str(building.get("model_source", "")) != "procedural":
				continue
			if bool(tier.get("one_story", false)) and int(building.get("floors", 1)) != 1:
				continue
			var fp: Rect2 = building.get("footprint", Rect2())
			var short_side = minf(fp.size.x, fp.size.y)
			if fp.get_area() < float(tier.get("min_area", 0.0)) or short_side < float(tier.get("min_short_side", 0.0)):
				continue
			var distance_sq = fp.get_center().distance_squared_to(park_center)
			if distance_sq < best_distance_sq:
				best_distance_sq = distance_sq
				freya_home_index = i
				selected_tier = tier
		if freya_home_index >= 0:
			break
	if freya_home_index < 0:
		return
	var home: Dictionary = buildings[freya_home_index]
	home["is_freya_home"] = true
	home["enterable"] = true
	home["home_interior_rect"] = Rect2()
	home["home_interior_root"] = null
	home["home_exterior_root"] = null
	home["home_selection_min_area"] = float(selected_tier.get("min_area", 0.0))
	home["home_selection_min_short_side"] = float(selected_tier.get("min_short_side", 0.0))
	home["home_selection_one_story"] = bool(selected_tier.get("one_story", false))
	buildings[freya_home_index] = home

func _mark_store_buildings() -> void:
	_clear_store_entry_indicators()
	_clear_store_shells()
	_clear_store_interiors()
	store_building_indices.clear()
	active_store_index = -1
	if buildings.is_empty():
		_rebuild_walkability_cache()
		return
	var candidates: Array[int] = []
	for i in range(buildings.size()):
		var b: Dictionary = buildings[i]
		var is_freya_home = bool(b.get("is_freya_home", false))
		b["is_store"] = false
		b["enterable"] = is_freya_home
		b["store_food_slots"] = 0
		b["entry_pos"] = Vector2(-1.0, -1.0)
		b["store_walk_blockers"] = []
		b["store_interior_rect"] = Rect2()
		b["store_reachable_points"] = PackedVector2Array()
		b["store_interior_root"] = null
		b["store_shell_root"] = null
		b["store_layout"] = {}
		buildings[i] = b
		if is_freya_home:
			continue

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
			if bool(b.get("is_freya_home", false)):
				continue
			var fp: Rect2 = b["footprint"]
			if fp.size.x >= 5.6 and fp.size.y >= 4.2:
				candidates.append(i)

	if candidates.is_empty():
		_rebuild_walkability_cache()
		_apply_store_focus_visuals()
		return

	# A suburban village has a few neighborhood shops, not a storefront on every block.
	var target_count = clampi(int(round(float(candidates.size()) * 0.06)), 4, 6)
	target_count = mini(target_count, candidates.size())
	for n in range(target_count):
		var pick = rng.randi_range(0, candidates.size() - 1)
		var idx = candidates[pick]
		candidates.remove_at(pick)
		var store: Dictionary = buildings[idx]
		store["is_store"] = true
		store["enterable"] = true
		var fp_store: Rect2 = store.get("footprint", Rect2())
		store["store_food_slots"] = clampi(int(round(fp_store.size.x * fp_store.size.y * 0.17)), 6, 14)
		store = _decorate_storefront(store)
		store = _create_store_entry_indicator(store)
		buildings[idx] = store
		store_building_indices.append(idx)
	_build_store_interiors()
	_rebuild_walkability_cache()
	_apply_store_focus_visuals()

func _compute_store_layout(fp: Rect2, front_is_south: bool) -> Dictionary:
	var x0 = fp.position.x + STORE_INTERIOR_MARGIN
	var x1 = fp.position.x + fp.size.x - STORE_INTERIOR_MARGIN
	var z0 = fp.position.y + STORE_INTERIOR_MARGIN
	var z1 = fp.position.y + fp.size.y - STORE_INTERIOR_MARGIN
	var inner_w = x1 - x0
	var inner_d = z1 - z0
	if inner_w < 2.2 or inner_d < 2.2:
		return {"valid": false}

	var wall_t = STORE_WALL_THICKNESS
	var door_half = minf(STORE_DOOR_HALF_WIDTH, inner_w * 0.24)
	var center_x = x0 + inner_w * 0.5
	var front_sign = 1.0 if front_is_south else -1.0
	var wall_blockers: Array[Rect2] = []
	var wall_visuals: Array[Rect2] = []
	var front_left_wall = Rect2()
	var front_right_wall = Rect2()
	var back_wall = Rect2()
	var door_opening = Rect2()
	var front_door_z = z1 - wall_t * 0.5 if front_is_south else z0 + wall_t * 0.5

	var left_wall = Rect2(x0, z0, wall_t, inner_d)
	var right_wall = Rect2(x1 - wall_t, z0, wall_t, inner_d)
	wall_blockers.append(left_wall)
	wall_blockers.append(right_wall)
	wall_visuals.append(left_wall)
	wall_visuals.append(right_wall)

	if front_is_south:
		back_wall = Rect2(x0, z0, inner_w, wall_t)
		wall_blockers.append(back_wall)
		wall_visuals.append(back_wall)
		var front_left_w = maxf(0.0, center_x - door_half - x0)
		var front_right_x = center_x + door_half
		var front_right_w = maxf(0.0, x1 - front_right_x)
		if front_left_w > 0.05:
			front_left_wall = Rect2(x0, z1 - wall_t, front_left_w, wall_t)
			wall_blockers.append(front_left_wall)
			wall_visuals.append(front_left_wall)
		if front_right_w > 0.05:
			front_right_wall = Rect2(front_right_x, z1 - wall_t, front_right_w, wall_t)
			wall_blockers.append(front_right_wall)
			wall_visuals.append(front_right_wall)
		var jamb_d = maxf(0.14, STORE_DOOR_DEPTH - wall_t)
		var jamb_l = Rect2(center_x - door_half - wall_t * 0.5, z1 - STORE_DOOR_DEPTH, wall_t, jamb_d)
		var jamb_r = Rect2(center_x + door_half - wall_t * 0.5, z1 - STORE_DOOR_DEPTH, wall_t, jamb_d)
		wall_visuals.append(jamb_l)
		wall_visuals.append(jamb_r)
		door_opening = Rect2(center_x - door_half, z1 - STORE_DOOR_DEPTH, door_half * 2.0, STORE_DOOR_DEPTH + 0.05)
	else:
		back_wall = Rect2(x0, z1 - wall_t, inner_w, wall_t)
		wall_blockers.append(back_wall)
		wall_visuals.append(back_wall)
		var front_left_w_n = maxf(0.0, center_x - door_half - x0)
		var front_right_x_n = center_x + door_half
		var front_right_w_n = maxf(0.0, x1 - front_right_x_n)
		if front_left_w_n > 0.05:
			front_left_wall = Rect2(x0, z0, front_left_w_n, wall_t)
			wall_blockers.append(front_left_wall)
			wall_visuals.append(front_left_wall)
		if front_right_w_n > 0.05:
			front_right_wall = Rect2(front_right_x_n, z0, front_right_w_n, wall_t)
			wall_blockers.append(front_right_wall)
			wall_visuals.append(front_right_wall)
		var jamb_d_n = maxf(0.14, STORE_DOOR_DEPTH - wall_t)
		var jamb_n_l = Rect2(center_x - door_half - wall_t * 0.5, z0 + wall_t, wall_t, jamb_d_n)
		var jamb_n_r = Rect2(center_x + door_half - wall_t * 0.5, z0 + wall_t, wall_t, jamb_d_n)
		wall_visuals.append(jamb_n_l)
		wall_visuals.append(jamb_n_r)
		door_opening = Rect2(center_x - door_half, z0 - 0.05, door_half * 2.0, STORE_DOOR_DEPTH + 0.05)

	var interior_rect = Rect2(x0 + wall_t, z0 + wall_t, inner_w - wall_t * 2.0, inner_d - wall_t * 2.0)
	var entry_center = Vector2(fp.position.x + fp.size.x * 0.5, fp.position.y + (fp.size.y if front_is_south else 0.0))
	var entry_inside = entry_center + Vector2(0.0, -front_sign) * 0.45
	var entry_outside = Vector2(center_x, front_door_z) + Vector2(0.0, front_sign) * 0.74

	return {
		"valid": true,
		"x0": x0,
		"x1": x1,
		"z0": z0,
		"z1": z1,
		"inner_w": inner_w,
		"inner_d": inner_d,
		"wall_t": wall_t,
		"door_half": door_half,
		"center_x": center_x,
		"front_sign": front_sign,
		"front_is_south": front_is_south,
		"front_door_z": front_door_z,
		"wall_blockers": wall_blockers,
		"wall_visuals": wall_visuals,
		"front_left_wall": front_left_wall,
		"front_right_wall": front_right_wall,
		"back_wall": back_wall,
		"door_opening_rect": door_opening,
		"interior_rect": interior_rect,
		"entry_inside_pos": entry_inside,
		"entry_outside_pos": entry_outside
	}

func _compute_home_layout(fp: Rect2, front_is_south: bool) -> Dictionary:
	var margin = 0.14
	var wall_t = 0.18
	var door_half = 0.54
	var door_depth = 0.68
	var x0 = fp.position.x + margin
	var x1 = fp.position.x + fp.size.x - margin
	var z0 = fp.position.y + margin
	var z1 = fp.position.y + fp.size.y - margin
	var inner_w = x1 - x0
	var inner_d = z1 - z0
	if inner_w < 3.4 or inner_d < 3.0:
		return {"valid": false}
	var center_x = x0 + inner_w * 0.5
	var front_sign = 1.0 if front_is_south else -1.0
	var wall_blockers: Array[Rect2] = []
	var wall_visuals: Array[Rect2] = []
	var left_wall = Rect2(x0, z0, wall_t, inner_d)
	var right_wall = Rect2(x1 - wall_t, z0, wall_t, inner_d)
	wall_blockers.append(left_wall)
	wall_blockers.append(right_wall)
	wall_visuals.append(left_wall)
	wall_visuals.append(right_wall)
	var front_z = z1 - wall_t if front_is_south else z0
	var back_wall = Rect2(x0, z0 if front_is_south else z1 - wall_t, inner_w, wall_t)
	wall_blockers.append(back_wall)
	wall_visuals.append(back_wall)
	var front_left_w = maxf(0.0, center_x - door_half - x0)
	var front_right_x = center_x + door_half
	var front_right_w = maxf(0.0, x1 - front_right_x)
	var front_left_wall = Rect2(x0, front_z, front_left_w, wall_t)
	var front_right_wall = Rect2(front_right_x, front_z, front_right_w, wall_t)
	if front_left_w > 0.05:
		wall_blockers.append(front_left_wall)
		wall_visuals.append(front_left_wall)
	if front_right_w > 0.05:
		wall_blockers.append(front_right_wall)
		wall_visuals.append(front_right_wall)
	var interior_rect = Rect2(
		x0 + wall_t,
		z0 + wall_t,
		inner_w - wall_t * 2.0,
		inner_d - wall_t * 2.0
	)
	var front_door_z = z1 - wall_t * 0.5 if front_is_south else z0 + wall_t * 0.5
	var entry_inside = Vector2(center_x, front_door_z - front_sign * 0.58)
	var entry_outside = Vector2(center_x, front_door_z + front_sign * 0.72)
	return {
		"valid": true,
		"x0": x0,
		"x1": x1,
		"z0": z0,
		"z1": z1,
		"inner_w": inner_w,
		"inner_d": inner_d,
		"wall_t": wall_t,
		"door_half": door_half,
		"door_depth": door_depth,
		"center_x": center_x,
		"front_sign": front_sign,
		"front_door_z": front_door_z,
		"wall_blockers": wall_blockers,
		"wall_visuals": wall_visuals,
		"left_wall": left_wall,
		"right_wall": right_wall,
		"back_wall": back_wall,
		"front_left_wall": front_left_wall,
		"front_right_wall": front_right_wall,
		"interior_rect": interior_rect,
		"entry_inside_pos": entry_inside,
		"entry_outside_pos": entry_outside
	}

func _home_material(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.0
	return material

func _add_home_box(
	parent: Node3D,
	node_name: String,
	size: Vector3,
	position: Vector3,
	material: Material
) -> MeshInstance3D:
	var item = MeshInstance3D.new()
	item.name = node_name
	var mesh = BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = position
	item.material_override = material
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(item, true)
	return item

func _add_contact_shadow(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	size: Vector2,
	material: Material
) -> MeshInstance3D:
	return _add_home_box(parent, node_name, Vector3(size.x, 0.008, size.y), Vector3(position.x, 0.041, position.z), material)

func _create_freya_home_dog_bowl(position: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "FreyaDogBowl"
	root.position = position
	freya_home_interior_root.add_child(root, true)

	var bowl_mat = _home_material(Color8(54, 116, 154), 0.56)
	var bowl_inside_mat = _home_material(Color8(35, 74, 96), 0.68)
	var food_mat = _home_material(Color8(126, 80, 47), 0.9)

	var base = MeshInstance3D.new()
	base.name = "BowlBase"
	var base_mesh = CylinderMesh.new()
	base_mesh.top_radius = 0.27
	base_mesh.bottom_radius = 0.3
	base_mesh.height = 0.07
	base_mesh.radial_segments = 12
	base.mesh = base_mesh
	base.position.y = 0.065
	base.material_override = bowl_mat
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(base, true)

	var rim = MeshInstance3D.new()
	rim.name = "BowlRim"
	var rim_mesh = TorusMesh.new()
	rim_mesh.inner_radius = 0.2
	rim_mesh.outer_radius = 0.3
	rim_mesh.rings = 16
	rim_mesh.ring_segments = 6
	rim.mesh = rim_mesh
	rim.position.y = 0.115
	rim.material_override = bowl_mat
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(rim, true)

	var inside = MeshInstance3D.new()
	inside.name = "BowlInterior"
	var inside_mesh = CylinderMesh.new()
	inside_mesh.top_radius = 0.2
	inside_mesh.bottom_radius = 0.2
	inside_mesh.height = 0.025
	inside_mesh.radial_segments = 12
	inside.mesh = inside_mesh
	inside.position.y = 0.102
	inside.material_override = bowl_inside_mat
	inside.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(inside, true)

	var food = MeshInstance3D.new()
	food.name = "BowlFood"
	var food_mesh = CylinderMesh.new()
	food_mesh.top_radius = 0.17
	food_mesh.bottom_radius = 0.18
	food_mesh.height = 0.035
	food_mesh.radial_segments = 10
	food.mesh = food_mesh
	food.position.y = 0.13
	food.material_override = food_mat
	food.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(food, true)

	for kibble_index in range(5):
		var angle = float(kibble_index) * TAU / 5.0 + 0.3
		_add_home_box(
			root,
			"BowlKibble",
			Vector3(0.052, 0.035, 0.052),
			Vector3(cos(angle) * 0.1, 0.16, sin(angle) * 0.1),
			food_mat
		)
	return root

func _add_emissive_room_light(
	parent: Node3D,
	position: Vector3,
	fixture_material: Material,
	pool_material: Material
) -> void:
	_add_home_box(parent, "InteriorLightCanopy", Vector3(0.28, 0.07, 0.28), Vector3(position.x, 2.45, position.z), fixture_material)
	_add_home_box(parent, "InteriorLightStem", Vector3(0.045, 0.24, 0.045), Vector3(position.x, 2.31, position.z), fixture_material)
	var pendant = MeshInstance3D.new()
	pendant.name = "InteriorLightPendant"
	var pendant_mesh = SphereMesh.new()
	pendant_mesh.radius = 0.13
	pendant_mesh.height = 0.26
	pendant_mesh.radial_segments = 10
	pendant_mesh.rings = 5
	pendant.mesh = pendant_mesh
	pendant.position = Vector3(position.x, 2.16, position.z)
	pendant.material_override = fixture_material
	pendant.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(pendant, true)
	var pool = MeshInstance3D.new()
	pool.name = "InteriorLightPool"
	var pool_mesh = CylinderMesh.new()
	pool_mesh.top_radius = 1.05
	pool_mesh.bottom_radius = 1.24
	pool_mesh.height = 0.008
	pool_mesh.radial_segments = 24
	pool.mesh = pool_mesh
	pool.position = Vector3(position.x, 0.048, position.z)
	pool.material_override = pool_material
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(pool, true)

func _add_windowed_wall(
	parent: Node3D,
	node_prefix: String,
	wall_rect: Rect2,
	wall_material: Material,
	trim_material: Material,
	glass_material: Material,
	wall_height: float,
	window_centers: Array,
	window_width: float,
	sill_y: float,
	window_height: float,
	treatment_material: Material = null,
	treatment_seed: int = 0
) -> int:
	if wall_rect.size.x <= 0.03 or wall_rect.size.y <= 0.03 or window_centers.is_empty():
		_add_store_wall_box(parent, wall_rect, wall_material, wall_height)
		return 0
	var horizontal = wall_rect.size.x >= wall_rect.size.y
	var axis_start = wall_rect.position.x if horizontal else wall_rect.position.y
	var axis_length = wall_rect.size.x if horizontal else wall_rect.size.y
	var axis_end = axis_start + axis_length
	var clamped_width = clampf(window_width, 0.42, maxf(0.42, axis_length - 0.28))
	var opening_bottom = clampf(sill_y, 0.42, wall_height - 0.9)
	var opening_height = clampf(window_height, 0.62, wall_height - opening_bottom - 0.24)
	var opening_top = opening_bottom + opening_height
	var centers: Array[float] = []
	for value in window_centers:
		var center = clampf(float(value), axis_start + clamped_width * 0.5 + 0.1, axis_end - clamped_width * 0.5 - 0.1)
		var duplicate = false
		for existing in centers:
			if absf(existing - center) < clamped_width * 0.72:
				duplicate = true
				break
		if not duplicate:
			centers.append(center)
	centers.sort()
	if centers.is_empty():
		_add_store_wall_box(parent, wall_rect, wall_material, wall_height)
		return 0

	# Continuous wall below and above the openings.
	_add_store_wall_box(parent, wall_rect, wall_material, opening_bottom, 0.0)
	if wall_height - opening_top > 0.04:
		_add_store_wall_box(parent, wall_rect, wall_material, wall_height - opening_top, opening_top)

	# Wall piers between and beyond the individual openings.
	var cursor = axis_start
	for center in centers:
		var opening_start = center - clamped_width * 0.5
		var opening_end = center + clamped_width * 0.5
		if opening_start - cursor > 0.035:
			var pier = Rect2()
			if horizontal:
				pier = Rect2(cursor, wall_rect.position.y, opening_start - cursor, wall_rect.size.y)
			else:
				pier = Rect2(wall_rect.position.x, cursor, wall_rect.size.x, opening_start - cursor)
			_add_store_wall_box(parent, pier, wall_material, opening_height, opening_bottom)
		cursor = opening_end
	if axis_end - cursor > 0.035:
		var final_pier = Rect2()
		if horizontal:
			final_pier = Rect2(cursor, wall_rect.position.y, axis_end - cursor, wall_rect.size.y)
		else:
			final_pier = Rect2(wall_rect.position.x, cursor, wall_rect.size.x, axis_end - cursor)
		_add_store_wall_box(parent, final_pier, wall_material, opening_height, opening_bottom)

	var frame_t = 0.075
	var wall_center_x = wall_rect.get_center().x
	var wall_center_z = wall_rect.get_center().y
	for window_index in range(centers.size()):
		var center = centers[window_index]
		var glass_size = Vector3(clamped_width - frame_t * 1.4, opening_height - frame_t * 1.4, 0.035)
		var glass_pos = Vector3(center, opening_bottom + opening_height * 0.5, wall_center_z)
		if not horizontal:
			glass_size = Vector3(0.035, opening_height - frame_t * 1.4, clamped_width - frame_t * 1.4)
			glass_pos = Vector3(wall_center_x, opening_bottom + opening_height * 0.5, center)
		_add_home_box(parent, "%sGlass" % node_prefix, glass_size, glass_pos, glass_material)
		if horizontal:
			for side in [-1.0, 1.0]:
				_add_home_box(parent, "%sFrame" % node_prefix, Vector3(frame_t, opening_height + frame_t * 2.0, wall_rect.size.y + 0.04), Vector3(center + side * clamped_width * 0.5, opening_bottom + opening_height * 0.5, wall_center_z), trim_material)
			for edge_y in [opening_bottom, opening_top]:
				_add_home_box(parent, "%sFrame" % node_prefix, Vector3(clamped_width + frame_t * 2.0, frame_t, wall_rect.size.y + 0.04), Vector3(center, edge_y, wall_center_z), trim_material)
			_add_home_box(parent, "%sSill" % node_prefix, Vector3(clamped_width + 0.2, 0.07, wall_rect.size.y + 0.18), Vector3(center, opening_bottom - 0.025, wall_center_z), trim_material)
		else:
			for side in [-1.0, 1.0]:
				_add_home_box(parent, "%sFrame" % node_prefix, Vector3(wall_rect.size.x + 0.04, opening_height + frame_t * 2.0, frame_t), Vector3(wall_center_x, opening_bottom + opening_height * 0.5, center + side * clamped_width * 0.5), trim_material)
			for edge_y in [opening_bottom, opening_top]:
				_add_home_box(parent, "%sFrame" % node_prefix, Vector3(wall_rect.size.x + 0.04, frame_t, clamped_width + frame_t * 2.0), Vector3(wall_center_x, edge_y, center), trim_material)
			_add_home_box(parent, "%sSill" % node_prefix, Vector3(wall_rect.size.x + 0.18, 0.07, clamped_width + 0.2), Vector3(wall_center_x, opening_bottom - 0.025, center), trim_material)

		# Treatments sit inside the glazed opening, leaving most of the view clear.
		if treatment_material != null:
			var treatment_style = posmod(treatment_seed + window_index, 3)
			if treatment_style == 0:
				if horizontal:
					for side in [-1.0, 1.0]:
						_add_home_box(parent, "%sCurtain" % node_prefix, Vector3(0.15, opening_height * 0.76, 0.028), Vector3(center + side * (clamped_width * 0.5 - 0.13), opening_bottom + opening_height * 0.54, wall_center_z), treatment_material)
				else:
					for side in [-1.0, 1.0]:
						_add_home_box(parent, "%sCurtain" % node_prefix, Vector3(0.028, opening_height * 0.76, 0.15), Vector3(wall_center_x, opening_bottom + opening_height * 0.54, center + side * (clamped_width * 0.5 - 0.13)), treatment_material)
			elif treatment_style == 1:
				if horizontal:
					_add_home_box(parent, "%sBlind" % node_prefix, Vector3(clamped_width - 0.14, 0.24, 0.026), Vector3(center, opening_top - 0.18, wall_center_z), treatment_material)
				else:
					_add_home_box(parent, "%sBlind" % node_prefix, Vector3(0.026, 0.24, clamped_width - 0.14), Vector3(wall_center_x, opening_top - 0.18, center), treatment_material)
	return centers.size()

func _build_freya_home_interior() -> void:
	if freya_home_index < 0 or freya_home_index >= buildings.size():
		return
	if freya_home_exterior_root != null and is_instance_valid(freya_home_exterior_root):
		freya_home_exterior_root.queue_free()
	if freya_home_interior_root != null and is_instance_valid(freya_home_interior_root):
		freya_home_interior_root.queue_free()
	freya_home_bowl_node = null
	freya_home_bowl_position = Vector2.ZERO
	var home: Dictionary = buildings[freya_home_index]
	var fp: Rect2 = home.get("footprint", Rect2())
	var front_is_south = bool(home.get("front_is_south", true))
	var layout = _compute_home_layout(fp, front_is_south)
	if not bool(layout.get("valid", false)):
		return
	var house_node: Node3D = home.get("node", null)
	if house_node == null or not is_instance_valid(house_node):
		return
	var siding_material: Material = null
	for child in house_node.get_children():
		if child is MeshInstance3D and child.name == "BuildingBody":
			siding_material = (child as MeshInstance3D).material_override
			(child as MeshInstance3D).visible = false
		elif child.name == "BrickFoundation" or child.name == "FoundationBelt" or child.name == "FrontDoor" or child.name == "Windows":
			if child is Node3D:
				(child as Node3D).visible = false
	if siding_material == null:
		siding_material = _home_material(Color8(196, 210, 192), 0.9)

	freya_home_exterior_root = Node3D.new()
	freya_home_exterior_root.name = "FreyaHomeExterior"
	static_root.add_child(freya_home_exterior_root)
	freya_home_interior_root = Node3D.new()
	freya_home_interior_root.name = "FreyaHomeInterior"
	static_root.add_child(freya_home_interior_root)

	var trim_mat = _home_material(Color8(242, 237, 220), 0.7)
	var door_mat = _home_material(Color8(70, 111, 104), 0.68)
	var floor_mat = _home_material(Color8(181, 139, 92), 0.82)
	var rug_mat = _home_material(Color8(116, 151, 158), 0.96)
	var sofa_mat = _home_material(Color8(120, 147, 126), 0.94)
	var wood_mat = _home_material(Color8(126, 85, 54), 0.88)
	var cabinet_mat = _home_material(Color8(224, 218, 198), 0.8)
	var cabinet_door_mat = _home_material(Color8(210, 203, 184), 0.82)
	var counter_mat = _home_material(Color8(112, 115, 111), 0.66)
	var fridge_mat = _home_material(Color8(183, 191, 194), 0.5)
	fridge_mat.metallic = 0.2
	var bed_mat = _home_material(Color8(235, 170, 177), 0.92)
	var home_glass_mat = _home_material(Color(0.68, 0.88, 0.94, 0.24), 0.08)
	home_glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	home_glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	home_glass_mat.metallic = 0.08
	var curtain_mat = _home_material(Color8(191, 126, 120), 0.94)
	var contact_shadow_mat = _home_material(Color(0.055, 0.06, 0.055, 0.2), 1.0)
	contact_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	contact_shadow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var interior_light_mat = _home_material(Color8(255, 236, 180), 0.18)
	interior_light_mat.emission_enabled = true
	interior_light_mat.emission = Color(1.0, 0.82, 0.48)
	interior_light_mat.emission_energy_multiplier = 0.9
	var light_pool_mat = _home_material(Color(1.0, 0.83, 0.5, 0.075), 1.0)
	light_pool_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	light_pool_mat.emission_enabled = true
	light_pool_mat.emission = Color(1.0, 0.78, 0.42)
	light_pool_mat.emission_energy_multiplier = 0.22
	var toy_mats = [
		_home_material(Color8(218, 78, 67), 0.8),
		_home_material(Color8(226, 176, 55), 0.8),
		_home_material(Color8(74, 132, 190), 0.8)
	]

	var body_h = float(home.get("body_height", 3.02))
	var home_window_count = 0
	var left_wall: Rect2 = layout.get("left_wall", Rect2())
	var right_wall: Rect2 = layout.get("right_wall", Rect2())
	var back_wall: Rect2 = layout.get("back_wall", Rect2())
	var front_left_wall: Rect2 = layout.get("front_left_wall", Rect2())
	var front_right_wall: Rect2 = layout.get("front_right_wall", Rect2())
	var side_window_centers = [
		left_wall.position.y + left_wall.size.y * 0.32,
		left_wall.position.y + left_wall.size.y * 0.68
	]
	home_window_count += _add_windowed_wall(freya_home_exterior_root, "HomeSideWindow", left_wall, siding_material, trim_mat, home_glass_mat, body_h, side_window_centers, 1.05, 0.8, 1.2, curtain_mat, 0)
	home_window_count += _add_windowed_wall(freya_home_exterior_root, "HomeSideWindow", right_wall, siding_material, trim_mat, home_glass_mat, body_h, side_window_centers, 1.05, 0.8, 1.2, curtain_mat, 1)
	var back_window_count = 3 if back_wall.size.x >= 10.0 else 2
	var back_window_centers: Array = []
	for window_index in range(back_window_count):
		back_window_centers.append(back_wall.position.x + back_wall.size.x * (float(window_index + 1) / float(back_window_count + 1)))
	home_window_count += _add_windowed_wall(freya_home_exterior_root, "HomeBackWindow", back_wall, siding_material, trim_mat, home_glass_mat, body_h, back_window_centers, 1.12, 0.8, 1.2, curtain_mat, 2)
	for front_wall in [front_left_wall, front_right_wall]:
		if front_wall.size.x > 0.65:
			home_window_count += _add_windowed_wall(freya_home_exterior_root, "HomeFrontWindow", front_wall, siding_material, trim_mat, home_glass_mat, body_h, [front_wall.get_center().x], minf(1.24, front_wall.size.x - 0.26), 0.76, 1.28, curtain_mat, 3)
	for wall_rect in layout.get("wall_visuals", []):
		if wall_rect is Rect2:
			_add_store_wall_band(freya_home_exterior_root, (wall_rect as Rect2).grow(0.015), trim_mat, 0.12, 0.16)

	var center_x = float(layout.get("center_x", fp.get_center().x))
	var front_sign = float(layout.get("front_sign", 1.0))
	var front_door_z = float(layout.get("front_door_z", fp.position.y))
	var door_half = float(layout.get("door_half", 0.54))
	for side in [-1.0, 1.0]:
		_add_home_box(
			freya_home_exterior_root,
			"HomeDoorJamb",
			Vector3(0.12, 2.05, 0.16),
			Vector3(center_x + side * (door_half + 0.06), 1.025, front_door_z + front_sign * 0.02),
			trim_mat
		)
	_add_home_box(
		freya_home_exterior_root,
		"HomeDoorLintel",
		Vector3(door_half * 2.0 + 0.24, 0.14, 0.17),
		Vector3(center_x, 2.08, front_door_z + front_sign * 0.02),
		trim_mat
	)
	var open_door = _add_home_box(
		freya_home_exterior_root,
		"OpenFrontDoor",
		Vector3(0.92, 1.92, 0.07),
		Vector3(center_x - door_half + 0.2, 0.98, front_door_z - front_sign * 0.28),
		door_mat
	)
	open_door.rotation.y = front_sign * deg_to_rad(68.0)
	_add_home_box(
		freya_home_exterior_root,
		"WelcomeMat",
		Vector3(0.92, 0.035, 0.54),
		Vector3(center_x, 0.04, front_door_z + front_sign * 0.44),
		wood_mat
	)

	var interior_rect: Rect2 = layout.get("interior_rect", fp.grow(-0.4))
	var floor = MeshInstance3D.new()
	var floor_mesh = PlaneMesh.new()
	floor_mesh.size = interior_rect.size
	floor.mesh = floor_mesh
	floor.position = Vector3(interior_rect.get_center().x, 0.034, interior_rect.get_center().y)
	floor.material_override = floor_mat
	floor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	freya_home_interior_root.add_child(floor)

	var ix0 = interior_rect.position.x
	var iz0 = interior_rect.position.y
	var iw = interior_rect.size.x
	var id = interior_rect.size.y
	var blockers: Array = layout.get("wall_blockers", []).duplicate()
	var bedroom_width = clampf(iw * 0.22, 2.8, 3.4)
	var bedroom_divider_x = ix0 + bedroom_width
	var bedroom_door_center_z = iz0 + id * 0.5
	var bedroom_door_half = 0.56
	var partition_t = 0.14
	var partition_h = 2.32
	var partition_mat = _home_material(Color8(235, 229, 211), 0.9)
	var partition_a = Rect2(ix0 + bedroom_width - partition_t * 0.5, iz0, partition_t, maxf(0.0, bedroom_door_center_z - bedroom_door_half - iz0))
	var partition_b_start = bedroom_door_center_z + bedroom_door_half
	var partition_b = Rect2(ix0 + bedroom_width - partition_t * 0.5, partition_b_start, partition_t, maxf(0.0, iz0 + id - partition_b_start))
	for partition in [partition_a, partition_b]:
		if partition.size.y > 0.08:
			_add_store_wall_box(freya_home_interior_root, partition, partition_mat, partition_h)
			_add_store_wall_band(freya_home_interior_root, partition, trim_mat, 0.11, 0.15)
			blockers.append(partition)
	_add_home_box(freya_home_interior_root, "BedroomDoorHeader", Vector3(partition_t + 0.04, 0.2, bedroom_door_half * 2.0), Vector3(bedroom_divider_x, 2.22, bedroom_door_center_z), trim_mat)

	# Living room: rug, sofa, coffee table, and TV console.
	var living_center = Vector3(ix0 + iw * 0.28, 0.0, iz0 + id * 0.62)
	_add_home_box(freya_home_interior_root, "LivingRoomRug", Vector3(minf(2.75, iw * 0.3), 0.025, minf(1.85, id * 0.38)), living_center + Vector3(0.0, 0.05, 0.0), rug_mat)
	var sofa_size = Vector3(minf(2.25, iw * 0.27), 0.46, 0.82)
	var sofa_pos = Vector3(living_center.x, 0.31, iz0 + id - 0.52)
	_add_home_box(freya_home_interior_root, "FamilySofaSeat", sofa_size, sofa_pos, sofa_mat)
	_add_home_box(freya_home_interior_root, "FamilySofaBack", Vector3(sofa_size.x, 0.76, 0.18), sofa_pos + Vector3(0.0, 0.31, 0.31), sofa_mat)
	var cushion_w = (sofa_size.x - 0.34) / 3.0
	for cushion_index in range(3):
		_add_home_box(
			freya_home_interior_root,
			"SofaCushion",
			Vector3(cushion_w - 0.035, 0.12, sofa_size.z - 0.24),
			sofa_pos + Vector3(-sofa_size.x * 0.5 + 0.17 + cushion_w * (float(cushion_index) + 0.5), 0.28, -0.06),
			sofa_mat
		)
	for side in [-1.0, 1.0]:
		_add_home_box(freya_home_interior_root, "FamilySofaArm", Vector3(0.16, 0.58, sofa_size.z), sofa_pos + Vector3(side * (sofa_size.x * 0.5 - 0.08), 0.09, 0.0), sofa_mat)
	_add_contact_shadow(freya_home_interior_root, "SofaContactShadow", sofa_pos, Vector2(sofa_size.x + 0.12, sofa_size.z + 0.1), contact_shadow_mat)
	blockers.append(Rect2(sofa_pos.x - sofa_size.x * 0.5, sofa_pos.z - sofa_size.z * 0.5, sofa_size.x, sofa_size.z))
	var coffee_pos = living_center + Vector3(0.0, 0.44, -0.12)
	_add_home_box(freya_home_interior_root, "CoffeeTableTop", Vector3(1.08, 0.1, 0.58), coffee_pos, wood_mat)
	for dx in [-0.44, 0.44]:
		for dz in [-0.2, 0.2]:
			_add_home_box(freya_home_interior_root, "CoffeeTableLeg", Vector3(0.07, 0.4, 0.07), coffee_pos + Vector3(dx, -0.23, dz), wood_mat)
	_add_contact_shadow(freya_home_interior_root, "CoffeeTableContactShadow", coffee_pos, Vector2(1.0, 0.5), contact_shadow_mat)
	blockers.append(Rect2(coffee_pos.x - 0.54, coffee_pos.z - 0.29, 1.08, 0.58))
	var tv_pos = Vector3(bedroom_divider_x + 0.12, 0.72, living_center.z + id * 0.08)
	_add_home_box(freya_home_interior_root, "TelevisionConsole", Vector3(0.34, 0.46, 1.08), tv_pos, wood_mat)
	_add_home_box(freya_home_interior_root, "Television", Vector3(0.08, 0.72, 0.94), tv_pos + Vector3(0.0, 0.63, 0.0), _home_material(Color8(35, 42, 46), 0.25))
	blockers.append(Rect2(tv_pos.x - 0.18, tv_pos.z - 0.55, 0.36, 1.1))

	# Kitchen and dining area.
	var kitchen_w = minf(2.5, iw * 0.42)
	var kitchen_pos = Vector3(ix0 + iw - kitchen_w * 0.5 - 0.22, 0.44, iz0 + 0.27)
	_add_home_box(freya_home_interior_root, "KitchenCabinets", Vector3(kitchen_w, 0.84, 0.48), kitchen_pos, cabinet_mat)
	_add_home_box(freya_home_interior_root, "KitchenCounter", Vector3(kitchen_w + 0.04, 0.09, 0.54), kitchen_pos + Vector3(0.0, 0.47, 0.0), counter_mat)
	var cabinet_door_count = clampi(int(round(kitchen_w / 0.58)), 3, 5)
	for door_index in range(cabinet_door_count):
		var door_w = kitchen_w / float(cabinet_door_count) - 0.035
		var door_x = kitchen_pos.x - kitchen_w * 0.5 + (float(door_index) + 0.5) * kitchen_w / float(cabinet_door_count)
		_add_home_box(freya_home_interior_root, "CabinetDoor", Vector3(door_w, 0.62, 0.025), Vector3(door_x, 0.43, kitchen_pos.z + 0.255), cabinet_door_mat)
		_add_home_box(freya_home_interior_root, "CabinetHandle", Vector3(0.035, 0.18, 0.035), Vector3(door_x + door_w * 0.32, 0.5, kitchen_pos.z + 0.282), counter_mat)
	_add_contact_shadow(freya_home_interior_root, "KitchenContactShadow", kitchen_pos, Vector2(kitchen_w + 0.08, 0.58), contact_shadow_mat)
	blockers.append(Rect2(kitchen_pos.x - kitchen_w * 0.5, kitchen_pos.z - 0.26, kitchen_w, 0.52))
	var fridge_pos = Vector3(ix0 + iw - 0.42, 0.88, iz0 + 0.82)
	_add_home_box(freya_home_interior_root, "Refrigerator", Vector3(0.62, 1.72, 0.58), fridge_pos, fridge_mat)
	blockers.append(Rect2(fridge_pos.x - 0.31, fridge_pos.z - 0.29, 0.62, 0.58))
	var bowl_pos = Vector3(kitchen_pos.x - kitchen_w * 0.27, 0.0, kitchen_pos.z + 0.68)
	freya_home_bowl_node = _create_freya_home_dog_bowl(bowl_pos)
	freya_home_bowl_position = Vector2(bowl_pos.x, bowl_pos.z)
	var table_pos = Vector3(ix0 + iw * 0.7, 0.73, iz0 + id * 0.59)
	var table_size = Vector3(1.45, 0.1, 0.86)
	_add_home_box(freya_home_interior_root, "DiningTableTop", table_size, table_pos, wood_mat)
	for dx in [-0.58, 0.58]:
		for dz in [-0.3, 0.3]:
			_add_home_box(freya_home_interior_root, "DiningTableLeg", Vector3(0.08, 0.69, 0.08), table_pos + Vector3(dx, -0.39, dz), wood_mat)
	_add_contact_shadow(freya_home_interior_root, "DiningTableContactShadow", table_pos, Vector2(table_size.x + 0.1, table_size.z + 0.1), contact_shadow_mat)
	blockers.append(Rect2(table_pos.x - table_size.x * 0.5, table_pos.z - table_size.z * 0.5, table_size.x, table_size.z))
	for chair_data in [
		{"offset": Vector3(-0.98, 0.0, 0.0), "back": Vector3(-0.18, 0.33, 0.0)},
		{"offset": Vector3(0.98, 0.0, 0.0), "back": Vector3(0.18, 0.33, 0.0)},
		{"offset": Vector3(0.0, 0.0, -0.7), "back": Vector3(0.0, 0.33, -0.18)},
		{"offset": Vector3(0.0, 0.0, 0.7), "back": Vector3(0.0, 0.33, 0.18)}
	]:
		var chair_offset: Vector3 = chair_data.get("offset", Vector3.ZERO)
		var chair_base: Vector3 = table_pos + chair_offset
		_add_home_box(freya_home_interior_root, "DiningChairSeat", Vector3(0.42, 0.1, 0.42), Vector3(chair_base.x, 0.46, chair_base.z), wood_mat)
		var back_offset: Vector3 = chair_data.get("back", Vector3.ZERO)
		var back_size = Vector3(0.1, 0.66, 0.42) if absf(back_offset.x) > 0.01 else Vector3(0.42, 0.66, 0.1)
		_add_home_box(freya_home_interior_root, "DiningChairBack", back_size, Vector3(chair_base.x + back_offset.x, 0.73, chair_base.z + back_offset.z), wood_mat)
		var rail_size = Vector3(0.06, 0.07, 0.32) if absf(back_offset.x) > 0.01 else Vector3(0.32, 0.07, 0.06)
		_add_home_box(freya_home_interior_root, "DiningChairRail", rail_size, Vector3(chair_base.x + back_offset.x, 0.88, chair_base.z + back_offset.z), trim_mat)

	# Ryah's corner: toddler bed, toy chest, and colorful blocks.
	var bed_size = Vector3(minf(1.55, iw * 0.28), 0.36, 0.72)
	var bed_pos = Vector3(ix0 + bed_size.x * 0.5 + 0.2, 0.22, iz0 + 0.48)
	_add_home_box(freya_home_interior_root, "RyahToddlerBed", bed_size, bed_pos, bed_mat)
	_add_home_box(freya_home_interior_root, "BedPillow", Vector3(0.32, 0.11, 0.54), bed_pos + Vector3(-bed_size.x * 0.3, 0.23, 0.0), trim_mat)
	for rail_z in [-1.0, 1.0]:
		_add_home_box(freya_home_interior_root, "ToddlerBedRail", Vector3(bed_size.x * 0.72, 0.22, 0.07), bed_pos + Vector3(0.12, 0.31, rail_z * (bed_size.z * 0.5 - 0.035)), trim_mat)
	_add_home_box(freya_home_interior_root, "ToddlerHeadboard", Vector3(0.1, 0.72, bed_size.z + 0.08), bed_pos + Vector3(-bed_size.x * 0.5 + 0.05, 0.25, 0.0), bed_mat)
	_add_contact_shadow(freya_home_interior_root, "BedContactShadow", bed_pos, Vector2(bed_size.x + 0.1, bed_size.z + 0.1), contact_shadow_mat)
	blockers.append(Rect2(bed_pos.x - bed_size.x * 0.5, bed_pos.z - bed_size.z * 0.5, bed_size.x, bed_size.z))
	var chest_pos = Vector3(ix0 + 0.38, 0.25, iz0 + 1.25)
	_add_home_box(freya_home_interior_root, "ToyChest", Vector3(0.56, 0.46, 0.42), chest_pos, wood_mat)
	blockers.append(Rect2(chest_pos.x - 0.28, chest_pos.z - 0.21, 0.56, 0.42))
	for toy_index in range(6):
		_add_home_box(
			freya_home_interior_root,
			"ToyBlock",
			Vector3(0.13, 0.13, 0.13),
			Vector3(
				ix0 + 0.8 + float(toy_index % 3) * 0.18,
				0.11,
				iz0 + 1.18 + float(toy_index / 3) * 0.19
			),
			toy_mats[toy_index % toy_mats.size()]
		)

	for light_pos in [
		Vector3(living_center.x, 0.0, living_center.z),
		Vector3(table_pos.x, 0.0, table_pos.z),
		Vector3(ix0 + bedroom_width * 0.5, 0.0, iz0 + id * 0.54),
		Vector3(kitchen_pos.x, 0.0, iz0 + id * 0.27)
	]:
		_add_emissive_room_light(freya_home_interior_root, light_pos, interior_light_mat, light_pool_mat)

	var path_center = Vector2(ix0 + iw * 0.47, iz0 + id * 0.46)
	ryah_diane_waypoints = PackedVector2Array([
		path_center + Vector2(-0.42, -0.28),
		path_center + Vector2(0.35, -0.4),
		path_center + Vector2(0.48, 0.18),
		path_center + Vector2(0.08, 0.52),
		path_center + Vector2(-0.5, 0.35)
	])
	ryah_diane_waypoint_index = 0
	ryah_diane_node = _create_ryah_diane(Vector3(path_center.x, 0.03, path_center.y))
	freya_home_interior_root.add_child(ryah_diane_node)

	home["enterable"] = true
	home["store_walk_blockers"] = blockers
	home["home_interior_rect"] = interior_rect
	home["store_interior_rect"] = interior_rect
	home["entry_pos"] = layout.get("entry_inside_pos", interior_rect.get_center())
	home["home_interior_root"] = freya_home_interior_root
	home["home_exterior_root"] = freya_home_exterior_root
	home["home_layout"] = layout
	home["dog_bowl_node"] = freya_home_bowl_node
	home["dog_bowl_pos"] = freya_home_bowl_position
	home["dog_bowl_unlimited"] = true
	home["transparent_window_count"] = home_window_count
	home["opaque_window_backing_count"] = 0
	home["home_scale_metrics"] = {
		"footprint_area": fp.get_area(),
		"interior_area": interior_rect.get_area(),
		"wall_height": body_h,
		"door_height": 2.05,
		"door_width": door_half * 2.0,
		"window_sill_height": 0.76,
		"dining_table_top": 0.78,
		"sofa_width": sofa_size.x,
		"bed_length": bed_size.x,
		"freya_height": FREYA_MODEL_TARGET_HEIGHT
	}
	buildings[freya_home_index] = home
	_rebuild_walkability_cache()
	_apply_freya_home_focus_visuals()

func _create_ryah_diane(position: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "Ryah Diane"
	root.position = position
	var skin_mat = _home_material(Color8(221, 174, 139), 0.82)
	var hair_mat = _home_material(Color8(82, 49, 30), 0.9)
	var shirt_mat = _home_material(Color8(225, 111, 135), 0.86)
	var pants_mat = _home_material(Color8(105, 137, 174), 0.9)
	var shoe_mat = _home_material(Color8(66, 57, 56), 0.88)
	var eye_mat = _home_material(Color8(44, 34, 29), 0.6)

	_add_home_box(root, "Torso", Vector3(0.32, 0.38, 0.24), Vector3(0.0, 0.5, 0.0), shirt_mat)
	var head = MeshInstance3D.new()
	head.name = "Head"
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.18
	head_mesh.height = 0.36
	head_mesh.radial_segments = 10
	head_mesh.rings = 5
	head.mesh = head_mesh
	head.position = Vector3(0.0, 0.84, 0.0)
	head.material_override = skin_mat
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(head)
	var hair = MeshInstance3D.new()
	hair.name = "Hair"
	var hair_mesh = SphereMesh.new()
	hair_mesh.radius = 0.19
	hair_mesh.height = 0.38
	hair_mesh.radial_segments = 10
	hair_mesh.rings = 5
	hair.mesh = hair_mesh
	hair.position = Vector3(0.0, 0.94, 0.025)
	hair.scale = Vector3(1.05, 0.6, 1.06)
	hair.material_override = hair_mat
	hair.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(hair)
	for eye_x in [-0.06, 0.06]:
		var eye = MeshInstance3D.new()
		var eye_mesh = SphereMesh.new()
		eye_mesh.radius = 0.018
		eye_mesh.height = 0.036
		eye_mesh.radial_segments = 6
		eye_mesh.rings = 3
		eye.mesh = eye_mesh
		eye.position = Vector3(eye_x, 0.85, -0.17)
		eye.material_override = eye_mat
		root.add_child(eye)

	ryah_diane_left_leg = Node3D.new()
	ryah_diane_left_leg.position = Vector3(-0.09, 0.31, 0.0)
	root.add_child(ryah_diane_left_leg)
	_add_home_box(ryah_diane_left_leg, "LeftLeg", Vector3(0.11, 0.3, 0.12), Vector3(0.0, -0.14, 0.0), pants_mat)
	_add_home_box(ryah_diane_left_leg, "LeftShoe", Vector3(0.13, 0.08, 0.2), Vector3(0.0, -0.3, -0.035), shoe_mat)
	ryah_diane_right_leg = Node3D.new()
	ryah_diane_right_leg.position = Vector3(0.09, 0.31, 0.0)
	root.add_child(ryah_diane_right_leg)
	_add_home_box(ryah_diane_right_leg, "RightLeg", Vector3(0.11, 0.3, 0.12), Vector3(0.0, -0.14, 0.0), pants_mat)
	_add_home_box(ryah_diane_right_leg, "RightShoe", Vector3(0.13, 0.08, 0.2), Vector3(0.0, -0.3, -0.035), shoe_mat)
	ryah_diane_left_arm = Node3D.new()
	ryah_diane_left_arm.position = Vector3(-0.2, 0.61, 0.0)
	root.add_child(ryah_diane_left_arm)
	_add_home_box(ryah_diane_left_arm, "LeftArm", Vector3(0.09, 0.3, 0.09), Vector3(0.0, -0.13, 0.0), skin_mat)
	ryah_diane_right_arm = Node3D.new()
	ryah_diane_right_arm.position = Vector3(0.2, 0.61, 0.0)
	root.add_child(ryah_diane_right_arm)
	_add_home_box(ryah_diane_right_arm, "RightArm", Vector3(0.09, 0.3, 0.09), Vector3(0.0, -0.13, 0.0), skin_mat)

	var name_label = Label3D.new()
	name_label.name = "RyahDianeLabel"
	name_label.text = "Ryah Diane"
	name_label.position = Vector3(0.0, 1.2, 0.0)
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.font_size = 28
	name_label.outline_size = 7
	name_label.modulate = Color(1.0, 0.95, 0.86)
	root.add_child(name_label)
	return root


func _begin_family_intro(view_id: String = "", force_static: bool = false) -> void:
	if family_intro_active or freya_home_index < 0 or freya_home_index >= buildings.size():
		return
	if freya == null or ryah_diane_node == null or freya_home_interior_root == null:
		push_error("Could not start the family intro inside Freya's live home.")
		return
	get_tree().paused = false
	var home: Dictionary = buildings[freya_home_index]
	var interior_rect: Rect2 = home.get("home_interior_rect", Rect2())
	if interior_rect.size.x <= 0.0 or interior_rect.size.y <= 0.0:
		push_error("Could not start the family intro: live home interior is unavailable.")
		return
	var layout: Dictionary = home.get("home_layout", {})
	family_front_sign = float(layout.get("front_sign", 1.0))
	var stage_2d = Vector2(
		interior_rect.position.x + interior_rect.size.x * 0.48,
		interior_rect.position.y + interior_rect.size.y * 0.46
	)
	family_focus_point = Vector3(stage_2d.x, 0.0, stage_2d.y)

	# Stage the actual persistent gameplay actors first. The final Freya position
	# is collision-tested and becomes the player's starting point after the cut.
	var freya_preferred = stage_2d + Vector2(0.0, family_front_sign * 2.1)
	var freya_start = _family_find_walkable_point(freya_preferred, interior_rect, home)
	freya.global_position = Vector3(freya_start.x, 0.0, freya_start.y)
	_family_face_freya_toward_cast(1.0)
	ryah_diane_node.global_position = family_focus_point + Vector3(0.0, 0.03, family_front_sign * 0.54)
	ryah_diane_node.rotation.y = PI if family_front_sign > 0.0 else 0.0
	var ryah_label = ryah_diane_node.get_node_or_null("RyahDianeLabel")
	if ryah_label != null:
		ryah_label.visible = false

	family_intro_root = Node3D.new()
	family_intro_root.name = "LiveHomeFamilyIntro"
	family_intro_root.set_meta("uses_live_home", true)
	freya_home_interior_root.add_child(family_intro_root, true)
	_create_family_intro_far_wall(home, layout)
	family_gene = FamilyVisualFactory.create_adult("Gene")
	family_zoe = FamilyVisualFactory.create_adult("Zoe")
	family_intro_root.add_child(family_gene, true)
	family_intro_root.add_child(family_zoe, true)
	family_gene_left_arm = family_gene.get_node_or_null("LeftArmPivot")
	family_gene_right_arm = family_gene.get_node_or_null("RightArmPivot")
	family_gene.global_position = family_focus_point + Vector3(-0.82, 0.0, -family_front_sign * 0.2)
	family_zoe.global_position = family_focus_point + Vector3(0.82, 0.0, -family_front_sign * 0.2)
	var adult_yaw = PI if family_front_sign > 0.0 else 0.0
	family_gene.rotation.y = adult_yaw
	family_zoe.rotation.y = adult_yaw
	family_gene.set_meta("stage_position", family_gene.position)
	family_zoe.set_meta("stage_position", family_zoe.position)

	family_pill_reveal = FamilyVisualFactory.create_pill_reveal()
	family_pill_reveal.position = FAMILY_PILL_REVEAL_POSITION
	family_gene.add_child(family_pill_reveal, true)
	family_pill_reveal.visible = false
	family_gene_beam = FamilyVisualFactory.create_abduction_effect("GeneAbduction", Color(0.31, 0.92, 1.0))
	family_zoe_beam = FamilyVisualFactory.create_abduction_effect("ZoeAbduction", Color(0.67, 0.45, 1.0))
	family_ryah_beam = FamilyVisualFactory.create_abduction_effect("RyahAbduction", Color(0.95, 0.57, 1.0))
	for effect in [family_gene_beam, family_zoe_beam, family_ryah_beam]:
		family_intro_root.add_child(effect, true)
	family_gene_beam.global_position = family_gene.global_position
	family_zoe_beam.global_position = family_zoe.global_position
	family_ryah_beam.global_position = ryah_diane_node.global_position
	family_bark_wave = FamilyVisualFactory.create_bark_wave("FreyaBarkWave", Color(1.0, 0.85, 0.42))
	family_loud_bark_wave = FamilyVisualFactory.create_bark_wave("FreyaSuperLoudBarkWave", Color(1.0, 0.98, 0.78))
	family_intro_root.add_child(family_bark_wave, true)
	family_intro_root.add_child(family_loud_bark_wave, true)
	family_bark_wave.global_position = freya.head_world_position()
	family_loud_bark_wave.global_position = freya.head_world_position()

	_create_family_intro_ui()
	_create_family_intro_audio()
	if ui_layer != null:
		ui_layer.visible = false
	if pause_menu_layer != null:
		pause_menu_layer.visible = false
	_apply_freya_home_focus_visuals()
	family_intro_active = true
	family_intro_played_events.clear()
	family_intro_static = force_static or not view_id.is_empty()
	family_intro_time = 0.0
	if not view_id.is_empty():
		var view_time = FamilyIntroTimeline.time_for_view(view_id)
		if view_time >= 0.0:
			family_intro_time = view_time
		else:
			family_intro_static = force_static
			push_warning("Unknown family intro view '%s'; starting the sequence normally." % view_id)
	if family_skip_button != null:
		family_skip_button.visible = not family_intro_static
	_apply_family_intro_time(family_intro_time)


func _create_family_intro_far_wall(home: Dictionary, layout: Dictionary) -> void:
	# Gameplay normally hides the complete custom exterior whenever Freya is
	# inside. For the cinematic, rebuild the camera-away/back and right walls so
	# the set reads as a room while the camera-facing wall remains open.
	var back_wall: Rect2 = layout.get("back_wall", Rect2())
	var right_wall: Rect2 = layout.get("right_wall", Rect2())
	if back_wall.size.x <= 0.05 or back_wall.size.y <= 0.05 or right_wall.size.x <= 0.05 or right_wall.size.y <= 0.05:
		return
	family_far_wall = Node3D.new()
	family_far_wall.name = "FamilyIntroVisibleWalls"
	family_far_wall.set_meta("camera_away_wall", true)
	family_far_wall.set_meta("right_side_wall", true)
	family_intro_root.add_child(family_far_wall, true)
	var wall_material = _home_material(Color8(235, 229, 211), 0.9)
	var trim_material = _home_material(Color8(247, 242, 227), 0.72)
	var glass_material = _home_material(Color(0.61, 0.82, 0.9, 0.34), 0.08)
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var curtain_material = _home_material(Color8(191, 126, 120), 0.94)
	var window_count = 3 if back_wall.size.x >= 10.0 else 2
	var window_centers: Array = []
	for window_index in range(window_count):
		window_centers.append(back_wall.position.x + back_wall.size.x * (float(window_index + 1) / float(window_count + 1)))
	_add_windowed_wall(
		family_far_wall,
		"FamilyFarWallWindow",
		back_wall,
		wall_material,
		trim_material,
		glass_material,
		float(home.get("body_height", 3.02)),
		window_centers,
		1.12,
		0.8,
		1.2,
		curtain_material,
		7
	)
	_add_store_wall_band(family_far_wall, back_wall, trim_material, 0.12, 0.16)
	var side_window_centers = [
		right_wall.position.y + right_wall.size.y * 0.32,
		right_wall.position.y + right_wall.size.y * 0.68
	]
	_add_windowed_wall(
		family_far_wall,
		"FamilyRightWallWindow",
		right_wall,
		wall_material,
		trim_material,
		glass_material,
		float(home.get("body_height", 3.02)),
		side_window_centers,
		1.05,
		0.8,
		1.2,
		curtain_material,
		8
	)
	_add_store_wall_band(family_far_wall, right_wall, trim_material, 0.12, 0.16)
	_create_family_intro_back_roof(home)


func _create_family_intro_back_roof(home: Dictionary) -> void:
	var fp: Rect2 = home.get("footprint", Rect2())
	if fp.size.x <= 0.1 or fp.size.y <= 0.1:
		return
	var body_height = float(home.get("body_height", 3.02))
	var roof_rise = float(home.get("roof_rise", 1.0))
	var eave_y = float(home.get("roof_eave_y", body_height - 0.12))
	var ridge_y = body_height + roof_rise
	var half_w = fp.size.x * 0.5 + 0.26
	var half_d = fp.size.y * 0.5 + 0.26
	var center = Vector3(fp.get_center().x, 0.0, fp.get_center().y)
	var back_sign = -family_front_sign
	var roof_style = str(home.get("roof_style", "gable"))
	var ridge_axis = str(home.get("roof_ridge_axis", "x"))
	var vertices: Array[Vector3] = []
	if ridge_axis == "x":
		var ridge_half_x = half_w if roof_style == "gable" else maxf(0.0, half_w - half_d)
		var back_left = center + Vector3(-half_w, eave_y, back_sign * half_d)
		var back_right = center + Vector3(half_w, eave_y, back_sign * half_d)
		var ridge_left = center + Vector3(-ridge_half_x, ridge_y, 0.0)
		var ridge_right = center + Vector3(ridge_half_x, ridge_y, 0.0)
		vertices = [back_left, back_right, ridge_right, back_left, ridge_right, ridge_left]
	elif roof_style == "hip":
		var ridge_half_z = maxf(0.0, half_d - half_w)
		var back_left = center + Vector3(-half_w, eave_y, back_sign * half_d)
		var back_right = center + Vector3(half_w, eave_y, back_sign * half_d)
		var ridge_back = center + Vector3(0.0, ridge_y, back_sign * ridge_half_z)
		vertices = [back_left, back_right, ridge_back]
	else:
		# With a north-south gable ridge, draw only the rear half of both slopes.
		var back_z = back_sign * half_d
		for side in [-1.0, 1.0]:
			var eave_mid = center + Vector3(side * half_w, eave_y, 0.0)
			var eave_back = center + Vector3(side * half_w, eave_y, back_z)
			var ridge_mid = center + Vector3(0.0, ridge_y, 0.0)
			var ridge_back = center + Vector3(0.0, ridge_y, back_z)
			vertices.append_array([eave_mid, eave_back, ridge_back, eave_mid, ridge_back, ridge_mid])
	if vertices.is_empty():
		return
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in vertices:
		surface.add_vertex(vertex)
	surface.generate_normals()
	family_back_roof = MeshInstance3D.new()
	family_back_roof.name = "FamilyIntroBackRoof"
	family_back_roof.mesh = surface.commit()
	var roof_material: Material = null
	for roof_part in home.get("roof_parts", []):
		if roof_part is GeometryInstance3D and is_instance_valid(roof_part as GeometryInstance3D):
			roof_material = (roof_part as GeometryInstance3D).material_override
			if roof_material != null:
				break
	if roof_material == null:
		roof_material = _home_material(Color8(72, 78, 80), 0.94)
	family_back_roof.material_override = roof_material
	family_back_roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	family_back_roof.set_meta("back_side_only", true)
	family_far_wall.add_child(family_back_roof, true)


func _family_find_walkable_point(preferred: Vector2, interior_rect: Rect2, home: Dictionary) -> Vector2:
	var stage_2d = Vector2(family_focus_point.x, family_focus_point.z)
	var ryah_stage = stage_2d + Vector2(0.0, family_front_sign * 0.54)
	var candidates = [
		preferred,
		preferred + Vector2(0.8, 0.0),
		preferred + Vector2(-0.8, 0.0),
		stage_2d + Vector2(-1.3, family_front_sign * 1.55),
		stage_2d + Vector2(1.3, family_front_sign * 1.55),
		stage_2d + Vector2(-1.65, family_front_sign * 1.1),
		stage_2d + Vector2(1.65, family_front_sign * 1.1),
		preferred + Vector2(0.0, -family_front_sign * 0.55),
		home.get("entry_pos", interior_rect.get_center()),
		interior_rect.get_center()
	]
	var best_walkable = Vector2(1000000.0, 1000000.0)
	var best_separation = -1.0
	for candidate in candidates:
		if candidate is Vector2 and interior_rect.grow(-0.3).has_point(candidate) and _is_walkable(candidate.x, candidate.y, FREYA_COLLISION_RADIUS):
			var separation = candidate.distance_to(ryah_stage)
			if separation >= 1.4:
				return candidate
			if separation > best_separation:
				best_separation = separation
				best_walkable = candidate
	if best_separation >= 0.0:
		return best_walkable
	return home.get("entry_pos", interior_rect.get_center())


func _family_face_freya_toward_cast(delta: float) -> void:
	if freya == null:
		return
	var toward_family = family_focus_point - freya.global_position
	toward_family.y = 0.0
	if toward_family.length_squared() > 0.0001:
		freya.force_face_direction(toward_family.normalized(), maxf(delta, 0.0001))


func _create_family_intro_ui() -> void:
	family_intro_layer = CanvasLayer.new()
	family_intro_layer.name = "FamilyIntroUI"
	family_intro_layer.layer = 20
	add_child(family_intro_layer)
	var overlay = Control.new()
	overlay.name = "FamilyIntroOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	family_intro_layer.add_child(overlay)
	for is_top in [true, false]:
		var bar = ColorRect.new()
		bar.name = "TopLetterbox" if is_top else "BottomLetterbox"
		bar.color = Color(0.0, 0.0, 0.0, 0.95)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.anchor_right = 1.0
		bar.anchor_top = 0.0 if is_top else 1.0
		bar.anchor_bottom = 0.0 if is_top else 1.0
		bar.offset_top = 0.0 if is_top else -56.0
		bar.offset_bottom = 56.0 if is_top else 0.0
		overlay.add_child(bar)

	family_skip_button = Button.new()
	family_skip_button.name = "SkipFamilyIntroButton"
	family_skip_button.text = "SKIP TO GAME  [SPACE / ESC]"
	family_skip_button.anchor_left = 1.0
	family_skip_button.anchor_right = 1.0
	family_skip_button.offset_left = -282.0
	family_skip_button.offset_right = -24.0
	family_skip_button.offset_top = 12.0
	family_skip_button.offset_bottom = 46.0
	family_skip_button.pressed.connect(_finish_family_intro)
	overlay.add_child(family_skip_button)

	family_scene_id_label = Label.new()
	family_scene_id_label.position = Vector2(22.0, 14.0)
	family_scene_id_label.size = Vector2(560.0, 30.0)
	family_scene_id_label.add_theme_font_size_override("font_size", 15)
	family_scene_id_label.add_theme_color_override("font_color", Color(0.74, 0.88, 0.92, 0.9))
	family_scene_id_label.visible = OS.get_environment("FREYA_INTRO_SHOW_SCENE_ID") == "1"
	overlay.add_child(family_scene_id_label)

	family_dialogue_panel = Panel.new()
	family_dialogue_panel.name = "FamilyDialoguePanel"
	family_dialogue_panel.anchor_left = 0.5
	family_dialogue_panel.anchor_top = 1.0
	family_dialogue_panel.anchor_right = 0.5
	family_dialogue_panel.anchor_bottom = 1.0
	family_dialogue_panel.offset_left = -485.0
	family_dialogue_panel.offset_top = -212.0
	family_dialogue_panel.offset_right = 485.0
	family_dialogue_panel.offset_bottom = -66.0
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.055, 0.075, 0.96)
	panel_style.border_color = Color(0.82, 0.9, 0.92, 0.92)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(14)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	panel_style.shadow_size = 8
	family_dialogue_panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(family_dialogue_panel)

	family_speaker_label = Label.new()
	family_speaker_label.name = "Speaker"
	family_speaker_label.position = Vector2(22.0, 12.0)
	family_speaker_label.size = Vector2(300.0, 28.0)
	family_speaker_label.add_theme_font_size_override("font_size", 19)
	family_dialogue_panel.add_child(family_speaker_label)
	family_dialogue_label = Label.new()
	family_dialogue_label.name = "Dialogue"
	family_dialogue_label.position = Vector2(22.0, 42.0)
	family_dialogue_label.size = Vector2(926.0, 90.0)
	family_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	family_dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	family_dialogue_label.add_theme_font_size_override("font_size", 25)
	family_dialogue_label.add_theme_color_override("font_color", Color(0.98, 0.98, 0.96))
	family_dialogue_panel.add_child(family_dialogue_label)
	family_dialogue_panel.visible = false


func _create_family_intro_audio() -> void:
	family_bark_player = AudioStreamPlayer.new()
	family_bark_player.name = "FamilyFreyaBark"
	family_bark_player.bus = "Master"
	add_child(family_bark_player)
	family_loud_bark_player = AudioStreamPlayer.new()
	family_loud_bark_player.name = "FamilyFreyaSuperLoudBark"
	family_loud_bark_player.bus = "Master"
	add_child(family_loud_bark_player)
	# These are exact authored mappings. A missing/invalid file stays silent.
	if not OS.has_feature("server") and DisplayServer.get_name() != "headless":
		family_bark_stream = _load_audio_stream_from_file(FAMILY_BARK_AUDIO_PATH)
		family_loud_bark_stream = _load_audio_stream_from_file(FAMILY_LOUD_BARK_AUDIO_PATH)
	family_bark_player.stream = family_bark_stream
	family_loud_bark_player.stream = family_loud_bark_stream


func _update_family_intro(delta: float) -> void:
	if not family_intro_active:
		return
	if not family_intro_static:
		var previous_time = family_intro_time
		family_intro_time = minf(FamilyIntroTimeline.TOTAL_DURATION, family_intro_time + delta)
		_fire_family_intro_events(previous_time, family_intro_time)
	_apply_family_intro_time(family_intro_time)
	if freya != null:
		freya.update_motion(maxf(delta, 0.0001), Vector3.ZERO, false, false)
		_family_face_freya_toward_cast(maxf(delta, 0.0001))
	if not family_intro_static and family_intro_time >= FamilyIntroTimeline.TOTAL_DURATION:
		_finish_family_intro()


func _fire_family_intro_events(previous_time: float, new_time: float) -> void:
	var normal_bark_time = 41.7
	var loud_bark_time = 50.0
	if previous_time < normal_bark_time and new_time >= normal_bark_time:
		_play_family_intro_bark("normal_bark", family_bark_player, family_bark_stream, -3.0)
	if previous_time < loud_bark_time and new_time >= loud_bark_time:
		_play_family_intro_bark("super_loud_bark", family_loud_bark_player, family_loud_bark_stream, 2.0)


func _play_family_intro_bark(event_id: String, player: AudioStreamPlayer, stream: AudioStream, volume_db: float) -> void:
	if family_intro_played_events.has(event_id):
		return
	family_intro_played_events[event_id] = true
	if player == null or stream == null or OS.has_feature("server") or DisplayServer.get_name() == "headless":
		return
	player.stop()
	player.stream = stream
	player.pitch_scale = 1.0
	player.volume_db = volume_db
	player.play()


func _apply_family_intro_time(time_seconds: float) -> void:
	var scene: Dictionary = FamilyIntroTimeline.scene_for_time(time_seconds)
	family_intro_current_scene_id = str(scene.get("id", ""))
	if family_scene_id_label != null:
		family_scene_id_label.text = family_intro_current_scene_id
	var speaker = str(scene.get("speaker", ""))
	var dialogue = str(scene.get("text", ""))
	if family_dialogue_panel != null:
		family_dialogue_panel.visible = not speaker.is_empty()
	if not speaker.is_empty():
		family_speaker_label.text = speaker
		family_speaker_label.add_theme_color_override("font_color", _family_speaker_color(speaker))
		var local_time = maxf(0.0, time_seconds - float(scene["start"]))
		var visible_characters = dialogue.length() if str(scene.get("event", "")) in ["bark", "loud_bark", "laugh"] else clampi(int(floor((local_time + 0.16) * 27.0)), 1, dialogue.length())
		family_dialogue_label.text = dialogue.substr(0, visible_characters)

	var pills_start = 28.4
	var parent_effect_start = 45.0
	var parent_vanish_time = 47.2
	var parent_effect_end = 48.0
	var ryah_effect_start = 48.0
	var loud_bark_start = 50.0
	var ryah_effect_end = 51.2
	if family_pill_reveal != null:
		family_pill_reveal.visible = time_seconds >= pills_start and time_seconds < parent_vanish_time
		family_pill_reveal.rotation.y = sin(time_seconds * 1.8) * 0.08
		# The bundle sits just above and behind Gene's palms. Keeping the two
		# volumes separate prevents the transparent bottles from making his hands
		# look as though they pass through the lower row.
		family_pill_reveal.position.y = FAMILY_PILL_REVEAL_POSITION.y + sin(time_seconds * 3.1) * FAMILY_PILL_REVEAL_BOB
	if family_gene != null:
		family_gene.visible = time_seconds < parent_vanish_time
		var gene_base: Vector3 = family_gene.get_meta("stage_position", family_gene.position)
		family_gene.position = gene_base + Vector3(0.0, absf(sin(time_seconds * 2.1)) * 0.012, 0.0)
	var pill_hold_amount = clampf(inverse_lerp(pills_start - 0.5, pills_start, time_seconds), 0.0, 1.0) if time_seconds < parent_vanish_time else 0.0
	_apply_gene_pill_hold_pose(family_gene_left_arm, -1.0, pill_hold_amount)
	_apply_gene_pill_hold_pose(family_gene_right_arm, 1.0, pill_hold_amount)
	if family_zoe != null:
		family_zoe.visible = time_seconds < parent_vanish_time
		var zoe_base: Vector3 = family_zoe.get_meta("stage_position", family_zoe.position)
		family_zoe.position = zoe_base + Vector3(0.0, absf(sin(time_seconds * 2.0 + 0.8)) * 0.012, 0.0)
	_apply_parent_abduction_effect(family_gene_beam, time_seconds, parent_effect_start, parent_effect_end, 0.0)
	_apply_parent_abduction_effect(family_zoe_beam, time_seconds, parent_effect_start, parent_effect_end, 0.7)
	if family_ryah_beam != null:
		family_ryah_beam.visible = time_seconds >= ryah_effect_start and time_seconds < ryah_effect_end
		if family_ryah_beam.visible:
			var grow = clampf(inverse_lerp(ryah_effect_start, loud_bark_start, time_seconds), 0.0, 1.0)
			var collapse = clampf(inverse_lerp(loud_bark_start, ryah_effect_end, time_seconds), 0.0, 1.0)
			var effect_scale = lerpf(0.25, 1.0, grow) * lerpf(1.0, 0.05, collapse)
			family_ryah_beam.scale = Vector3(effect_scale, maxf(0.08, effect_scale), effect_scale)
			family_ryah_beam.rotation.y = time_seconds * 2.8
	_apply_family_bark_wave(family_bark_wave, time_seconds, 41.7, 42.7, false)
	_apply_family_bark_wave(family_loud_bark_wave, time_seconds, 50.0, 51.2, true)
	_apply_family_intro_camera(time_seconds, scene)


func _apply_gene_pill_hold_pose(arm: Node3D, side: float, amount: float) -> void:
	if arm == null:
		return
	var neutral: Vector3 = arm.get_meta("neutral_rotation", Vector3(0.0, 0.0, side * -0.08))
	arm.rotation = Vector3(
		lerpf(neutral.x, 0.92, amount),
		neutral.y,
		# Keep each palm beneath an outside edge of the bundle instead of pulling
		# both hands inward through the bottles.
		lerpf(neutral.z, side * -0.11, amount)
	)


func _family_speaker_color(speaker: String) -> Color:
	match speaker:
		"GENE":
			return Color(0.55, 0.84, 1.0)
		"ZOE":
			return Color(1.0, 0.72, 0.82)
		"FREYA":
			return Color(1.0, 0.86, 0.4)
		_:
			return Color(0.84, 0.94, 0.9)


func _apply_parent_abduction_effect(effect: Node3D, time_seconds: float, start: float, end: float, phase: float) -> void:
	if effect == null:
		return
	effect.visible = time_seconds >= start and time_seconds < end
	if not effect.visible:
		return
	var progress = clampf(inverse_lerp(start, end, time_seconds), 0.0, 1.0)
	var pulse = 0.9 + sin(time_seconds * 8.0 + phase) * 0.1
	effect.scale = Vector3(pulse, lerpf(0.3, 1.0, minf(1.0, progress * 2.0)), pulse)
	effect.rotation.y = time_seconds * (2.4 + phase * 0.2)
	for child in effect.get_children():
		if child is MeshInstance3D and child.name.begins_with("AbductionRing"):
			child.rotation.y = time_seconds * (3.0 if child.name.ends_with("0") else -3.7)


func _apply_family_bark_wave(wave: Node3D, time_seconds: float, start: float, end: float, loud: bool) -> void:
	if wave == null:
		return
	wave.visible = time_seconds >= start and time_seconds < end
	if not wave.visible:
		return
	wave.global_position = freya.head_world_position()
	wave.rotation.y = PI if family_front_sign > 0.0 else 0.0
	for child in wave.get_children():
		if not (child is MeshInstance3D):
			continue
		var ring_index = int(child.get_meta("ring_index", 0))
		var ring_progress = clampf(inverse_lerp(start + ring_index * 0.12, end, time_seconds), 0.0, 1.0)
		var radius_scale = lerpf(0.45, 5.8 if loud else 3.1, ring_progress)
		child.scale = Vector3.ONE * radius_scale
		child.visible = ring_progress > 0.0 and ring_progress < 0.98


func _apply_family_intro_camera(time_seconds: float, scene: Dictionary) -> void:
	var target = family_focus_point + Vector3(0.0, 0.95, family_front_sign * 0.05)
	var speaker = str(scene.get("speaker", ""))
	if speaker == "GENE" and family_gene != null:
		target = target.lerp(family_gene.global_position + Vector3(0.0, 1.15, 0.0), 0.28)
	elif speaker == "ZOE" and family_zoe != null:
		target = target.lerp(family_zoe.global_position + Vector3(0.0, 1.15, 0.0), 0.28)
	elif str(scene.get("event", "")) in ["ryah_targeted", "loud_bark", "ryah_saved"]:
		target = target.lerp(ryah_diane_node.global_position + Vector3(0.0, 0.65, 0.0), 0.38)
	var drift = Vector3(sin(time_seconds * 0.18) * 0.12, sin(time_seconds * 0.13) * 0.06, 0.0)
	# Preserve the original left-side composition. The house's restored physical
	# right wall is the unobstructive wall visible at screen-left from this angle.
	camera_node.global_position = family_focus_point + Vector3(-4.9, 4.7, family_front_sign * 6.1) + drift
	camera_node.fov = 39.0
	camera_node.look_at(target, Vector3.UP)


func _finish_family_intro() -> void:
	if not family_intro_active:
		return
	family_intro_active = false
	family_intro_requested = false
	if family_bark_player != null:
		family_bark_player.stop()
	if family_loud_bark_player != null:
		family_loud_bark_player.stop()
	if family_intro_root != null and is_instance_valid(family_intro_root):
		family_intro_root.queue_free()
	if family_intro_layer != null and is_instance_valid(family_intro_layer):
		family_intro_layer.queue_free()
	if family_bark_player != null and is_instance_valid(family_bark_player):
		family_bark_player.queue_free()
	if family_loud_bark_player != null and is_instance_valid(family_loud_bark_player):
		family_loud_bark_player.queue_free()
	var ryah_label = ryah_diane_node.get_node_or_null("RyahDianeLabel") if ryah_diane_node != null else null
	if ryah_label != null:
		ryah_label.visible = true
	if ui_layer != null:
		ui_layer.visible = true
	if pause_menu_layer != null:
		pause_menu_layer.visible = true
	camera_orbit_angle = 0.0 if family_front_sign > 0.0 else PI
	camera_zoom_target = 10.8
	camera_planar_distance = camera_zoom_target
	camera_focus = freya.global_position + Vector3(0.0, 0.95, 0.0)
	_apply_freya_home_focus_visuals()
	_update_camera(0.0)
	_update_roof_occlusion(0.0)
	_update_ui()
	_show_status("Freya protected Ryah Diane. Keep her safe!", 2.2)


func _run_family_intro_validation() -> bool:
	var failures: Array[String] = []
	if FAMILY_INTRO_TREE_META != "friendly_freya_family_intro_pending":
		failures.append("family_handoff_key_bad")
	var expected_speakers = ["ZOE", "GENE", "ZOE", "GENE", "GENE & ZOE", "ZOE", "GENE", "ZOE", "GENE", "FREYA", "ZOE", "FREYA"]
	var expected_text = [
		"Congrats on your last day! I'm so glad you'll be able to work from home now.",
		"Who knew that Elon Musk would need a licensed pharmacist for his new company that lets guys suck their own dicks?",
		"I mean, it's incredible. The drug loosens your joints, eliminates pain, AND makes you really want to suck your own dick!",
		"Didn't know Elon needed that last part",
		"Ha, ha, ha",
		"Anyways, did you get our parting gift?",
		"Yes! I was able to swipe these from the pharmacy when my manager wasn't looking. She'll get blamed for it, so it's all good.",
		"But who will look after Ryah when we're celebrating?",
		"Freya will!",
		"BARK!",
		"Okay, ope---",
		"BARK!"
	]
	if FamilyIntroTimeline.SCENES.size() != 16:
		failures.append("family_scene_count_%d" % FamilyIntroTimeline.SCENES.size())
	var previous_end = 0.0
	for scene_index in range(FamilyIntroTimeline.SCENES.size()):
		var scene: Dictionary = FamilyIntroTimeline.SCENES[scene_index]
		if absf(float(scene.get("start", -1.0)) - previous_end) > 0.001:
			failures.append("family_timeline_gap_%d" % scene_index)
		if float(scene.get("end", 0.0)) <= float(scene.get("start", 0.0)):
			failures.append("family_scene_duration_bad_%d" % scene_index)
		previous_end = float(scene.get("end", 0.0))
	if absf(previous_end - FamilyIntroTimeline.TOTAL_DURATION) > 0.001:
		failures.append("family_total_duration_bad")
	var dialogue_scenes = FamilyIntroTimeline.dialogue_scenes()
	if dialogue_scenes.size() != expected_text.size():
		failures.append("family_dialogue_count_%d" % dialogue_scenes.size())
	else:
		for dialogue_index in range(dialogue_scenes.size()):
			if str(dialogue_scenes[dialogue_index].get("speaker", "")) != expected_speakers[dialogue_index]:
				failures.append("family_speaker_bad_%d" % dialogue_index)
			if str(dialogue_scenes[dialogue_index].get("text", "")) != expected_text[dialogue_index]:
				failures.append("family_text_bad_%d" % dialogue_index)
	if family_intro_root == null or family_intro_root.get_parent() != freya_home_interior_root or not bool(family_intro_root.get_meta("uses_live_home", false)):
		failures.append("family_not_inside_live_home")
	if family_far_wall == null or family_far_wall.get_parent() != family_intro_root or not bool(family_far_wall.get_meta("camera_away_wall", false)):
		failures.append("family_camera_away_wall_missing")
	elif not bool(family_far_wall.get_meta("right_side_wall", false)):
		failures.append("family_right_side_wall_missing")
	if family_back_roof == null or family_back_roof.get_parent() != family_far_wall or not bool(family_back_roof.get_meta("back_side_only", false)):
		failures.append("family_back_roof_missing")
	if camera_node == null or camera_node.global_position.x >= family_focus_point.x:
		failures.append("family_original_camera_side_bad")
	var freya_ryah_separation = Vector2(freya.global_position.x, freya.global_position.z).distance_to(Vector2(ryah_diane_node.global_position.x, ryah_diane_node.global_position.z))
	if freya_ryah_separation < 1.4:
		failures.append("family_freya_too_close_to_ryah_%.2f" % freya_ryah_separation)
	for adult in [family_gene, family_zoe]:
		if adult == null or str(adult.get_meta("visual_signature", "")) != "friendly_freya_family_adult_v1":
			failures.append("family_adult_visual_bad")
	if family_gene == null or str(family_gene.get_meta("reference_traits", "")) != "dark_hair_beard_glasses":
		failures.append("gene_reference_traits_bad")
	if family_zoe == null or str(family_zoe.get_meta("reference_traits", "")) != "curly_light_brown_hair_black_top":
		failures.append("zoe_reference_traits_bad")
	if family_pill_reveal == null or family_pill_reveal.get_child_count() != 9:
		failures.append("pill_bottle_count_bad")
	if family_gene_beam == null or family_zoe_beam == null or family_ryah_beam == null:
		failures.append("family_abduction_effect_missing")
	elif family_gene_beam.find_children("AbductionRing*", "MeshInstance3D", true, false).size() != 2 or family_zoe_beam.find_children("AbductionRing*", "MeshInstance3D", true, false).size() != 2:
		failures.append("parent_abduction_ring_count_bad")
	var saved_time = family_intro_time
	_apply_family_intro_time(FamilyIntroTimeline.time_for_view("family_pills"))
	if not family_pill_reveal.visible:
		failures.append("pill_reveal_not_visible")
	if family_gene_left_arm == null or family_gene_right_arm == null or family_gene_left_arm.rotation.x < 0.85 or family_gene_right_arm.rotation.x < 0.85:
		failures.append("family_gene_pill_hold_pose_missing")
	elif absf(family_gene_left_arm.rotation.z) > 0.14 or absf(family_gene_right_arm.rotation.z) > 0.14:
		failures.append("family_gene_hands_too_far_inside_pills")
	if family_pill_reveal.position.y < 1.07 or family_pill_reveal.position.z < -0.42:
		failures.append("family_pills_overlap_hands")
	_apply_family_intro_time(FamilyIntroTimeline.time_for_view("family_abduction"))
	if not family_gene_beam.visible or not family_zoe_beam.visible or not family_gene.visible or not family_zoe.visible:
		failures.append("parent_abduction_checkpoint_bad")
	_apply_family_intro_time(47.5)
	if family_gene.visible or family_zoe.visible:
		failures.append("parents_did_not_disappear")
	_apply_family_intro_time(FamilyIntroTimeline.time_for_view("family_ryah_targeted"))
	if not family_ryah_beam.visible or not ryah_diane_node.visible:
		failures.append("ryah_target_checkpoint_bad")
	_apply_family_intro_time(FamilyIntroTimeline.time_for_view("family_loud_bark"))
	if not family_loud_bark_wave.visible or not ryah_diane_node.visible:
		failures.append("super_loud_bark_checkpoint_bad")
	_apply_family_intro_time(FamilyIntroTimeline.time_for_view("family_ryah_saved"))
	if family_ryah_beam.visible or not ryah_diane_node.visible:
		failures.append("ryah_not_saved")
	var home_rect: Rect2 = buildings[freya_home_index].get("home_interior_rect", Rect2())
	if not home_rect.grow(0.1).has_point(Vector2(freya.global_position.x, freya.global_position.z)):
		failures.append("family_freya_not_inside_live_home")
	if not ResourceLoader.exists(FAMILY_BARK_AUDIO_PATH) or not ResourceLoader.exists(FAMILY_LOUD_BARK_AUDIO_PATH):
		failures.append("family_exact_bark_audio_missing")
	var saved_events = family_intro_played_events.duplicate()
	family_intro_played_events.clear()
	_fire_family_intro_events(0.0, FamilyIntroTimeline.TOTAL_DURATION)
	if family_intro_played_events.size() != 2 or not family_intro_played_events.has("normal_bark") or not family_intro_played_events.has("super_loud_bark"):
		failures.append("family_bark_schedule_bad")
	family_intro_played_events = saved_events
	_apply_family_intro_time(saved_time)
	var intro_root_before_handoff = family_intro_root
	var intro_layer_before_handoff = family_intro_layer
	_finish_family_intro()
	if family_intro_active or ui_layer == null or not ui_layer.visible:
		failures.append("family_gameplay_unlock_failed")
	if intro_root_before_handoff == null or not intro_root_before_handoff.is_queued_for_deletion():
		failures.append("family_temporary_visuals_not_cleared")
	if intro_layer_before_handoff == null or not intro_layer_before_handoff.is_queued_for_deletion():
		failures.append("family_cinematic_ui_not_cleared")
	var final_ryah_label = ryah_diane_node.get_node_or_null("RyahDianeLabel") if ryah_diane_node != null else null
	if final_ryah_label == null or not final_ryah_label.visible:
		failures.append("family_ryah_gameplay_label_not_restored")
	if failures.is_empty():
		print("FAMILY_INTRO_OK: live home, exact dialogue, Gene/Zoe likeness cues, 9 pill bottles, parent abduction, Ryah rescue, authored barks, and gameplay handoff validated")
		return true
	push_error("FAMILY_INTRO_FAIL: " + ", ".join(failures))
	return false

func _update_ryah_diane(delta: float) -> void:
	if ryah_diane_node == null or not is_instance_valid(ryah_diane_node) or ryah_diane_waypoints.is_empty():
		return
	var target_2d = ryah_diane_waypoints[ryah_diane_waypoint_index]
	var current_2d = Vector2(ryah_diane_node.position.x, ryah_diane_node.position.z)
	var to_target = target_2d - current_2d
	if to_target.length_squared() < 0.025:
		ryah_diane_waypoint_index = (ryah_diane_waypoint_index + 1) % ryah_diane_waypoints.size()
		target_2d = ryah_diane_waypoints[ryah_diane_waypoint_index]
		to_target = target_2d - current_2d
	if to_target.length_squared() <= 0.0001:
		return
	var direction = to_target.normalized()
	var travel = minf(to_target.length(), delta * 0.5)
	current_2d += direction * travel
	ryah_diane_node.position.x = current_2d.x
	ryah_diane_node.position.z = current_2d.y
	ryah_diane_node.rotation.y = lerp_angle(
		ryah_diane_node.rotation.y,
		atan2(-direction.x, -direction.y),
		clampf(delta * 7.0, 0.0, 1.0)
	)
	ryah_diane_walk_phase += delta * 8.2
	var swing = sin(ryah_diane_walk_phase) * 0.42
	if ryah_diane_left_leg != null:
		ryah_diane_left_leg.rotation.x = swing
	if ryah_diane_right_leg != null:
		ryah_diane_right_leg.rotation.x = -swing
	if ryah_diane_left_arm != null:
		ryah_diane_left_arm.rotation.x = -swing * 0.72
	if ryah_diane_right_arm != null:
		ryah_diane_right_arm.rotation.x = swing * 0.72
	ryah_diane_node.position.y = 0.03 + absf(sin(ryah_diane_walk_phase * 2.0)) * 0.018

func _is_inside_freya_home(p: Vector2) -> bool:
	if freya_home_index < 0 or freya_home_index >= buildings.size():
		return false
	var home: Dictionary = buildings[freya_home_index]
	var interior_rect: Rect2 = home.get("home_interior_rect", Rect2())
	return interior_rect.size.x > 0.0 and interior_rect.size.y > 0.0 and interior_rect.grow(0.1).has_point(p)

func _apply_freya_home_focus_visuals() -> void:
	var inside = false
	if freya != null and is_instance_valid(freya):
		inside = _is_inside_freya_home(Vector2(freya.global_position.x, freya.global_position.z))
	freya_inside_home = inside
	if freya_home_index < 0 or freya_home_index >= buildings.size():
		return
	var home: Dictionary = buildings[freya_home_index]
	var house_node: Node3D = home.get("node", null)
	if house_node != null and is_instance_valid(house_node):
		house_node.visible = not inside
	if freya_home_exterior_root != null and is_instance_valid(freya_home_exterior_root):
		freya_home_exterior_root.visible = not inside
	if freya_home_interior_root != null and is_instance_valid(freya_home_interior_root):
		freya_home_interior_root.visible = true

func _add_yard_sphere(parent: Node3D, node_name: String, position: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var item = MeshInstance3D.new()
	item.name = node_name
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	item.mesh = mesh
	item.position = position
	item.material_override = material
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(item)
	return item

func _add_yard_cylinder(parent: Node3D, node_name: String, position: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var item = MeshInstance3D.new()
	item.name = node_name
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	item.mesh = mesh
	item.position = position
	item.material_override = material
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(item)
	return item

func _build_suburban_yard_details() -> void:
	if suburban_yard_root != null and is_instance_valid(suburban_yard_root):
		suburban_yard_root.queue_free()
	suburban_yard_root = Node3D.new()
	suburban_yard_root.name = "SuburbanYardDetails"
	static_root.add_child(suburban_yard_root)
	facade_clearance_rects.clear()
	mailboxes.clear()
	suburban_yard_detail_count = 0
	suburban_driveway_count = 0
	freya_home_backyard_detail_count = 0

	var path_mat = _home_material(Color8(184, 180, 169), 0.96)
	var driveway_mat = _home_material(Color8(118, 124, 125), 0.98)
	var hedge_mats = [
		_home_material(Color8(62, 116, 67), 0.98),
		_home_material(Color8(73, 126, 70), 0.98),
		_home_material(Color8(55, 103, 61), 0.98)
	]
	var soil_mat = _home_material(Color8(82, 59, 43), 1.0)
	var flower_mats = [
		_home_material(Color8(218, 92, 104), 0.86),
		_home_material(Color8(234, 177, 62), 0.86),
		_home_material(Color8(128, 102, 190), 0.86)
	]
	var yard_wood_mat = _home_material(Color8(124, 88, 58), 0.92)
	var yard_trim_mat = _home_material(Color8(226, 220, 202), 0.82)
	var yard_metal_mat = _home_material(Color8(62, 68, 69), 0.58)
	yard_metal_mat.metallic = 0.45
	var mailbox_mats = [
		_home_material(Color8(72, 91, 105), 0.72),
		_home_material(Color8(118, 67, 58), 0.74),
		_home_material(Color8(78, 100, 77), 0.76)
	]
	var play_mats = [
		_home_material(Color8(224, 72, 64), 0.82),
		_home_material(Color8(237, 185, 54), 0.82),
		_home_material(Color8(68, 125, 190), 0.82)
	]

	for building_index in range(buildings.size()):
		var building: Dictionary = buildings[building_index]
		var fp: Rect2 = building.get("footprint", Rect2())
		if fp.size.x <= 0.1 or fp.size.y <= 0.1:
			continue
		var front_is_south = bool(building.get("front_is_south", true))
		var front_sign = 1.0 if front_is_south else -1.0
		var front_z = fp.position.y + fp.size.y if front_is_south else fp.position.y
		var center_x = fp.get_center().x
		var is_store = bool(building.get("is_store", false))
		var is_home = bool(building.get("is_freya_home", false))
		var clearance_w = maxf(1.8, fp.size.x - 0.5) if (is_store or is_home) else minf(3.0, fp.size.x * 0.48)
		var clearance_depth = 3.4 if is_store else 2.7
		var clearance_z0 = minf(front_z, front_z + front_sign * clearance_depth)
		facade_clearance_rects.append(Rect2(center_x - clearance_w * 0.5, clearance_z0, clearance_w, clearance_depth))
		if is_store:
			building["facade_clearance_width"] = clearance_w
			buildings[building_index] = building
			continue

		var detail_count = 0
		var local_rng = RandomNumberGenerator.new()
		local_rng.seed = 918273 + building_index * 104729
		var path_depth = 2.16
		_add_home_box(
			suburban_yard_root,
			"FrontWalk",
			Vector3(1.02, 0.018, path_depth),
			Vector3(center_x, 0.031, front_z + front_sign * path_depth * 0.5),
			path_mat
		)
		detail_count += 1

		# Hedges and flowers stay to the sides of the entrance sightline.
		for side in [-1.0, 1.0]:
			var hedge_x = center_x + side * minf(fp.size.x * 0.34, 3.1)
			var hedge_w = clampf(fp.size.x * 0.16, 0.78, 1.65)
			_add_home_box(suburban_yard_root, "FrontHedge", Vector3(hedge_w, 0.54, 0.38), Vector3(hedge_x, 0.28, front_z + front_sign * 0.48), hedge_mats[(building_index + int(side > 0.0)) % hedge_mats.size()])
			var bed_pos = Vector3(hedge_x, 0.04, front_z + front_sign * 0.76)
			_add_home_box(suburban_yard_root, "FlowerBed", Vector3(hedge_w, 0.07, 0.42), bed_pos, soil_mat)
			for flower_index in range(3):
				_add_yard_sphere(suburban_yard_root, "YardFlower", bed_pos + Vector3(lerpf(-hedge_w * 0.32, hedge_w * 0.32, float(flower_index) / 2.0), 0.16, 0.0), 0.085, flower_mats[(building_index + flower_index) % flower_mats.size()])
			detail_count += 5

		# Porch planters and an abstract but readable house-number plaque.
		for side in [-1.0, 1.0]:
			var planter_pos = Vector3(center_x + side * 0.7, 0.17, front_z + front_sign * 0.24)
			_add_home_box(suburban_yard_root, "PorchPlanter", Vector3(0.34, 0.28, 0.3), planter_pos, yard_wood_mat)
			_add_yard_sphere(suburban_yard_root, "PorchPlant", planter_pos + Vector3(0.0, 0.27, 0.0), 0.18, hedge_mats[(building_index + 1) % hedge_mats.size()])
			detail_count += 2
		var plaque_z = front_z + front_sign * 0.105
		_add_home_box(suburban_yard_root, "HouseNumberPlaque", Vector3(0.48, 0.22, 0.035), Vector3(center_x + 0.78, 1.72, plaque_z), yard_trim_mat)
		for glyph_index in range(3):
			_add_home_box(suburban_yard_root, "HouseNumberGlyph", Vector3(0.045, 0.13, 0.018), Vector3(center_x + 0.64 + float(glyph_index) * 0.14, 1.72, plaque_z + front_sign * 0.028), yard_metal_mat)
		detail_count += 4

		var mailbox_side = -1.0 if building_index % 2 == 0 else 1.0
		var mailbox_x = center_x + mailbox_side * minf(fp.size.x * 0.38, 3.35)
		var mailbox_z = front_z + front_sign * 1.72
		var mailbox_root = Node3D.new()
		mailbox_root.name = "MailboxClaimTarget"
		mailbox_root.position = Vector3(mailbox_x, 0.0, mailbox_z)
		suburban_yard_root.add_child(mailbox_root, true)
		_add_home_box(mailbox_root, "MailboxPost", Vector3(0.09, 0.82, 0.09), Vector3(0.0, 0.42, 0.0), yard_wood_mat)
		_add_home_box(mailbox_root, "MailboxBody", Vector3(0.36, 0.3, 0.54), Vector3(0.0, 0.89, 0.0), mailbox_mats[building_index % mailbox_mats.size()])
		_add_home_box(mailbox_root, "MailboxFlagPost", Vector3(0.045, 0.34, 0.045), Vector3(mailbox_side * 0.215, 0.98, 0.0), yard_metal_mat)
		_add_home_box(mailbox_root, "MailboxFlag", Vector3(0.17, 0.15, 0.035), Vector3(mailbox_side * 0.275, 1.09, 0.0), play_mats[0])
		mailboxes.append({
			"node": mailbox_root,
			"pos": Vector2(mailbox_x, mailbox_z),
			"radius": MAILBOX_COLLISION_RADIUS,
			"claimed": false,
			"claimed_by": CLAIM_OWNER_NONE,
			"claim_progress": 0.0,
			"claim_ring": null,
			"building_index": building_index
		})
		building["mailbox_index"] = mailboxes.size() - 1
		detail_count += 4

		# Empty pads preserve the no-cars rule while giving the lots suburban structure.
		var has_driveway = building_index % 3 != 1
		var driveway_side = 1.0 if building_index % 2 == 0 else -1.0
		if has_driveway:
			var drive_x = (fp.position.x + fp.size.x + 1.16) if driveway_side > 0.0 else (fp.position.x - 1.16)
			if drive_x > 1.2 and drive_x < MAP_W - 1.2:
				_add_home_box(suburban_yard_root, "EmptyDriveway", Vector3(2.12, 0.016, 2.58), Vector3(drive_x, 0.029, front_z + front_sign * 1.29), driveway_mat)
				detail_count += 1
				suburban_driveway_count += 1
				building["has_driveway"] = true
			else:
				building["has_driveway"] = false
		else:
			building["has_driveway"] = false

		var back_z = fp.position.y if front_is_south else fp.position.y + fp.size.y
		var back_prop_z = back_z + front_sign * 0.9
		var back_side = -driveway_side
		var side_x = (fp.position.x + fp.size.x + 0.82) if back_side > 0.0 else (fp.position.x - 0.82)
		var backyard_count = 0
		if building_index % 4 == 0 or is_home:
			_add_home_box(suburban_yard_root, "GardenBed", Vector3(1.72, 0.14, 0.78), Vector3(side_x, 0.09, back_prop_z), soil_mat)
			for crop_index in range(4):
				_add_yard_sphere(suburban_yard_root, "GardenPlant", Vector3(side_x + lerpf(-0.6, 0.6, float(crop_index) / 3.0), 0.24, back_prop_z), 0.14, hedge_mats[(building_index + crop_index) % hedge_mats.size()])
			backyard_count += 5
		if building_index % 5 == 0 or is_home:
			var shed_pos = Vector3(side_x, 0.68, back_prop_z + front_sign * 1.25)
			_add_home_box(suburban_yard_root, "GardenShed", Vector3(1.46, 1.34, 1.14), shed_pos, yard_wood_mat)
			_add_home_box(suburban_yard_root, "GardenShedRoof", Vector3(1.62, 0.12, 1.3), shed_pos + Vector3(0.0, 0.72, 0.0), yard_trim_mat)
			_add_home_box(suburban_yard_root, "GardenShedDoor", Vector3(0.55, 0.94, 0.035), shed_pos + Vector3(0.0, -0.1, front_sign * 0.59), yard_trim_mat)
			backyard_count += 3
		if building_index % 3 == 0 or is_home:
			var grill_pos = Vector3(side_x - back_side * 1.25, 0.0, back_prop_z)
			_add_yard_cylinder(suburban_yard_root, "BackyardGrill", grill_pos + Vector3(0.0, 0.62, 0.0), 0.3, 0.34, yard_metal_mat)
			_add_home_box(suburban_yard_root, "GrillStand", Vector3(0.09, 0.58, 0.09), grill_pos + Vector3(0.0, 0.3, 0.0), yard_metal_mat)
			_add_home_box(suburban_yard_root, "GrillHandle", Vector3(0.58, 0.06, 0.08), grill_pos + Vector3(0.0, 0.72, -front_sign * 0.16), yard_metal_mat)
			backyard_count += 3
		var hose = _add_yard_cylinder(suburban_yard_root, "HoseReel", Vector3(fp.position.x + (fp.size.x if back_side > 0.0 else 0.0), 0.58, back_prop_z + front_sign * 0.45), 0.24, 0.12, play_mats[2])
		hose.rotation_degrees.z = 90.0
		backyard_count += 1
		if is_home:
			var toy_base = Vector3(side_x - back_side * 1.1, 0.0, back_prop_z + front_sign * 1.05)
			_add_home_box(suburban_yard_root, "Sandbox", Vector3(1.18, 0.16, 0.92), toy_base + Vector3(0.0, 0.09, 0.0), yard_wood_mat)
			_add_yard_sphere(suburban_yard_root, "PlayBall", toy_base + Vector3(0.86, 0.18, 0.22), 0.18, play_mats[0])
			for toy_index in range(3):
				_add_home_box(suburban_yard_root, "OutdoorToy", Vector3(0.18, 0.18, 0.18), toy_base + Vector3(-0.32 + float(toy_index) * 0.28, 0.2, 0.0), play_mats[toy_index])
			backyard_count += 5
			freya_home_backyard_detail_count = backyard_count

		detail_count += backyard_count
		suburban_yard_detail_count += detail_count
		building["yard_identity"] = true
		building["yard_detail_count"] = detail_count
		building["backyard_detail_count"] = backyard_count
		building["facade_clearance_width"] = clearance_w
		buildings[building_index] = building

	# Mailbox anchors remain live for claim state/rings while their static meshes
	# are batched separately. The broad yard batch then skips those Node3D roots.
	_batch_static_prop_visuals(mailboxes, "BatchedMailboxes")
	_batch_static_prop_visuals([{"node": suburban_yard_root}], "BatchedSuburbanYards")

func _point_in_facade_clearance(p: Vector2, radius: float = 0.0) -> bool:
	for rect in facade_clearance_rects:
		if rect.grow(maxf(0.0, radius)).has_point(p):
			return true
	return false

func _store_texture_cache_key(base_color: Color, accent_color: Color, mortar_color: Color, seed_value: int, coarse: bool) -> String:
	return "%s|%s|%s|%d|%d" % [
		base_color.to_html(false),
		accent_color.to_html(false),
		mortar_color.to_html(false),
		seed_value,
		1 if coarse else 0
	]

func _get_or_create_store_masonry_texture(
	base_color: Color,
	accent_color: Color,
	mortar_color: Color,
	seed_value: int,
	coarse: bool = false
) -> Texture2D:
	var key = _store_texture_cache_key(base_color, accent_color, mortar_color, seed_value, coarse)
	if storefront_texture_cache.has(key):
		var cached: Texture2D = storefront_texture_cache[key]
		if cached != null:
			return cached
	var created = _create_store_masonry_texture(base_color, accent_color, mortar_color, seed_value, coarse)
	storefront_texture_cache[key] = created
	return created

func _create_store_masonry_texture(
	base_color: Color,
	accent_color: Color,
	mortar_color: Color,
	seed_value: int,
	coarse: bool = false
) -> Texture2D:
	var tex_size = 320 if coarse else 256
	var mortar_px = 2
	var block_w = 42 if coarse else 30
	var block_h = 16 if coarse else 12
	var row_step = block_h + mortar_px
	var col_step = block_w + mortar_px
	var img = Image.create(tex_size, tex_size, true, Image.FORMAT_RGBA8)
	img.fill(mortar_color)

	var row_count = int(ceil(float(tex_size + row_step) / float(row_step)))
	var col_count = int(ceil(float(tex_size + col_step * 2) / float(col_step)))
	var seed_phase = float(posmod(seed_value, 97)) * 0.131
	for row in range(row_count):
		var y0 = row * row_step + mortar_px
		var row_shift = col_step / 2 if row % 2 == 1 else 0
		for col in range(col_count):
			var x0 = col * col_step - row_shift + mortar_px
			var x1 = x0 + block_w
			var y1 = y0 + block_h
			if x1 <= 0 or x0 >= tex_size or y1 <= 0 or y0 >= tex_size:
				continue

			var tone_mix = clampf(0.5 + 0.5 * sin(float(row) * 1.73 + float(col) * 2.19 + seed_phase), 0.0, 1.0)
			var block_color = base_color.lerp(accent_color, tone_mix * 0.62)
			if posmod(row * 3 + col + seed_value, 13) == 0:
				block_color = block_color.lerp(base_color.darkened(0.28), 0.42)
			elif posmod(row + col * 2 + seed_value, 11) == 0:
				block_color = block_color.lerp(accent_color.lightened(0.15), 0.28)

			var draw_x0 = maxi(0, x0)
			var draw_x1 = mini(tex_size, x1)
			var draw_y0 = maxi(0, y0)
			var draw_y1 = mini(tex_size, y1)
			for py in range(draw_y0, draw_y1):
				var ly = py - y0
				var y_mul = 1.0
				if ly <= 1:
					y_mul = 0.92
				elif ly >= block_h - 2:
					y_mul = 1.03
				for px in range(draw_x0, draw_x1):
					var lx = px - x0
					var edge_mul = y_mul
					if lx <= 1 or lx >= block_w - 2:
						edge_mul *= 0.94
					var speck = 0.95 + 0.08 * sin(float(px) * 0.12 + float(py) * 0.08 + seed_phase)
					var final_mul = clampf(edge_mul * speck, 0.74, 1.18)
					img.set_pixel(
						px,
						py,
						Color(
							clampf(block_color.r * final_mul, 0.0, 1.0),
							clampf(block_color.g * final_mul, 0.0, 1.0),
							clampf(block_color.b * final_mul, 0.0, 1.0),
							1.0
						)
					)

	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _decorate_storefront(building: Dictionary) -> Dictionary:
	var fp: Rect2 = building.get("footprint", Rect2())
	if fp.size.x <= 0.0 or fp.size.y <= 0.0:
		return building
	var front_is_south = bool(building.get("front_is_south", true))
	var layout: Dictionary = _compute_store_layout(fp, front_is_south)
	if not bool(layout.get("valid", false)):
		return building

	var existing_shell: Node3D = building.get("store_shell_root", null)
	if existing_shell != null and is_instance_valid(existing_shell):
		existing_shell.queue_free()

	var shell_root = Node3D.new()
	shell_root.name = "StorefrontShell"
	static_root.add_child(shell_root)
	store_shell_nodes.append(shell_root)
	building["store_shell_root"] = shell_root
	building["store_layout"] = layout
	building["entry_pos"] = layout.get("entry_inside_pos", Vector2(-1.0, -1.0))

	var storefront_h = clampf(2.72 + fp.size.x * 0.035, 2.72, 3.05)
	var upper_h = 0.68
	var commercial_h = storefront_h + upper_h
	building["height"] = commercial_h
	building["commercial_height"] = commercial_h
	var upper_rect = fp.grow(-0.1)
	var palette_seed = abs(int(round(fp.position.x * 17.0 + fp.position.y * 23.0 + fp.size.x * 11.0 + fp.size.y * 5.0)))
	var facade_palettes: Array = [
		{
			"shell": Color8(228, 214, 187),
			"upper": Color8(174, 158, 138),
			"trim": Color8(247, 239, 223),
			"sign": Color8(56, 138, 92),
			"sign_emission": Color(0.18, 0.48, 0.3),
			"canopy": Color8(66, 142, 101),
			"stripe": Color8(248, 239, 210)
		},
		{
			"shell": Color8(223, 204, 191),
			"upper": Color8(166, 150, 143),
			"trim": Color8(245, 229, 220),
			"sign": Color8(183, 74, 56),
			"sign_emission": Color(0.54, 0.2, 0.14),
			"canopy": Color8(168, 62, 49),
			"stripe": Color8(252, 228, 212)
		},
		{
			"shell": Color8(220, 219, 198),
			"upper": Color8(154, 157, 145),
			"trim": Color8(240, 239, 225),
			"sign": Color8(53, 98, 161),
			"sign_emission": Color(0.17, 0.3, 0.54),
			"canopy": Color8(51, 90, 148),
			"stripe": Color8(219, 234, 247)
		},
		{
			"shell": Color8(231, 206, 170),
			"upper": Color8(181, 145, 108),
			"trim": Color8(249, 234, 205),
			"sign": Color8(199, 103, 40),
			"sign_emission": Color(0.58, 0.28, 0.09),
			"canopy": Color8(186, 90, 31),
			"stripe": Color8(250, 225, 169)
		}
	]
	var palette: Dictionary = facade_palettes[posmod(palette_seed, facade_palettes.size())]
	var shell_color: Color = palette.get("shell", Color8(181, 169, 152))
	var upper_color: Color = palette.get("upper", Color8(152, 142, 132))
	var trim_color: Color = palette.get("trim", Color8(226, 216, 198))
	var sign_color: Color = palette.get("sign", Color8(243, 212, 112))
	var sign_emission_color: Color = palette.get("sign_emission", Color(0.58, 0.47, 0.17))
	var canopy_color: Color = palette.get("canopy", Color8(134, 72, 58))
	var stripe_color: Color = palette.get("stripe", Color8(246, 230, 204))
	var shell_tex = _get_or_create_store_masonry_texture(
		shell_color.darkened(0.12),
		shell_color.lightened(0.08),
		trim_color.lightened(0.12),
		palette_seed + 17,
		false
	)
	var shell_mat = StandardMaterial3D.new()
	shell_mat.albedo_color = shell_color
	shell_mat.albedo_texture = shell_tex
	shell_mat.uv1_scale = Vector3(3.05, 3.05, 1.0)
	shell_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	shell_mat.roughness = 0.84
	shell_mat.metallic = 0.04

	var upper_mat = StandardMaterial3D.new()
	upper_mat.albedo_color = upper_color
	upper_mat.roughness = 0.89
	upper_mat.metallic = 0.03

	var trim_mat = StandardMaterial3D.new()
	trim_mat.albedo_color = trim_color
	trim_mat.roughness = 0.46
	trim_mat.metallic = 0.06

	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.66, 0.86, 0.92, 0.22)
	glass_mat.roughness = 0.07
	glass_mat.metallic = 0.08
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(0.34, 0.5, 0.58)
	glass_mat.emission_energy_multiplier = 0.24

	var sign_mat = StandardMaterial3D.new()
	sign_mat.albedo_color = sign_color
	sign_mat.roughness = 0.32
	sign_mat.metallic = 0.06
	sign_mat.emission_enabled = true
	sign_mat.emission = sign_emission_color
	sign_mat.emission_energy_multiplier = 0.66

	var canopy_mat = StandardMaterial3D.new()
	canopy_mat.albedo_color = canopy_color
	canopy_mat.roughness = 0.5
	canopy_mat.metallic = 0.03

	var canopy_stripe_mat = StandardMaterial3D.new()
	canopy_stripe_mat.albedo_color = stripe_color
	canopy_stripe_mat.roughness = 0.47
	canopy_stripe_mat.metallic = 0.02

	var sign_letter_mat = StandardMaterial3D.new()
	sign_letter_mat.albedo_color = Color8(252, 246, 224)
	sign_letter_mat.roughness = 0.18
	sign_letter_mat.metallic = 0.0
	sign_letter_mat.emission_enabled = true
	sign_letter_mat.emission = Color(0.98, 0.88, 0.58)
	sign_letter_mat.emission_energy_multiplier = 0.58

	var produce_top_mat = StandardMaterial3D.new()
	produce_top_mat.albedo_color = Color8(142, 92, 56)
	produce_top_mat.roughness = 0.82
	produce_top_mat.metallic = 0.0

	var produce_frame_mat = StandardMaterial3D.new()
	produce_frame_mat.albedo_color = Color8(98, 67, 43)
	produce_frame_mat.roughness = 0.88
	produce_frame_mat.metallic = 0.0

	var produce_mats: Array = []
	for c in [Color8(198, 45, 40), Color8(226, 138, 38), Color8(205, 186, 59), Color8(116, 164, 56), Color8(172, 88, 62)]:
		var pm = StandardMaterial3D.new()
		pm.albedo_color = c
		pm.roughness = 0.78
		pm.metallic = 0.0
		produce_mats.append(pm)

	var accent_strip_mat = StandardMaterial3D.new()
	accent_strip_mat.albedo_color = sign_color.darkened(0.1)
	accent_strip_mat.roughness = 0.36
	accent_strip_mat.metallic = 0.04

	var logo_badge_mat = StandardMaterial3D.new()
	logo_badge_mat.albedo_color = Color8(250, 241, 217)
	logo_badge_mat.roughness = 0.22
	logo_badge_mat.metallic = 0.0
	logo_badge_mat.emission_enabled = true
	logo_badge_mat.emission = Color(0.97, 0.88, 0.64)
	logo_badge_mat.emission_energy_multiplier = 0.34

	var pendant_mat = StandardMaterial3D.new()
	pendant_mat.albedo_color = Color8(246, 234, 188)
	pendant_mat.roughness = 0.21
	pendant_mat.metallic = 0.0
	pendant_mat.emission_enabled = true
	pendant_mat.emission = Color(1.0, 0.92, 0.68)
	pendant_mat.emission_energy_multiplier = 0.68

	var chalkboard_mat = StandardMaterial3D.new()
	chalkboard_mat.albedo_color = Color8(42, 54, 44)
	chalkboard_mat.roughness = 0.9
	chalkboard_mat.metallic = 0.0

	var chalk_frame_mat = StandardMaterial3D.new()
	chalk_frame_mat.albedo_color = Color8(125, 91, 56)
	chalk_frame_mat.roughness = 0.84
	chalk_frame_mat.metallic = 0.0

	var entry_metal_mat = StandardMaterial3D.new()
	entry_metal_mat.albedo_color = Color8(77, 82, 86)
	entry_metal_mat.roughness = 0.35
	entry_metal_mat.metallic = 0.58

	var entry_notice_mat = StandardMaterial3D.new()
	entry_notice_mat.albedo_color = Color8(245, 238, 224)
	entry_notice_mat.roughness = 0.5
	entry_notice_mat.metallic = 0.0

	var entry_notice_text_mat = StandardMaterial3D.new()
	entry_notice_text_mat.albedo_color = Color8(47, 55, 62)
	entry_notice_text_mat.roughness = 0.68
	entry_notice_text_mat.metallic = 0.0

	var entry_lamp_mat = StandardMaterial3D.new()
	entry_lamp_mat.albedo_color = Color8(253, 238, 188)
	entry_lamp_mat.roughness = 0.16
	entry_lamp_mat.metallic = 0.0
	entry_lamp_mat.emission_enabled = true
	entry_lamp_mat.emission = Color(1.0, 0.9, 0.64)
	entry_lamp_mat.emission_energy_multiplier = 0.84

	var planter_mat = StandardMaterial3D.new()
	planter_mat.albedo_color = Color8(112, 74, 48)
	planter_mat.roughness = 0.9

	var flower_mat = StandardMaterial3D.new()
	flower_mat.albedo_color = sign_color.lightened(0.18)
	flower_mat.roughness = 0.82

	var facade_shadow_mat = StandardMaterial3D.new()
	facade_shadow_mat.albedo_color = Color(0.06, 0.065, 0.06, 0.2)
	facade_shadow_mat.roughness = 1.0
	facade_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	facade_shadow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	if upper_rect.size.x > 0.2 and upper_rect.size.y > 0.2:
		_add_store_wall_box(shell_root, upper_rect, upper_mat, upper_h, storefront_h)
		_add_store_wall_band(shell_root, upper_rect.grow(0.06), trim_mat, commercial_h - 0.04, 0.18)
		_add_store_wall_band(shell_root, upper_rect.grow(0.12), accent_strip_mat, commercial_h + 0.07, 0.08)

	var front_left_window_wall: Rect2 = layout.get("front_left_wall", Rect2())
	var front_right_window_wall: Rect2 = layout.get("front_right_wall", Rect2())
	var storefront_window_count = 0
	for wall_rect in layout.get("wall_visuals", []):
		if wall_rect is Rect2:
			var wall_shape = wall_rect as Rect2
			var is_front_window_wall = wall_shape == front_left_window_wall or wall_shape == front_right_window_wall
			if is_front_window_wall and wall_shape.size.x > 0.45:
				storefront_window_count += _add_windowed_wall(
					shell_root,
					"StoreWindow",
					wall_shape,
					shell_mat,
					trim_mat,
					glass_mat,
					storefront_h,
					[wall_shape.get_center().x],
					maxf(0.38, wall_shape.size.x - 0.24),
					0.46,
					minf(1.62, storefront_h - 0.92)
				)
			else:
				_add_store_wall_box(shell_root, wall_shape, shell_mat, storefront_h, 0.0)
			var shell_band_rect = _inset_store_visual_rect(wall_shape, 0.018)
			_add_store_wall_band(shell_root, shell_band_rect, trim_mat, storefront_h - 0.08, 0.1)
			var curb_band_rect = _inset_store_visual_rect(wall_shape, 0.01)
			_add_store_wall_band(shell_root, curb_band_rect, trim_mat, 0.2, 0.12)

	var front_sign = float(layout.get("front_sign", 1.0))
	var front_door_z = float(layout.get("front_door_z", fp.position.y + (fp.size.y if front_is_south else 0.0)))
	var center_x = float(layout.get("center_x", fp.position.x + fp.size.x * 0.5))
	var door_half = float(layout.get("door_half", STORE_DOOR_HALF_WIDTH))
	var door_width = door_half * 2.0

	for front_rect in [front_left_window_wall, front_right_window_wall]:
		if not (front_rect is Rect2):
			continue
		var seg: Rect2 = front_rect as Rect2
		if seg.size.x <= 1.35:
			continue
		var mullion = MeshInstance3D.new()
		var mullion_mesh = BoxMesh.new()
		mullion_mesh.size = Vector3(0.065, minf(1.62, storefront_h - 0.92), 0.07)
		mullion.mesh = mullion_mesh
		mullion.position = Vector3(seg.get_center().x, 0.46 + mullion_mesh.size.y * 0.5, seg.get_center().y + front_sign * 0.025)
		mullion.material_override = trim_mat
		shell_root.add_child(mullion)

	var door_jamb_h = storefront_h * 0.72
	for side in [-1.0, 1.0]:
		var jamb = MeshInstance3D.new()
		var jamb_mesh = BoxMesh.new()
		jamb_mesh.size = Vector3(0.13, door_jamb_h, 0.17)
		jamb.mesh = jamb_mesh
		jamb.position = Vector3(center_x + side * (door_half + 0.065), door_jamb_h * 0.5, front_door_z + front_sign * 0.03)
		jamb.material_override = trim_mat
		shell_root.add_child(jamb)

	var lintel = MeshInstance3D.new()
	var lintel_mesh = BoxMesh.new()
	lintel_mesh.size = Vector3(door_width + 0.26, 0.2, 0.18)
	lintel.mesh = lintel_mesh
	lintel.position = Vector3(center_x, door_jamb_h + 0.1, front_door_z + front_sign * 0.03)
	lintel.material_override = trim_mat
	shell_root.add_child(lintel)

	var door_glass = MeshInstance3D.new()
	var door_glass_mesh = BoxMesh.new()
	door_glass_mesh.size = Vector3(maxf(0.7, door_width * 0.78), door_jamb_h - 0.32, 0.055)
	door_glass.mesh = door_glass_mesh
	door_glass.position = Vector3(center_x, door_jamb_h * 0.5, front_door_z + front_sign * 0.045)
	door_glass.material_override = glass_mat
	shell_root.add_child(door_glass)

	var door_kickplate = MeshInstance3D.new()
	var kickplate_mesh = BoxMesh.new()
	kickplate_mesh.size = Vector3(door_width * 0.82, 0.24, 0.065)
	door_kickplate.mesh = kickplate_mesh
	door_kickplate.position = Vector3(center_x, 0.18, front_door_z + front_sign * 0.055)
	door_kickplate.material_override = entry_metal_mat
	shell_root.add_child(door_kickplate)

	var door_handle = MeshInstance3D.new()
	var handle_mesh = BoxMesh.new()
	handle_mesh.size = Vector3(0.055, 0.34, 0.07)
	door_handle.mesh = handle_mesh
	door_handle.position = Vector3(center_x + door_width * 0.29, 1.08, front_door_z + front_sign * 0.1)
	door_handle.material_override = entry_metal_mat
	shell_root.add_child(door_handle)

	for side in [-1.0, 1.0]:
		var pilaster = MeshInstance3D.new()
		var pilaster_mesh = BoxMesh.new()
		pilaster_mesh.size = Vector3(0.22, storefront_h - 0.14, 0.2)
		pilaster.mesh = pilaster_mesh
		pilaster.position = Vector3(
			fp.position.x + fp.size.x * (0.03 if side < 0.0 else 0.97),
			(storefront_h - 0.14) * 0.5,
			front_door_z + front_sign * 0.04
		)
		pilaster.material_override = trim_mat
		shell_root.add_child(pilaster)

	var left_front_seg: Rect2 = layout.get("front_left_wall", Rect2())
	var right_front_seg: Rect2 = layout.get("front_right_wall", Rect2())
	var detail_side = 1.0
	if right_front_seg.size.x < 0.32 and left_front_seg.size.x > right_front_seg.size.x:
		detail_side = -1.0
	var opposite_side = -detail_side
	var detail_x = center_x + detail_side * (door_half + 0.2)
	var opposite_x = center_x + opposite_side * (door_half + 0.2)

	var address_plaque = MeshInstance3D.new()
	var address_plaque_mesh = BoxMesh.new()
	address_plaque_mesh.size = Vector3(clampf(door_width * 0.46, 0.54, 0.9), 0.1, 0.04)
	address_plaque.mesh = address_plaque_mesh
	address_plaque.position = Vector3(center_x, door_jamb_h + 0.27, front_door_z + front_sign * 0.09)
	address_plaque.material_override = entry_notice_mat
	shell_root.add_child(address_plaque)

	var address_text = MeshInstance3D.new()
	var address_text_mesh = BoxMesh.new()
	address_text_mesh.size = Vector3(address_plaque_mesh.size.x * 0.62, 0.035, 0.01)
	address_text.mesh = address_text_mesh
	address_text.position = address_plaque.position + Vector3(0.0, 0.0, front_sign * 0.03)
	address_text.material_override = entry_notice_text_mat
	shell_root.add_child(address_text)

	var hours_plaque = MeshInstance3D.new()
	var hours_plaque_mesh = BoxMesh.new()
	hours_plaque_mesh.size = Vector3(0.16, 0.33, 0.03)
	hours_plaque.mesh = hours_plaque_mesh
	hours_plaque.position = Vector3(detail_x, storefront_h * 0.38, front_door_z + front_sign * 0.08)
	hours_plaque.material_override = entry_notice_mat
	shell_root.add_child(hours_plaque)

	var hours_text = MeshInstance3D.new()
	var hours_text_mesh = BoxMesh.new()
	hours_text_mesh.size = Vector3(0.11, 0.22, 0.01)
	hours_text.mesh = hours_text_mesh
	hours_text.position = hours_plaque.position + Vector3(0.0, 0.0, front_sign * 0.025)
	hours_text.material_override = entry_notice_text_mat
	shell_root.add_child(hours_text)

	var intercom = MeshInstance3D.new()
	var intercom_mesh = BoxMesh.new()
	intercom_mesh.size = Vector3(0.08, 0.2, 0.03)
	intercom.mesh = intercom_mesh
	intercom.position = Vector3(opposite_x, storefront_h * 0.34, front_door_z + front_sign * 0.09)
	intercom.material_override = entry_metal_mat
	shell_root.add_child(intercom)

	var intercom_button = MeshInstance3D.new()
	var intercom_button_mesh = BoxMesh.new()
	intercom_button_mesh.size = Vector3(0.028, 0.028, 0.012)
	intercom_button.mesh = intercom_button_mesh
	intercom_button.position = intercom.position + Vector3(0.0, -0.05, front_sign * 0.024)
	intercom_button.material_override = entry_notice_mat
	shell_root.add_child(intercom_button)

	for side in [-1.0, 1.0]:
		var sconce = MeshInstance3D.new()
		var sconce_mesh = BoxMesh.new()
		sconce_mesh.size = Vector3(0.07, 0.14, 0.06)
		sconce.mesh = sconce_mesh
		sconce.position = Vector3(center_x + side * (door_half + 0.16), door_jamb_h + 0.2, front_door_z + front_sign * 0.08)
		sconce.material_override = entry_metal_mat
		shell_root.add_child(sconce)

		var lamp = MeshInstance3D.new()
		var lamp_mesh = SphereMesh.new()
		lamp_mesh.radius = 0.038
		lamp_mesh.height = 0.076
		lamp.mesh = lamp_mesh
		lamp.position = sconce.position + Vector3(0.0, -0.02, front_sign * 0.05)
		lamp.material_override = entry_lamp_mat
		shell_root.add_child(lamp)

	var security_cam = MeshInstance3D.new()
	var security_cam_mesh = BoxMesh.new()
	security_cam_mesh.size = Vector3(0.09, 0.06, 0.16)
	security_cam.mesh = security_cam_mesh
	security_cam.position = Vector3(
		center_x + opposite_side * (door_half + 0.13),
		door_jamb_h + 0.28,
		front_door_z + front_sign * 0.1
	)
	security_cam.rotation_degrees = Vector3(-18.0, opposite_side * -32.0, 0.0)
	security_cam.material_override = entry_metal_mat
	shell_root.add_child(security_cam)

	var sign = MeshInstance3D.new()
	var sign_mesh = BoxMesh.new()
	sign_mesh.size = Vector3(clampf(fp.size.x * 0.62, 2.7, 5.9), 0.44, 0.2)
	sign.mesh = sign_mesh
	sign.position = Vector3(center_x, storefront_h - 0.36, front_door_z + front_sign * 0.08)
	sign.material_override = sign_mat
	shell_root.add_child(sign)

	var fascia = MeshInstance3D.new()
	var fascia_mesh = BoxMesh.new()
	fascia_mesh.size = Vector3(clampf(fp.size.x * 0.76, 3.0, 6.9), 0.12, 0.16)
	fascia.mesh = fascia_mesh
	fascia.position = Vector3(center_x, storefront_h - 0.67, front_door_z + front_sign * 0.08)
	fascia.material_override = accent_strip_mat
	shell_root.add_child(fascia)

	var logo_badge = MeshInstance3D.new()
	var logo_mesh = BoxMesh.new()
	logo_mesh.size = Vector3(0.42, 0.42, 0.05)
	logo_badge.mesh = logo_mesh
	logo_badge.position = Vector3(center_x, storefront_h - 0.34, front_door_z + front_sign * 0.22)
	logo_badge.material_override = logo_badge_mat
	shell_root.add_child(logo_badge)

	var logo_leaf = MeshInstance3D.new()
	var logo_leaf_mesh = BoxMesh.new()
	logo_leaf_mesh.size = Vector3(0.1, 0.2, 0.04)
	logo_leaf.mesh = logo_leaf_mesh
	logo_leaf.position = logo_badge.position + Vector3(0.13, 0.17, front_sign * 0.01)
	logo_leaf.rotation_degrees = Vector3(0.0, 0.0, -28.0)
	logo_leaf.material_override = canopy_mat
	shell_root.add_child(logo_leaf)

	var blade_side = -1.0 if front_sign > 0.0 else 1.0
	var blade_sign = MeshInstance3D.new()
	var blade_mesh = BoxMesh.new()
	blade_mesh.size = Vector3(0.18, 0.64, 0.54)
	blade_sign.mesh = blade_mesh
	blade_sign.position = Vector3(
		center_x + blade_side * (door_half + 0.42),
		storefront_h * 0.64,
		front_door_z + front_sign * 0.24
	)
	blade_sign.material_override = sign_mat
	shell_root.add_child(blade_sign)

	var blade_bracket = MeshInstance3D.new()
	var blade_bracket_mesh = BoxMesh.new()
	blade_bracket_mesh.size = Vector3(0.12, 0.08, 0.3)
	blade_bracket.mesh = blade_bracket_mesh
	blade_bracket.position = Vector3(
		center_x + blade_side * (door_half + 0.29),
		storefront_h * 0.64,
		front_door_z + front_sign * 0.15
	)
	blade_bracket.material_override = trim_mat
	shell_root.add_child(blade_bracket)

	var sign_letter_count = clampi(int(round(sign_mesh.size.x / 0.5)), 5, 10)
	for li in range(sign_letter_count):
		var t = (float(li) + 0.5) / float(sign_letter_count)
		var letter = MeshInstance3D.new()
		var letter_mesh = BoxMesh.new()
		letter_mesh.size = Vector3(maxf(0.12, sign_mesh.size.x / float(sign_letter_count) * 0.46), 0.14, 0.04)
		letter.mesh = letter_mesh
		letter.position = Vector3(
			lerpf(center_x - sign_mesh.size.x * 0.41, center_x + sign_mesh.size.x * 0.41, t),
			storefront_h - 0.35 + sin(float(li) * 1.8) * 0.018,
			front_door_z + front_sign * 0.2
		)
		letter.material_override = sign_letter_mat
		shell_root.add_child(letter)

	var awning = MeshInstance3D.new()
	var awning_mesh = BoxMesh.new()
	awning_mesh.size = Vector3(clampf(fp.size.x * 0.66, 2.6, 6.0), 0.08, 0.84)
	awning.mesh = awning_mesh
	awning.position = Vector3(center_x, storefront_h * 0.62, front_door_z + front_sign * 0.38)
	awning.material_override = canopy_mat
	shell_root.add_child(awning)

	var awning_shadow = MeshInstance3D.new()
	awning_shadow.name = "AwningContactShadow"
	var awning_shadow_mesh = BoxMesh.new()
	awning_shadow_mesh.size = Vector3(awning_mesh.size.x * 0.94, 0.14, 0.026)
	awning_shadow.mesh = awning_shadow_mesh
	awning_shadow.position = Vector3(center_x, awning.position.y - 0.24, front_door_z + front_sign * 0.06)
	awning_shadow.material_override = facade_shadow_mat
	awning_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shell_root.add_child(awning_shadow)

	var storefront_contact = MeshInstance3D.new()
	storefront_contact.name = "StorefrontContactShadow"
	var storefront_contact_mesh = BoxMesh.new()
	storefront_contact_mesh.size = Vector3(fp.size.x - 0.16, 0.04, 0.14)
	storefront_contact.mesh = storefront_contact_mesh
	storefront_contact.position = Vector3(center_x, 0.045, front_door_z + front_sign * 0.08)
	storefront_contact.material_override = facade_shadow_mat
	storefront_contact.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shell_root.add_child(storefront_contact)

	var stripe_count = clampi(int(round(awning_mesh.size.x / 0.48)), 5, 13)
	for si in range(stripe_count):
		var stripe_t = (float(si) + 0.5) / float(stripe_count)
		var stripe = MeshInstance3D.new()
		var stripe_mesh = BoxMesh.new()
		stripe_mesh.size = Vector3(maxf(0.1, awning_mesh.size.x / float(stripe_count) * 0.46), awning_mesh.size.y + 0.01, 0.07)
		stripe.mesh = stripe_mesh
		stripe.position = Vector3(
			lerpf(center_x - awning_mesh.size.x * 0.45, center_x + awning_mesh.size.x * 0.45, stripe_t),
			awning.position.y,
			awning.position.z + front_sign * (awning_mesh.size.z * 0.36)
		)
		if si % 2 == 0:
			stripe.material_override = canopy_stripe_mat
		else:
			stripe.material_override = canopy_mat
		shell_root.add_child(stripe)

	var pendant_count = clampi(int(round(awning_mesh.size.x / 1.35)), 2, 4)
	for pi in range(pendant_count):
		var t = (float(pi) + 0.5) / float(pendant_count)
		var cord = MeshInstance3D.new()
		var cord_mesh = BoxMesh.new()
		cord_mesh.size = Vector3(0.01, 0.12, 0.01)
		cord.mesh = cord_mesh
		cord.position = Vector3(
			lerpf(center_x - awning_mesh.size.x * 0.4, center_x + awning_mesh.size.x * 0.4, t),
			awning.position.y - 0.09,
			awning.position.z - front_sign * 0.16
		)
		cord.material_override = trim_mat
		shell_root.add_child(cord)

		var pendant = MeshInstance3D.new()
		var pendant_mesh = SphereMesh.new()
		pendant_mesh.radius = 0.05
		pendant_mesh.height = 0.1
		pendant.mesh = pendant_mesh
		pendant.position = cord.position + Vector3(0.0, -0.075, 0.0)
		pendant.material_override = pendant_mat
		shell_root.add_child(pendant)

	var threshold = MeshInstance3D.new()
	var threshold_mesh = BoxMesh.new()
	var threshold_depth = STORE_DOOR_DEPTH + 0.54
	threshold_mesh.size = Vector3(maxf(0.9, door_width * 0.94), 0.05, threshold_depth)
	threshold.mesh = threshold_mesh
	threshold.position = Vector3(
		center_x,
		0.026,
		front_door_z - front_sign * (threshold_depth * 0.5 - STORE_WALL_THICKNESS * 0.3)
	)
	threshold.material_override = trim_mat
	shell_root.add_child(threshold)

	for side in [-1.0, 1.0]:
		var board = MeshInstance3D.new()
		var board_mesh = BoxMesh.new()
		board_mesh.size = Vector3(0.22, 0.64, 0.06)
		board.mesh = board_mesh
		board.position = Vector3(
			center_x + side * maxf(0.54, door_half + 0.18),
			0.33,
			front_door_z + front_sign * 0.63
		)
		board.rotation_degrees = Vector3(-10.0, side * 8.0, 0.0)
		board.material_override = chalkboard_mat
		shell_root.add_child(board)

		var board_frame = MeshInstance3D.new()
		var board_frame_mesh = BoxMesh.new()
		board_frame_mesh.size = Vector3(0.26, 0.68, 0.05)
		board_frame.mesh = board_frame_mesh
		board_frame.position = board.position + Vector3(0.0, 0.0, -front_sign * 0.01)
		board_frame.rotation_degrees = board.rotation_degrees
		board_frame.material_override = chalk_frame_mat
		shell_root.add_child(board_frame)

	for front_rect in [layout.get("front_left_wall", Rect2()), layout.get("front_right_wall", Rect2())]:
		if not (front_rect is Rect2):
			continue
		var seg: Rect2 = front_rect as Rect2
		if seg.size.x < 0.86:
			continue
		var stand_w = clampf(seg.size.x - 0.2, 0.74, 1.28)
		var stand_d = 0.42
		var stand_center_x = seg.position.x + seg.size.x * 0.5
		var stand_center_z = front_door_z + front_sign * 0.72
		var produce_stand_rect = Rect2(
			stand_center_x - stand_w * 0.5,
			stand_center_z - stand_d * 0.5,
			stand_w,
			stand_d
		)
		_add_store_stand(shell_root, produce_stand_rect, produce_frame_mat, produce_top_mat, 0.66)
		_add_bodega_stock_to_fixture(shell_root, produce_stand_rect.grow(-0.03), 0.71, produce_mats, false)

		var planter = MeshInstance3D.new()
		var planter_mesh = BoxMesh.new()
		planter_mesh.size = Vector3(stand_w, 0.24, 0.3)
		planter.mesh = planter_mesh
		planter.position = Vector3(stand_center_x, 0.16, front_door_z + front_sign * 1.02)
		planter.material_override = planter_mat
		shell_root.add_child(planter)
		for flower_index in range(4):
			var flower = MeshInstance3D.new()
			var flower_mesh = SphereMesh.new()
			flower_mesh.radius = 0.075
			flower_mesh.height = 0.15
			flower_mesh.radial_segments = 8
			flower_mesh.rings = 4
			flower.mesh = flower_mesh
			flower.position = planter.position + Vector3(
				lerpf(-stand_w * 0.38, stand_w * 0.38, float(flower_index) / 3.0),
				0.2 + 0.035 * float(flower_index % 2),
				0.0
			)
			flower.material_override = flower_mat
			shell_root.add_child(flower)

	_batch_storefront_visuals(shell_root)
	building["transparent_window_count"] = storefront_window_count + 1 # glazed door
	building["opaque_window_backing_count"] = 0
	building["storefront_contact_shadow_count"] = 2
	building["window_sill_height"] = 0.46
	return building

func _batch_storefront_visuals(shell_root: Node3D) -> void:
	if shell_root == null:
		return
	var groups: Dictionary = {}
	for child in shell_root.get_children():
		if not (child is MeshInstance3D):
			continue
		var mesh_instance = child as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var source_mesh: Mesh = mesh_instance.mesh
		var batch_mesh: Mesh = source_mesh
		var transform = mesh_instance.transform
		var shape_key = _static_prop_mesh_signature(source_mesh, mesh_instance.material_override)
		if source_mesh is BoxMesh:
			var unit_box = BoxMesh.new()
			unit_box.size = Vector3.ONE
			batch_mesh = unit_box
			transform *= Transform3D(Basis().scaled((source_mesh as BoxMesh).size), Vector3.ZERO)
			var material_id = mesh_instance.material_override.get_instance_id() if mesh_instance.material_override != null else 0
			shape_key = "box:%d" % material_id
		elif source_mesh is SphereMesh:
			var unit_sphere = SphereMesh.new()
			unit_sphere.radius = 0.5
			unit_sphere.height = 1.0
			unit_sphere.radial_segments = 10
			unit_sphere.rings = 5
			batch_mesh = unit_sphere
			var sphere = source_mesh as SphereMesh
			transform *= Transform3D(Basis().scaled(Vector3(sphere.radius * 2.0, sphere.height, sphere.radius * 2.0)), Vector3.ZERO)
			var material_id = mesh_instance.material_override.get_instance_id() if mesh_instance.material_override != null else 0
			shape_key = "sphere:%d" % material_id
		var group: Dictionary = groups.get(shape_key, {
			"mesh": batch_mesh,
			"material": mesh_instance.material_override,
			"transforms": []
		})
		var transforms: Array = group.get("transforms", [])
		transforms.append(transform)
		group["transforms"] = transforms
		groups[shape_key] = group
		shell_root.remove_child(mesh_instance)
		mesh_instance.free()

	for shape_key in groups.keys():
		var group: Dictionary = groups[shape_key]
		var transforms: Array = group.get("transforms", [])
		if transforms.is_empty():
			continue
		var multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = group.get("mesh", null)
		multimesh.instance_count = transforms.size()
		for i in range(transforms.size()):
			multimesh.set_instance_transform(i, transforms[i] as Transform3D)
		var instance = MultiMeshInstance3D.new()
		instance.name = "StorefrontVisualGroup"
		instance.multimesh = multimesh
		instance.material_override = group.get("material", null)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shell_root.add_child(instance)

func _clear_store_entry_indicators() -> void:
	for item in store_entry_indicators:
		var n: Node3D = item.get("node", null)
		if n != null and is_instance_valid(n):
			n.queue_free()
	store_entry_indicators.clear()

func _clear_store_shells() -> void:
	for n in store_shell_nodes:
		if n != null and is_instance_valid(n):
			n.queue_free()
	store_shell_nodes.clear()

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
		b["store_reachable_points"] = PackedVector2Array()
		b["store_interior_root"] = null
		buildings[i] = b

func _add_store_wall_box(
	parent: Node3D,
	wall_rect: Rect2,
	material: Material,
	height: float = STORE_INTERIOR_WALL_HEIGHT,
	base_y: float = 0.0
) -> void:
	if wall_rect.size.x <= 0.03 or wall_rect.size.y <= 0.03:
		return
	var wall = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(wall_rect.size.x, height, wall_rect.size.y)
	wall.mesh = mesh
	wall.position = Vector3(
		wall_rect.position.x + wall_rect.size.x * 0.5,
		base_y + height * 0.5,
		wall_rect.position.y + wall_rect.size.y * 0.5
	)
	wall.material_override = material
	parent.add_child(wall)

func _inset_store_visual_rect(rect: Rect2, inset: float) -> Rect2:
	if inset <= 0.0:
		return rect
	var max_inset = minf(rect.size.x, rect.size.y) * 0.45
	var amount = minf(inset, max_inset)
	if amount <= 0.0:
		return rect
	var shrunk = rect.grow(-amount)
	if shrunk.size.x <= 0.03 or shrunk.size.y <= 0.03:
		return rect
	return shrunk

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
		var shell_override: Node3D = b.get("store_shell_root", null)
		var has_override_shell = shell_override != null and is_instance_valid(shell_override)
		var front_is_south = bool(b.get("front_is_south", true))
		var layout: Dictionary = b.get("store_layout", {})
		if not bool(layout.get("valid", false)):
			layout = _compute_store_layout(fp, front_is_south)
		if not bool(layout.get("valid", false)):
			continue
		b["store_layout"] = layout
		var x0 = float(layout.get("x0", fp.position.x + STORE_INTERIOR_MARGIN))
		var x1 = float(layout.get("x1", fp.position.x + fp.size.x - STORE_INTERIOR_MARGIN))
		var z0 = float(layout.get("z0", fp.position.y + STORE_INTERIOR_MARGIN))
		var z1 = float(layout.get("z1", fp.position.y + fp.size.y - STORE_INTERIOR_MARGIN))
		var inner_w = float(layout.get("inner_w", x1 - x0))
		var inner_d = float(layout.get("inner_d", z1 - z0))
		var interior_rect: Rect2 = layout.get(
			"interior_rect",
			Rect2(x0 + STORE_WALL_THICKNESS, z0 + STORE_WALL_THICKNESS, inner_w - STORE_WALL_THICKNESS * 2.0, inner_d - STORE_WALL_THICKNESS * 2.0)
		)
		var entry_inside: Vector2 = layout.get("entry_inside_pos", interior_rect.get_center())

		var interior_root = Node3D.new()
		interior_root.name = "StoreInterior"
		interior_root.visible = true
		static_root.add_child(interior_root)
		store_interior_nodes.append(interior_root)

		var floor = MeshInstance3D.new()
		var floor_mesh = PlaneMesh.new()
		floor_mesh.size = Vector2(inner_w, inner_d)
		floor.mesh = floor_mesh
		floor.position = Vector3(x0 + inner_w * 0.5, 0.032, z0 + inner_d * 0.5)
		floor.material_override = floor_mat
		interior_root.add_child(floor)

		# Keep interiors open-top so Freya remains visible while inside stores.

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

		var wall_t = float(layout.get("wall_t", STORE_WALL_THICKNESS))
		var blockers: Array[Rect2] = []
		var wall_visuals: Array[Rect2] = []
		var produce_fixtures: Array[Rect2] = []
		var meat_fixtures: Array[Rect2] = []
		var wall_blockers: Array[Rect2] = []
		var candidate_fixtures: Array[Dictionary] = []
		for wall_rect in layout.get("wall_blockers", []):
			if wall_rect is Rect2:
				var wr = wall_rect as Rect2
				blockers.append(wr)
				wall_blockers.append(wr)
		for wall_rect in layout.get("wall_visuals", []):
			if wall_rect is Rect2:
				wall_visuals.append(wall_rect as Rect2)

		if inner_d > 3.2:
			var side_depth = inner_d - 1.9
			var fixture_l = Rect2(x0 + wall_t + 0.16, z0 + 0.92, 0.5, side_depth)
			var fixture_r = Rect2(x1 - wall_t - 0.66, z0 + 0.92, 0.5, side_depth)
			if fixture_l.size.y > 1.0:
				candidate_fixtures.append({"rect": fixture_l, "kind": "produce"})
			if fixture_r.size.y > 1.0:
				candidate_fixtures.append({"rect": fixture_r, "kind": "produce"})

		if inner_w > 6.2 and inner_d > 4.0:
			var aisle_depth = clampf(inner_d * 0.44, 1.9, inner_d - 1.2)
			var aisle_z = z0 + (inner_d - aisle_depth) * 0.5
			var aisle_a = Rect2(x0 + inner_w * 0.33 - 0.18, aisle_z, 0.36, aisle_depth)
			var aisle_b = Rect2(x0 + inner_w * 0.67 - 0.18, aisle_z, 0.36, aisle_depth)
			candidate_fixtures.append({"rect": aisle_a, "kind": "produce"})
			candidate_fixtures.append({"rect": aisle_b, "kind": "produce"})

		var meat_counter_w = clampf(inner_w * 0.46, 1.3, inner_w - 1.1)
		var meat_counter_x = x0 + (inner_w - meat_counter_w) * 0.5
		var meat_counter = Rect2(
			meat_counter_x,
			(z0 + wall_t + 0.26) if front_is_south else (z1 - wall_t - 0.74),
			meat_counter_w,
			0.48
		)
		candidate_fixtures.append({"rect": meat_counter, "kind": "meat"})

		if inner_w > 4.2 and inner_d > 3.4:
			var island_w = clampf(inner_w * 0.24, 0.82, 1.5)
			var island_d = clampf(inner_d * 0.2, 0.88, 1.6)
			var island = Rect2(
				x0 + inner_w * 0.5 - island_w * 0.5,
				z0 + inner_d * 0.54 - island_d * 0.5,
				island_w,
				island_d
			)
			candidate_fixtures.append({"rect": island, "kind": "produce"})

		if inner_w > 7.2 and inner_d > 4.2:
			var island2_w = clampf(inner_w * 0.2, 0.76, 1.3)
			var island2_d = clampf(inner_d * 0.16, 0.82, 1.28)
			var island2 = Rect2(
				x0 + inner_w * 0.28 - island2_w * 0.5,
				z0 + inner_d * 0.46 - island2_d * 0.5,
				island2_w,
				island2_d
			)
			candidate_fixtures.append({"rect": island2, "kind": "produce"})

		var layout_pick = _select_store_fixtures_for_access(interior_rect, entry_inside, wall_blockers, candidate_fixtures)
		var selected_fixtures: Array = layout_pick.get("fixtures", [])
		var reachable_points: PackedVector2Array = layout_pick.get("reachable", PackedVector2Array())
		blockers = layout_pick.get("blockers", blockers)
		for item in selected_fixtures:
			if not (item is Dictionary):
				continue
			var fixture_rect: Rect2 = item.get("rect", Rect2())
			if fixture_rect.size.x <= 0.01 or fixture_rect.size.y <= 0.01:
				continue
			var kind = str(item.get("kind", "produce"))
			if kind == "meat":
				meat_fixtures.append(fixture_rect)
			else:
				produce_fixtures.append(fixture_rect)

		for wall_rect in wall_visuals:
			var front_left_window_wall: Rect2 = layout.get("front_left_wall", Rect2())
			var front_right_window_wall: Rect2 = layout.get("front_right_wall", Rect2())
			if has_override_shell and (wall_rect == front_left_window_wall or wall_rect == front_right_window_wall):
				# The exterior shell owns the real glazed opening. A second interior
				# wall here would make transparent glass look opaque from outdoors.
				continue
			var interior_wall_rect = wall_rect
			if has_override_shell:
				# Keep interior and exterior wall visuals aligned but non-coplanar to avoid shimmer.
				interior_wall_rect = _inset_store_visual_rect(interior_wall_rect, 0.03)
			_add_store_wall_box(interior_root, interior_wall_rect, wall_mat, STORE_INTERIOR_WALL_HEIGHT)
			var trim_rect = _inset_store_visual_rect(interior_wall_rect, 0.02)
			if trim_rect.size.x > 0.03 and trim_rect.size.y > 0.03:
				_add_store_wall_box(interior_root, trim_rect, wall_trim_mat, 0.11)
			var lower_band_rect = _inset_store_visual_rect(interior_wall_rect, 0.01)
			var upper_band_rect = _inset_store_visual_rect(interior_wall_rect, 0.014)
			_add_store_wall_band(interior_root, lower_band_rect, wall_band_mat, 0.58, 0.08)
			_add_store_wall_band(interior_root, upper_band_rect, wall_trim_mat, 1.74, 0.06)

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
		b["store_interior_rect"] = interior_rect
		b["store_reachable_points"] = reachable_points
		b["entry_pos"] = layout.get("entry_inside_pos", b.get("entry_pos", Vector2(-1.0, -1.0)))
		b["store_interior_root"] = interior_root
		b["store_scale_metrics"] = {
			"door_width": float(layout.get("door_half", STORE_DOOR_HALF_WIDTH)) * 2.0,
			"wall_height": STORE_INTERIOR_WALL_HEIGHT,
			"window_sill_height": float(b.get("window_sill_height", 0.46)),
			"minimum_aisle_width": FREYA_COLLISION_RADIUS * 2.0 + 0.12,
			"fixture_top_min": 0.88,
			"fixture_top_max": 1.06
		}
		buildings[idx] = b

func _select_store_fixtures_for_access(
	interior_rect: Rect2,
	entry_inside: Vector2,
	wall_blockers: Array[Rect2],
	candidates: Array[Dictionary]
) -> Dictionary:
	var selected: Array[Dictionary] = []
	for item in candidates:
		if not (item is Dictionary):
			continue
		var rect: Rect2 = item.get("rect", Rect2())
		if rect.size.x <= 0.03 or rect.size.y <= 0.03:
			continue
		selected.append(item)

	var blockers: Array = wall_blockers.duplicate()
	for item in selected:
		var rect: Rect2 = item.get("rect", Rect2())
		if rect.size.x > 0.03 and rect.size.y > 0.03:
			blockers.append(rect)

	var base_reachable = _store_reachable_points(interior_rect, entry_inside, wall_blockers)
	var min_reachable = maxi(10, int(floor(float(base_reachable.size()) * 0.55)))
	var reachable = _store_reachable_points(interior_rect, entry_inside, blockers)
	var guard = 0
	while reachable.size() < min_reachable and not selected.is_empty() and guard < 10:
		guard += 1
		var best_idx = -1
		var best_count = reachable.size()
		for i in range(selected.size()):
			var test_blockers: Array = wall_blockers.duplicate()
			for j in range(selected.size()):
				if j == i:
					continue
				var test_rect: Rect2 = selected[j].get("rect", Rect2())
				if test_rect.size.x > 0.03 and test_rect.size.y > 0.03:
					test_blockers.append(test_rect)
			var test_count = _store_reachable_points(interior_rect, entry_inside, test_blockers).size()
			if test_count > best_count:
				best_count = test_count
				best_idx = i
		if best_idx < 0:
			selected.remove_at(selected.size() - 1)
		else:
			selected.remove_at(best_idx)

		blockers = wall_blockers.duplicate()
		for item in selected:
			var rect: Rect2 = item.get("rect", Rect2())
			if rect.size.x > 0.03 and rect.size.y > 0.03:
				blockers.append(rect)
		reachable = _store_reachable_points(interior_rect, entry_inside, blockers)

	return {
		"fixtures": selected,
		"reachable": reachable,
		"blockers": blockers
	}

func _store_reachable_points(
	interior_rect: Rect2,
	entry_inside: Vector2,
	blockers: Array,
	cell_size: float = 0.34
) -> PackedVector2Array:
	var reachable = PackedVector2Array()
	if interior_rect.size.x <= 0.12 or interior_rect.size.y <= 0.12:
		return reachable

	var cols = maxi(3, int(ceil(interior_rect.size.x / maxf(0.18, cell_size))))
	var rows = maxi(3, int(ceil(interior_rect.size.y / maxf(0.18, cell_size))))
	var total = cols * rows
	if total <= 0:
		return reachable
	var step_x = interior_rect.size.x / float(cols)
	var step_y = interior_rect.size.y / float(rows)

	var centers: Array[Vector2] = []
	centers.resize(total)
	var walkable = PackedByteArray()
	walkable.resize(total)
	walkable.fill(0)
	var visited = PackedByteArray()
	visited.resize(total)
	visited.fill(0)

	var walkable_count = 0
	var inner_rect = interior_rect.grow(-0.03)
	for row in range(rows):
		for col in range(cols):
			var idx = row * cols + col
			var center = Vector2(
				interior_rect.position.x + (float(col) + 0.5) * step_x,
				interior_rect.position.y + (float(row) + 0.5) * step_y
			)
			centers[idx] = center
			if not inner_rect.has_point(center):
				continue
			if _point_in_rect_list(blockers, center, 0.09):
				continue
			walkable[idx] = 1
			walkable_count += 1

	if walkable_count <= 0:
		return reachable

	var start_idx = -1
	var nearest_dist = 1000000000.0
	for idx in range(total):
		if walkable[idx] == 0:
			continue
		var d = centers[idx].distance_squared_to(entry_inside)
		if d < nearest_dist:
			nearest_dist = d
			start_idx = idx
	if start_idx < 0:
		return reachable

	var queue: Array[int] = [start_idx]
	visited[start_idx] = 1
	var read_idx = 0
	while read_idx < queue.size():
		var current = queue[read_idx]
		read_idx += 1
		reachable.append(centers[current])

		var row = int(current / cols)
		var col = int(current - row * cols)
		var neighbor_indices = [
			Vector2i(col + 1, row),
			Vector2i(col - 1, row),
			Vector2i(col, row + 1),
			Vector2i(col, row - 1)
		]
		for coord in neighbor_indices:
			if coord.x < 0 or coord.x >= cols or coord.y < 0 or coord.y >= rows:
				continue
			var next_idx = coord.y * cols + coord.x
			if visited[next_idx] != 0 or walkable[next_idx] == 0:
				continue
			visited[next_idx] = 1
			queue.append(next_idx)
	return reachable

func _rebuild_walkability_cache() -> void:
	blocking_building_rects.clear()
	blocking_building_grid.clear()
	store_walk_blockers.clear()
	for b in buildings:
		var rect: Rect2 = b.get("collision_rect", b["footprint"])
		if not bool(b.get("enterable", false)):
			blocking_building_rects.append(rect)
			var min_cell = Vector2i(
				int(floor(rect.position.x / COLLISION_GRID_SIZE)),
				int(floor(rect.position.y / COLLISION_GRID_SIZE))
			)
			var rect_end = rect.position + rect.size
			var max_cell = Vector2i(
				int(floor(rect_end.x / COLLISION_GRID_SIZE)),
				int(floor(rect_end.y / COLLISION_GRID_SIZE))
			)
			for cell_x in range(min_cell.x, max_cell.x + 1):
				for cell_y in range(min_cell.y, max_cell.y + 1):
					var key = Vector2i(cell_x, cell_y)
					var cell_rects: Array = blocking_building_grid.get(key, [])
					cell_rects.append(rect)
					blocking_building_grid[key] = cell_rects
		var blockers = b.get("store_walk_blockers", [])
		if blockers is Array:
			for wall in blockers:
				if wall is Rect2:
					store_walk_blockers.append(wall)

func _rebuild_static_obstacle_grid() -> void:
	static_obstacle_grid.clear()
	_append_static_obstacles_to_grid(trees, TREE_COLLISION_SCALE, "tree")
	_append_static_obstacles_to_grid(dumpsters, DUMPSTER_COLLISION_RADIUS, "dumpster")
	_append_static_obstacles_to_grid(street_poles, STREET_POLE_COLLISION_RADIUS, "pole")
	_append_static_obstacles_to_grid(fire_hydrants, FIRE_HYDRANT_COLLISION_RADIUS, "hydrant")

func _append_static_obstacles_to_grid(items: Array, fallback_radius: float, kind: String) -> void:
	for item in items:
		if not (item is Dictionary):
			continue
		var entry: Dictionary = item
		var center: Vector2 = entry.get("pos", Vector2.ZERO)
		var cell = Vector2i(
			int(floor(center.x / STATIC_OBSTACLE_GRID_SIZE)),
			int(floor(center.y / STATIC_OBSTACLE_GRID_SIZE))
		)
		var cell_items: Array = static_obstacle_grid.get(cell, [])
		cell_items.append({
			"pos": center,
			"radius": float(entry.get("radius", fallback_radius)),
			"kind": kind
		})
		static_obstacle_grid[cell] = cell_items

func _point_in_static_obstacle(p: Vector2, mover_radius: float) -> bool:
	var center_cell = Vector2i(
		int(floor(p.x / STATIC_OBSTACLE_GRID_SIZE)),
		int(floor(p.y / STATIC_OBSTACLE_GRID_SIZE))
	)
	for cell_x in range(center_cell.x - 1, center_cell.x + 2):
		for cell_y in range(center_cell.y - 1, center_cell.y + 2):
			var obstacles: Array = static_obstacle_grid.get(Vector2i(cell_x, cell_y), [])
			for obstacle in obstacles:
				if not (obstacle is Dictionary):
					continue
				var data: Dictionary = obstacle
				var kind = str(data.get("kind", ""))
				var extra_radius = mover_radius
				if kind == "tree":
					extra_radius = maxf(0.2, mover_radius * 0.95)
				elif kind == "dumpster":
					extra_radius = maxf(0.08, mover_radius * 0.9)
				elif kind == "pole" or kind == "hydrant":
					extra_radius = maxf(0.04, mover_radius * 0.45)
				var center: Vector2 = data.get("pos", Vector2.ZERO)
				var radius = float(data.get("radius", 0.0)) + extra_radius
				var dx = center.x - p.x
				if absf(dx) > radius:
					continue
				var dz = center.y - p.y
				if absf(dz) > radius:
					continue
				if dx * dx + dz * dz <= radius * radius:
					return true
	return false

func _create_store_entry_indicator(building: Dictionary) -> Dictionary:
	var fp: Rect2 = building.get("footprint", Rect2())
	if fp.size.x <= 0.0 or fp.size.y <= 0.0:
		return building

	var front_is_south = bool(building.get("front_is_south", true))
	var layout: Dictionary = building.get("store_layout", {})
	if not bool(layout.get("valid", false)):
		layout = _compute_store_layout(fp, front_is_south)
	if not bool(layout.get("valid", false)):
		return building
	building["store_layout"] = layout
	var front_sign = float(layout.get("front_sign", 1.0 if front_is_south else -1.0))
	var entry_outside: Vector2 = layout.get(
		"entry_outside_pos",
		Vector2(fp.position.x + fp.size.x * 0.5, fp.position.y + (fp.size.y if front_is_south else 0.0))
	)

	var marker = Node3D.new()
	marker.name = "StoreEntryMarker"
	var base_world = Vector3(entry_outside.x, 0.055, entry_outside.y)
	marker.position = base_world
	if static_root != null:
		static_root.add_child(marker)
	elif world_root != null:
		world_root.add_child(marker)
	else:
		add_child(marker)

	var plate_mat = StandardMaterial3D.new()
	plate_mat.albedo_color = Color(0.98, 0.9, 0.44, 0.6)
	plate_mat.roughness = 0.38
	plate_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plate_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	plate_mat.emission_enabled = true
	plate_mat.emission = Color(0.96, 0.82, 0.28)
	plate_mat.emission_energy_multiplier = 0.36

	var arrow_mat = StandardMaterial3D.new()
	arrow_mat.albedo_color = Color(1.0, 0.95, 0.72, 0.92)
	arrow_mat.roughness = 0.26
	arrow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arrow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	arrow_mat.emission_enabled = true
	arrow_mat.emission = Color(1.0, 0.9, 0.58)
	arrow_mat.emission_energy_multiplier = 0.62

	var base_plate = MeshInstance3D.new()
	var base_plate_mesh = CylinderMesh.new()
	base_plate_mesh.top_radius = 0.2
	base_plate_mesh.bottom_radius = 0.22
	base_plate_mesh.height = 0.012
	base_plate.mesh = base_plate_mesh
	base_plate.position = Vector3(0.0, -0.01, 0.0)
	base_plate.material_override = plate_mat
	base_plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.add_child(base_plate)

	var inward = -front_sign
	var base_rot = 0.0 if inward > 0.0 else 180.0
	var shaft = MeshInstance3D.new()
	var shaft_mesh = BoxMesh.new()
	shaft_mesh.size = Vector3(0.04, 0.018, 0.15)
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0.0, 0.002, inward * 0.025)
	shaft.rotation_degrees.y = base_rot
	shaft.material_override = arrow_mat
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.add_child(shaft)

	for side in [-1.0, 1.0]:
		var wing = MeshInstance3D.new()
		var wing_mesh = BoxMesh.new()
		wing_mesh.size = Vector3(0.034, 0.018, 0.14)
		wing.mesh = wing_mesh
		wing.position = Vector3(side * 0.045, 0.002, inward * 0.095)
		wing.rotation_degrees.y = base_rot + side * 44.0
		wing.material_override = arrow_mat
		wing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		marker.add_child(wing)

	building["entry_pos"] = layout.get("entry_inside_pos", building.get("entry_pos", Vector2(-1.0, -1.0)))
	store_entry_indicators.append({
		"node": marker,
		"base": base_world,
		"front_sign": front_sign,
		"phase": rng.randf_range(0.0, TAU)
	})
	return building

func _populate_store_foods() -> void:
	for item in store_foods:
		var n: Node3D = item.get("node", null)
		if n != null and is_instance_valid(n):
			n.queue_free()
	store_foods.clear()

	for building_idx in range(buildings.size()):
		var b: Dictionary = buildings[building_idx]
		if not bool(b.get("is_store", false)):
			continue
		var count = int(b.get("store_food_slots", 3))
		for i in range(count):
			_spawn_store_food_in_building(b, building_idx)

func _spawn_store_food_in_building(building: Dictionary, building_idx: int = -1) -> bool:
	var fp: Rect2 = building.get("footprint", Rect2())
	if fp.size.x < 1.6 or fp.size.y < 1.6:
		return false
	var interior_rect: Rect2 = building.get("store_interior_rect", fp.grow(-0.42))
	if interior_rect.size.x < 0.8 or interior_rect.size.y < 0.8:
		interior_rect = fp.grow(-0.42)

	var reachable_points: PackedVector2Array = building.get("store_reachable_points", PackedVector2Array())
	if reachable_points.is_empty():
		var entry_inside: Vector2 = building.get("entry_pos", interior_rect.get_center())
		var blockers = building.get("store_walk_blockers", [])
		if blockers is Array:
			reachable_points = _store_reachable_points(interior_rect, entry_inside, blockers)
	for attempt in range(42):
		var p = Vector2.ZERO
		if not reachable_points.is_empty():
			var base = reachable_points[rng.randi_range(0, reachable_points.size() - 1)]
			p = base + Vector2(rng.randf_range(-0.08, 0.08), rng.randf_range(-0.08, 0.08))
			p.x = clampf(p.x, interior_rect.position.x + 0.08, interior_rect.position.x + interior_rect.size.x - 0.08)
			p.y = clampf(p.y, interior_rect.position.y + 0.08, interior_rect.position.y + interior_rect.size.y - 0.08)
		else:
			p = Vector2(
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
		node.visible = building_idx >= 0 and building_idx == active_store_index
		store_foods.append({"node": node, "pos": p, "store_index": building_idx})
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
						"claimed_by": CLAIM_OWNER_NONE,
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
						"claimed_by": CLAIM_OWNER_NONE,
						"claim_progress": 0.0,
						"claim_ring": null
					})
				z += STREET_POLE_SPACING
	_batch_static_prop_visuals(street_poles, "BatchedStreetPoles")

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
							"claimed_by": CLAIM_OWNER_NONE,
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
							"claimed_by": CLAIM_OWNER_NONE,
							"claim_progress": 0.0,
							"claim_ring": null
						})
				z += FIRE_HYDRANT_SPACING
	_batch_static_prop_visuals(fire_hydrants, "BatchedFireHydrants")

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
	base_mesh.radial_segments = 8
	base.mesh = base_mesh
	base.position = Vector3(0.0, 0.08, 0.0)
	base.material_override = fire_hydrant_body_material
	root.add_child(base)

	var body = MeshInstance3D.new()
	var body_mesh = CylinderMesh.new()
	body_mesh.top_radius = 0.11
	body_mesh.bottom_radius = 0.13
	body_mesh.height = 0.52
	body_mesh.radial_segments = 8
	body.mesh = body_mesh
	body.position = Vector3(0.0, 0.36, 0.0)
	body.material_override = fire_hydrant_body_material
	root.add_child(body)

	var dome = MeshInstance3D.new()
	var dome_mesh = SphereMesh.new()
	dome_mesh.radius = 0.13
	dome_mesh.height = 0.26
	dome_mesh.radial_segments = 8
	dome_mesh.rings = 4
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
		arm_mesh.radial_segments = 8
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
	if _point_in_facade_clearance(p, 0.38):
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
	glass_mesh.radial_segments = 8
	glass_mesh.rings = 4
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
	_batch_static_prop_visuals(dumpsters, "BatchedDumpsters")

func _batch_static_prop_visuals(items: Array, batch_name: String) -> void:
	if static_root == null or items.is_empty():
		return
	var previous = static_root.get_node_or_null(batch_name)
	if previous != null:
		previous.queue_free()
	var groups: Dictionary = {}
	var static_inverse = static_root.global_transform.affine_inverse()
	for item in items:
		if not (item is Dictionary):
			continue
		var root: Node3D = (item as Dictionary).get("node", null)
		if root == null or not is_instance_valid(root):
			continue
		for child in root.get_children():
			if not (child is MeshInstance3D):
				continue
			var mesh_instance = child as MeshInstance3D
			if mesh_instance.mesh == null:
				continue
			var local_transform = static_inverse * mesh_instance.global_transform
			var cell = Vector2i(
				int(floor(local_transform.origin.x / 56.0)),
				int(floor(local_transform.origin.z / 56.0))
			)
			var signature = "%d:%d:%s" % [
				cell.x,
				cell.y,
				_static_prop_mesh_signature(mesh_instance.mesh, mesh_instance.material_override)
			]
			var group: Dictionary = groups.get(signature, {
				"mesh": mesh_instance.mesh,
				"material": mesh_instance.material_override,
				"transforms": []
			})
			var transforms: Array = group.get("transforms", [])
			transforms.append(local_transform)
			group["transforms"] = transforms
			groups[signature] = group
			root.remove_child(mesh_instance)
			mesh_instance.free()

	var batch_root = Node3D.new()
	batch_root.name = batch_name
	static_root.add_child(batch_root)
	for signature in groups.keys():
		var group: Dictionary = groups[signature]
		var transforms: Array = group.get("transforms", [])
		if transforms.is_empty():
			continue
		var multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = group.get("mesh", null)
		multimesh.instance_count = transforms.size()
		for i in range(transforms.size()):
			multimesh.set_instance_transform(i, transforms[i] as Transform3D)
		var instance = MultiMeshInstance3D.new()
		instance.name = "%sGroup" % batch_name
		instance.multimesh = multimesh
		instance.material_override = group.get("material", null)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		batch_root.add_child(instance)

func _static_prop_mesh_signature(mesh: Mesh, material: Material) -> String:
	var material_id = material.get_instance_id() if material != null else 0
	if mesh is BoxMesh:
		var size = (mesh as BoxMesh).size
		return "box:%.4f:%.4f:%.4f:%d" % [size.x, size.y, size.z, material_id]
	if mesh is CylinderMesh:
		var cylinder = mesh as CylinderMesh
		return "cylinder:%.4f:%.4f:%.4f:%d" % [cylinder.top_radius, cylinder.bottom_radius, cylinder.height, material_id]
	if mesh is SphereMesh:
		var sphere = mesh as SphereMesh
		return "sphere:%.4f:%.4f:%d" % [sphere.radius, sphere.height, material_id]
	return "%s:%d:%d" % [mesh.get_class(), mesh.get_instance_id(), material_id]

func _batch_neighborhood_building_details() -> void:
	var groups: Dictionary = {}
	var unit_box = BoxMesh.new()
	unit_box.size = Vector3.ONE
	for building_idx in range(buildings.size()):
		var building: Dictionary = buildings[building_idx]
		if bool(building.get("is_store", false)) or bool(building.get("is_freya_home", false)) or str(building.get("model_source", "")) != "procedural":
			continue
		var root: Node3D = building.get("node", null)
		if root == null or not is_instance_valid(root):
			continue
		var roof_parts: Array = building.get("roof_parts", [])
		for child in root.get_children():
			if not (child is GeometryInstance3D) or roof_parts.has(child):
				continue
			var geometry = child as GeometryInstance3D
			var material: Material = geometry.material_override
			var material_id = material.get_instance_id() if material != null else 0
			if child is MeshInstance3D:
				var mesh_instance = child as MeshInstance3D
				if not (mesh_instance.mesh is BoxMesh):
					continue
				var box_size = (mesh_instance.mesh as BoxMesh).size
				var world_transform = root.transform * mesh_instance.transform * Transform3D(Basis().scaled(box_size), Vector3.ZERO)
				_append_building_detail_batch(groups, world_transform, material, material_id)
				root.remove_child(mesh_instance)
				mesh_instance.free()
			elif child is MultiMeshInstance3D:
				var multi_instance = child as MultiMeshInstance3D
				if multi_instance.multimesh == null or not (multi_instance.multimesh.mesh is BoxMesh):
					continue
				var box_size = (multi_instance.multimesh.mesh as BoxMesh).size
				for instance_idx in range(multi_instance.multimesh.instance_count):
					var world_transform = (
						root.transform
						* multi_instance.transform
						* multi_instance.multimesh.get_instance_transform(instance_idx)
						* Transform3D(Basis().scaled(box_size), Vector3.ZERO)
					)
					_append_building_detail_batch(groups, world_transform, material, material_id)
				root.remove_child(multi_instance)
				multi_instance.free()
		building["batched_details"] = true
		buildings[building_idx] = building

	var batch_root = Node3D.new()
	batch_root.name = "BatchedNeighborhoodDetails"
	static_root.add_child(batch_root)
	for signature in groups.keys():
		var group: Dictionary = groups[signature]
		var transforms: Array = group.get("transforms", [])
		if transforms.is_empty():
			continue
		var multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = unit_box
		multimesh.instance_count = transforms.size()
		for i in range(transforms.size()):
			multimesh.set_instance_transform(i, transforms[i] as Transform3D)
		var instance = MultiMeshInstance3D.new()
		instance.name = "NeighborhoodDetailGroup"
		instance.multimesh = multimesh
		instance.material_override = group.get("material", null)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		batch_root.add_child(instance)

func _append_building_detail_batch(
	groups: Dictionary,
	world_transform: Transform3D,
	material: Material,
	material_id: int
) -> void:
	var cell = Vector2i(
		int(floor(world_transform.origin.x / 56.0)),
		int(floor(world_transform.origin.z / 56.0))
	)
	var signature = "%d:%d:%d" % [cell.x, cell.y, material_id]
	var group: Dictionary = groups.get(signature, {"material": material, "transforms": []})
	var transforms: Array = group.get("transforms", [])
	transforms.append(world_transform)
	group["transforms"] = transforms
	groups[signature] = group

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
	var roll = rng.randf()
	if roll < 0.58:
		return 1
	if roll < 0.94:
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
	created["is_freya_home"] = false
	created["enterable"] = false
	created["store_food_slots"] = 0
	created["store_walk_blockers"] = []
	created["store_interior_rect"] = Rect2()
	created["store_interior_root"] = null
	created["alien_occupied"] = false
	created["alien_integrity"] = 0.0
	created["alien_visual_root"] = null
	created["alien_occupant_serial"] = -1
	created["alien_occupant_count"] = 0
	created["alien_pee_exposure"] = 0.0
	created["alien_reinforcement_sources"] = 0
	created["alien_reinforcement_strength"] = 0.0
	created["alien_spawn_cooldown"] = rng.randf_range(FREE_ALIEN_SPAWN_MIN_SEC, FREE_ALIEN_SPAWN_MAX_SEC)
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
	if _point_in_facade_clearance(p, 1.15):
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
		"scale": tree_scale,
		"radius": TREE_COLLISION_SCALE * tree_scale,
		"height": 3.65 * tree_scale,
		"claimed": false,
		"claimed_by": CLAIM_OWNER_NONE,
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
	TreeFactoryScript.create_forest_visuals(trees, static_root)

func _build_grass_spikes() -> void:
	var blade_mesh = BoxMesh.new()
	blade_mesh.size = Vector3(0.03, 0.36, 0.03)

	var blade_mat = StandardMaterial3D.new()
	blade_mat.vertex_color_use_as_albedo = true
	blade_mat.roughness = 0.95
	blade_mat.metallic = 0.0
	blade_mat.cull_mode = StandardMaterial3D.CULL_DISABLED

	var points: Array = []
	for i in range(3600):
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
		if points.size() >= 1500:
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
	body_mesh.radial_segments = 6
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
	branch_mesh.radial_segments = 6
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
	if npc_model_paths.is_empty() and _model_has_walk_animation(FREYA_PRIMARY_MODEL):
		npc_model_paths = [FREYA_PRIMARY_MODEL]
	var breed_model_cache := {}
	for breed_id in NPC_BREED_SEQUENCE:
		breed_model_cache[breed_id] = _resolve_breed_model_path(breed_id, npc_model_paths)

	freya = DogAgentScript.new()
	freya.configure({
		"is_freya": true,
		"coat_color": Color(0.07, 0.07, 0.07),
		"speed": FREYA_BASE_SPEED,
		"scene_path": freya_model,
		"model_scale": 1.0,
		"target_length": FREYA_MODEL_TARGET_LENGTH,
		"target_height": FREYA_MODEL_TARGET_HEIGHT
	})
	freya.position = _freya_spawn_point_near_dog_park()
	dynamic_root.add_child(freya)

	dogs.clear()
	alien_transfers.clear()
	free_aliens.clear()
	alien_transfer_serial = 0
	alien_expulsion_count = 0
	alien_building_occupation_count = 0
	ryah_alien_defense_count = 0
	var total_dogs = NPC_DOG_COUNT
	var park_dogs = mini(DOG_PARK_NPC_COUNT, total_dogs)
	var city_dogs = max(0, total_dogs - park_dogs)
	var city_points = _spawn_points_even(city_dogs, "sidewalk")
	var park_points = _spawn_points_in_rect(dog_park.grow(-0.45), park_dogs, "grass")
	# Possession is sampled separately from every cosmetic decision. Exactly 75%
	# of NPC dogs are selected at random, but nothing on the dog model receives
	# this state; Freya's behavior is the player's only clue before expulsion.
	var possession_rng = RandomNumberGenerator.new()
	possession_rng.seed = int(rng.randi()) ^ 0x6A09E667
	var shuffled_indices: Array[int] = []
	for dog_index in range(total_dogs):
		shuffled_indices.append(dog_index)
	for shuffle_index in range(shuffled_indices.size() - 1, 0, -1):
		var swap_index = possession_rng.randi_range(0, shuffle_index)
		var held = shuffled_indices[shuffle_index]
		shuffled_indices[shuffle_index] = shuffled_indices[swap_index]
		shuffled_indices[swap_index] = held
	var possessed_indices := {}
	var possessed_target_count = clampi(int(round(float(total_dogs) * ALIEN_POSSESSION_CHANCE)), 0, total_dogs)
	for selected_index in range(possessed_target_count):
		possessed_indices[shuffled_indices[selected_index]] = true

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
		var identity = _resolve_breed_identity(i, zone_idx, in_park)
		var primary_breed = str(identity.get("primary", "mixed"))
		var secondary_breed = str(identity.get("secondary", ""))
		var is_mix = bool(identity.get("is_mixed", false))
		var primary_ratio = clampf(float(identity.get("primary_ratio", 1.0)), 0.0, 1.0)
		var primary_def = _breed_definition(primary_breed)
		var secondary_def = _breed_definition(secondary_breed if is_mix else primary_breed)

		var dog_model = str(breed_model_cache.get(primary_breed, ""))
		var secondary_model = str(breed_model_cache.get(secondary_breed, ""))
		if is_mix and not secondary_model.is_empty() and cosmetic_rng.randf() > primary_ratio:
			dog_model = secondary_model
		if dog_model.is_empty() and npc_model_paths.size() > 0:
			dog_model = str(npc_model_paths[posmod(i + zone_idx + (1 if in_park else 0), npc_model_paths.size())])

		var coat_palette: Array = []
		for c in primary_def.get("coat_palette", []):
			coat_palette.append(c)
		if is_mix:
			for c in secondary_def.get("coat_palette", []):
				coat_palette.append(c)
		# The dog-park roster uses each breed's canonical first swatch so its
		# deliberately varied lineup stays readable; city dogs rotate the full
		# palette for individual variety.
		var coat_seed = 0 if in_park else i * 5 + zone_idx * 2
		var coat = _color_from_palette(
			coat_palette,
			coat_seed,
			Color8(126, 108, 92)
		)

		var speed_primary: Vector2 = primary_def.get("speed_range", Vector2(1.7, 2.6))
		var speed_secondary: Vector2 = secondary_def.get("speed_range", speed_primary)
		var speed_min = lerpf(speed_secondary.x, speed_primary.x, primary_ratio)
		var speed_max = lerpf(speed_secondary.y, speed_primary.y, primary_ratio)
		if speed_max < speed_min + 0.05:
			speed_max = speed_min + 0.05
		var dog_speed = cosmetic_rng.randf_range(speed_min, speed_max)

		var scale_primary = float(primary_def.get("base_scale", 1.0))
		var scale_secondary = float(secondary_def.get("base_scale", scale_primary))
		var jitter_primary = float(primary_def.get("scale_jitter", 0.1))
		var jitter_secondary = float(secondary_def.get("scale_jitter", jitter_primary))
		var base_scale = lerpf(scale_secondary, scale_primary, primary_ratio)
		var scale_jitter = lerpf(jitter_secondary, jitter_primary, primary_ratio)
		var size_mult = base_scale * cosmetic_rng.randf_range(maxf(0.88, 1.0 - scale_jitter), 1.0 + scale_jitter * 0.6)
		var length_mult_primary = float(primary_def.get("target_length_mult", 1.0))
		var length_mult_secondary = float(secondary_def.get("target_length_mult", length_mult_primary))
		var height_mult_primary = float(primary_def.get("target_height_mult", 1.0))
		var height_mult_secondary = float(secondary_def.get("target_height_mult", height_mult_primary))
		var target_length = FREYA_MODEL_TARGET_LENGTH * lerpf(length_mult_secondary, length_mult_primary, primary_ratio) * size_mult
		var target_height = FREYA_MODEL_TARGET_HEIGHT * lerpf(height_mult_secondary, height_mult_primary, primary_ratio) * size_mult
		target_length = clampf(target_length, FREYA_MODEL_TARGET_LENGTH * 0.62, FREYA_MODEL_TARGET_LENGTH * 1.34)
		target_height = clampf(target_height, FREYA_MODEL_TARGET_HEIGHT * 0.54, FREYA_MODEL_TARGET_HEIGHT * 1.22)
		var model_scale = _npc_model_scale_for_path(dog_model)

		var breed_profile = str(primary_def.get("breed_profile", "mixed"))
		if is_mix and cosmetic_rng.randf() > primary_ratio:
			breed_profile = str(secondary_def.get("breed_profile", breed_profile))
		dog.configure({
			"is_freya": false,
			"coat_color": coat,
			"speed": dog_speed,
			"scene_path": dog_model,
			"model_scale": model_scale,
			"target_length": target_length,
			"target_height": target_height,
			"breed_profile": breed_profile,
			"breed_id": primary_breed,
			"breed_mix": {
				"primary": primary_breed,
				"secondary": secondary_breed,
				"primary_ratio": primary_ratio
			},
			"variant_seed": int(cosmetic_rng.randi())
		})
		dog.scale = Vector3.ONE
		dynamic_root.add_child(dog)
		var pref_surface = _pick_dog_pref_surface(in_park)
		var starts_possessed = possessed_indices.has(i)
		dogs.append({
			"node": dog,
			"dir": _random_dir(),
			"speed": dog_speed,
			"wander": rng.randf_range(0.6, 2.0),
			"bark": rng.randf_range(0.4, 1.2),
			"park": in_park,
			"pref_surface": pref_surface,
			"pref_timer": rng.randf_range(1.2, 3.6),
			"breed_id": primary_breed,
			"breed_profile": breed_profile,
			"model_path": dog_model,
			"visual_style": dog.visual_style_signature() if dog.has_method("visual_style_signature") else "unknown",
			"shape_signature": dog.breed_shape_signature() if dog.has_method("breed_shape_signature") else "unknown",
			"coat_signature": coat.to_html(false),
			"army_aligned": false,
			"socialization_progress": 0.0,
			"flee_timer": 0.0,
			"flee_direction": Vector3.ZERO,
			"alien_possessed": starts_possessed,
			"alien_origin_possessed": starts_possessed,
			"alien_expelled": false,
			"exorcism_progress": 0.0,
			"exorcism_latched": false,
			"alien_transfer_serial": -1,
			"appearance_signature": dog.cosmetic_signature() if dog.has_method("cosmetic_signature") else "unknown"
		})

func _breed_definition(breed_id: String) -> Dictionary:
	var key = breed_id.to_lower()
	if DOG_BREED_DEFINITIONS.has(key):
		return DOG_BREED_DEFINITIONS[key]
	return DOG_BREED_DEFINITIONS["mixed"]

func _non_mixed_breed_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in NPC_BREED_SEQUENCE:
		if id == "mixed":
			continue
		if DOG_BREED_DEFINITIONS.has(id):
			ids.append(id)
	return ids

func _breed_definition_issues() -> Array[String]:
	var issues: Array[String] = []
	var required_keys = [
		"display_name",
		"breed_profile",
		"model_candidates",
		"coat_palette",
		"speed_range",
		"base_scale",
		"scale_jitter",
		"target_length_mult",
		"target_height_mult",
		"mixable"
	]
	for breed_id in DOG_BREED_DEFINITIONS.keys():
		var def: Dictionary = DOG_BREED_DEFINITIONS[breed_id]
		for k in required_keys:
			if not def.has(k):
				issues.append("breed_%s_missing_%s" % [breed_id, str(k)])
		var model_candidates = def.get("model_candidates", [])
		if not (model_candidates is Array) or (model_candidates as Array).is_empty():
			issues.append("breed_%s_missing_model_candidates" % breed_id)
		var coat_palette = def.get("coat_palette", [])
		if not (coat_palette is Array) or (coat_palette as Array).is_empty():
			issues.append("breed_%s_missing_coat_palette" % breed_id)
		var speed_range = def.get("speed_range", Vector2(0.0, 0.0))
		if not (speed_range is Vector2) or speed_range.x <= 0.0 or speed_range.y <= speed_range.x:
			issues.append("breed_%s_invalid_speed_range" % breed_id)
		var tl = float(def.get("target_length_mult", 0.0))
		var th = float(def.get("target_height_mult", 0.0))
		if tl <= 0.0 or th <= 0.0:
			issues.append("breed_%s_invalid_target_dimensions" % breed_id)

	for seq_id in NPC_BREED_SEQUENCE:
		if not DOG_BREED_DEFINITIONS.has(seq_id):
			issues.append("npc_breed_sequence_unknown_%s" % seq_id)
	for park_id in DOG_PARK_BREED_SEQUENCE:
		if not DOG_BREED_DEFINITIONS.has(park_id):
			issues.append("dog_park_breed_sequence_unknown_%s" % park_id)

	var mixed_def: Dictionary = DOG_BREED_DEFINITIONS.get("mixed", {})
	var mix_components = mixed_def.get("mix_components", [])
	if not (mix_components is Array) or (mix_components as Array).is_empty():
		issues.append("mixed_missing_mix_components")
	else:
		for component in mix_components:
			var cid = str(component)
			if not DOG_BREED_DEFINITIONS.has(cid):
				issues.append("mixed_component_unknown_%s" % cid)
				continue
			if cid == "mixed":
				issues.append("mixed_component_cannot_reference_mixed")
			elif not bool(DOG_BREED_DEFINITIONS[cid].get("mixable", false)):
				issues.append("mixed_component_not_mixable_%s" % cid)
	return issues

func _resolve_breed_identity(index: int, zone_idx: int, in_park: bool) -> Dictionary:
	var base_breed = DOG_PARK_BREED_SEQUENCE[posmod(index, DOG_PARK_BREED_SEQUENCE.size())] if in_park else NPC_BREED_SEQUENCE[posmod(index + zone_idx * 3, NPC_BREED_SEQUENCE.size())]
	if base_breed != "mixed":
		return {
			"primary": base_breed,
			"secondary": "",
			"primary_ratio": 1.0,
			"is_mixed": false
		}

	var mix_pool: Array[String] = _non_mixed_breed_ids()
	if mix_pool.is_empty():
		return {
			"primary": "mixed",
			"secondary": "",
			"primary_ratio": 1.0,
			"is_mixed": false
		}

	var primary_idx = posmod(index * 2 + zone_idx + (5 if in_park else 0), mix_pool.size())
	var secondary_idx = posmod(index * 3 + zone_idx * 2 + (3 if in_park else 1), mix_pool.size())
	if secondary_idx == primary_idx and mix_pool.size() > 1:
		secondary_idx = (secondary_idx + 1) % mix_pool.size()
	var blend_phase = float(posmod(index * 37 + zone_idx * 11 + (9 if in_park else 0), 100)) / 99.0
	var primary_ratio = lerpf(0.4, 0.65, blend_phase)
	return {
		"primary": mix_pool[primary_idx],
		"secondary": mix_pool[secondary_idx] if mix_pool.size() > 1 else "",
		"primary_ratio": primary_ratio,
		"is_mixed": mix_pool.size() > 1
	}

func _resolve_breed_model_path(breed_id: String, fallback_models: Array) -> String:
	var definition = _breed_definition(breed_id)
	var candidates: Array = definition.get("model_candidates", [])
	var existing_candidates = _existing_model_paths(candidates)
	if not existing_candidates.is_empty():
		# Static breed models still receive DogAgent's procedural whole-body gait,
		# so visual breed variety no longer depends on authored animation clips.
		return str(existing_candidates[0])
	if fallback_models.is_empty():
		if _model_has_walk_animation(FREYA_PRIMARY_MODEL):
			return FREYA_PRIMARY_MODEL
		return ""
	var idx = posmod(abs(int(hash("%s_fallback" % breed_id))), fallback_models.size())
	return str(fallback_models[idx])

func _color_from_palette(palette: Array, seed_idx: int, fallback: Color) -> Color:
	if palette.is_empty():
		return fallback
	var idx = posmod(seed_idx, palette.size())
	var c = palette[idx]
	if c is Color:
		return c
	return fallback

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
			score += 3.0 if surf == "sidewalk" else 0.62
		else:
			score += 2.35 if surf == "grass" else 0.68

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
		_spawn_poop(false)

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
		for attempt in range(120):
			var candidate = Vector2(
				rng.randf_range(0.8, MAP_W - 0.8),
				rng.randf_range(0.8, MAP_H - 0.8)
			)
			if dog_park.grow(0.45).has_point(candidate):
				continue
			if _surface_at(candidate) != "grass":
				continue
			if not _is_walkable(candidate.x, candidate.y, 0.1):
				continue
			p2 = candidate
			found = true
			break
	if not found:
		for attempt in range(90):
			var p3 = _random_walkable_point(true, 0.1)
			var fallback = Vector2(p3.x, p3.z)
			if dog_park.grow(0.45).has_point(fallback):
				continue
			if _surface_at(fallback) == "road":
				continue
			p2 = fallback
			found = true
			break
	if not found:
		return
	if _surface_at(p2) == "road":
		return
	if not prefer_dog_park and dog_park.grow(0.35).has_point(p2):
		return
	for item in poops:
		var pos: Vector2 = item["pos"]
		if pos.distance_to(p2) < 1.2:
			return
	var p3 = Vector3(p2.x, 0.0, p2.y)

	var root = Node3D.new()
	root.position = p3

	var blobs = [Vector3(0.0, 0.08, 0.0), Vector3(-0.11, 0.05, 0.08), Vector3(0.1, 0.05, 0.08)]
	var blob_multimesh = MultiMesh.new()
	blob_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	blob_multimesh.mesh = poop_blob_mesh
	blob_multimesh.instance_count = blobs.size()
	for blob_index in range(blobs.size()):
		blob_multimesh.set_instance_transform(
			blob_index,
			Transform3D(Basis().scaled(Vector3(1.0, 0.7, 1.0)), blobs[blob_index])
		)
	var blob_instance = MultiMeshInstance3D.new()
	blob_instance.multimesh = blob_multimesh
	blob_instance.material_override = poop_material
	blob_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(blob_instance)

	dynamic_root.add_child(root)
	poops.append({"node": root, "pos": p2})

func _freya_spawn_point_near_dog_park() -> Vector3:
	var visual_view = OS.get_environment("FREYA_VISUAL_VIEW").to_lower()
	if not visual_view.is_empty():
		if visual_view == "dog_park_friendly":
			return Vector3(dog_park.get_center().x, 0.0, dog_park.get_center().y + 1.4)
		var target_index = -1
		if visual_view == "home_inside" or visual_view == "home_outside":
			target_index = freya_home_index
		elif visual_view == "storefront":
			for store_index in store_building_indices:
				if bool(buildings[store_index].get("front_is_south", true)):
					target_index = store_index
					break
			if target_index < 0 and not store_building_indices.is_empty():
				target_index = store_building_indices[0]
		elif visual_view == "wide_gable" or visual_view == "wide_hip":
			var requested_style = "gable" if visual_view == "wide_gable" else "hip"
			var best_area = -1.0
			for building_index in range(buildings.size()):
				var candidate: Dictionary = buildings[building_index]
				if bool(candidate.get("is_store", false)) or str(candidate.get("roof_style", "")) != requested_style:
					continue
				if not bool(candidate.get("front_is_south", true)):
					continue
				var candidate_fp: Rect2 = candidate.get("footprint", Rect2())
				if candidate_fp.get_area() > best_area:
					best_area = candidate_fp.get_area()
					target_index = building_index
			if target_index < 0:
				for building_index in range(buildings.size()):
					var candidate: Dictionary = buildings[building_index]
					if not bool(candidate.get("is_store", false)) and str(candidate.get("roof_style", "")) == requested_style:
						target_index = building_index
						break
		if target_index >= 0 and target_index < buildings.size():
			var target_building: Dictionary = buildings[target_index]
			var target_fp: Rect2 = target_building.get("footprint", Rect2())
			var target_front_south = bool(target_building.get("front_is_south", true))
			var target_front_sign = 1.0 if target_front_south else -1.0
			camera_orbit_angle = 0.0 if target_front_south else PI
			var target_layout: Dictionary = target_building.get("home_layout", {}) if bool(target_building.get("is_freya_home", false)) else target_building.get("store_layout", {})
			var target_point = Vector2(target_fp.get_center().x, target_fp.position.y + (target_fp.size.y if target_front_south else 0.0) + target_front_sign * 2.0)
			if visual_view == "home_inside":
				target_point = target_building.get("home_interior_rect", target_fp).get_center()
			elif visual_view == "home_outside" or visual_view == "storefront":
				target_point = target_layout.get("entry_outside_pos", target_point)
			return Vector3(target_point.x, 0.0, target_point.y)
	var home_preview = OS.get_environment("FREYA_START_AT_HOME").to_lower()
	if (home_preview == "inside" or home_preview == "outside") and freya_home_index >= 0 and freya_home_index < buildings.size():
		var home: Dictionary = buildings[freya_home_index]
		var layout: Dictionary = home.get("home_layout", {})
		var home_point: Vector2 = home.get("home_interior_rect", Rect2()).get_center()
		if home_preview == "outside":
			home_point = layout.get("entry_outside_pos", home_point)
		return Vector3(home_point.x, 0.0, home_point.y)
	if dog_park.size.x > 0.8 and dog_park.size.y > 0.8:
		var outer = dog_park.grow(3.2)
		var inner_block = dog_park.grow(0.55)
		var clipped = outer.intersection(Rect2(0.0, 0.0, MAP_W, MAP_H))
		for i in range(260):
			var p = Vector2(
				rng.randf_range(clipped.position.x + FREYA_COLLISION_RADIUS, clipped.position.x + clipped.size.x - FREYA_COLLISION_RADIUS),
				rng.randf_range(clipped.position.y + FREYA_COLLISION_RADIUS, clipped.position.y + clipped.size.y - FREYA_COLLISION_RADIUS)
			)
			if inner_block.has_point(p):
				continue
			if not _is_walkable(p.x, p.y, FREYA_COLLISION_RADIUS):
				continue
			if _surface_at(p) == "road":
				continue
			return Vector3(p.x, 0.0, p.y)
	return _random_walkable_point(true, FREYA_COLLISION_RADIUS)

func _random_walkable_point_in_rect(rect: Rect2, avoid_roads: bool, radius: float, attempts: int) -> Vector3:
	var clipped = rect.intersection(Rect2(0.0, 0.0, MAP_W, MAP_H))
	if clipped.size.x <= 0.05 or clipped.size.y <= 0.05:
		return Vector3(1000000000.0, 1000000000.0, 1000000000.0)
	for i in range(maxi(8, attempts)):
		var p = Vector2(
			rng.randf_range(clipped.position.x + radius, clipped.position.x + clipped.size.x - radius),
			rng.randf_range(clipped.position.y + radius, clipped.position.y + clipped.size.y - radius)
		)
		if not _is_walkable(p.x, p.y, radius):
			continue
		if avoid_roads and _surface_at(p) == "road":
			continue
		return Vector3(p.x, 0.0, p.y)
	return Vector3(1000000000.0, 1000000000.0, 1000000000.0)

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
	if _point_in_occupied_store(p, radius):
		return false
	if _point_in_blocking_building(p, radius + BUILDING_COLLISION_PAD):
		return false
	if _point_in_store_wall(p, maxf(0.02, radius * 0.56)):
		return false
	if _point_in_static_obstacle(p, radius):
		return false
	return true

func _point_in_occupied_store(p: Vector2, pad: float = 0.0) -> bool:
	for store_index in store_building_indices:
		if store_index < 0 or store_index >= buildings.size():
			continue
		var store: Dictionary = buildings[store_index]
		if not bool(store.get("alien_occupied", false)):
			continue
		var footprint: Rect2 = store.get("footprint", Rect2())
		if footprint.grow(pad).has_point(p):
			return true
	return false

func _point_in_building(p: Vector2, pad: float) -> bool:
	for b in buildings:
		var rect: Rect2 = b.get("collision_rect", b["footprint"])
		if rect.grow(pad).has_point(p):
			return true
	return false

func _point_in_blocking_building(p: Vector2, pad: float) -> bool:
	var min_cell = Vector2i(
		int(floor((p.x - pad) / COLLISION_GRID_SIZE)),
		int(floor((p.y - pad) / COLLISION_GRID_SIZE))
	)
	var max_cell = Vector2i(
		int(floor((p.x + pad) / COLLISION_GRID_SIZE)),
		int(floor((p.y + pad) / COLLISION_GRID_SIZE))
	)
	for cell_x in range(min_cell.x, max_cell.x + 1):
		for cell_y in range(min_cell.y, max_cell.y + 1):
			var cell_rects: Array = blocking_building_grid.get(Vector2i(cell_x, cell_y), [])
			for rect in cell_rects:
				if rect is Rect2 and (rect as Rect2).grow(pad).has_point(p):
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
		var radius = tree_radius + extra_radius
		var dx = center.x - p.x
		if absf(dx) > radius:
			continue
		var dz = center.y - p.y
		if absf(dz) > radius:
			continue
		if dx * dx + dz * dz <= radius * radius:
			return true
	return false

func _point_in_dumpster(p: Vector2, extra_radius: float) -> bool:
	for d in dumpsters:
		var center: Vector2 = d.get("pos", Vector2.ZERO)
		var dumpster_radius = float(d.get("radius", DUMPSTER_COLLISION_RADIUS))
		var radius = dumpster_radius + extra_radius
		var dx = center.x - p.x
		if absf(dx) > radius:
			continue
		var dz = center.y - p.y
		if absf(dz) > radius:
			continue
		if dx * dx + dz * dz <= radius * radius:
			return true
	return false

func _point_in_street_pole(p: Vector2, extra_radius: float) -> bool:
	for pole in street_poles:
		var center: Vector2 = pole.get("pos", Vector2.ZERO)
		var pole_radius = float(pole.get("radius", STREET_POLE_COLLISION_RADIUS))
		var radius = pole_radius + extra_radius
		var dx = center.x - p.x
		if absf(dx) > radius:
			continue
		var dz = center.y - p.y
		if absf(dz) > radius:
			continue
		if dx * dx + dz * dz <= radius * radius:
			return true
	return false

func _point_in_fire_hydrant(p: Vector2, extra_radius: float) -> bool:
	for hydrant in fire_hydrants:
		var center: Vector2 = hydrant.get("pos", Vector2.ZERO)
		var radius = float(hydrant.get("radius", FIRE_HYDRANT_COLLISION_RADIUS))
		radius += extra_radius
		var dx = center.x - p.x
		if absf(dx) > radius:
			continue
		var dz = center.y - p.y
		if absf(dz) > radius:
			continue
		if dx * dx + dz * dz <= radius * radius:
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
		var radius = pole_radius + margin
		var dx = center.x - p.x
		if absf(dx) > radius:
			continue
		var dz = center.y - p.y
		if absf(dz) > radius:
			continue
		if dx * dx + dz * dz <= radius * radius:
			return true
	for hydrant in fire_hydrants:
		var center: Vector2 = hydrant.get("pos", Vector2.ZERO)
		var hydrant_radius = float(hydrant.get("radius", FIRE_HYDRANT_COLLISION_RADIUS))
		var radius = hydrant_radius + margin
		var dx = center.x - p.x
		if absf(dx) > radius:
			continue
		var dz = center.y - p.y
		if absf(dz) > radius:
			continue
		if dx * dx + dz * dz <= radius * radius:
			return true
	return false

func _update_freya(delta: float) -> void:
	freya_social = clamp(freya_social - delta * 1.0, 0.0, 100.0)

	if freya_vomit_timer > 0.0:
		_increase_freya_hunger(delta, HUNGER_ACTIVE_ACTION_PER_SEC)
		freya_vomit_timer = max(0.0, freya_vomit_timer - delta)
		if freya_vomit_timer <= 0.0 and vomit_sfx_player != null and is_instance_valid(vomit_sfx_player):
			vomit_sfx_player.stop()
		freya.update_motion(delta, Vector3.ZERO, false, true)
		return

	if freya_eat_timer > 0.0:
		# Eating is restorative; its short animation should not be charged as work.
		_increase_freya_hunger(delta, HUNGER_IDLE_PER_SEC)
		freya_eat_timer = max(0.0, freya_eat_timer - delta)
		if freya_eat_timer <= 0.0 and eat_sfx_player != null and is_instance_valid(eat_sfx_player):
			eat_sfx_player.stop()
		freya.update_motion(delta, Vector3.ZERO, false, false, true)
		return

	var input_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var input_y = Input.get_action_strength("move_up") - Input.get_action_strength("move_down")
	var moving = Vector2(input_x, input_y)

	if moving.length_squared() < 0.0001:
		_increase_freya_hunger(delta, HUNGER_IDLE_PER_SEC)
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
		_increase_freya_hunger(delta, HUNGER_IDLE_PER_SEC)
		freya_move_dir = Vector3.ZERO
		freya.update_motion(delta, Vector3.ZERO, false, false)
		return
	move_dir = move_dir.normalized()
	freya_move_dir = move_dir

	var running = Input.is_action_pressed("run")
	_increase_freya_hunger(delta, HUNGER_RUN_PER_SEC if running else HUNGER_WALK_PER_SEC)
	var speed = _compute_freya_move_speed(running)

	var next: Vector3 = freya.global_position + move_dir * speed * delta
	if _is_walkable(next.x, freya.global_position.z, FREYA_COLLISION_RADIUS):
		freya.global_position.x = next.x
	if _is_walkable(freya.global_position.x, next.z, FREYA_COLLISION_RADIUS):
		freya.global_position.z = next.z

	freya.update_motion(delta, move_dir, running, false)

func _increase_freya_hunger(delta: float, rate_per_second: float) -> void:
	if delta <= 0.0 or rate_per_second <= 0.0:
		return
	freya_hunger = clampf(freya_hunger + delta * rate_per_second, 0.0, 100.0)

func _compute_freya_move_speed(running: bool) -> float:
	var speed_penalty = freya_hunger * 0.0043
	var speed = FREYA_BASE_SPEED * (1.0 - speed_penalty)
	# Possessed dogs make Freya hesitate before the player knows why. The modest
	# cap keeps this readable without making nearby crowds frustrating to cross.
	speed *= 1.0 - clampf(freya_alien_discomfort, 0.0, 1.0) * 0.1
	if running:
		speed *= FREYA_RUN_MULT
		if freya_has_stick and carried_stick != null and is_instance_valid(carried_stick):
			speed *= FREYA_STICK_RUN_MULT
	return maxf(1.7, speed)

func _update_dogs(delta: float) -> void:
	var friendly_requested = Input.is_action_pressed("friendly_social")
	var aggressive_social = Input.is_action_pressed("aggressive_social")
	if aggressive_social:
		friendly_requested = false
	var friendly_social = friendly_requested and freya_hunger < 99.999
	if friendly_requested and not friendly_social and status_timer <= 0.15:
		_show_status("Freya is too hungry to socialize.", 1.15)
	var friendly_interaction_active = false
	var friendly_possessed_interaction_active = false
	var aggressive_interaction_active = false
	var passive_social_target = Vector3.ZERO
	var passive_social_target_dist = 1000000.0
	var has_passive_social_target = false
	_update_aggressive_bark_context(delta, aggressive_social)

	for i in range(dogs.size()):
		var state: Dictionary = dogs[i]
		var dog: Node3D = state.get("node", null)
		if dog == null or not is_instance_valid(dog):
			continue
		if bool(state.get("army_aligned", false)) and dog.has_method("set_army_aligned"):
			# Keep the visible collar invariant tied to state, including restored or
			# externally-authored army dogs that did not pass through recruitment.
			dog.call("set_army_aligned", true)
		state["wander"] = float(state["wander"]) - delta
		state["bark"] = float(state["bark"]) - delta
		state["pref_timer"] = float(state.get("pref_timer", 1.5)) - delta
		var flee_timer = maxf(0.0, float(state.get("flee_timer", 0.0)) - delta)
		state["flee_timer"] = flee_timer
		var is_fleeing = flee_timer > 0.0

		var in_park = bool(state.get("park", false))
		var pref_surface = str(state.get("pref_surface", "sidewalk"))
		if (not is_fleeing) and float(state["pref_timer"]) <= 0.0:
			pref_surface = _pick_dog_pref_surface(in_park)
			state["pref_surface"] = pref_surface
			state["pref_timer"] = rng.randf_range(1.4, 4.2)
			state["wander"] = 0.0

		var dir: Vector3 = state["dir"]
		if is_fleeing:
			var away = dog.global_position - freya.global_position
			away.y = 0.0
			if away.length_squared() < 0.001:
				away = state.get("flee_direction", Vector3.RIGHT)
			if away.length_squared() < 0.001:
				away = Vector3.RIGHT.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
			dir = away.normalized()
			state["flee_direction"] = dir
		elif float(state["wander"]) <= 0.0:
			var drive_surface = pref_surface
			if (not in_park) and pref_surface == "sidewalk" and rng.randf() < 0.2:
				drive_surface = "grass"
			dir = _choose_dog_direction(dog.global_position, drive_surface, in_park)
			state["wander"] = rng.randf_range(0.8, 2.6)

		var speed = float(state["speed"]) * (DOG_FLEE_SPEED_MULT if is_fleeing else 1.0)
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

		var near: float = dog.global_position.distance_to(freya.global_position)
		var in_social_range = near < SOCIALIZE_RANGE
		if friendly_social and (not is_fleeing) and in_social_range:
			var sniff_result = _apply_mutual_butt_sniff(dog, state, delta)
			dir = sniff_result.get("dir", dir)
			state = sniff_result.get("state", state)
			near = float(sniff_result.get("near", near))
			in_social_range = near < SOCIALIZE_RANGE

		dog.update_motion(delta, dir, is_fleeing, false)
		state["dir"] = dir

		var friendly_interacting = friendly_social and (not is_fleeing) and in_social_range
		var aggressive_interacting = aggressive_social and in_social_range
		if aggressive_interacting:
			aggressive_interaction_active = true
		if friendly_interacting:
			friendly_interaction_active = true
			if bool(state.get("alien_possessed", false)):
				friendly_possessed_interaction_active = true
			freya_social = clamp(freya_social + delta * 22.0, 0.0, 100.0)
			if friendly_social and near < 3.4 and near < passive_social_target_dist:
				passive_social_target = dog.global_position
				passive_social_target_dist = near
				has_passive_social_target = true
		if (friendly_interacting or aggressive_interacting) and float(state["bark"]) <= 0.0:
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

		state = _update_exorcism_for_dog(state, i, delta, aggressive_social, in_social_range)
		if friendly_interacting and not bool(state.get("army_aligned", false)):
			var progress = minf(DOG_ARMY_ALIGN_TIME, float(state.get("socialization_progress", 0.0)) + delta)
			state["socialization_progress"] = progress
			if progress >= DOG_ARMY_ALIGN_TIME:
				state["army_aligned"] = true
				if dog.has_method("set_army_aligned"):
					dog.call("set_army_aligned", true)
				_show_status("A real dog joined Freya's army.", 1.25)
		dogs[i] = state

	if friendly_interaction_active:
		_increase_freya_hunger(delta, SOCIALIZATION_HUNGER_PER_SEC)
	if aggressive_interaction_active:
		_increase_freya_hunger(delta, HUNGER_ACTIVE_ACTION_PER_SEC)
	if friendly_possessed_interaction_active:
		freya_vomit = clampf(freya_vomit + delta * POSSESSED_SOCIAL_VOMIT_PER_SEC, 0.0, 100.0)
	_update_passive_social_dance(delta, friendly_social, aggressive_social, has_passive_social_target, passive_social_target)

func _update_exorcism_for_dog(
	state: Dictionary,
	dog_index: int,
	delta: float,
	aggressive_social: bool,
	in_social_range: bool
) -> Dictionary:
	if (not aggressive_social) or (not in_social_range):
		state["exorcism_progress"] = maxf(0.0, float(state.get("exorcism_progress", 0.0)) - delta * 1.6)
		state["exorcism_latched"] = false
		return state
	if bool(state.get("exorcism_latched", false)):
		return state
	var progress = float(state.get("exorcism_progress", 0.0))
	if aggressive_social and in_social_range:
		progress = minf(ALIEN_EXPEL_BARK_TIME, progress + delta)
	state["exorcism_progress"] = progress
	if progress < ALIEN_EXPEL_BARK_TIME:
		return state

	var dog: Node3D = state.get("node", null)
	if dog == null or not is_instance_valid(dog):
		return state
	state["exorcism_progress"] = 0.0
	state["exorcism_latched"] = true
	if bool(state.get("alien_possessed", false)):
		state["alien_possessed"] = false
		state["alien_expelled"] = true
		state["alien_transfer_serial"] = alien_transfer_serial
		_spawn_alien_transfer(dog.head_world_position(), dog_index)
		alien_expulsion_count += 1
		_show_status("An alien fled that dog toward the buildings!", 1.35)
	else:
		var away = dog.global_position - freya.global_position
		away.y = 0.0
		if away.length_squared() < 0.001:
			away = Vector3.RIGHT.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		state["flee_direction"] = away.normalized()
		state["flee_timer"] = DOG_WRONG_GUESS_FLEE_TIME
		_show_status("That was a real dog — Freya scared it away.", 1.35)
	return state

func _nearest_random_alien_building(origin: Vector2, excluded_indices: Array = []) -> int:
	var excluded := {}
	for excluded_index in excluded_indices:
		excluded[int(excluded_index)] = true
	var candidates: Array = []
	for building_index in range(buildings.size()):
		if excluded.has(building_index):
			continue
		var building: Dictionary = buildings[building_index]
		if bool(building.get("alien_occupied", false)):
			continue
		var footprint: Rect2 = building.get("footprint", Rect2())
		if footprint.size.x <= 0.0 or footprint.size.y <= 0.0:
			continue
		var closest = Vector2(
			clampf(origin.x, footprint.position.x, footprint.end.x),
			clampf(origin.y, footprint.position.y, footprint.end.y)
		)
		candidates.append({"index": building_index, "dist_sq": origin.distance_squared_to(closest)})
	if candidates.is_empty():
		return -1
	candidates.sort_custom(func(a, b):
		return float(a.get("dist_sq", 0.0)) < float(b.get("dist_sq", 0.0))
	)
	var pool_size = mini(ALIEN_NEAREST_BUILDING_POOL, candidates.size())
	return int(candidates[rng.randi_range(0, pool_size - 1)].get("index", -1))

func _nearest_alien_building(
	origin: Vector2,
	excluded_indices: Array = [],
	allow_occupied: bool = true,
	allow_freya_home: bool = true
) -> int:
	var excluded := {}
	for excluded_index in excluded_indices:
		excluded[int(excluded_index)] = true
	var closest_index = -1
	var closest_distance_sq = INF
	for building_index in range(buildings.size()):
		if excluded.has(building_index):
			continue
		var building: Dictionary = buildings[building_index]
		if (not allow_occupied) and bool(building.get("alien_occupied", false)):
			continue
		if (not allow_freya_home) and bool(building.get("is_freya_home", false)):
			continue
		var footprint: Rect2 = building.get("footprint", Rect2())
		if footprint.size.x <= 0.0 or footprint.size.y <= 0.0:
			continue
		var closest = Vector2(
			clampf(origin.x, footprint.position.x, footprint.end.x),
			clampf(origin.y, footprint.position.y, footprint.end.y)
		)
		var distance_sq = origin.distance_squared_to(closest)
		if distance_sq < closest_distance_sq:
			closest_distance_sq = distance_sq
			closest_index = building_index
	return closest_index

func _alien_building_target_position(building_index: int) -> Vector3:
	if building_index < 0 or building_index >= buildings.size():
		return Vector3.ZERO
	var building: Dictionary = buildings[building_index]
	var footprint: Rect2 = building.get("footprint", Rect2())
	var center = footprint.get_center()
	var height = maxf(2.4, float(building.get("height", 3.5)))
	return Vector3(center.x, height * 0.74 + 0.35, center.y)

func _alien_building_approach_position(building_index: int, origin: Vector2) -> Vector3:
	if building_index < 0 or building_index >= buildings.size():
		return Vector3(origin.x, 0.0, origin.y)
	var building: Dictionary = buildings[building_index]
	var footprint: Rect2 = building.get("footprint", Rect2())
	if footprint.size.x <= 0.0 or footprint.size.y <= 0.0:
		return Vector3(origin.x, 0.0, origin.y)
	var clearance = ALIEN_COLLISION_RADIUS + BUILDING_COLLISION_PAD + 0.12
	var candidates: Array[Vector2] = []
	var projected_x = clampf(origin.x, footprint.position.x, footprint.end.x)
	var projected_z = clampf(origin.y, footprint.position.y, footprint.end.y)
	candidates.append(Vector2(footprint.position.x - clearance, projected_z))
	candidates.append(Vector2(footprint.end.x + clearance, projected_z))
	candidates.append(Vector2(projected_x, footprint.position.y - clearance))
	candidates.append(Vector2(projected_x, footprint.end.y + clearance))

	var layout: Dictionary = building.get("store_layout", {})
	var entry_outside: Vector2 = layout.get("entry_outside_pos", building.get("entry_pos", footprint.get_center()))
	var entry_outward = entry_outside - footprint.get_center()
	if entry_outward.length_squared() > 0.001:
		candidates.append(entry_outside + entry_outward.normalized() * clearance)

	for fraction in [0.18, 0.36, 0.5, 0.64, 0.82]:
		var side_x = lerpf(footprint.position.x, footprint.end.x, float(fraction))
		var side_z = lerpf(footprint.position.y, footprint.end.y, float(fraction))
		candidates.append(Vector2(side_x, footprint.position.y - clearance))
		candidates.append(Vector2(side_x, footprint.end.y + clearance))
		candidates.append(Vector2(footprint.position.x - clearance, side_z))
		candidates.append(Vector2(footprint.end.x + clearance, side_z))

	var best = candidates[0]
	var best_distance_sq = INF
	for candidate in candidates:
		if not _is_walkable(candidate.x, candidate.y, ALIEN_COLLISION_RADIUS):
			continue
		var distance_sq = origin.distance_squared_to(candidate)
		if distance_sq < best_distance_sq:
			best = candidate
			best_distance_sq = distance_sq
	return Vector3(best.x, 0.0, best.y)

func _create_alien_transfer_visual() -> Node3D:
	return AlienVisualFactoryScript.create_imp({
		"body": alien_body_material,
		"face": alien_face_material,
		"horn": alien_horn_material,
		"eye": alien_eye_material,
		"fang": alien_fang_material
	}, ALIEN_VISUAL_SCALE)

func _update_alien_character_pose(node: Node3D, delta: float, move_direction: Vector3, moved_distance: float, phase: float) -> float:
	return AlienVisualFactoryScript.update_pose(node, delta, move_direction, moved_distance, phase, world_time)

func _move_alien_with_collisions(node: Node3D, desired_direction: Vector3, speed: float, delta: float, steering_sign: float = 1.0) -> Vector3:
	if node == null or not is_instance_valid(node) or delta <= 0.0 or speed <= 0.0:
		return Vector3.ZERO
	var direction = Vector3(desired_direction.x, 0.0, desired_direction.z)
	if direction.length_squared() <= 0.0001:
		node.global_position.y = 0.0
		return Vector3.ZERO
	direction = direction.normalized()
	var start = node.global_position
	start.y = 0.0
	node.global_position = start
	var remaining = speed * delta
	var iterations = 0
	while remaining > 0.0001 and iterations < 192:
		var step_distance = minf(remaining, ALIEN_MOVE_SUBSTEP)
		var step = _try_alien_collision_step(node, direction, step_distance, steering_sign)
		if step.length_squared() <= 0.000001:
			break
		remaining -= step_distance
		iterations += 1
	node.global_position.y = 0.0
	return node.global_position - start

func _try_alien_collision_step(node: Node3D, desired_direction: Vector3, distance: float, steering_sign: float) -> Vector3:
	var start = node.global_position
	var angles = [0.0, 0.52 * steering_sign, -0.52 * steering_sign, 1.0 * steering_sign, -1.0 * steering_sign, 1.48 * steering_sign, -1.48 * steering_sign]
	for angle in angles:
		var direction = desired_direction.rotated(Vector3.UP, float(angle)).normalized()
		var target = start + direction * distance
		target.y = 0.0
		if _is_walkable(target.x, target.z, ALIEN_COLLISION_RADIUS):
			node.global_position = target
			return target - start

		# Match Freya and the dogs: test X and Z independently so characters slide
		# along walls instead of stopping dead when only one axis is obstructed.
		var slid = start
		if _is_walkable(target.x, slid.z, ALIEN_COLLISION_RADIUS):
			slid.x = target.x
		if _is_walkable(slid.x, target.z, ALIEN_COLLISION_RADIUS):
			slid.z = target.z
		if slid.distance_squared_to(start) > 0.000001:
			node.global_position = slid
			return slid - start
	return Vector3.ZERO

func _spawn_alien_transfer(origin: Vector3, source_dog_index: int) -> void:
	var target_index = _nearest_random_alien_building(Vector2(origin.x, origin.z))
	if target_index < 0:
		return
	var visual = _create_alien_transfer_visual()
	dynamic_root.add_child(visual)
	visual.global_position = Vector3(origin.x, 0.0, origin.z)
	alien_transfers.append({
		"serial": alien_transfer_serial,
		"node": visual,
		"source_dog_index": source_dog_index,
		"target_index": target_index,
		"target_history": [target_index],
		"excluded_indices": [],
		"phase": "travel",
		"repel_timer": 0.0,
		"repel_direction": Vector3.ZERO,
		"age": 0.0,
		"walk_phase": rng.randf_range(0.0, TAU),
		"steering_sign": -1.0 if alien_transfer_serial % 2 == 0 else 1.0,
		"stuck_timer": 0.0
	})
	alien_transfer_serial += 1

func _retarget_alien_transfer(transfer: Dictionary) -> Dictionary:
	var node: Node3D = transfer.get("node", null)
	if node == null or not is_instance_valid(node):
		transfer["target_index"] = -1
		return transfer
	var excluded: Array = transfer.get("excluded_indices", [])
	var origin = Vector2(node.global_position.x, node.global_position.z)
	var target_index = _nearest_random_alien_building(origin, excluded)
	transfer["target_index"] = target_index
	if target_index >= 0:
		var history: Array = transfer.get("target_history", [])
		history.append(target_index)
		transfer["target_history"] = history
		transfer["phase"] = "travel"
	return transfer

func _trigger_ryah_alien_defense() -> void:
	ryah_alien_defense_count += 1
	ryah_alien_cry_timer = maxf(ryah_alien_cry_timer, ALIEN_RYAH_REPEL_TIME + 1.15)
	if ryah_diane_node != null and is_instance_valid(ryah_diane_node):
		if ryah_alien_cry_visual_root == null or not is_instance_valid(ryah_alien_cry_visual_root):
			ryah_alien_cry_visual_root = Node3D.new()
			ryah_alien_cry_visual_root.name = "RyahAlienDefenseCrying"
			ryah_alien_cry_visual_root.position = Vector3(0.0, 0.82, -0.07)
			ryah_diane_node.add_child(ryah_alien_cry_visual_root)
			for tear_index in range(6):
				var tear = MeshInstance3D.new()
				tear.name = "RyahTear"
				var tear_mesh = SphereMesh.new()
				tear_mesh.radius = 0.026
				tear_mesh.height = 0.075
				tear.mesh = tear_mesh
				tear.position = Vector3(-0.08 if tear_index % 2 == 0 else 0.08, -0.03 - float(tear_index / 2) * 0.08, -0.11)
				tear.material_override = ryah_tear_material
				tear.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				tear.set_meta("tear_index", tear_index)
				ryah_alien_cry_visual_root.add_child(tear)
			for wave_index in range(2):
				var wave = MeshInstance3D.new()
				wave.name = "RyahCryWave"
				var wave_mesh = TorusMesh.new()
				wave_mesh.inner_radius = 0.16 + float(wave_index) * 0.09
				wave_mesh.outer_radius = wave_mesh.inner_radius + 0.018
				wave_mesh.rings = 16
				wave_mesh.ring_segments = 4
				wave.mesh = wave_mesh
				wave.rotation_degrees.x = 90.0
				wave.position = Vector3(0.0, 0.02, -0.15)
				wave.material_override = ryah_tear_material
				wave.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				wave.set_meta("wave_index", wave_index)
				ryah_alien_cry_visual_root.add_child(wave)
		ryah_alien_cry_visual_root.visible = true
	_show_status("Ryah Diane cried so fiercely the alien fled her house!", 1.8)

func _update_ryah_alien_crying(delta: float) -> void:
	ryah_alien_cry_timer = maxf(0.0, ryah_alien_cry_timer - delta)
	if ryah_alien_cry_visual_root == null or not is_instance_valid(ryah_alien_cry_visual_root):
		return
	ryah_alien_cry_visual_root.visible = ryah_alien_cry_timer > 0.0
	if ryah_alien_cry_timer <= 0.0:
		return
	if ryah_diane_left_arm != null:
		ryah_diane_left_arm.rotation.x = -1.05 + 0.14 * sin(world_time * 13.0)
	if ryah_diane_right_arm != null:
		ryah_diane_right_arm.rotation.x = -1.05 - 0.14 * sin(world_time * 13.0)
	for child in ryah_alien_cry_visual_root.get_children():
		if not (child is MeshInstance3D):
			continue
		var mesh_child = child as MeshInstance3D
		if mesh_child.name == "RyahTear":
			var tear_index = int(mesh_child.get_meta("tear_index", 0))
			var fall = fposmod(world_time * 1.9 + float(tear_index) * 0.19, 0.58)
			mesh_child.position.y = -0.02 - fall
			mesh_child.position.x = (-0.08 if tear_index % 2 == 0 else 0.08) + sin(world_time * 8.0 + tear_index) * 0.015
		else:
			var wave_index = int(mesh_child.get_meta("wave_index", 0))
			var pulse = fposmod(world_time * 2.2 + float(wave_index) * 0.47, 1.0)
			mesh_child.scale = Vector3.ONE * (0.55 + pulse * 1.35)
			mesh_child.transparency = pulse * 0.78

func _update_alien_transfers(delta: float) -> void:
	for transfer_index in range(alien_transfers.size() - 1, -1, -1):
		var transfer: Dictionary = alien_transfers[transfer_index]
		var node: Node3D = transfer.get("node", null)
		if node == null or not is_instance_valid(node):
			alien_transfers.remove_at(transfer_index)
			continue
		transfer["age"] = float(transfer.get("age", 0.0)) + delta
		node.global_position.y = 0.0
		var walk_phase = float(transfer.get("walk_phase", 0.0))
		var steering_sign = float(transfer.get("steering_sign", 1.0))

		if str(transfer.get("phase", "travel")) == "repelled":
			var repel_timer = maxf(0.0, float(transfer.get("repel_timer", 0.0)) - delta)
			transfer["repel_timer"] = repel_timer
			var repel_direction: Vector3 = transfer.get("repel_direction", Vector3.RIGHT)
			repel_direction.y = 0.0
			var repelled_step = _move_alien_with_collisions(node, repel_direction, ALIEN_TRAVEL_SPEED * 0.88, delta, steering_sign)
			walk_phase = _update_alien_character_pose(node, delta, repelled_step, repelled_step.length(), walk_phase)
			transfer["walk_phase"] = walk_phase
			if repel_timer <= 0.0:
				transfer = _retarget_alien_transfer(transfer)
				if int(transfer.get("target_index", -1)) < 0:
					node.queue_free()
					alien_transfers.remove_at(transfer_index)
					continue
			alien_transfers[transfer_index] = transfer
			continue

		var target_index = int(transfer.get("target_index", -1))
		if target_index < 0 or target_index >= buildings.size() or bool(buildings[target_index].get("alien_occupied", false)):
			transfer = _retarget_alien_transfer(transfer)
			target_index = int(transfer.get("target_index", -1))
			if target_index < 0:
				node.queue_free()
				alien_transfers.remove_at(transfer_index)
				continue
		var target_pos = _alien_building_approach_position(target_index, Vector2(node.global_position.x, node.global_position.z))
		var to_target = target_pos - node.global_position
		to_target.y = 0.0
		if to_target.length() > ALIEN_POSSESSION_REACH:
			var moved = _move_alien_with_collisions(node, to_target, ALIEN_TRAVEL_SPEED, delta, steering_sign)
			walk_phase = _update_alien_character_pose(node, delta, moved, moved.length(), walk_phase)
			transfer["walk_phase"] = walk_phase
			var stuck_timer = 0.0 if moved.length_squared() > 0.00001 else float(transfer.get("stuck_timer", 0.0)) + delta
			if stuck_timer >= 0.8:
				steering_sign *= -1.0
				transfer["steering_sign"] = steering_sign
				stuck_timer = 0.0
			transfer["stuck_timer"] = stuck_timer
			alien_transfers[transfer_index] = transfer
			continue

		if bool(buildings[target_index].get("is_freya_home", false)):
			_trigger_ryah_alien_defense()
			var excluded: Array = transfer.get("excluded_indices", [])
			excluded.append(target_index)
			transfer["excluded_indices"] = excluded
			transfer["phase"] = "repelled"
			transfer["repel_timer"] = ALIEN_RYAH_REPEL_TIME
			var home_center = buildings[target_index].get("footprint", Rect2()).get_center()
			var away = node.global_position - Vector3(home_center.x, 0.0, home_center.y)
			if away.length_squared() < 0.001:
				away = Vector3.RIGHT.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
			away.y = 0.0
			transfer["repel_direction"] = away.normalized()
			alien_transfers[transfer_index] = transfer
			continue

		_occupy_building_with_alien(target_index, int(transfer.get("serial", -1)))
		node.queue_free()
		alien_transfers.remove_at(transfer_index)

func _free_alien_spawn_position(store_index: int) -> Vector3:
	var building: Dictionary = buildings[store_index]
	var footprint: Rect2 = building.get("footprint", Rect2())
	var center = footprint.get_center()
	var layout: Dictionary = building.get("store_layout", {})
	var outside: Vector2 = layout.get("entry_outside_pos", building.get("entry_pos", center))
	var outward = outside - center
	if outward.length_squared() < 0.001:
		outward = Vector2.DOWN if bool(building.get("front_is_south", true)) else Vector2.UP
	outside += outward.normalized() * 0.8
	if _is_walkable(outside.x, outside.y, ALIEN_COLLISION_RADIUS):
		return Vector3(outside.x, 0.0, outside.y)
	return _alien_building_approach_position(store_index, outside)

func _random_free_alien_roam_target(store_index: int) -> Vector3:
	var building: Dictionary = buildings[store_index]
	var center: Vector2 = building.get("footprint", Rect2()).get_center()
	for attempt in range(32):
		var angle = rng.randf_range(0.0, TAU)
		var distance = rng.randf_range(1.8, FREE_ALIEN_ROAM_RADIUS)
		var candidate = Vector2(center.x + cos(angle) * distance, center.y + sin(angle) * distance)
		if _is_walkable(candidate.x, candidate.y, ALIEN_COLLISION_RADIUS):
			return Vector3(candidate.x, 0.0, candidate.y)
	return _free_alien_spawn_position(store_index)

func _spawn_free_alien_from_store(store_index: int) -> bool:
	if free_aliens.size() >= MAX_FREE_ALIENS or store_index < 0 or store_index >= buildings.size():
		return false
	var building: Dictionary = buildings[store_index]
	if not bool(building.get("is_store", false)) or not bool(building.get("alien_occupied", false)):
		return false
	var visual = _create_alien_transfer_visual()
	visual.name = "StorefrontFreeAlien"
	dynamic_root.add_child(visual)
	visual.global_position = _free_alien_spawn_position(store_index)
	free_aliens.append({
		"serial": alien_transfer_serial,
		"node": visual,
		"source_store_index": store_index,
		"phase": "roam",
		"target_index": -1,
		"excluded_indices": [store_index],
		"roam_target": _random_free_alien_roam_target(store_index),
		"roam_timer": rng.randf_range(1.8, 4.0),
		"walk_phase": rng.randf_range(0.0, TAU),
		"steering_sign": -1.0 if alien_transfer_serial % 2 == 0 else 1.0,
		"stuck_timer": 0.0
	})
	alien_transfer_serial += 1
	return true

func _clear_free_aliens() -> void:
	for alien in free_aliens:
		var node: Node3D = alien.get("node", null)
		if node != null and is_instance_valid(node):
			node.queue_free()
	free_aliens.clear()

func _update_free_alien_generation(delta: float) -> void:
	for store_index in store_building_indices:
		if store_index < 0 or store_index >= buildings.size():
			continue
		var store: Dictionary = buildings[store_index]
		if not bool(store.get("alien_occupied", false)):
			continue
		var cooldown = maxf(0.0, float(store.get("alien_spawn_cooldown", FREE_ALIEN_SPAWN_MIN_SEC)) - delta)
		store["alien_spawn_cooldown"] = cooldown
		if cooldown <= 0.0 and free_aliens.size() < MAX_FREE_ALIENS:
			if _spawn_free_alien_from_store(store_index):
				store["alien_spawn_cooldown"] = rng.randf_range(FREE_ALIEN_SPAWN_MIN_SEC, FREE_ALIEN_SPAWN_MAX_SEC)
		buildings[store_index] = store

func _retarget_free_alien(alien: Dictionary) -> Dictionary:
	var node: Node3D = alien.get("node", null)
	if node == null or not is_instance_valid(node):
		alien["target_index"] = -1
		return alien
	var excluded: Array = alien.get("excluded_indices", [])
	var origin = Vector2(node.global_position.x, node.global_position.z)
	alien["target_index"] = _nearest_alien_building(origin, excluded, true, true)
	return alien

func _update_free_aliens(delta: float) -> void:
	_update_free_alien_generation(delta)
	for alien_index in range(free_aliens.size() - 1, -1, -1):
		var alien: Dictionary = free_aliens[alien_index]
		var node: Node3D = alien.get("node", null)
		if node == null or not is_instance_valid(node):
			free_aliens.remove_at(alien_index)
			continue
		node.global_position.y = 0.0
		var walk_phase = float(alien.get("walk_phase", 0.0))
		var steering_sign = float(alien.get("steering_sign", 1.0))

		if str(alien.get("phase", "roam")) == "roam":
			if freya != null and is_instance_valid(freya) and node.global_position.distance_to(freya.global_position) <= FREE_ALIEN_APPROACH_RADIUS:
				alien["phase"] = "flee"
				alien = _retarget_free_alien(alien)
				_show_status("The alien fled toward the nearest building!", 1.15)
			else:
				var source_store = int(alien.get("source_store_index", -1))
				if source_store < 0 or source_store >= buildings.size():
					node.queue_free()
					free_aliens.remove_at(alien_index)
					continue
				var roam_timer = maxf(0.0, float(alien.get("roam_timer", 0.0)) - delta)
				var roam_target: Vector3 = alien.get("roam_target", _random_free_alien_roam_target(source_store))
				var to_roam = roam_target - node.global_position
				if roam_timer <= 0.0 or to_roam.length() < 0.2:
					roam_target = _random_free_alien_roam_target(source_store)
					alien["roam_target"] = roam_target
					alien["roam_timer"] = rng.randf_range(1.8, 4.0)
					to_roam = roam_target - node.global_position
				else:
					alien["roam_timer"] = roam_timer
				if to_roam.length_squared() > 0.001:
					to_roam.y = 0.0
					var moved = _move_alien_with_collisions(node, to_roam, FREE_ALIEN_ROAM_SPEED, delta, steering_sign)
					walk_phase = _update_alien_character_pose(node, delta, moved, moved.length(), walk_phase)
					alien["walk_phase"] = walk_phase
					var stuck_timer = 0.0 if moved.length_squared() > 0.00001 else float(alien.get("stuck_timer", 0.0)) + delta
					if stuck_timer >= 0.7:
						steering_sign *= -1.0
						alien["steering_sign"] = steering_sign
						alien["roam_target"] = _random_free_alien_roam_target(source_store)
						alien["roam_timer"] = rng.randf_range(1.2, 2.8)
						stuck_timer = 0.0
					alien["stuck_timer"] = stuck_timer
				free_aliens[alien_index] = alien
				continue

		var target_index = int(alien.get("target_index", -1))
		if target_index < 0 or target_index >= buildings.size():
			alien = _retarget_free_alien(alien)
			target_index = int(alien.get("target_index", -1))
			if target_index < 0:
				free_aliens[alien_index] = alien
				continue
		var target_pos = _alien_building_approach_position(target_index, Vector2(node.global_position.x, node.global_position.z))
		var to_target = target_pos - node.global_position
		to_target.y = 0.0
		if to_target.length() > ALIEN_POSSESSION_REACH:
			var moved = _move_alien_with_collisions(node, to_target, ALIEN_TRAVEL_SPEED, delta, steering_sign)
			walk_phase = _update_alien_character_pose(node, delta, moved, moved.length(), walk_phase)
			alien["walk_phase"] = walk_phase
			var stuck_timer = 0.0 if moved.length_squared() > 0.00001 else float(alien.get("stuck_timer", 0.0)) + delta
			if stuck_timer >= 0.8:
				steering_sign *= -1.0
				alien["steering_sign"] = steering_sign
				stuck_timer = 0.0
			alien["stuck_timer"] = stuck_timer
			free_aliens[alien_index] = alien
			continue
		if bool(buildings[target_index].get("is_freya_home", false)):
			_trigger_ryah_alien_defense()
			var excluded: Array = alien.get("excluded_indices", [])
			excluded.append(target_index)
			alien["excluded_indices"] = excluded
			alien = _retarget_free_alien(alien)
			free_aliens[alien_index] = alien
			continue
		_occupy_building_with_alien(target_index, int(alien.get("serial", -1)))
		node.queue_free()
		free_aliens.remove_at(alien_index)

func _alien_box(parent: Node3D, name: String, size: Vector3, position: Vector3, material: Material, rotation_z: float = 0.0, casts_shadow: bool = false) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = name
	var box = BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = position
	mesh_instance.rotation.z = rotation_z
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if casts_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh_instance, true)
	return mesh_instance

func _create_alien_building_visual(building_index: int) -> Node3D:
	var building: Dictionary = buildings[building_index]
	var footprint: Rect2 = building.get("footprint", Rect2())
	var height = maxf(2.4, float(building.get("height", 3.5)))
	var center = footprint.get_center()
	var root = Node3D.new()
	root.name = "AlienOccupationVisual"
	root.position = Vector3(center.x, 0.0, center.y)
	dynamic_root.add_child(root)

	var membrane_h = height * 0.76
	var membrane_y = membrane_h * 0.5 + 0.18
	_alien_box(root, "AlienMembrane", Vector3(footprint.size.x + 0.16, membrane_h, 0.055), Vector3(0.0, membrane_y, footprint.size.y * 0.5 + 0.07), alien_building_material)
	_alien_box(root, "AlienMembrane", Vector3(footprint.size.x + 0.16, membrane_h, 0.055), Vector3(0.0, membrane_y, -footprint.size.y * 0.5 - 0.07), alien_building_material)
	_alien_box(root, "AlienMembrane", Vector3(0.055, membrane_h, footprint.size.y + 0.16), Vector3(footprint.size.x * 0.5 + 0.07, membrane_y, 0.0), alien_building_material)
	_alien_box(root, "AlienMembrane", Vector3(0.055, membrane_h, footprint.size.y + 0.16), Vector3(-footprint.size.x * 0.5 - 0.07, membrane_y, 0.0), alien_building_material)

	for vein_index in range(8):
		var side = -1.0 if vein_index % 2 == 0 else 1.0
		var x = lerpf(-footprint.size.x * 0.42, footprint.size.x * 0.42, float(vein_index) / 7.0)
		var z = side * (footprint.size.y * 0.5 + 0.105)
		_alien_box(
			root,
			"AlienVein",
			Vector3(0.065, membrane_h * 0.72, 0.035),
			Vector3(x, membrane_y, z),
			alien_building_accent_material,
			(-0.34 if vein_index % 3 == 0 else (0.26 if vein_index % 3 == 1 else 0.0))
		)

	var crown = Node3D.new()
	crown.name = "AlienCrown"
	crown.position.y = height + 0.28
	root.add_child(crown)
	var roof_ring = MeshInstance3D.new()
	roof_ring.name = "AlienRoofSigil"
	var roof_ring_mesh = TorusMesh.new()
	roof_ring_mesh.inner_radius = 0.72
	roof_ring_mesh.outer_radius = 0.8
	roof_ring_mesh.rings = 24
	roof_ring_mesh.ring_segments = 6
	roof_ring.mesh = roof_ring_mesh
	roof_ring.scale = Vector3(maxf(0.8, footprint.size.x * 0.34), 1.0, maxf(0.8, footprint.size.y * 0.34))
	roof_ring.material_override = alien_building_accent_material
	roof_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	crown.add_child(roof_ring)

	for spike_index in range(5):
		var spike = MeshInstance3D.new()
		spike.name = "AlienRoofSpike"
		var spike_mesh = CylinderMesh.new()
		spike_mesh.top_radius = 0.0
		spike_mesh.bottom_radius = 0.11
		spike_mesh.height = 0.72 + float(spike_index % 2) * 0.24
		spike_mesh.radial_segments = 6
		spike.mesh = spike_mesh
		var angle = TAU * float(spike_index) / 5.0
		spike.position = Vector3(cos(angle) * minf(footprint.size.x * 0.26, 1.7), spike_mesh.height * 0.5, sin(angle) * minf(footprint.size.y * 0.26, 1.5))
		spike.rotation_degrees.z = sin(angle) * 15.0
		spike.material_override = alien_core_material
		spike.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		crown.add_child(spike)

	var eye = MeshInstance3D.new()
	eye.name = "AlienBuildingEye"
	var eye_mesh = SphereMesh.new()
	eye_mesh.radius = 0.28
	eye_mesh.height = 0.56
	eye_mesh.radial_segments = 12
	eye_mesh.rings = 7
	eye.mesh = eye_mesh
	eye.position.y = 0.78
	eye.scale = Vector3(1.0, 0.62, 1.0)
	eye.material_override = alien_core_material
	eye.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	crown.add_child(eye)

	var count_label = Label3D.new()
	count_label.name = "AlienOccupantCount"
	count_label.position = Vector3(0.0, 1.42, 0.0)
	count_label.font_size = 34
	count_label.outline_size = 8
	count_label.modulate = Color(0.72, 1.0, 0.82)
	count_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	count_label.no_depth_test = true
	crown.add_child(count_label)

	if bool(building.get("is_store", false)):
		var layout: Dictionary = building.get("store_layout", {})
		var entry: Vector2 = layout.get("entry_outside_pos", building.get("entry_pos", center))
		var lock_local = Vector3(entry.x - center.x, 0.82, entry.y - center.y)
		for lock_angle in [-0.62, 0.62]:
			_alien_box(root, "AlienStoreLock", Vector3(1.45, 0.12, 0.13), lock_local, alien_core_material, lock_angle)
	return root

func _occupy_building_with_alien(building_index: int, alien_serial: int) -> bool:
	if building_index < 0 or building_index >= buildings.size():
		return false
	var building: Dictionary = buildings[building_index]
	if bool(building.get("is_freya_home", false)):
		return false
	var was_occupied = bool(building.get("alien_occupied", false))
	var freya_was_inside_store = false
	if bool(building.get("is_store", false)) and freya != null and is_instance_valid(freya):
		var freya_pos_2d = Vector2(freya.global_position.x, freya.global_position.z)
		freya_was_inside_store = _is_inside_store_index(building_index, freya_pos_2d)
	var visual: Node3D = building.get("alien_visual_root", null)
	if not was_occupied or visual == null or not is_instance_valid(visual):
		if visual != null and is_instance_valid(visual):
			visual.queue_free()
		visual = _create_alien_building_visual(building_index)
	building["alien_occupied"] = true
	building["alien_integrity"] = maxf(float(building.get("alien_integrity", 0.0)), 1.0 if not was_occupied else ALIEN_BUILDING_MIN_INTEGRITY)
	building["alien_visual_root"] = visual
	building["alien_occupant_serial"] = alien_serial
	building["alien_occupant_count"] = maxi(0, int(building.get("alien_occupant_count", 0))) + 1
	if not was_occupied:
		building["alien_pee_exposure"] = 0.0
		building["alien_spawn_cooldown"] = rng.randf_range(4.0, 8.0)
	buildings[building_index] = building
	_update_alien_building_label(building_index)
	if freya_was_inside_store:
		var footprint: Rect2 = building.get("footprint", Rect2())
		var center = footprint.get_center()
		var layout: Dictionary = building.get("store_layout", {})
		var outside: Vector2 = layout.get("entry_outside_pos", building.get("entry_pos", center))
		var outward = outside - center
		if outward.length_squared() < 0.001:
			outward = Vector2.DOWN if bool(building.get("front_is_south", true)) else Vector2.UP
		outside += outward.normalized() * 0.85
		freya.global_position = Vector3(outside.x, freya.global_position.y, outside.y)
		active_store_index = -1
		_apply_store_focus_visuals()
	if not was_occupied:
		alien_building_occupation_count += 1
		_show_status("A nearby building has become alien! Pee along its walls to weaken it.", 1.75)
	return true

func _update_alien_building_label(building_index: int) -> void:
	if building_index < 0 or building_index >= buildings.size():
		return
	var building: Dictionary = buildings[building_index]
	var visual: Node3D = building.get("alien_visual_root", null)
	if visual == null or not is_instance_valid(visual):
		return
	var label: Label3D = visual.get_node_or_null("AlienCrown/AlienOccupantCount")
	if label == null:
		return
	var count = maxi(0, int(building.get("alien_occupant_count", 0)))
	var line = "ALIENS ×%d" % count
	if bool(building.get("is_store", false)):
		line += "\nSTORE LOCKED"
	var sources = maxi(0, int(building.get("alien_reinforcement_sources", 0)))
	if sources > 0:
		line += "\nREINFORCED ×%d" % sources
	label.text = line

func _update_alien_reinforcement_fields() -> void:
	var occupied_store_indices: Array[int] = []
	for store_index in store_building_indices:
		if store_index >= 0 and store_index < buildings.size() and bool(buildings[store_index].get("alien_occupied", false)):
			occupied_store_indices.append(store_index)
	for building_index in range(buildings.size()):
		var building: Dictionary = buildings[building_index]
		var source_count = 0
		if bool(building.get("alien_occupied", false)):
			var center: Vector2 = building.get("footprint", Rect2()).get_center()
			for store_index in occupied_store_indices:
				if store_index == building_index:
					continue
				var store_center: Vector2 = buildings[store_index].get("footprint", Rect2()).get_center()
				if center.distance_to(store_center) <= ALIEN_STOREFRONT_REINFORCEMENT_RADIUS:
					source_count += 1
		building["alien_reinforcement_sources"] = source_count
		building["alien_reinforcement_strength"] = float(source_count) * ALIEN_STOREFRONT_REINFORCEMENT_PER_SOURCE
		buildings[building_index] = building
		if bool(building.get("alien_occupied", false)):
			_update_alien_building_label(building_index)

func _update_alien_building_visuals(delta: float) -> void:
	for building_index in range(buildings.size()):
		var building: Dictionary = buildings[building_index]
		if not bool(building.get("alien_occupied", false)):
			continue
		var visual: Node3D = building.get("alien_visual_root", null)
		if visual == null or not is_instance_valid(visual):
			visual = _create_alien_building_visual(building_index)
			building["alien_visual_root"] = visual
			buildings[building_index] = building
		var integrity = clampf(float(building.get("alien_integrity", 1.0)), ALIEN_BUILDING_MIN_INTEGRITY, 1.0)
		var damage_stage = 0 if integrity > 0.66 else (1 if integrity > 0.33 else 2)
		visual.scale = Vector3.ONE * [1.0, 0.94, 0.88][damage_stage]
		var crown: Node3D = visual.get_node_or_null("AlienCrown")
		if crown != null:
			crown.rotation.y = 0.0
		var stack: Array[Node] = [visual]
		while not stack.is_empty():
			var current: Node = stack.pop_back()
			if current is GeometryInstance3D:
				(current as GeometryInstance3D).transparency = [0.0, 0.22, 0.42][damage_stage]
			for child in current.get_children():
				stack.append(child)
		_update_alien_building_label(building_index)

func _alien_occupied_building_count() -> int:
	var count = 0
	for building in buildings:
		if bool(building.get("alien_occupied", false)):
			count += 1
	return count

func _alien_total_occupant_count() -> int:
	var count = 0
	for building in buildings:
		if bool(building.get("alien_occupied", false)):
			count += maxi(0, int(building.get("alien_occupant_count", 0)))
	return count

func _update_freya_alien_discomfort(delta: float) -> void:
	if freya == null or not is_instance_valid(freya):
		freya_alien_discomfort = 0.0
		return
	var nearest_distance = ALIEN_DISCOMFORT_RADIUS
	var threat_position = freya.global_position
	for state in dogs:
		if not bool(state.get("alien_possessed", false)):
			continue
		var dog: Node3D = state.get("node", null)
		if dog == null or not is_instance_valid(dog):
			continue
		var distance = dog.global_position.distance_to(freya.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			threat_position = dog.global_position
	var target_strength = 0.0
	if nearest_distance < ALIEN_DISCOMFORT_RADIUS:
		target_strength = clampf(1.0 - (nearest_distance - 0.8) / (ALIEN_DISCOMFORT_RADIUS - 0.8), 0.0, 1.0)
	freya_alien_discomfort = lerpf(freya_alien_discomfort, target_strength, clampf(delta * 6.0, 0.0, 1.0))
	if freya.has_method("set_discomfort"):
		freya.call("set_discomfort", freya_alien_discomfort, threat_position, delta)

func _count_dogs_near_freya(radius: float) -> int:
	if freya == null:
		return 0
	var count = 0
	for d in dogs:
		var dn: Node3D = d.get("node", null)
		if dn == null or not is_instance_valid(dn):
			continue
		if dn.global_position.distance_to(freya.global_position) < radius:
			count += 1
	return count

func _node_forward_2d(node: Node3D) -> Vector2:
	if node == null or not is_instance_valid(node):
		return Vector2.RIGHT
	var f3 = -node.global_transform.basis.z
	f3.y = 0.0
	if f3.length_squared() < 0.0001:
		return Vector2.RIGHT
	return Vector2(f3.x, f3.z).normalized()

func _apply_mutual_butt_sniff(dog: Node3D, state: Dictionary, delta: float) -> Dictionary:
	var result = {
		"dir": state.get("dir", Vector3.FORWARD),
		"state": state,
		"near": dog.global_position.distance_to(freya.global_position)
	}
	if dog == null or not is_instance_valid(dog) or freya == null or not is_instance_valid(freya):
		return result

	var dog_pos = Vector2(dog.global_position.x, dog.global_position.z)
	var freya_pos = Vector2(freya.global_position.x, freya.global_position.z)
	var dog_forward = _node_forward_2d(dog)
	var freya_forward = _node_forward_2d(freya)
	var dog_butt = dog_pos - dog_forward * 0.4
	var freya_butt = freya_pos - freya_forward * 0.43

	var dog_to_freya_butt = freya_butt - dog_pos
	var freya_to_dog_butt = dog_butt - freya_pos
	if dog_to_freya_butt.length_squared() > 0.0001:
		var sniff_dir = dog_to_freya_butt.normalized()
		var sniff3 = Vector3(sniff_dir.x, 0.0, sniff_dir.y)
		result["dir"] = sniff3
		if dog.has_method("force_face_direction"):
			dog.call("force_face_direction", sniff3, delta * 4.6)
	if freya_to_dog_butt.length_squared() > 0.0001 and freya.has_method("force_face_direction"):
		var freya_sniff = freya_to_dog_butt.normalized()
		freya.call("force_face_direction", Vector3(freya_sniff.x, 0.0, freya_sniff.y), delta * 4.4)

	if dog_to_freya_butt.length_squared() > 0.0001:
		var dog_step = minf(0.9, float(state.get("speed", 2.0)) * 0.46) * delta
		var dog_target = dog_pos + dog_to_freya_butt.normalized() * dog_step
		if _is_walkable(dog_target.x, dog_target.y, DOG_COLLISION_RADIUS) and _surface_at(dog_target) != "road":
			dog.global_position.x = dog_target.x
			dog.global_position.z = dog_target.y

	result["near"] = dog.global_position.distance_to(freya.global_position)
	return result

func _update_aggressive_bark_context(delta: float, aggressive_social: bool) -> void:
	aggressive_bark_nearby_count = _count_dogs_near_freya(SOCIALIZE_RANGE + 0.05) if aggressive_social else 0
	if aggressive_social:
		var pack_target = float(max(1, aggressive_bark_nearby_count))
		aggressive_bark_pressure = lerpf(aggressive_bark_pressure, pack_target, clampf(delta * 7.0, 0.0, 1.0))
	else:
		aggressive_bark_pressure = maxf(1.0, aggressive_bark_pressure - delta * 2.4)

func _freya_is_idle_for_social_dance() -> bool:
	if freya == null:
		return false
	if freya_vomit_timer > 0.0:
		return false
	if freya_eat_timer > 0.0:
		return false
	if Input.is_action_pressed("claim"):
		return false
	var input_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var input_y = Input.get_action_strength("move_up") - Input.get_action_strength("move_down")
	return Vector2(input_x, input_y).length_squared() < 0.0001

func _update_passive_social_dance(
	delta: float,
	friendly_social: bool,
	aggressive_social: bool,
	has_target: bool,
	target_pos: Vector3
) -> void:
	if freya == null:
		freya_social_dance_phase = 0.0
		return
	if (not friendly_social) or aggressive_social or (not has_target) or (not _freya_is_idle_for_social_dance()):
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

func _ensure_interact_highlight_root() -> void:
	if dynamic_root == null:
		return
	if interact_highlight_root != null and is_instance_valid(interact_highlight_root):
		return
	interact_highlight_root = Node3D.new()
	interact_highlight_root.name = "InteractHighlights"
	dynamic_root.add_child(interact_highlight_root)

func _make_interact_highlight_node() -> MeshInstance3D:
	var marker = MeshInstance3D.new()
	var mesh = TorusMesh.new()
	mesh.inner_radius = 0.07
	mesh.outer_radius = 0.11
	marker.mesh = mesh
	marker.rotation_degrees.x = 90.0
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat = interact_highlight_material
	if mat != null:
		marker.material_override = mat
	return marker

func _mark_interactable_highlight(seen: Dictionary, id: String, world_pos: Vector3, scale_xy: float = 1.0) -> void:
	if id.is_empty():
		return
	_ensure_interact_highlight_root()
	if interact_highlight_root == null or not is_instance_valid(interact_highlight_root):
		return
	seen[id] = true
	var entry: Dictionary = interact_highlights.get(id, {})
	var marker: MeshInstance3D = entry.get("node", null)
	if marker == null or not is_instance_valid(marker):
		marker = _make_interact_highlight_node()
		interact_highlight_root.add_child(marker)
		entry["node"] = marker
		entry["phase"] = rng.randf_range(0.0, TAU)
	var phase = float(entry.get("phase", 0.0))
	var bob = INTERACT_HIGHLIGHT_BOB_AMPLITUDE * sin(world_time * INTERACT_HIGHLIGHT_BOB_SPEED + phase)
	marker.global_position = world_pos + Vector3(0.0, 0.11 + bob, 0.0)
	marker.scale = Vector3(scale_xy, scale_xy, scale_xy)
	marker.visible = true
	interact_highlights[id] = entry

func _hide_interactable_highlights() -> void:
	for id in interact_highlights.keys():
		var entry: Dictionary = interact_highlights.get(id, {})
		var marker: MeshInstance3D = entry.get("node", null)
		if marker != null and is_instance_valid(marker):
			marker.visible = false

func _update_interactable_highlights(delta: float) -> void:
	if freya == null:
		_hide_interactable_highlights()
		return
	interact_highlight_update_timer = maxf(0.0, interact_highlight_update_timer - delta)
	if interact_highlight_update_timer > 0.0:
		return
	interact_highlight_update_timer = INTERACT_HIGHLIGHT_UPDATE_INTERVAL
	var seen := {}
	var freya_pos = Vector2(freya.global_position.x, freya.global_position.z)
	if freya_home_bowl_node != null and is_instance_valid(freya_home_bowl_node) and _is_inside_freya_home(freya_pos):
		var bowl_range = HOME_DOG_BOWL_EAT_RANGE + 0.15
		if freya_pos.distance_squared_to(freya_home_bowl_position) <= bowl_range * bowl_range:
			_mark_interactable_highlight(seen, "home_dog_bowl", freya_home_bowl_node.global_position, 0.82)

	if not freya_has_stick and carried_stick == null:
		var stick_range_sq = (STICK_PICKUP_RANGE + 0.15) * (STICK_PICKUP_RANGE + 0.15)
		for item in sticks:
			var node: Node3D = item.get("node", null)
			if node == null or not is_instance_valid(node):
				continue
			var p: Vector2 = item.get("pos", Vector2(node.global_position.x, node.global_position.z))
			if freya_pos.distance_squared_to(p) > stick_range_sq:
				continue
			_mark_interactable_highlight(seen, "stick_%d" % node.get_instance_id(), node.global_position, 0.9)

	var bone_range_sq = (BONE_PICKUP_RANGE + 0.12) * (BONE_PICKUP_RANGE + 0.12)
	for item in bones:
		var node: Node3D = item.get("node", null)
		if node == null or not is_instance_valid(node):
			continue
		var p: Vector2 = item.get("pos", Vector2(node.global_position.x, node.global_position.z))
		if freya_pos.distance_squared_to(p) > bone_range_sq:
			continue
		_mark_interactable_highlight(seen, "bone_%d" % node.get_instance_id(), node.global_position, 0.88)

	var food_range_sq = 1.72 * 1.72
	for item in store_foods:
		var node: Node3D = item.get("node", null)
		if node == null or not is_instance_valid(node):
			continue
		var p: Vector2 = item.get("pos", Vector2(node.global_position.x, node.global_position.z))
		if freya_pos.distance_squared_to(p) > food_range_sq:
			continue
		_mark_interactable_highlight(seen, "food_%d" % node.get_instance_id(), node.global_position, 0.82)

	var poop_range_sq = 1.62 * 1.62
	for item in poops:
		var node: Node3D = item.get("node", null)
		if node == null or not is_instance_valid(node):
			continue
		var p: Vector2 = item.get("pos", Vector2(node.global_position.x, node.global_position.z))
		if freya_pos.distance_squared_to(p) > poop_range_sq:
			continue
		_mark_interactable_highlight(seen, "poop_%d" % node.get_instance_id(), node.global_position, 0.75)

	var claim_target = _find_nearest_claim_target()
	if bool(claim_target.get("found", false)):
		var claim_dist_sq = float(claim_target.get("dist_sq", 1000000.0))
		if claim_dist_sq <= CLAIM_RANGE * CLAIM_RANGE:
			var target_type = int(claim_target.get("type", CLAIM_TARGET_NONE))
			var target_index = int(claim_target.get("index", -1))
			if target_type != CLAIM_TARGET_NONE and target_index >= 0:
				var world = _claim_target_base_world_position(target_type, target_index)
				_mark_interactable_highlight(
					seen,
					"claim_%d_%d" % [target_type, target_index],
					world + Vector3(0.0, 0.16, 0.0),
					1.05
				)

	var dumpster_idx = _find_nearest_dumpster_index()
	if dumpster_idx >= 0 and dumpster_idx < dumpsters.size():
		var d: Dictionary = dumpsters[dumpster_idx]
		if not bool(d.get("searched", false)):
			var dnode: Node3D = d.get("node", null)
			if dnode != null and is_instance_valid(dnode):
				_mark_interactable_highlight(seen, "dumpster_%d" % dumpster_idx, dnode.global_position + Vector3(0.0, 0.14, 0.0), 1.0)

	for id in interact_highlights.keys():
		if seen.has(id):
			continue
		var entry: Dictionary = interact_highlights.get(id, {})
		var marker: MeshInstance3D = entry.get("node", null)
		if marker != null and is_instance_valid(marker):
			marker.visible = false

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

func _claim_owner_from_entry(entry: Dictionary) -> String:
	return ClaimUtilsScript.owner_from_entry(entry)

func _entry_is_claimed_by(entry: Dictionary, owner: String) -> bool:
	return ClaimUtilsScript.is_claimed_by(entry, owner)

func _entry_is_claimed(entry: Dictionary) -> bool:
	return ClaimUtilsScript.is_claimed(entry)

func _apply_claim_owner_to_entry(entry: Dictionary, owner: String) -> Dictionary:
	return ClaimUtilsScript.apply_owner(entry, owner)

func _alien_building_wall_point(building_index: int, origin: Vector2) -> Vector2:
	if building_index < 0 or building_index >= buildings.size():
		return origin
	var footprint: Rect2 = buildings[building_index].get("footprint", Rect2())
	if footprint.size.x <= 0.0 or footprint.size.y <= 0.0:
		return origin
	var point = Vector2(
		clampf(origin.x, footprint.position.x, footprint.end.x),
		clampf(origin.y, footprint.position.y, footprint.end.y)
	)
	if not footprint.has_point(origin):
		return point
	var left_dist = absf(origin.x - footprint.position.x)
	var right_dist = absf(footprint.end.x - origin.x)
	var top_dist = absf(origin.y - footprint.position.y)
	var bottom_dist = absf(footprint.end.y - origin.y)
	var nearest = minf(minf(left_dist, right_dist), minf(top_dist, bottom_dist))
	if nearest == left_dist:
		point.x = footprint.position.x
	elif nearest == right_dist:
		point.x = footprint.end.x
	elif nearest == top_dist:
		point.y = footprint.position.y
	else:
		point.y = footprint.end.y
	return point

func _find_nearest_claim_target() -> Dictionary:
	var found := false
	var best_dist_sq := CLAIM_RANGE * CLAIM_RANGE
	var best_type := CLAIM_TARGET_NONE
	var best_index := -1
	var freya_pos = Vector2(freya.global_position.x, freya.global_position.z)

	for i in range(street_poles.size()):
		var pole: Dictionary = street_poles[i]
		if _entry_is_claimed_by(pole, CLAIM_OWNER_FREYA):
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
		if _entry_is_claimed_by(tree, CLAIM_OWNER_FREYA):
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
		if _entry_is_claimed_by(hydrant, CLAIM_OWNER_FREYA):
			continue
		var pos: Vector2 = hydrant.get("pos", Vector2.ZERO)
		var dist_sq = freya_pos.distance_squared_to(pos)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_type = CLAIM_TARGET_FIRE_HYDRANT
			best_index = i
			found = true

	for i in range(mailboxes.size()):
		var mailbox: Dictionary = mailboxes[i]
		if _entry_is_claimed_by(mailbox, CLAIM_OWNER_FREYA):
			continue
		var pos: Vector2 = mailbox.get("pos", Vector2.ZERO)
		var dist_sq = freya_pos.distance_squared_to(pos)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_type = CLAIM_TARGET_MAILBOX
			best_index = i
			found = true

	for i in range(buildings.size()):
		var building: Dictionary = buildings[i]
		if not bool(building.get("alien_occupied", false)):
			continue
		if float(building.get("alien_integrity", 1.0)) <= ALIEN_BUILDING_MIN_INTEGRITY + 0.001:
			continue
		var wall_point = _alien_building_wall_point(i, freya_pos)
		var dist_sq = freya_pos.distance_squared_to(wall_point)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_type = CLAIM_TARGET_ALIEN_BUILDING
			best_index = i
			found = true

	return {"found": found, "type": best_type, "index": best_index, "dist_sq": best_dist_sq}

func _claim_target_owner(target_type: int, index: int) -> String:
	if index < 0:
		return CLAIM_OWNER_NONE
	if target_type == CLAIM_TARGET_LIGHT_POLE and index < street_poles.size():
		return _claim_owner_from_entry(street_poles[index])
	if target_type == CLAIM_TARGET_TREE and index < trees.size():
		return _claim_owner_from_entry(trees[index])
	if target_type == CLAIM_TARGET_FIRE_HYDRANT and index < fire_hydrants.size():
		return _claim_owner_from_entry(fire_hydrants[index])
	if target_type == CLAIM_TARGET_MAILBOX and index < mailboxes.size():
		return _claim_owner_from_entry(mailboxes[index])
	if target_type == CLAIM_TARGET_ALIEN_BUILDING and index < buildings.size():
		return CLAIM_OWNER_ENEMY if bool(buildings[index].get("alien_occupied", false)) else CLAIM_OWNER_NONE
	return CLAIM_OWNER_NONE

func _set_claim_owner(target_type: int, index: int, owner: String) -> void:
	if index < 0:
		return
	var owner_key = ClaimUtilsScript.normalized_owner(owner)
	if target_type == CLAIM_TARGET_LIGHT_POLE and index < street_poles.size():
		street_poles[index] = _apply_claim_owner_to_entry(street_poles[index], owner_key)
	elif target_type == CLAIM_TARGET_TREE and index < trees.size():
		trees[index] = _apply_claim_owner_to_entry(trees[index], owner_key)
	elif target_type == CLAIM_TARGET_FIRE_HYDRANT and index < fire_hydrants.size():
		fire_hydrants[index] = _apply_claim_owner_to_entry(fire_hydrants[index], owner_key)
	elif target_type == CLAIM_TARGET_MAILBOX and index < mailboxes.size():
		mailboxes[index] = _apply_claim_owner_to_entry(mailboxes[index], owner_key)
	if owner_key != CLAIM_OWNER_NONE:
		_ensure_claim_ring_for_target(target_type, index)

func _find_nearest_claim_target_owned_by(origin: Vector2, owner: String, max_range: float) -> Dictionary:
	var found := false
	var best_dist_sq := max_range * max_range
	var best_type := CLAIM_TARGET_NONE
	var best_index := -1

	for i in range(street_poles.size()):
		var pole: Dictionary = street_poles[i]
		if not _entry_is_claimed_by(pole, owner):
			continue
		var pos: Vector2 = pole.get("pos", Vector2.ZERO)
		var dist_sq = origin.distance_squared_to(pos)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_type = CLAIM_TARGET_LIGHT_POLE
			best_index = i
			found = true

	for i in range(trees.size()):
		var tree: Dictionary = trees[i]
		if not _entry_is_claimed_by(tree, owner):
			continue
		var pos: Vector2 = tree.get("pos", Vector2.ZERO)
		var dist_sq = origin.distance_squared_to(pos)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_type = CLAIM_TARGET_TREE
			best_index = i
			found = true

	for i in range(fire_hydrants.size()):
		var hydrant: Dictionary = fire_hydrants[i]
		if not _entry_is_claimed_by(hydrant, owner):
			continue
		var pos: Vector2 = hydrant.get("pos", Vector2.ZERO)
		var dist_sq = origin.distance_squared_to(pos)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_type = CLAIM_TARGET_FIRE_HYDRANT
			best_index = i
			found = true

	for i in range(mailboxes.size()):
		var mailbox: Dictionary = mailboxes[i]
		if not _entry_is_claimed_by(mailbox, owner):
			continue
		var pos: Vector2 = mailbox.get("pos", Vector2.ZERO)
		var dist_sq = origin.distance_squared_to(pos)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_type = CLAIM_TARGET_MAILBOX
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
		if not _entry_is_claimed_by(pole, CLAIM_OWNER_FREYA):
			pole["claim_progress"] = 0.0
			street_poles[index] = pole
		return
	if target_type == CLAIM_TARGET_TREE:
		if index >= trees.size():
			return
		var tree: Dictionary = trees[index]
		if not _entry_is_claimed_by(tree, CLAIM_OWNER_FREYA):
			tree["claim_progress"] = 0.0
			trees[index] = tree
		return
	if target_type == CLAIM_TARGET_FIRE_HYDRANT:
		if index >= fire_hydrants.size():
			return
		var hydrant: Dictionary = fire_hydrants[index]
		if not _entry_is_claimed_by(hydrant, CLAIM_OWNER_FREYA):
			hydrant["claim_progress"] = 0.0
			fire_hydrants[index] = hydrant
		return
	if target_type == CLAIM_TARGET_MAILBOX:
		if index >= mailboxes.size():
			return
		var mailbox: Dictionary = mailboxes[index]
		if not _entry_is_claimed_by(mailbox, CLAIM_OWNER_FREYA):
			mailbox["claim_progress"] = 0.0
			mailboxes[index] = mailbox
	# Alien integrity is persistent damage, unlike an interrupted territory claim.
	# Nothing resets when Freya stops peeing on an occupied wall.

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
		return
	if target_type == CLAIM_TARGET_MAILBOX:
		if index >= mailboxes.size():
			return
		var mailbox: Dictionary = mailboxes[index]
		var existing = mailbox.get("claim_ring", null)
		if existing != null and is_instance_valid(existing):
			return
		var node: Node3D = mailbox.get("node", null)
		if node == null or not is_instance_valid(node):
			return
		var ring = _create_claim_ring_node(0.3)
		node.add_child(ring)
		mailbox["claim_ring"] = ring
		mailboxes[index] = mailbox

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
	if target_type == CLAIM_TARGET_MAILBOX and index >= 0 and index < mailboxes.size():
		var mailbox: Dictionary = mailboxes[index]
		var node: Node3D = mailbox.get("node", null)
		if node != null and is_instance_valid(node):
			return node.global_position + Vector3(0.0, 1.1, 0.0)
		var p: Vector2 = mailbox.get("pos", Vector2.ZERO)
		return Vector3(p.x, 1.1, p.y)
	if target_type == CLAIM_TARGET_ALIEN_BUILDING and index >= 0 and index < buildings.size():
		return _alien_building_target_position(index)
	return freya.global_position + Vector3(0.0, 1.5, 0.0)

func _claim_progress_for_target(target_type: int, index: int) -> float:
	if target_type == CLAIM_TARGET_LIGHT_POLE and index >= 0 and index < street_poles.size():
		return clampf(float(street_poles[index].get("claim_progress", 0.0)), 0.0, 1.0)
	if target_type == CLAIM_TARGET_TREE and index >= 0 and index < trees.size():
		return clampf(float(trees[index].get("claim_progress", 0.0)), 0.0, 1.0)
	if target_type == CLAIM_TARGET_FIRE_HYDRANT and index >= 0 and index < fire_hydrants.size():
		return clampf(float(fire_hydrants[index].get("claim_progress", 0.0)), 0.0, 1.0)
	if target_type == CLAIM_TARGET_MAILBOX and index >= 0 and index < mailboxes.size():
		return clampf(float(mailboxes[index].get("claim_progress", 0.0)), 0.0, 1.0)
	if target_type == CLAIM_TARGET_ALIEN_BUILDING and index >= 0 and index < buildings.size():
		var integrity = clampf(float(buildings[index].get("alien_integrity", 1.0)), ALIEN_BUILDING_MIN_INTEGRITY, 1.0)
		return clampf((1.0 - integrity) / (1.0 - ALIEN_BUILDING_MIN_INTEGRITY), 0.0, 1.0)
	return 0.0

func _claim_entry_for_target(target_type: int, index: int) -> Dictionary:
	if target_type == CLAIM_TARGET_LIGHT_POLE and index >= 0 and index < street_poles.size():
		return street_poles[index]
	if target_type == CLAIM_TARGET_TREE and index >= 0 and index < trees.size():
		return trees[index]
	if target_type == CLAIM_TARGET_FIRE_HYDRANT and index >= 0 and index < fire_hydrants.size():
		return fire_hydrants[index]
	if target_type == CLAIM_TARGET_MAILBOX and index >= 0 and index < mailboxes.size():
		return mailboxes[index]
	return {}

func _set_claim_entry_for_target(target_type: int, index: int, entry: Dictionary) -> void:
	if target_type == CLAIM_TARGET_LIGHT_POLE and index >= 0 and index < street_poles.size():
		street_poles[index] = entry
	elif target_type == CLAIM_TARGET_TREE and index >= 0 and index < trees.size():
		trees[index] = entry
	elif target_type == CLAIM_TARGET_FIRE_HYDRANT and index >= 0 and index < fire_hydrants.size():
		fire_hydrants[index] = entry
	elif target_type == CLAIM_TARGET_MAILBOX and index >= 0 and index < mailboxes.size():
		mailboxes[index] = entry

func _advance_claim_progress(target_type: int, index: int, delta: float, fill_time: float) -> bool:
	var entry = _claim_entry_for_target(target_type, index)
	if entry.is_empty():
		return false
	var progress = clampf(float(entry.get("claim_progress", 0.0)) + delta / maxf(0.001, fill_time), 0.0, 1.0)
	entry["claim_progress"] = progress
	_set_claim_entry_for_target(target_type, index, entry)
	return progress >= 1.0

func _weaken_alien_building(building_index: int, delta: float) -> bool:
	if building_index < 0 or building_index >= buildings.size():
		return false
	var building: Dictionary = buildings[building_index]
	if not bool(building.get("alien_occupied", false)):
		return false
	var integrity = clampf(float(building.get("alien_integrity", 1.0)), ALIEN_BUILDING_MIN_INTEGRITY, 1.0)
	var strength_bonus = 1.0 + float(maxi(0, freya_strength - FREYA_STRENGTH_MIN_LEVEL)) * 0.12
	var reinforcement = maxf(0.0, float(building.get("alien_reinforcement_strength", 0.0)))
	var weaken_delta = delta * strength_bonus * (1.0 - ALIEN_BUILDING_MIN_INTEGRITY) / (ALIEN_BUILDING_WEAKEN_TIME * (1.0 + reinforcement))
	integrity = maxf(ALIEN_BUILDING_MIN_INTEGRITY, integrity - weaken_delta)
	building["alien_integrity"] = integrity
	building["alien_pee_exposure"] = float(building.get("alien_pee_exposure", 0.0)) + delta
	buildings[building_index] = building
	return integrity <= ALIEN_BUILDING_MIN_INTEGRITY + 0.0001

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
	if target_type == CLAIM_TARGET_MAILBOX and index >= 0 and index < mailboxes.size():
		var mailbox: Dictionary = mailboxes[index]
		var node: Node3D = mailbox.get("node", null)
		if node != null and is_instance_valid(node):
			return node.global_position
		var p: Vector2 = mailbox.get("pos", Vector2.ZERO)
		return Vector3(p.x, 0.0, p.y)
	if target_type == CLAIM_TARGET_ALIEN_BUILDING and index >= 0 and index < buildings.size():
		var freya_pos = Vector2(freya.global_position.x, freya.global_position.z)
		var wall_point = _alien_building_wall_point(index, freya_pos)
		return Vector3(wall_point.x, 0.0, wall_point.y)
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
	if target_type == CLAIM_TARGET_MAILBOX and index >= 0 and index < mailboxes.size():
		var mailbox: Dictionary = mailboxes[index]
		var radius = float(mailbox.get("radius", MAILBOX_COLLISION_RADIUS))
		return Vector3(
			center.x + toward_freya.x * (radius + 0.04),
			center.y + 0.56,
			center.z + toward_freya.y * (radius + 0.04)
		)
	if target_type == CLAIM_TARGET_ALIEN_BUILDING and index >= 0 and index < buildings.size():
		return center + Vector3(toward_freya.x * 0.04, 0.48, toward_freya.y * 0.04)
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
		_stop_claim_pee_audio()
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
				_stop_claim_pee_audio()
				_try_search_dumpster(dumpster_idx)
				return

	if not bool(target.get("found", false)):
		_reset_claim_progress(prev_type, prev_index)
		active_claim_target_type = CLAIM_TARGET_NONE
		active_claim_target_index = -1
		_stop_claim_pee_audio()
		if Input.is_action_just_pressed("claim"):
			_show_status("No tree, pole, hydrant, mailbox, alien wall, or dumpster in range", 0.95)
		return

	var target_type = int(target.get("type", CLAIM_TARGET_NONE))
	var target_index = int(target.get("index", -1))
	if prev_type != CLAIM_TARGET_NONE and (prev_type != target_type or prev_index != target_index):
		_reset_claim_progress(prev_type, prev_index)

	active_claim_target_type = target_type
	active_claim_target_index = target_index
	_increase_freya_hunger(delta, HUNGER_ACTIVE_ACTION_PER_SEC)
	_update_claim_pee_dribble(delta)
	if target_type == CLAIM_TARGET_ALIEN_BUILDING:
		var critically_weakened = _weaken_alien_building(target_index, delta)
		if not critically_weakened:
			return
		active_claim_target_type = CLAIM_TARGET_NONE
		active_claim_target_index = -1
		_stop_claim_pee_audio()
		_show_status("Alien hold critically weakened — ready for future fortification.", 1.55)
		return

	var claimed_now = _advance_claim_progress(target_type, target_index, delta, CLAIM_FILL_TIME)
	if claimed_now:
		_set_claim_owner(target_type, target_index, CLAIM_OWNER_FREYA)

	if not claimed_now:
		return

	active_claim_target_type = CLAIM_TARGET_NONE
	active_claim_target_index = -1
	_stop_claim_pee_audio()
	if target_type == CLAIM_TARGET_LIGHT_POLE:
		if _claimed_light_pole_count() >= OBJECTIVE_CLAIM_TARGET:
			_show_status("Objective complete: Claim 10 light poles", 1.35)
		else:
			_show_status("Light pole claimed by Freya!", 0.95)
	elif target_type == CLAIM_TARGET_TREE:
		if _claimed_tree_count() >= OBJECTIVE_CLAIM_TARGET:
			_show_status("Objective complete: Claim 10 trees", 1.35)
		else:
			_show_status("Tree claimed by Freya!", 0.95)
	elif target_type == CLAIM_TARGET_FIRE_HYDRANT:
		if _claimed_fire_hydrant_count() >= OBJECTIVE_HYDRANT_TARGET:
			_show_status("Objective complete: Claim 8 fire hydrants", 1.35)
		else:
			_show_status("Fire hydrant claimed by Freya!", 0.95)
	elif target_type == CLAIM_TARGET_MAILBOX:
		_show_status("Mailbox claimed by Freya!", 0.95)

func _update_claim_rings(delta: float = 0.016) -> void:
	claim_ring_update_timer = maxf(0.0, claim_ring_update_timer - delta)
	if claim_ring_update_timer > 0.0:
		return
	claim_ring_update_timer = CLAIM_RING_UPDATE_INTERVAL
	var pulse_base = 0.99 + 0.06 * (0.5 + 0.5 * sin(world_time * CLAIM_RING_PULSE_SPEED))

	for i in range(street_poles.size()):
		var pole: Dictionary = street_poles[i]
		var ring = pole.get("claim_ring", null)
		if ring == null or not is_instance_valid(ring):
			continue
		var ring_node := ring as Node3D
		var owner = _claim_owner_from_entry(pole)
		var claimed = _entry_is_claimed(pole)
		ring_node.visible = claimed
		if not claimed:
			continue
		var pole_ring_mesh := ring as MeshInstance3D
		if pole_ring_mesh != null:
			pole_ring_mesh.material_override = claim_ring_enemy_material if owner == CLAIM_OWNER_ENEMY else claim_ring_material
		var pulse = pulse_base + 0.018 * sin(world_time * 1.45 + float(i) * 0.41)
		ring_node.scale = Vector3(pulse, 1.0, pulse)

	for i in range(trees.size()):
		var tree: Dictionary = trees[i]
		var ring = tree.get("claim_ring", null)
		if ring == null or not is_instance_valid(ring):
			continue
		var ring_node := ring as Node3D
		var owner = _claim_owner_from_entry(tree)
		var claimed = _entry_is_claimed(tree)
		ring_node.visible = claimed
		if not claimed:
			continue
		var tree_ring_mesh := ring as MeshInstance3D
		if tree_ring_mesh != null:
			tree_ring_mesh.material_override = claim_ring_enemy_material if owner == CLAIM_OWNER_ENEMY else claim_ring_material
		var pulse = pulse_base + 0.018 * sin(world_time * 1.38 + float(i) * 0.37)
		ring_node.scale = Vector3(pulse, 1.0, pulse)

	for i in range(fire_hydrants.size()):
		var hydrant: Dictionary = fire_hydrants[i]
		var ring = hydrant.get("claim_ring", null)
		if ring == null or not is_instance_valid(ring):
			continue
		var ring_node := ring as Node3D
		var owner = _claim_owner_from_entry(hydrant)
		var claimed = _entry_is_claimed(hydrant)
		ring_node.visible = claimed
		if not claimed:
			continue
		var hydrant_ring_mesh := ring as MeshInstance3D
		if hydrant_ring_mesh != null:
			hydrant_ring_mesh.material_override = claim_ring_enemy_material if owner == CLAIM_OWNER_ENEMY else claim_ring_material
		var pulse = pulse_base + 0.02 * sin(world_time * 1.52 + float(i) * 0.35)
		ring_node.scale = Vector3(pulse, 1.0, pulse)

	for i in range(mailboxes.size()):
		var mailbox: Dictionary = mailboxes[i]
		var ring = mailbox.get("claim_ring", null)
		if ring == null or not is_instance_valid(ring):
			continue
		var ring_node := ring as Node3D
		var owner = _claim_owner_from_entry(mailbox)
		var claimed = _entry_is_claimed(mailbox)
		ring_node.visible = claimed
		if not claimed:
			continue
		var mailbox_ring_mesh := ring as MeshInstance3D
		if mailbox_ring_mesh != null:
			mailbox_ring_mesh.material_override = claim_ring_enemy_material if owner == CLAIM_OWNER_ENEMY else claim_ring_material
		var pulse = pulse_base + 0.019 * sin(world_time * 1.47 + float(i) * 0.33)
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
	elif active_claim_target_type == CLAIM_TARGET_MAILBOX:
		claim_meter_label.text = "Claiming Mailbox"
	elif active_claim_target_type == CLAIM_TARGET_ALIEN_BUILDING:
		var building: Dictionary = buildings[active_claim_target_index]
		var occupants = maxi(0, int(building.get("alien_occupant_count", 0)))
		var reinforcement = maxi(0, int(building.get("alien_reinforcement_sources", 0)))
		claim_meter_label.text = "Alien hold · %d inside" % occupants
		if reinforcement > 0:
			claim_meter_label.text = "Aliens %d · Reinforced ×%d" % [occupants, reinforcement]
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
		if _try_eat_home_bowl(false):
			return
		if _try_eat_bone(false):
			return
		if _try_eat_store_food(false):
			return
		if _try_eat_poop(false):
			return
		_drop_carried_stick()
		return
	freya_has_stick = false
	if _try_eat_home_bowl(false):
		return
	if _try_pickup_stick():
		return
	if _try_eat_bone(false):
		return
	if _try_eat_store_food(false):
		return
	_try_eat_poop(true)

func _try_eat_home_bowl(show_fail_status: bool = false) -> bool:
	if freya == null or not is_instance_valid(freya) or freya_home_bowl_node == null or not is_instance_valid(freya_home_bowl_node):
		if show_fail_status:
			_show_status("Freya's bowl is unavailable", 0.8)
		return false
	var freya_pos = Vector2(freya.global_position.x, freya.global_position.z)
	if not _is_inside_freya_home(freya_pos) or freya_pos.distance_to(freya_home_bowl_position) > HOME_DOG_BOWL_EAT_RANGE:
		if show_fail_status:
			_show_status("Freya is not near her bowl", 0.8)
		return false

	freya_hunger = 0.0
	_trigger_freya_eat_feedback("food")
	_show_status("Ate dinner from Freya's bowl — Hunger 0%", 1.15)
	return true

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

func _trigger_freya_eat_feedback(kind: String) -> void:
	var eat_duration = 0.42
	match kind:
		"poop":
			eat_duration = 0.56
		"bone":
			eat_duration = 0.34
		"food":
			eat_duration = 0.44
		_:
			eat_duration = 0.42
	freya_eat_timer = maxf(freya_eat_timer, eat_duration)
	if freya != null and is_instance_valid(freya):
		var facing = -freya.global_transform.basis.z
		facing.y = 0.0
		if facing.length_squared() < 0.0001:
			facing = Vector3.FORWARD
		# Kick the animation this frame so eating reads immediately on input.
		freya.update_motion(0.02, facing.normalized(), false, false, true)
	_play_eat_sound(kind)

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

	freya_strength = clampi(freya_strength + 1, FREYA_STRENGTH_MIN_LEVEL, FREYA_STRENGTH_MAX_LEVEL)
	freya_hunger = clamp(freya_hunger - 3.0, 0.0, 100.0)
	_trigger_freya_eat_feedback("bone")
	_show_status("Crunch! Strength level %d/%d" % [freya_strength, FREYA_STRENGTH_MAX_LEVEL], 0.95)
	return true

func _try_eat_store_food(show_fail_status: bool = false) -> bool:
	var best_idx = -1
	var best_d = 9999.0
	var freya_pos = Vector2(freya.global_position.x, freya.global_position.z)
	for i in range(store_foods.size()):
		var item: Dictionary = store_foods[i]
		var store_index = int(item.get("store_index", -1))
		if store_index >= 0 and store_index < buildings.size() and bool(buildings[store_index].get("alien_occupied", false)):
			continue
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
	_trigger_freya_eat_feedback("food")
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
	_trigger_freya_eat_feedback("poop")
	_show_status("Yum...", 0.7)
	return true

func _try_vomit() -> void:
	if freya_vomit < 100.0:
		_show_status("Vomit meter not full", 0.9)
		return
	freya_vomit = 0.0

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
	var spray = _create_vomit_spray_node(vomit_origin, puddle.position + Vector3(0.0, 0.04, 0.0))
	if spray != null:
		dynamic_root.add_child(spray)
		vomit_sprays.append({"node": spray, "ttl": 0.7})

	freya_vomit_timer = 1.05
	_play_vomit_sound()
	if hit_dog and not objective_puke_on_dog_complete:
		objective_puke_on_dog_complete = true
		_show_status("Objective complete: Puke on another dog", 1.4)
	elif hit_dog:
		_show_status("Direct hit!", 0.9)
	else:
		_show_status("Bleaaargh!", 1.0)

func _freya_vomit_origin_and_direction() -> Dictionary:
	var body_forward = -freya.global_transform.basis.z
	body_forward.y = 0.0
	if body_forward.length_squared() < 0.0001:
		body_forward = Vector3.FORWARD
	body_forward = body_forward.normalized()

	var head_pos = freya.global_position + Vector3(0.0, 0.9, 0.0)
	if freya != null and freya.has_method("head_world_position"):
		head_pos = freya.call("head_world_position")

	var origin = head_pos + body_forward * 0.26 + Vector3(0.0, -0.07, 0.0)
	var forward = body_forward
	if freya != null and freya.has_method("mouth_world_position"):
		var candidate_origin: Vector3 = freya.call("mouth_world_position")
		var from_head = candidate_origin - head_pos
		var from_body = candidate_origin - freya.global_position
		var from_head_flat = Vector2(from_head.x, from_head.z)
		var from_body_flat = Vector2(from_body.x, from_body.z)
		if from_head.length() < 0.9 and from_head_flat.length_squared() > 0.0001:
			var mouth_dir = Vector3(from_head_flat.x, 0.0, from_head_flat.y).normalized()
			var body_to_mouth_dir = Vector3(from_body_flat.x, 0.0, from_body_flat.y).normalized()
			# Reject anchors that are side/rear-facing to avoid butt-spawned vomit.
			if mouth_dir.dot(body_forward) > 0.24 and body_to_mouth_dir.dot(body_forward) > 0.12:
				origin = candidate_origin
				if mouth_dir.dot(body_forward) > 0.38:
					forward = mouth_dir

	origin.y = maxf(origin.y, freya.global_position.y + 0.3)
	return {"origin": origin, "forward": forward.normalized()}

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

func _create_vomit_spray_node(start_pos: Vector3, end_pos: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "VomitSpray"
	var control = (start_pos + end_pos) * 0.5 + Vector3.UP * 0.14
	var segments = 6
	for i in range(segments):
		var t0 = float(i) / float(segments)
		var t1 = float(i + 1) / float(segments)
		var p0 = _quadratic_point(start_pos, control, end_pos, t0)
		var p1 = _quadratic_point(start_pos, control, end_pos, t1)
		var delta = p1 - p0
		var len = delta.length()
		if len < 0.001:
			continue
		var seg = MeshInstance3D.new()
		var mesh = CylinderMesh.new()
		var width = lerpf(0.05, 0.026, t0)
		mesh.top_radius = width * 0.72
		mesh.bottom_radius = width
		mesh.height = len
		seg.mesh = mesh
		var dir = delta / len
		var x_axis = Vector3.UP.cross(dir)
		if x_axis.length_squared() < 0.0001:
			x_axis = Vector3.RIGHT
		x_axis = x_axis.normalized()
		var z_axis = dir.cross(x_axis).normalized()
		seg.transform = Transform3D(Basis(x_axis, dir, z_axis).orthonormalized(), (p0 + p1) * 0.5)
		seg.material_override = vomit_material_a if i % 2 == 0 else vomit_material_b
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(seg)

	var chunk_count = 8
	for i in range(chunk_count):
		var chunk = MeshInstance3D.new()
		var chunk_mesh = SphereMesh.new()
		chunk_mesh.radius = rng.randf_range(0.018, 0.042)
		chunk_mesh.height = chunk_mesh.radius * 2.0
		chunk.mesh = chunk_mesh
		var t = rng.randf_range(0.1, 0.95)
		var base = _quadratic_point(start_pos, control, end_pos, t)
		var spread = Vector3(rng.randf_range(-0.04, 0.04), rng.randf_range(-0.015, 0.03), rng.randf_range(-0.04, 0.04))
		chunk.position = base + spread
		chunk.scale = Vector3(rng.randf_range(0.7, 1.35), rng.randf_range(0.5, 1.12), rng.randf_range(0.7, 1.35))
		chunk.material_override = vomit_material_b if i % 3 == 0 else vomit_material_a
		chunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(chunk)
	return root

func _update_vomit_sprays(delta: float) -> void:
	for i in range(vomit_sprays.size() - 1, -1, -1):
		var spray: Dictionary = vomit_sprays[i]
		spray["ttl"] = float(spray.get("ttl", 0.0)) - delta
		var node: Node3D = spray.get("node", null)
		if float(spray["ttl"]) <= 0.0 or node == null or not is_instance_valid(node):
			if node != null and is_instance_valid(node):
				node.queue_free()
			vomit_sprays.remove_at(i)
			continue
		var fade = clampf(float(spray["ttl"]) / 0.7, 0.0, 1.0)
		var pulse = 0.92 + 0.12 * sin(world_time * 17.0 + float(i) * 1.3)
		node.scale = Vector3.ONE * (fade * pulse)
		vomit_sprays[i] = spray

func _update_poops(delta: float) -> void:
	poop_spawn_timer -= delta
	if poop_spawn_timer <= 0.0:
		poop_spawn_timer = rng.randf_range(1.8, 3.8)
		if poops.size() < 48:
			_spawn_poop(false)

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
		var t = world_time * 1.9 + phase
		var bob = 0.014 * sin(t * 1.6)
		var glide = (0.5 + 0.5 * sin(t * 0.92)) * 0.055
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
	if bool(b.get("alien_occupied", false)):
		return false
	var interior_rect: Rect2 = b.get("store_interior_rect", Rect2())
	if interior_rect.size.x > 0.0 and interior_rect.size.y > 0.0 and interior_rect.grow(0.18).has_point(p):
		return true
	var fp: Rect2 = b.get("footprint", Rect2())
	if fp.size.x <= 0.0 or fp.size.y <= 0.0:
		return false
	if fp.grow(-0.04).has_point(p):
		var blockers = b.get("store_walk_blockers", [])
		return not _point_in_rect_list(blockers, p, 0.1)
	return false

func _is_inside_store_interior(store_idx: int, p: Vector2) -> bool:
	if store_idx < 0 or store_idx >= buildings.size():
		return false
	var b: Dictionary = buildings[store_idx]
	if bool(b.get("alien_occupied", false)):
		return false
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
	return _store_index_containing_freya()

func _store_index_containing_freya() -> int:
	if freya == null or store_building_indices.is_empty():
		return -1
	var p = Vector2(freya.global_position.x, freya.global_position.z)
	for idx in store_building_indices:
		if idx < 0 or idx >= buildings.size():
			continue
		if _is_inside_store_index(idx, p):
			return idx
	return -1

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
		var shell_override: Node3D = b.get("store_shell_root", null)
		var interior_root: Node3D = b.get("store_interior_root", null)
		var is_active = inside_store and idx == active_idx
		var has_override_shell = shell_override != null and is_instance_valid(shell_override)
		if shell != null and is_instance_valid(shell):
			shell.visible = (not has_override_shell) and (not is_active)
		if has_override_shell:
			shell_override.visible = not is_active
		var roof_parts: Array = b.get("roof_parts", [])
		for part in roof_parts:
			if part is Node3D and is_instance_valid(part as Node3D):
				(part as Node3D).visible = (not is_active) and (not has_override_shell)
		if interior_root != null and is_instance_valid(interior_root):
			# Furnishings remain visible through the true glazed openings. The active
			# shell still hides when Freya enters so the camera gets a clean cutaway.
			interior_root.visible = true
	for food in store_foods:
		var food_node: Node3D = food.get("node", null)
		if food_node != null and is_instance_valid(food_node):
			var food_store_index = int(food.get("store_index", -1))
			var store_available = food_store_index >= 0 and food_store_index < buildings.size() and not bool(buildings[food_store_index].get("alien_occupied", false))
			food_node.visible = inside_store and store_available and food_store_index == active_idx

func _update_store_focus(delta: float) -> void:
	store_focus_timer = maxf(0.0, store_focus_timer - delta)
	if store_focus_timer > 0.0:
		return
	store_focus_timer = STORE_FOCUS_UPDATE_INTERVAL
	var store_idx = -1
	if freya != null:
		var p = Vector2(freya.global_position.x, freya.global_position.z)
		store_idx = _store_index_for_visual_focus(p)
		var inside_home_now = _is_inside_freya_home(p)
		if inside_home_now != freya_inside_home:
			_apply_freya_home_focus_visuals()
			if inside_home_now:
				_show_status("Freya's home — Ryah Diane is inside", 1.35)
	if store_idx == active_store_index:
		return
	active_store_index = store_idx
	_apply_store_focus_visuals()

func _has_back_alley_rowhouse_corridor() -> bool:
	var best_pair_score = 0
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
			if absf(north_back - north_edge) <= 0.42 and not bool(b.get("front_is_south", true)):
				north_count += 1

			var south_back = fp.position.y
			if absf(south_back - south_edge) <= 0.42 and bool(b.get("front_is_south", false)):
				south_count += 1

			if north_count >= 3 and south_count >= 3:
				return true
		best_pair_score = maxi(best_pair_score, mini(north_count, south_count))
	return best_pair_score >= 2

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
		if bool(b.get("batched_details", false)):
			# The ground-level wall/foundation meshes live in the verified world-space batch.
			continue
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

func _count_box_meshes(root: Node) -> int:
	if root == null:
		return 0
	var count = 0
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh is BoxMesh:
			count += 1
		for child in n.get_children():
			stack.append(child)
	return count

func _count_nodes_named(root: Node, name_fragment: String) -> int:
	if root == null:
		return 0
	var count = 0
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.name.contains(name_fragment):
			count += 1
		for child in n.get_children():
			stack.append(child)
	return count

func _count_transparent_geometry(root: Node) -> int:
	if root == null:
		return 0
	var count = 0
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is GeometryInstance3D:
			var material: Material = (n as GeometryInstance3D).material_override
			if material is BaseMaterial3D and (material as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				count += 1
		for child in n.get_children():
			stack.append(child)
	return count

func _node_visual_dimensions(node: Node3D) -> Vector3:
	if node == null or not is_instance_valid(node):
		return Vector3.ZERO
	if node.has_method("visual_dimensions"):
		var dims_value = node.call("visual_dimensions")
		if dims_value is Vector3:
			return dims_value

	var node_stack: Array[Node3D] = [node]
	var xf_stack: Array[Transform3D] = [Transform3D.IDENTITY]
	var has_point := false
	var min_v := Vector3.ZERO
	var max_v := Vector3.ZERO
	while not node_stack.is_empty():
		var n: Node3D = node_stack.pop_back()
		var xf: Transform3D = xf_stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.mesh != null:
				var local_aabb := mi.mesh.get_aabb().merge(mi.get_aabb())
				if local_aabb.size.x > 0.000001 and local_aabb.size.y > 0.000001 and local_aabb.size.z > 0.000001:
					for corner in _aabb_corners(local_aabb):
						var p = xf * corner
						if not has_point:
							min_v = p
							max_v = p
							has_point = true
						else:
							min_v = min_v.min(p)
							max_v = max_v.max(p)
		for c in n.get_children():
			if c is Node3D:
				var child := c as Node3D
				node_stack.append(child)
				xf_stack.append(xf * child.transform)

	if not has_point:
		return Vector3.ZERO
	return max_v - min_v

func _find_alien_transfer_index_by_serial(serial: int) -> int:
	for transfer_index in range(alien_transfers.size()):
		if int(alien_transfers[transfer_index].get("serial", -1)) == serial:
			return transfer_index
	return -1

func _remove_alien_transfer_by_serial(serial: int) -> void:
	var transfer_index = _find_alien_transfer_index_by_serial(serial)
	if transfer_index < 0:
		return
	var node: Node3D = alien_transfers[transfer_index].get("node", null)
	if node != null and is_instance_valid(node):
		node.queue_free()
	alien_transfers.remove_at(transfer_index)

func _append_army_collar_validation_failures(failures: Array[String]) -> void:
	var checked_breeds := {}
	for state in dogs:
		var breed_id = str(state.get("breed_id", "unknown"))
		if checked_breeds.has(breed_id):
			continue
		var dog: Node3D = state.get("node", null)
		if dog == null or not is_instance_valid(dog) or not dog.has_method("set_army_aligned"):
			continue
		checked_breeds[breed_id] = true
		var saved_alignment = bool(state.get("army_aligned", false))
		dog.call("set_army_aligned", true)
		if _count_nodes_named(dog, "ArmyCamoCollar") != 1:
			failures.append("target_army_collar_root_missing_%s" % breed_id)
		elif not dog.has_method("army_collar_is_neck_mounted") or not bool(dog.call("army_collar_is_neck_mounted")):
			failures.append("target_army_collar_not_neck_mounted_%s" % breed_id)
		elif not dog.has_method("army_collar_is_clearly_visible") or not bool(dog.call("army_collar_is_clearly_visible")):
			failures.append("target_army_collar_not_readable_%s" % breed_id)
		var plate_count = _count_nodes_named(dog, "ArmyCollarCamoPlate")
		var edge_count = _count_nodes_named(dog, "ArmyCollarEdgeBand")
		var buckle_count = _count_nodes_named(dog, "ArmyCollarBuckle")
		if plate_count < 12 or edge_count != 2 or buckle_count < 2:
			failures.append("target_army_collar_visual_components_missing_%s_%d_%d_%d" % [breed_id, plate_count, edge_count, buckle_count])
		dog.call("set_army_aligned", saved_alignment)
	if checked_breeds.size() < 8:
		failures.append("target_army_collar_breed_coverage_low_%d" % checked_breeds.size())

func _append_mailbox_claim_validation_failures(failures: Array[String]) -> void:
	var expected_mailboxes = 0
	for building in buildings:
		if not bool(building.get("is_store", false)):
			expected_mailboxes += 1
	if mailboxes.size() != expected_mailboxes or mailboxes.is_empty():
		failures.append("target_mailbox_population_bad_%d_expected_%d" % [mailboxes.size(), expected_mailboxes])
		return
	var mailbox_batch = static_root.get_node_or_null("BatchedMailboxes")
	if mailbox_batch == null or mailbox_batch.get_child_count() < 2:
		failures.append("target_mailbox_batched_visuals_missing")

	for mailbox_index in range(mailboxes.size()):
		var mailbox: Dictionary = mailboxes[mailbox_index]
		var node: Node3D = mailbox.get("node", null)
		var pos: Vector2 = mailbox.get("pos", Vector2.ZERO)
		if node == null or not is_instance_valid(node) or Vector2(node.global_position.x, node.global_position.z).distance_to(pos) > 0.001:
			failures.append("target_mailbox_anchor_invalid_%d" % mailbox_index)
			break
		if not mailbox.has("claimed_by") or not mailbox.has("claim_progress") or float(mailbox.get("radius", 0.0)) < 0.2:
			failures.append("target_mailbox_claim_schema_invalid_%d" % mailbox_index)
			break

	var mailbox_index = 0
	var saved_mailbox: Dictionary = mailboxes[mailbox_index].duplicate()
	var mailbox_pos: Vector2 = saved_mailbox.get("pos", Vector2.ZERO)
	var saved_freya_pos = freya.global_position
	var saved_hunger = freya_hunger
	var saved_type = active_claim_target_type
	var saved_index = active_claim_target_index
	var saved_ring_timer = claim_ring_update_timer
	freya.global_position = Vector3(mailbox_pos.x, 0.0, mailbox_pos.y)
	var clean_mailbox: Dictionary = saved_mailbox.duplicate()
	clean_mailbox["claimed"] = false
	clean_mailbox["claimed_by"] = CLAIM_OWNER_NONE
	clean_mailbox["claim_progress"] = 0.0
	clean_mailbox["claim_ring"] = null
	mailboxes[mailbox_index] = clean_mailbox
	var nearest = _find_nearest_claim_target()
	if not bool(nearest.get("found", false)) or int(nearest.get("type", CLAIM_TARGET_NONE)) != CLAIM_TARGET_MAILBOX or int(nearest.get("index", -1)) != mailbox_index:
		failures.append("target_mailbox_not_selectable_for_claim")

	var base_pos = _claim_target_base_world_position(CLAIM_TARGET_MAILBOX, mailbox_index)
	var pee_pos = _claim_target_pee_world_position(CLAIM_TARGET_MAILBOX, mailbox_index)
	var radial_offset = Vector2(pee_pos.x - base_pos.x, pee_pos.z - base_pos.z).length()
	if absf(pee_pos.y - 0.56) > 0.01 or radial_offset < MAILBOX_COLLISION_RADIUS + 0.03:
		failures.append("target_mailbox_pee_impact_bad")

	Input.action_press("claim")
	_update_claiming(CLAIM_FILL_TIME + 0.05)
	Input.action_release("claim")
	if not _entry_is_claimed_by(mailboxes[mailbox_index], CLAIM_OWNER_FREYA):
		failures.append("target_mailbox_claim_progression_failed")
	var ring: MeshInstance3D = mailboxes[mailbox_index].get("claim_ring", null)
	claim_ring_update_timer = 0.0
	_update_claim_rings(0.1)
	if ring == null or not is_instance_valid(ring) or not ring.visible or ring.material_override != claim_ring_material:
		failures.append("target_mailbox_freya_ring_missing")
	var minimap_points = _collect_claimed_minimap_points()
	if not (minimap_points.get("mailboxes_freya", PackedVector2Array()) as PackedVector2Array).has(mailbox_pos):
		failures.append("target_mailbox_freya_minimap_marker_missing")

	_set_claim_owner(CLAIM_TARGET_MAILBOX, mailbox_index, CLAIM_OWNER_ENEMY)
	claim_ring_update_timer = 0.0
	_update_claim_rings(0.1)
	nearest = _find_nearest_claim_target()
	if ring == null or ring.material_override != claim_ring_enemy_material or int(nearest.get("type", CLAIM_TARGET_NONE)) != CLAIM_TARGET_MAILBOX:
		failures.append("target_mailbox_enemy_reclaim_state_bad")
	minimap_points = _collect_claimed_minimap_points()
	if not (minimap_points.get("mailboxes_enemy", PackedVector2Array()) as PackedVector2Array).has(mailbox_pos):
		failures.append("target_mailbox_enemy_minimap_marker_missing")

	var interrupted: Dictionary = mailboxes[mailbox_index]
	interrupted["claimed"] = false
	interrupted["claimed_by"] = CLAIM_OWNER_NONE
	interrupted["claim_progress"] = 0.5
	mailboxes[mailbox_index] = interrupted
	_reset_claim_progress(CLAIM_TARGET_MAILBOX, mailbox_index)
	if float(mailboxes[mailbox_index].get("claim_progress", 1.0)) > 0.001:
		failures.append("target_mailbox_interrupted_progress_not_reset")

	if ring != null and is_instance_valid(ring):
		ring.queue_free()
	mailboxes[mailbox_index] = saved_mailbox
	freya.global_position = saved_freya_pos
	freya_hunger = saved_hunger
	active_claim_target_type = saved_type
	active_claim_target_index = saved_index
	claim_ring_update_timer = saved_ring_timer
	_hide_claim_meter()

func _append_alien_validation_failures(failures: Array[String]) -> void:
	# The expelled/storefront alien must be an actual opaque voxel character, not
	# the legacy hovering orb, and its walk cycle must articulate paired limbs.
	var imp_visual = _create_alien_transfer_visual()
	dynamic_root.add_child(imp_visual)
	var imp_mesh_count = _count_mesh_instances(imp_visual)
	var imp_box_count = _count_box_meshes(imp_visual)
	if imp_visual.name != "AlienImp" or imp_visual.get_node_or_null("AlienRig/AlienBody") == null or imp_visual.get_node_or_null("AlienRig/AlienHeadPivot/AlienHead") == null:
		failures.append("target_alien_imp_body_hierarchy_missing")
	if _count_nodes_named(imp_visual, "Eye") != 2 or _count_nodes_named(imp_visual, "ArmPivot") != 2 or _count_nodes_named(imp_visual, "LegPivot") != 2:
		failures.append("target_alien_imp_articulated_limbs_or_eyes_missing")
	if _count_nodes_named(imp_visual, "HornPivot") != 2 or _count_nodes_named(imp_visual, "Tail") < 4 or _count_nodes_named(imp_visual, "Foot") != 2:
		failures.append("target_alien_imp_horns_tail_or_feet_missing")
	if imp_mesh_count < 24 or imp_box_count != imp_mesh_count:
		failures.append("target_alien_imp_not_voxel_character_%d_of_%d" % [imp_box_count, imp_mesh_count])
	if _count_nodes_named(imp_visual, "OrbitRing") > 0 or _count_nodes_named(imp_visual, "Tendril") > 0:
		failures.append("target_alien_legacy_floating_parts_present")
	if _count_transparent_geometry(imp_visual) > 0:
		failures.append("target_alien_imp_body_not_solid")
	var imp_dims = _node_visual_dimensions(imp_visual)
	if ALIEN_VISUAL_SCALE < 0.8 or ALIEN_VISUAL_SCALE > 0.88:
		failures.append("target_alien_imp_scale_constant_bad_%.2f" % ALIEN_VISUAL_SCALE)
	if imp_dims.y < 1.05 or imp_dims.y > 1.22 or imp_dims.x < 0.44 or imp_dims.z < 0.65:
		failures.append("target_alien_imp_scale_bad_%.2fx%.2fx%.2f" % [imp_dims.x, imp_dims.y, imp_dims.z])
	var imp_rig: Node3D = imp_visual.get_node_or_null("AlienRig")
	var imp_left_leg: Node3D = imp_visual.get_node_or_null("AlienRig/AlienLeftLegPivot")
	var imp_right_leg: Node3D = imp_visual.get_node_or_null("AlienRig/AlienRightLegPivot")
	var imp_left_arm: Node3D = imp_visual.get_node_or_null("AlienRig/AlienLeftArmPivot")
	var imp_root_y = imp_visual.global_position.y
	var imp_phase = _update_alien_character_pose(imp_visual, 0.1, Vector3(0.4, 0.0, -1.0).normalized(), 0.4, 0.0)
	if imp_left_leg == null or imp_right_leg == null or imp_left_arm == null or absf(imp_left_leg.rotation.x) < 0.05 or absf(imp_left_arm.rotation.x) < 0.04:
		failures.append("target_alien_imp_walk_pose_missing")
	elif absf(imp_left_leg.rotation.x + imp_right_leg.rotation.x) > 0.001:
		failures.append("target_alien_imp_legs_not_counter_swinging")
	if imp_rig == null or imp_rig.position.y <= 0.0 or absf(imp_visual.global_position.y - imp_root_y) > 0.001 or imp_phase <= 0.0:
		failures.append("target_alien_imp_gait_not_ground_rooted")
	imp_visual.queue_free()

	if FREE_ALIEN_ROAM_SPEED <= 2.95 or FREE_ALIEN_ROAM_SPEED > FREYA_BASE_SPEED:
		failures.append("target_alien_roam_speed_not_brisk_%.2f" % FREE_ALIEN_ROAM_SPEED)
	if ALIEN_TRAVEL_SPEED <= FREYA_BASE_SPEED or ALIEN_TRAVEL_SPEED >= FREYA_BASE_SPEED * FREYA_RUN_MULT:
		failures.append("target_alien_travel_speed_not_fast_bounded_%.2f" % ALIEN_TRAVEL_SPEED)

	# A deliberately large step toward a solid building must be substepped and
	# remain on walkable ground; the alien may slide/steer but never tunnel.
	var collision_test_index = -1
	var collision_start = Vector3.ZERO
	for building_index in range(buildings.size()):
		var collision_building: Dictionary = buildings[building_index]
		if bool(collision_building.get("enterable", false)):
			continue
		var collision_center: Vector2 = collision_building.get("footprint", Rect2()).get_center()
		var candidate_start = _alien_building_approach_position(building_index, collision_center + Vector2(100.0, 0.0))
		if _is_walkable(candidate_start.x, candidate_start.z, ALIEN_COLLISION_RADIUS):
			collision_test_index = building_index
			collision_start = candidate_start
			break
	if collision_test_index < 0:
		failures.append("target_alien_collision_probe_building_missing")
	else:
		var collision_probe = _create_alien_transfer_visual()
		dynamic_root.add_child(collision_probe)
		collision_probe.global_position = collision_start
		var collision_center: Vector2 = buildings[collision_test_index].get("footprint", Rect2()).get_center()
		var collision_direction = Vector3(collision_center.x - collision_start.x, 0.0, collision_center.y - collision_start.z)
		var collision_delta = 0.7
		var collision_moved = _move_alien_with_collisions(collision_probe, collision_direction, ALIEN_TRAVEL_SPEED, collision_delta, 1.0)
		var collision_end = Vector2(collision_probe.global_position.x, collision_probe.global_position.z)
		if collision_moved.length() > ALIEN_TRAVEL_SPEED * collision_delta + 0.001:
			failures.append("target_alien_collision_speed_cap_bypassed")
		if absf(collision_probe.global_position.y) > 0.001 or not _is_walkable(collision_end.x, collision_end.y, ALIEN_COLLISION_RADIUS):
			failures.append("target_alien_collision_or_grounding_bypassed")
		if _point_in_blocking_building(collision_end, ALIEN_COLLISION_RADIUS + BUILDING_COLLISION_PAD):
			failures.append("target_alien_tunneled_into_building")
		collision_probe.queue_free()

	var expected_possessed = int(round(float(dogs.size()) * ALIEN_POSSESSION_CHANCE))
	var origin_possessed = 0
	var current_possessed = 0
	var possessed_styles := {}
	var ordinary_styles := {}
	var cosmetic_styles := {}
	var cosmetic_colors := {}
	var possessed_test_index = -1
	for dog_index in range(dogs.size()):
		var state: Dictionary = dogs[dog_index]
		var dog: Node3D = state.get("node", null)
		var started_possessed = bool(state.get("alien_origin_possessed", false))
		if started_possessed:
			origin_possessed += 1
		if bool(state.get("alien_possessed", false)):
			current_possessed += 1
			if possessed_test_index < 0:
				possessed_test_index = dog_index
		var signature = str(state.get("appearance_signature", "unknown:-1"))
		var parts = signature.split(":")
		var style = str(parts[0]) if parts.size() > 0 else "unknown"
		var color = str(parts[1]) if parts.size() > 1 else "-1"
		cosmetic_styles[style] = true
		cosmetic_colors[color] = true
		if started_possessed:
			possessed_styles[style] = true
		else:
			ordinary_styles[style] = true
		if dog == null or not is_instance_valid(dog):
			failures.append("target_alien_dog_node_missing")
		elif _count_nodes_named(dog, "Alien") > 0:
			failures.append("target_secret_alien_has_visual_marker_%d" % dog_index)
	if origin_possessed != expected_possessed:
		failures.append("target_alien_origin_ratio_bad_%d_of_%d" % [origin_possessed, dogs.size()])
	if origin_possessed <= 0 or origin_possessed >= dogs.size():
		failures.append("target_alien_secret_groups_missing")
	if cosmetic_styles.size() < 3 or cosmetic_colors.size() < 4:
		failures.append("target_dog_cosmetic_variety_low_%d_%d" % [cosmetic_styles.size(), cosmetic_colors.size()])
	if current_possessed > origin_possessed:
		failures.append("target_alien_dog_repossessed_without_mechanic")
	if possessed_styles.is_empty() or ordinary_styles.is_empty():
		failures.append("target_alien_cosmetic_groups_missing")
	if possessed_test_index < 0:
		failures.append("target_no_possessed_dog_available")
	else:
		var test_state: Dictionary = dogs[possessed_test_index]
		var test_dog: Node3D = test_state.get("node", null)
		var saved_dog_pos = test_dog.global_position
		test_dog.global_position = freya.global_position + Vector3(1.1, 0.0, 0.0)
		freya_alien_discomfort = 0.0
		_update_freya_alien_discomfort(0.5)
		var uneasy_strength = freya_alien_discomfort
		if uneasy_strength < 0.35:
			failures.append("target_freya_alien_discomfort_missing")
		test_state["alien_possessed"] = false
		dogs[possessed_test_index] = test_state
		_update_freya_alien_discomfort(0.5)
		if freya_alien_discomfort >= uneasy_strength:
			failures.append("target_freya_discomfort_not_clearing")

		test_state["alien_possessed"] = true
		var transfers_before = alien_transfers.size()
		test_state["exorcism_latched"] = false
		test_state = _update_exorcism_for_dog(test_state, possessed_test_index, ALIEN_EXPEL_BARK_TIME, true, true)
		dogs[possessed_test_index] = test_state
		var expelled_serial = int(test_state.get("alien_transfer_serial", -1))
		if bool(test_state.get("alien_possessed", true)) or not bool(test_state.get("alien_expelled", false)):
			failures.append("target_alien_bark_expulsion_failed")
		if alien_transfers.size() != transfers_before + 1 or _find_alien_transfer_index_by_serial(expelled_serial) < 0:
			failures.append("target_alien_transfer_not_spawned")
		else:
			var expelled_index = _find_alien_transfer_index_by_serial(expelled_serial)
			var expelled_node: Node3D = alien_transfers[expelled_index].get("node", null)
			if expelled_node == null or expelled_node.get_node_or_null("AlienRig") == null or absf(expelled_node.global_position.y) > 0.001:
				failures.append("target_expelled_alien_not_grounded_imp")
		_remove_alien_transfer_by_serial(expelled_serial)
		test_state["alien_possessed"] = true
		test_state["alien_expelled"] = false
		test_state["exorcism_latched"] = false
		test_state["exorcism_progress"] = 0.0
		test_state["alien_transfer_serial"] = -1
		dogs[possessed_test_index] = test_state
		test_dog.global_position = saved_dog_pos

	var occupation_test_index = -1
	for building_index in range(buildings.size()):
		if bool(buildings[building_index].get("is_freya_home", false)):
			continue
		if bool(buildings[building_index].get("alien_occupied", false)):
			continue
		occupation_test_index = building_index
		break
	if occupation_test_index < 0:
		failures.append("target_no_building_for_alien_occupation")
	else:
		# Exercise the real locomotion path: the imp runs to a reachable exterior
		# contact point and only then uses its possession exception.
		var travel_saved_building: Dictionary = buildings[occupation_test_index].duplicate()
		var travel_occupation_count_before = alien_building_occupation_count
		var travel_serial = alien_transfer_serial
		alien_transfer_serial += 1
		var travel_center: Vector2 = buildings[occupation_test_index].get("footprint", Rect2()).get_center()
		var travel_approach = _alien_building_approach_position(occupation_test_index, travel_center + Vector2(100.0, 0.0))
		var travel_outward = Vector2(travel_approach.x, travel_approach.z) - travel_center
		if travel_outward.length_squared() < 0.001:
			travel_outward = Vector2.RIGHT
		travel_outward = travel_outward.normalized()
		var travel_spawn = travel_approach + Vector3(travel_outward.x, 0.0, travel_outward.y) * 1.2
		if not _is_walkable(travel_spawn.x, travel_spawn.z, ALIEN_COLLISION_RADIUS):
			travel_spawn = travel_approach + Vector3(-travel_outward.y, 0.0, travel_outward.x) * 0.9
		if not _is_walkable(travel_spawn.x, travel_spawn.z, ALIEN_COLLISION_RADIUS):
			travel_spawn = travel_approach
		var travel_visual = _create_alien_transfer_visual()
		dynamic_root.add_child(travel_visual)
		travel_visual.global_position = travel_spawn
		alien_transfers.append({
			"serial": travel_serial,
			"node": travel_visual,
			"source_dog_index": -1,
			"target_index": occupation_test_index,
			"target_history": [occupation_test_index],
			"excluded_indices": [],
			"phase": "travel",
			"repel_timer": 0.0,
			"repel_direction": Vector3.ZERO,
			"age": 0.0,
			"walk_phase": 0.0,
			"steering_sign": 1.0,
			"stuck_timer": 0.0
		})
		var travel_moved = false
		var travel_invalid_step = false
		for tick in range(240):
			var live_index = _find_alien_transfer_index_by_serial(travel_serial)
			if live_index < 0:
				break
			var live_node: Node3D = alien_transfers[live_index].get("node", null)
			var before_step = live_node.global_position
			_update_alien_transfers(0.05)
			live_index = _find_alien_transfer_index_by_serial(travel_serial)
			if live_index < 0:
				break
			live_node = alien_transfers[live_index].get("node", null)
			var step_distance = live_node.global_position.distance_to(before_step)
			travel_moved = travel_moved or step_distance > 0.001
			var live_ground = Vector2(live_node.global_position.x, live_node.global_position.z)
			if step_distance > ALIEN_TRAVEL_SPEED * 0.05 + 0.002 or absf(live_node.global_position.y) > 0.001 or not _is_walkable(live_ground.x, live_ground.y, ALIEN_COLLISION_RADIUS):
				travel_invalid_step = true
				break
		if travel_invalid_step:
			failures.append("target_alien_travel_collision_or_speed_invalid")
		if travel_spawn.distance_to(travel_approach) > ALIEN_POSSESSION_REACH and not travel_moved:
			failures.append("target_alien_did_not_walk_to_building")
		if _find_alien_transfer_index_by_serial(travel_serial) >= 0 or not bool(buildings[occupation_test_index].get("alien_occupied", false)):
			failures.append("target_alien_walk_to_possession_failed")
		elif int(buildings[occupation_test_index].get("alien_occupant_count", 0)) != 1 or alien_building_occupation_count != travel_occupation_count_before + 1:
			failures.append("target_alien_walk_possession_count_bad")
		_remove_alien_transfer_by_serial(travel_serial)
		var travel_building_visual: Node3D = buildings[occupation_test_index].get("alien_visual_root", null)
		if travel_building_visual != null and is_instance_valid(travel_building_visual):
			travel_building_visual.queue_free()
		buildings[occupation_test_index] = travel_saved_building
		alien_building_occupation_count = travel_occupation_count_before

		var occupation_count_before = alien_building_occupation_count
		if not _occupy_building_with_alien(occupation_test_index, 99101):
			failures.append("target_alien_building_occupation_failed")
		else:
			var occupied: Dictionary = buildings[occupation_test_index]
			var alien_visual: Node3D = occupied.get("alien_visual_root", null)
			if not bool(occupied.get("alien_occupied", false)) or alien_visual == null or not is_instance_valid(alien_visual):
				failures.append("target_alien_building_state_missing")
			else:
				if _count_nodes_named(alien_visual, "AlienMembrane") < 4 or _count_nodes_named(alien_visual, "AlienVein") < 8:
					failures.append("target_alien_building_visual_detail_low")
				if alien_visual.get_node_or_null("AlienCrown") == null:
					failures.append("target_alien_building_crown_missing")
				var initial_scale = alien_visual.scale
				var initial_crown_rotation = (alien_visual.get_node("AlienCrown") as Node3D).rotation
				var saved_world_time = world_time
				world_time += 12.0
				_update_alien_building_visuals(1.0)
				if not alien_visual.scale.is_equal_approx(initial_scale) or not (alien_visual.get_node("AlienCrown") as Node3D).rotation.is_equal_approx(initial_crown_rotation):
					failures.append("target_alien_building_not_static")
				world_time = saved_world_time
			if int(occupied.get("alien_occupant_count", 0)) != 1:
				failures.append("target_alien_initial_occupant_count_bad")
			elif not _occupy_building_with_alien(occupation_test_index, 99102):
				failures.append("target_alien_multi_occupation_rejected")
			elif int(buildings[occupation_test_index].get("alien_occupant_count", 0)) != 2:
				failures.append("target_alien_occupant_count_not_incremented")
			var integrity_before = float(occupied.get("alien_integrity", 0.0))
			_weaken_alien_building(occupation_test_index, 0.75)
			var weakened: Dictionary = buildings[occupation_test_index]
			if float(weakened.get("alien_integrity", 1.0)) >= integrity_before:
				failures.append("target_alien_pee_not_weakening")
			if float(weakened.get("alien_pee_exposure", 0.0)) < 0.74:
				failures.append("target_alien_pee_exposure_not_persistent")
			_weaken_alien_building(occupation_test_index, ALIEN_BUILDING_WEAKEN_TIME * 2.0)
			weakened = buildings[occupation_test_index]
			if absf(float(weakened.get("alien_integrity", 1.0)) - ALIEN_BUILDING_MIN_INTEGRITY) > 0.001:
				failures.append("target_alien_integrity_floor_bad")
			if not bool(weakened.get("alien_occupied", false)):
				failures.append("target_alien_future_retake_hook_bypassed")
			_update_minimap_dynamic(0.0)
			if minimap == null or minimap.alien_buildings.is_empty():
				failures.append("target_alien_minimap_visual_missing")
			if alien_visual != null and is_instance_valid(alien_visual):
				alien_visual.queue_free()
			weakened["alien_occupied"] = false
			weakened["alien_integrity"] = 0.0
			weakened["alien_visual_root"] = null
			weakened["alien_occupant_serial"] = -1
			weakened["alien_occupant_count"] = 0
			weakened["alien_pee_exposure"] = 0.0
			weakened["alien_reinforcement_sources"] = 0
			weakened["alien_reinforcement_strength"] = 0.0
			buildings[occupation_test_index] = weakened
			alien_building_occupation_count = occupation_count_before

	if freya_home_index < 0 or freya_home_index >= buildings.size():
		failures.append("target_alien_ryah_home_missing")
	else:
		var home_before: Dictionary = buildings[freya_home_index]
		var defense_before = ryah_alien_defense_count
		var defense_serial = alien_transfer_serial
		alien_transfer_serial += 1
		var defense_visual = _create_alien_transfer_visual()
		dynamic_root.add_child(defense_visual)
		var home_center: Vector2 = home_before.get("footprint", Rect2()).get_center()
		defense_visual.global_position = _alien_building_approach_position(freya_home_index, home_center + Vector2(0.0, 100.0))
		alien_transfers.append({
			"serial": defense_serial,
			"node": defense_visual,
			"source_dog_index": -1,
			"target_index": freya_home_index,
			"target_history": [freya_home_index],
			"excluded_indices": [],
			"phase": "travel",
			"repel_timer": 0.0,
			"repel_direction": Vector3.ZERO,
			"age": 0.0,
			"walk_phase": 0.0,
			"steering_sign": 1.0,
			"stuck_timer": 0.0
		})
		_update_alien_transfers(0.05)
		var defense_index = _find_alien_transfer_index_by_serial(defense_serial)
		if defense_index < 0:
			failures.append("target_ryah_alien_transfer_removed")
		else:
			var defense_transfer: Dictionary = alien_transfers[defense_index]
			if str(defense_transfer.get("phase", "")) != "repelled":
				failures.append("target_ryah_alien_not_repelled")
			if absf(defense_visual.global_position.y) > 0.001:
				failures.append("target_ryah_alien_repel_not_grounded")
			if bool(buildings[freya_home_index].get("alien_occupied", false)):
				failures.append("target_ryah_home_alien_occupied")
			if ryah_alien_defense_count != defense_before + 1 or ryah_alien_cry_visual_root == null:
				failures.append("target_ryah_cry_defense_missing")
			defense_transfer["repel_timer"] = 0.0
			alien_transfers[defense_index] = defense_transfer
			_update_alien_transfers(0.05)
			defense_index = _find_alien_transfer_index_by_serial(defense_serial)
			if defense_index >= 0 and int(alien_transfers[defense_index].get("target_index", freya_home_index)) == freya_home_index:
				failures.append("target_ryah_alien_not_rerouted")
		_remove_alien_transfer_by_serial(defense_serial)
		buildings[freya_home_index] = home_before

	freya_alien_discomfort = 0.0
	if freya != null and freya.has_method("set_discomfort"):
		freya.call("set_discomfort", 0.0, freya.global_position, 1.0)

func _append_alien_storefront_validation_failures(failures: Array[String]) -> void:
	if store_building_indices.is_empty():
		return
	_clear_free_aliens()
	for store_index in store_building_indices:
		var unoccupied_store: Dictionary = buildings[store_index]
		unoccupied_store["alien_spawn_cooldown"] = 0.0
		buildings[store_index] = unoccupied_store
	_update_free_alien_generation(0.1)
	if not free_aliens.is_empty():
		failures.append("target_free_alien_generated_without_occupied_store")
		_clear_free_aliens()

	var store_index = store_building_indices[0]
	var saved_store: Dictionary = buildings[store_index].duplicate()
	var occupation_count_before = alien_building_occupation_count
	if not _occupy_building_with_alien(store_index, 99201):
		failures.append("target_alien_storefront_occupation_failed")
		return
	var occupied_store: Dictionary = buildings[store_index]
	var store_visual: Node3D = occupied_store.get("alien_visual_root", null)
	var interior_center: Vector2 = occupied_store.get("store_interior_rect", occupied_store.get("footprint", Rect2())).get_center()
	if _is_inside_store_index(store_index, interior_center) or _is_inside_store_interior(store_index, interior_center):
		failures.append("target_occupied_store_still_enterable")
	if _is_walkable(interior_center.x, interior_center.y, FREYA_COLLISION_RADIUS):
		failures.append("target_occupied_store_not_physically_locked")
	if store_visual == null or not is_instance_valid(store_visual) or _count_nodes_named(store_visual, "AlienStoreLock") < 2:
		failures.append("target_occupied_store_lock_visual_missing")
	if int(occupied_store.get("alien_occupant_count", 0)) != 1:
		failures.append("target_occupied_store_count_missing")

	var food_count_before = store_foods.size()
	var saved_freya_position = freya.global_position
	for food in store_foods:
		if int(food.get("store_index", -1)) == store_index:
			var food_pos: Vector2 = food.get("pos", interior_center)
			freya.global_position = Vector3(food_pos.x, freya.global_position.y, food_pos.y)
			_try_eat_store_food(false)
			break
	if store_foods.size() != food_count_before:
		failures.append("target_occupied_store_food_still_usable")
	freya.global_position = saved_freya_position

	var nearby_index = -1
	var store_center: Vector2 = occupied_store.get("footprint", Rect2()).get_center()
	var nearby_distance = INF
	for building_index in range(buildings.size()):
		if building_index == store_index or bool(buildings[building_index].get("is_freya_home", false)):
			continue
		var candidate_center: Vector2 = buildings[building_index].get("footprint", Rect2()).get_center()
		var distance = store_center.distance_to(candidate_center)
		if distance <= ALIEN_STOREFRONT_REINFORCEMENT_RADIUS and distance < nearby_distance:
			nearby_distance = distance
			nearby_index = building_index
	var saved_nearby: Dictionary = {}
	if nearby_index < 0:
		failures.append("target_no_building_in_storefront_reinforcement_radius")
	else:
		saved_nearby = buildings[nearby_index].duplicate()
		_occupy_building_with_alien(nearby_index, 99202)
		_update_alien_reinforcement_fields()
		var reinforced: Dictionary = buildings[nearby_index]
		if int(reinforced.get("alien_reinforcement_sources", 0)) < 1 or float(reinforced.get("alien_reinforcement_strength", 0.0)) <= 0.0:
			failures.append("target_storefront_reinforcement_missing")

	occupied_store = buildings[store_index]
	occupied_store["alien_spawn_cooldown"] = 0.0
	buildings[store_index] = occupied_store
	_update_free_alien_generation(0.1)
	if free_aliens.size() != 1 or int(free_aliens[0].get("source_store_index", -1)) != store_index:
		failures.append("target_occupied_store_free_alien_generation_failed")
	else:
		var free_alien: Dictionary = free_aliens[0]
		var free_node: Node3D = free_alien.get("node", null)
		if free_node == null or absf(free_node.global_position.y) > 0.001 or _count_nodes_named(free_node, "LegPivot") != 2:
			failures.append("target_storefront_alien_not_grounded_imp")
		var expected_target = _nearest_alien_building(Vector2(free_node.global_position.x, free_node.global_position.z), [store_index], true, true)
		freya.global_position = free_node.global_position
		occupied_store = buildings[store_index]
		occupied_store["alien_spawn_cooldown"] = FREE_ALIEN_SPAWN_MAX_SEC
		buildings[store_index] = occupied_store
		_update_free_aliens(0.01)
		if free_aliens.is_empty() or str(free_aliens[0].get("phase", "")) != "flee" or int(free_aliens[0].get("target_index", -1)) != expected_target:
			failures.append("target_free_alien_nearest_building_flee_failed")
		elif absf((free_aliens[0].get("node", null) as Node3D).global_position.y) > 0.001:
			failures.append("target_free_alien_flee_not_grounded")
	freya.global_position = saved_freya_position

	while free_aliens.size() < MAX_FREE_ALIENS:
		occupied_store = buildings[store_index]
		occupied_store["alien_spawn_cooldown"] = 0.0
		buildings[store_index] = occupied_store
		_update_free_alien_generation(0.1)
	var capped_count = free_aliens.size()
	occupied_store = buildings[store_index]
	occupied_store["alien_spawn_cooldown"] = 0.0
	buildings[store_index] = occupied_store
	_update_free_alien_generation(0.1)
	if capped_count != MAX_FREE_ALIENS or free_aliens.size() != MAX_FREE_ALIENS:
		failures.append("target_free_alien_cap_failed")
	_clear_free_aliens()

	if store_visual != null and is_instance_valid(store_visual):
		store_visual.queue_free()
	buildings[store_index] = saved_store
	if nearby_index >= 0:
		var nearby_visual: Node3D = buildings[nearby_index].get("alien_visual_root", null)
		if nearby_visual != null and is_instance_valid(nearby_visual):
			nearby_visual.queue_free()
		buildings[nearby_index] = saved_nearby
	alien_building_occupation_count = occupation_count_before
	_update_alien_reinforcement_fields()
	_apply_store_focus_visuals()

func _append_size_validation_failures(failures: Array[String]) -> void:
	var freya_dims = _node_visual_dimensions(freya)
	if freya_dims.y < 0.82 or freya_dims.y > 1.35:
		failures.append("freya_height_out_of_range_%.2f" % freya_dims.y)
	if freya_dims.z < 1.0 or freya_dims.z > 2.05:
		failures.append("freya_length_out_of_range_%.2f" % freya_dims.z)

	var npc_checked = 0
	var npc_invalid = 0
	var npc_too_small = 0
	var npc_too_large = 0
	var npc_min_h = 1000000.0
	var npc_max_h = 0.0
	for d in dogs:
		var dog_node: Node3D = d.get("node", null)
		var dims = _node_visual_dimensions(dog_node)
		if dims.y <= 0.05 or dims.z <= 0.1:
			npc_invalid += 1
			continue
		npc_checked += 1
		npc_min_h = minf(npc_min_h, dims.y)
		npc_max_h = maxf(npc_max_h, dims.y)
		var ratio = dims.y / maxf(0.01, freya_dims.y)
		if ratio < 0.5:
			npc_too_small += 1
		elif ratio > 1.28:
			npc_too_large += 1
	if npc_checked <= 0:
		failures.append("npc_size_check_no_dogs")
	else:
		if npc_invalid > 0:
			failures.append("npc_size_invalid_%d" % npc_invalid)
		if npc_too_small > 0:
			failures.append("npc_too_small_vs_freya_%d" % npc_too_small)
		if npc_too_large > 0:
			failures.append("npc_too_large_vs_freya_%d" % npc_too_large)
		if npc_max_h > 0.01:
			var spread = npc_max_h / maxf(0.01, npc_min_h)
			if spread < 1.1:
				failures.append("npc_size_spread_low")

	var building_count = 0
	var building_height_sum = 0.0
	var multistory_house_count = 0
	var one_story_count = 0
	var max_floor_count = 0
	for b in buildings:
		var h = float(b.get("height", 0.0))
		if h <= 0.0:
			continue
		building_count += 1
		building_height_sum += h
		var floors = int(b.get("floors", 0))
		max_floor_count = maxi(max_floor_count, floors)
		if floors == 1:
			one_story_count += 1
		var model_path = str(b.get("external_model_path", "")).to_lower()
		if floors > 1 and model_path.contains("building_house"):
			multistory_house_count += 1
	if building_count > 0:
		var avg_building_height = building_height_sum / float(building_count)
		var building_to_dog_ratio = avg_building_height / maxf(0.01, freya_dims.y)
		if building_to_dog_ratio < 3.2 or building_to_dog_ratio > 11.0:
			failures.append("building_dog_scale_ratio_bad_%.2f" % building_to_dog_ratio)
		if float(one_story_count) / float(building_count) < 0.45:
			failures.append("northbrook_single_story_share_low_%d_of_%d" % [one_story_count, building_count])
	if max_floor_count > 3:
		failures.append("northbrook_building_over_three_stories_%d" % max_floor_count)
	if multistory_house_count > 0:
		failures.append("multistory_house_model_used_%d" % multistory_house_count)

	var metrics = BuildingFactoryScript.brick_style_metrics()
	var uv_scale = float(metrics.get("uv_scale", 0.0))
	var brick_px_w = float(metrics.get("brick_px_w", 0.0))
	var brick_px_h = float(metrics.get("brick_px_h", 0.0))
	var brick_world_w = float(metrics.get("brick_world_w_m", 0.0))
	var brick_world_h = float(metrics.get("brick_world_h_m", 0.0))
	if uv_scale < 0.35 or uv_scale > 0.5:
		failures.append("brick_world_uv_scale_bad_%.3f" % uv_scale)
	if brick_px_w > 36.0 or brick_px_h > 14.0:
		failures.append("brick_pattern_too_large")
	if brick_world_w < 0.18 or brick_world_w > 0.24 or brick_world_h < 0.06 or brick_world_h > 0.085:
		failures.append("brick_world_dimensions_bad_%.3fx%.3f" % [brick_world_w, brick_world_h])

func _run_targeted_validation_checks() -> bool:
	var failures: Array[String] = []
	var saved_pos = freya.global_position
	var saved_cam_pos = camera_node.global_position
	var saved_active = active_store_index
	var saved_timer = store_focus_timer
	var saved_hunger = freya_hunger
	var saved_eat_timer = freya_eat_timer
	_append_alien_validation_failures(failures)
	_append_army_collar_validation_failures(failures)
	_append_mailbox_claim_validation_failures(failures)

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
			var shell_override: Node3D = b.get("store_shell_root", null)
			var interior_root: Node3D = b.get("store_interior_root", null)
			if interior_root == null or not is_instance_valid(interior_root) or not interior_root.visible:
				failures.append("target_store_interior_not_visible")
			var has_override_shell = shell_override != null and is_instance_valid(shell_override)
			if (shell == null or not is_instance_valid(shell)) and (not has_override_shell):
				failures.append("target_store_shell_missing")
			elif has_override_shell:
				if shell_override.visible:
					failures.append("target_store_override_not_hidden_inside")
				if shell != null and is_instance_valid(shell) and shell.visible:
					failures.append("target_store_base_shell_visible_with_override")
			elif shell != null and is_instance_valid(shell) and shell.visible:
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
				if has_override_shell:
					if shell_override != null and is_instance_valid(shell_override) and not shell_override.visible:
						failures.append("target_store_override_not_restored_after_exit")
					if shell != null and is_instance_valid(shell) and shell.visible:
						failures.append("target_store_base_shell_visible_with_override_after_exit")
				else:
					if interior_root != null and is_instance_valid(interior_root) and not interior_root.visible:
						failures.append("target_store_interior_hidden_behind_windows")
					if shell != null and is_instance_valid(shell) and not shell.visible:
						failures.append("target_store_shell_not_restored_after_exit")
				if store_focus_overlay != null and store_focus_overlay.visible:
					failures.append("target_store_overlay_still_visible_after_exit")

		for store_idx in store_building_indices:
			var store_building: Dictionary = buildings[store_idx]
			var commercial_height = float(store_building.get("commercial_height", 0.0))
			if commercial_height < 3.2 or commercial_height > 4.05:
				failures.append("target_store_commercial_height_bad_%.2f" % commercial_height)
			var store_shell: Node3D = store_building.get("store_shell_root", null)
			if store_shell == null or not is_instance_valid(store_shell) or store_shell.get_child_count() < 12:
				failures.append("target_store_exterior_detail_low")
			elif int(store_building.get("transparent_window_count", 0)) < 3 or _count_transparent_geometry(store_shell) < 1:
				failures.append("target_store_windows_not_transparent")
			if int(store_building.get("opaque_window_backing_count", -1)) != 0:
				failures.append("target_store_window_opaque_backing")
			if int(store_building.get("storefront_contact_shadow_count", 0)) < 2:
				failures.append("target_store_contact_depth_missing")
			var store_scale: Dictionary = store_building.get("store_scale_metrics", {})
			if float(store_scale.get("door_width", 0.0)) < FREYA_COLLISION_RADIUS * 4.0:
				failures.append("target_store_door_scale_bad")
			if float(store_scale.get("minimum_aisle_width", 0.0)) < FREYA_COLLISION_RADIUS * 2.0 + 0.08:
				failures.append("target_store_aisle_scale_bad")
			if float(store_scale.get("window_sill_height", 0.0)) < 0.4 or float(store_scale.get("window_sill_height", 0.0)) > 0.62:
				failures.append("target_store_window_sill_scale_bad")
			var visible_store_interior: Node3D = store_building.get("store_interior_root", null)
			if visible_store_interior == null or not is_instance_valid(visible_store_interior) or not visible_store_interior.visible:
				failures.append("target_store_interior_not_visible_through_glass")

		_append_alien_storefront_validation_failures(failures)

	var gable_count = 0
	var hip_count = 0
	var roof_palette_indices := {}
	var porch_styles := {}
	for building in buildings:
		if bool(building.get("is_store", false)) or str(building.get("model_source", "")) != "procedural":
			continue
		var roof_style = str(building.get("roof_style", ""))
		roof_palette_indices[int(building.get("roof_material_index", -1))] = true
		porch_styles[str(building.get("porch_style", ""))] = true
		if roof_style == "gable":
			gable_count += 1
			var gable_root: Node3D = building.get("node", null)
			if gable_root == null or gable_root.get_node_or_null("SupportedGableEnds") == null:
				failures.append("target_gable_support_missing")
			elif gable_root.get_node_or_null("GableEaveFascia") == null:
				failures.append("target_gable_fascia_missing")
			elif gable_root.get_node_or_null("GableSoffit") == null:
				failures.append("target_gable_soffit_missing")
			elif (building.get("roof_parts", []) as Array).has(gable_root.get_node_or_null("SupportedGableEnds")):
				failures.append("target_gable_support_in_roof_cutaway")
		elif roof_style == "hip":
			hip_count += 1
			var hip_root: Node3D = building.get("node", null)
			if hip_root == null or hip_root.get_node_or_null("HipEaveFascia") == null:
				failures.append("target_hip_fascia_missing")
			elif hip_root.get_node_or_null("HipSoffit") == null:
				failures.append("target_hip_soffit_missing")
		var body_height = float(building.get("body_height", 0.0))
		var eave_y = float(building.get("roof_eave_y", 1000.0))
		if body_height <= 0.0 or eave_y > body_height - 0.08 or eave_y < body_height - 0.2:
			failures.append("target_roof_wall_overlap_bad")
		var building_fp: Rect2 = building.get("footprint", Rect2())
		var expected_ridge_axis = "x" if building_fp.size.x >= building_fp.size.y else "z"
		if str(building.get("roof_ridge_axis", "")) != expected_ridge_axis:
			failures.append("target_roof_ridge_axis_bad")
		var roof_rise = float(building.get("roof_rise", 0.0))
		if roof_rise < 0.8 or roof_rise > minf(building_fp.size.x, building_fp.size.y) * 0.3:
			failures.append("target_roof_pitch_scale_bad")
	if gable_count <= 0 or hip_count <= 0:
		failures.append("target_suburban_roof_variety_missing_%d_%d" % [gable_count, hip_count])
	if roof_palette_indices.size() < 3:
		failures.append("target_roof_material_variety_low_%d" % roof_palette_indices.size())
	for expected_porch_style in ["stoop", "covered", "low_deck"]:
		if not porch_styles.has(expected_porch_style):
			failures.append("target_porch_style_missing_%s" % expected_porch_style)
	var suburban_metrics = BuildingFactoryScript.suburban_style_metrics()
	if int(suburban_metrics.get("siding_materials", 0)) < 4 or int(suburban_metrics.get("textured_siding_materials", 0)) != int(suburban_metrics.get("siding_materials", 0)):
		failures.append("target_textured_house_walls_missing")
	if int(suburban_metrics.get("roof_materials", 0)) < 3 or int(suburban_metrics.get("textured_roof_materials", 0)) != int(suburban_metrics.get("roof_materials", 0)):
		failures.append("target_textured_roof_materials_missing")

	var residential_count = 0
	var residential_yard_count = 0
	var annotated_driveway_count = 0
	for neighborhood_building in buildings:
		if bool(neighborhood_building.get("is_store", false)):
			continue
		residential_count += 1
		if bool(neighborhood_building.get("yard_identity", false)) and int(neighborhood_building.get("yard_detail_count", 0)) >= 18:
			residential_yard_count += 1
		if bool(neighborhood_building.get("has_driveway", false)):
			annotated_driveway_count += 1
	if residential_count <= 0 or residential_yard_count != residential_count:
		failures.append("target_residential_yard_identity_incomplete_%d_of_%d" % [residential_yard_count, residential_count])
	if suburban_yard_detail_count < residential_count * 18:
		failures.append("target_suburban_yard_detail_low_%d" % suburban_yard_detail_count)
	if annotated_driveway_count != suburban_driveway_count or suburban_driveway_count < int(floor(float(residential_count) * 0.45)):
		failures.append("target_empty_driveway_coverage_bad_%d" % suburban_driveway_count)
	if freya_home_backyard_detail_count < 14:
		failures.append("target_freya_home_backyard_detail_low_%d" % freya_home_backyard_detail_count)
	if facade_clearance_rects.size() != buildings.size():
		failures.append("target_facade_clearance_coverage_bad_%d" % facade_clearance_rects.size())
	for tree in trees:
		var tree_pos: Vector2 = tree.get("pos", Vector2.ZERO)
		if _point_in_facade_clearance(tree_pos, 0.75):
			failures.append("target_tree_blocks_facade_sightline")
			break
	for pole in street_poles:
		var pole_pos: Vector2 = pole.get("pos", Vector2.ZERO)
		if _point_in_facade_clearance(pole_pos, 0.22):
			failures.append("target_pole_blocks_facade_sightline")
			break

	if freya_home_index < 0 or freya_home_index >= buildings.size():
		failures.append("target_freya_home_missing")
	else:
		var home: Dictionary = buildings[freya_home_index]
		if not bool(home.get("is_freya_home", false)) or bool(home.get("is_store", false)):
			failures.append("target_freya_home_identity_bad")
		var home_rect: Rect2 = home.get("home_interior_rect", Rect2())
		if home_rect.get_area() < 58.0 or home_rect.size.x < 8.0 or home_rect.size.y < 4.4:
			failures.append("target_freya_home_interior_invalid")
		if freya_home_interior_root == null or not is_instance_valid(freya_home_interior_root):
			failures.append("target_freya_home_interior_missing")
		elif _count_mesh_instances(freya_home_interior_root) < 28:
			failures.append("target_freya_home_furnishing_low")
		if ryah_diane_node == null or not is_instance_valid(ryah_diane_node):
			failures.append("target_ryah_diane_missing")
		else:
			if ryah_diane_node.get_node_or_null("RyahDianeLabel") == null:
				failures.append("target_ryah_diane_label_missing")
			if ryah_diane_node.get_node_or_null("Hair") == null:
				failures.append("target_ryah_diane_hair_missing")
			var ryah_before = ryah_diane_node.position
			_update_ryah_diane(0.5)
			if ryah_diane_node.position.distance_squared_to(ryah_before) < 0.0004:
				failures.append("target_ryah_diane_not_walking")
		if int(home.get("transparent_window_count", 0)) < 7 or _count_transparent_geometry(freya_home_exterior_root) < 1:
			failures.append("target_home_windows_not_transparent")
		if int(home.get("opaque_window_backing_count", -1)) != 0:
			failures.append("target_home_window_opaque_backing")
		if _count_nodes_named(freya_home_exterior_root, "Sill") < int(home.get("transparent_window_count", 0)):
			failures.append("target_home_window_sills_missing")
		if _count_nodes_named(freya_home_exterior_root, "Curtain") + _count_nodes_named(freya_home_exterior_root, "Blind") < 3:
			failures.append("target_home_window_treatments_missing")
		if _count_nodes_named(freya_home_interior_root, "SofaCushion") < 3:
			failures.append("target_home_sofa_cushions_missing")
		if _count_nodes_named(freya_home_interior_root, "CabinetDoor") < 3 or _count_nodes_named(freya_home_interior_root, "CabinetHandle") < 3:
			failures.append("target_home_cabinet_detail_missing")
		if _count_nodes_named(freya_home_interior_root, "DiningChairRail") < 4:
			failures.append("target_home_chair_rails_missing")
		if _count_nodes_named(freya_home_interior_root, "ToddlerBedRail") < 2:
			failures.append("target_home_bed_rails_missing")
		if _count_nodes_named(freya_home_interior_root, "InteriorLightPool") < 4 or _count_nodes_named(freya_home_interior_root, "InteriorLightPendant") < 4:
			failures.append("target_home_emissive_lighting_missing")
		if _count_nodes_named(freya_home_interior_root, "ContactShadow") < 4:
			failures.append("target_home_contact_depth_missing")
		var bowl_pos: Vector2 = home.get("dog_bowl_pos", Vector2.ZERO)
		if freya_home_bowl_node == null or not is_instance_valid(freya_home_bowl_node) or _count_nodes_named(freya_home_interior_root, "FreyaDogBowl") != 1:
			failures.append("target_home_dog_bowl_missing")
		elif not home_rect.has_point(bowl_pos) or not bool(home.get("dog_bowl_unlimited", false)):
			failures.append("target_home_dog_bowl_invalid")
		else:
			var bowl_instance_id = freya_home_bowl_node.get_instance_id()
			freya.global_position = Vector3(bowl_pos.x, freya.global_position.y, bowl_pos.y)
			freya_hunger = 73.0
			if not _try_eat_home_bowl(false) or absf(freya_hunger) > 0.001:
				failures.append("target_home_dog_bowl_did_not_zero_hunger")
			freya_hunger = 48.0
			if not _try_eat_home_bowl(false) or absf(freya_hunger) > 0.001:
				failures.append("target_home_dog_bowl_not_reusable")
			if freya_home_bowl_node == null or not is_instance_valid(freya_home_bowl_node) or freya_home_bowl_node.get_instance_id() != bowl_instance_id:
				failures.append("target_home_dog_bowl_consumed")
		var scale_metrics: Dictionary = home.get("home_scale_metrics", {})
		var freya_height = float(scale_metrics.get("freya_height", 0.0))
		var door_height = float(scale_metrics.get("door_height", 0.0))
		var wall_height = float(scale_metrics.get("wall_height", 0.0))
		var table_top = float(scale_metrics.get("dining_table_top", 0.0))
		if freya_height <= 0.0 or door_height / freya_height < 1.75 or door_height / freya_height > 2.15:
			failures.append("target_home_door_freya_scale_bad")
		if wall_height / maxf(0.01, freya_height) < 2.6 or wall_height / maxf(0.01, freya_height) > 3.25:
			failures.append("target_home_wall_freya_scale_bad")
		if table_top < 0.72 or table_top > 0.82:
			failures.append("target_home_furniture_scale_bad")
		var window_sill_height = float(scale_metrics.get("window_sill_height", 0.0))
		if window_sill_height < 0.7 or window_sill_height > 0.9:
			failures.append("target_home_window_sill_scale_bad")
		if float(scale_metrics.get("door_width", 0.0)) < FREYA_COLLISION_RADIUS * 2.8:
			failures.append("target_home_door_width_scale_bad")
		if float(scale_metrics.get("sofa_width", 0.0)) < 1.9 or float(scale_metrics.get("bed_length", 0.0)) < 1.35:
			failures.append("target_home_assembled_furniture_scale_bad")
		var home_center = home_rect.get_center()
		freya.global_position = Vector3(home_center.x, freya.global_position.y, home_center.y)
		store_focus_timer = 0.0
		_update_store_focus(0.2)
		var home_shell: Node3D = home.get("node", null)
		if not freya_inside_home:
			failures.append("target_freya_home_focus_not_entering")
		if home_shell != null and is_instance_valid(home_shell) and home_shell.visible:
			failures.append("target_freya_home_shell_visible_inside")
		var home_fp: Rect2 = home.get("footprint", Rect2())
		var home_distance = home_fp.get_center().distance_squared_to(dog_park.get_center())
		var selection_min_area = float(home.get("home_selection_min_area", 0.0))
		var selection_min_short_side = float(home.get("home_selection_min_short_side", 0.0))
		var selection_one_story = bool(home.get("home_selection_one_story", false))
		for candidate in buildings:
			if str(candidate.get("model_source", "")) != "procedural":
				continue
			if selection_one_story and int(candidate.get("floors", 1)) != 1:
				continue
			var candidate_fp: Rect2 = candidate.get("footprint", Rect2())
			if candidate_fp.get_area() < selection_min_area or minf(candidate_fp.size.x, candidate_fp.size.y) < selection_min_short_side:
				continue
			if candidate_fp.get_center().distance_squared_to(dog_park.get_center()) + 0.01 < home_distance:
				failures.append("target_freya_home_not_closest_to_park")
				break
		var home_layout: Dictionary = home.get("home_layout", {})
		var home_entry_outside: Vector2 = home_layout.get("entry_outside_pos", home_fp.get_center())
		if not _near_enterable_doorway(home, home_entry_outside):
			failures.append("target_home_preentry_cutaway_zone_missing")
		else:
			freya.global_position = Vector3(home_entry_outside.x, freya.global_position.y, home_entry_outside.y)
			_apply_freya_home_focus_visuals()
			occlusion_update_timer = 0.0
			_update_roof_occlusion(0.2)
			for roof_part in home.get("roof_parts", []):
				if roof_part is Node3D and is_instance_valid(roof_part as Node3D) and (roof_part as Node3D).visible:
					failures.append("target_home_roof_not_hidden_before_entry")
					break

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
		# Keep the target immediately behind the test house. With the corrected
		# one-story scale, a symmetric camera/target setup aims the ray above the
		# roof and is not an occlusion at all.
		var blocked_pos = Vector3(cx, 0.0, rect.position.y + rect.size.y * 1.55)
		var clear_pos = Vector3(cam_pos.x + 0.15, 0.0, cam_pos.z + 0.2)
		if not _freya_occluded_by_buildings(cam_pos, blocked_pos):
			failures.append("target_ghost_not_blocked_when_hidden")
		if _freya_occluded_by_buildings(cam_pos, clear_pos):
			failures.append("target_ghost_blocked_when_clear")
		if _freya_occluded_by_buildings(cam_pos, Vector3(cx, 0.0, cz)) and rect.size.x < 4.0:
			failures.append("target_ghost_false_positive_small_building")

		occlusion_update_timer = 0.0
		camera_node.global_position = cam_pos
		freya.global_position = blocked_pos
		_update_roof_occlusion(0.25)
		if outlined_freya_meshes.is_empty():
			failures.append("target_ghost_outline_not_shown")
		freya.global_position = clear_pos
		_update_roof_occlusion(0.25)
		if not outlined_freya_meshes.is_empty():
			failures.append("target_ghost_outline_not_cleared")
		freya.global_position = blocked_pos
		_update_roof_occlusion(0.25)
		if outlined_freya_meshes.is_empty():
			failures.append("target_ghost_outline_not_restored")

	freya.global_position = saved_pos
	camera_node.global_position = saved_cam_pos
	active_store_index = saved_active
	store_focus_timer = saved_timer
	freya_hunger = saved_hunger
	freya_eat_timer = saved_eat_timer
	_apply_store_focus_visuals()
	_apply_freya_home_focus_visuals()

	if failures.is_empty():
		print("TARGET_OK: smaller-imp+readable-army-collars+mailbox-claim+alien-collision+possession+home-bowl+store-lock+visual validations passed")
		return true
	else:
		push_error("TARGET_FAIL: " + ", ".join(failures))
		return false

func _run_headless_smoke_checks() -> bool:
	var failures: Array[String] = []
	var park_center = dog_park.position + dog_park.size * 0.5
	var initial_spawn_distance = Vector2(freya.global_position.x, freya.global_position.z).distance_to(park_center)
	var expected_blocks = CITY_BLOCK_COLUMNS * CITY_BLOCK_ROWS
	if city_blocks.size() != expected_blocks:
		failures.append("city_block_count_%d_expected_%d" % [city_blocks.size(), expected_blocks])
	var center_block = _city_center_block()
	if center_block.is_empty():
		failures.append("center_block_missing")
	else:
		var center_rect: Rect2 = center_block.get("rect", Rect2())
		if center_rect.size.x <= 0.01 or center_rect.size.y <= 0.01:
			failures.append("center_block_rect_invalid")
		else:
			if not center_rect.has_point(park_center):
				failures.append("dog_park_not_center_block")
			elif not center_rect.encloses(dog_park):
				failures.append("dog_park_not_fully_inside_center_block")
	if dog_park.has_point(Vector2(freya.global_position.x, freya.global_position.z)):
		failures.append("freya_spawned_inside_dog_park")

	# Hunger metabolism must be almost flat at rest and clearly activity-driven.
	var metabolism_saved_pos = freya.global_position
	var metabolism_saved_hunger = freya_hunger
	var metabolism_saved_social = freya_social
	var metabolism_saved_vomit_timer = freya_vomit_timer
	var metabolism_saved_eat_timer = freya_eat_timer
	freya_vomit_timer = 0.0
	freya_eat_timer = 0.0
	Input.action_release("move_right")
	Input.action_release("run")
	freya_hunger = 0.0
	_update_freya(10.0)
	var idle_hunger_gain = freya_hunger
	freya.global_position = metabolism_saved_pos
	freya_hunger = 0.0
	Input.action_press("move_right")
	_update_freya(1.0)
	Input.action_release("move_right")
	var walk_hunger_gain = freya_hunger
	freya.global_position = metabolism_saved_pos
	freya_hunger = 0.0
	Input.action_press("move_right")
	Input.action_press("run")
	_update_freya(1.0)
	Input.action_release("run")
	Input.action_release("move_right")
	var run_hunger_gain = freya_hunger
	if idle_hunger_gain <= 0.0 or idle_hunger_gain > 0.3:
		failures.append("idle_hunger_not_very_slow_%.3f" % idle_hunger_gain)
	if walk_hunger_gain < HUNGER_WALK_PER_SEC - 0.01 or walk_hunger_gain <= idle_hunger_gain:
		failures.append("walking_hunger_rate_not_increased_%.3f" % walk_hunger_gain)
	if run_hunger_gain < HUNGER_RUN_PER_SEC - 0.01 or run_hunger_gain <= walk_hunger_gain:
		failures.append("running_hunger_rate_not_increased_%.3f" % run_hunger_gain)
	if HUNGER_ACTIVE_ACTION_PER_SEC <= HUNGER_RUN_PER_SEC:
		failures.append("active_action_hunger_rate_not_increased")
	freya.global_position = metabolism_saved_pos
	freya_hunger = metabolism_saved_hunger
	freya_social = metabolism_saved_social
	freya_vomit_timer = metabolism_saved_vomit_timer
	freya_eat_timer = metabolism_saved_eat_timer

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

	# Strength-level check
	freya_strength = FREYA_STRENGTH_MIN_LEVEL
	var test_bone = _create_bone_node()
	var bone_pos = Vector3(freya.global_position.x + 0.48, 0.03, freya.global_position.z + 0.08)
	test_bone.position = bone_pos
	dynamic_root.add_child(test_bone)
	bones.append({"node": test_bone, "pos": Vector2(bone_pos.x, bone_pos.z)})
	if not _try_eat_bone(false):
		failures.append("bone_not_consumed")
	elif freya_strength != FREYA_STRENGTH_MIN_LEVEL + 1:
		failures.append("strength_level_not_incremented")
	freya_strength = FREYA_STRENGTH_MAX_LEVEL
	var cap_bone = _create_bone_node()
	var cap_bone_pos = Vector3(freya.global_position.x + 0.56, 0.03, freya.global_position.z - 0.12)
	cap_bone.position = cap_bone_pos
	dynamic_root.add_child(cap_bone)
	bones.append({"node": cap_bone, "pos": Vector2(cap_bone_pos.x, cap_bone_pos.z)})
	_try_eat_bone(false)
	if freya_strength != FREYA_STRENGTH_MAX_LEVEL:
		failures.append("strength_level_exceeds_cap")

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

	# Socialization, army alignment, Hunger gate, and wrong-guess flee checks
	if dogs.size() > 0:
		var state: Dictionary = dogs[0]
		var dog: Node3D = state.get("node", null)
		if dog == null or not is_instance_valid(dog):
			failures.append("smoke_dog_missing")
		else:
			var saved_other_possession: Array[bool] = []
			for other_index in range(1, dogs.size()):
				var other_state: Dictionary = dogs[other_index]
				saved_other_possession.append(bool(other_state.get("alien_possessed", false)))
				other_state["alien_possessed"] = false
				dogs[other_index] = other_state
			dog.global_position = freya.global_position + Vector3(1.15, 0.0, 0.0)
			state["dir"] = Vector3.ZERO
			state["speed"] = 0.0
			state["wander"] = 1.2
			state["bark"] = 0.0
			state["alien_possessed"] = false
			state["army_aligned"] = false
			state["socialization_progress"] = 0.0
			state["flee_timer"] = 0.0
			state["exorcism_latched"] = false
			dogs[0] = state

			freya_hunger = 40.0
			freya_vomit = 18.0
			var hunger_before_social = freya_hunger
			var vomit_before_real_social = freya_vomit
			var social_before = freya_social
			var bark_before = bark_pulses.size()
			Input.action_press("friendly_social")
			_update_dogs(0.2)
			Input.action_release("friendly_social")
			if freya_social <= social_before:
				failures.append("social_not_increasing")
			if freya_hunger <= hunger_before_social:
				failures.append("social_hunger_cost_missing")
			if absf(freya_vomit - vomit_before_real_social) > 0.001:
				failures.append("real_dog_social_increased_vomit")
			if bark_pulses.size() <= bark_before:
				failures.append("friendly_bark_not_triggering")

			state = dogs[0]
			state["alien_possessed"] = true
			dogs[0] = state
			var vomit_before_possessed_social = freya_vomit
			Input.action_press("friendly_social")
			_update_dogs(0.5)
			Input.action_release("friendly_social")
			if freya_vomit < vomit_before_possessed_social + POSSESSED_SOCIAL_VOMIT_PER_SEC * 0.5 - 0.01:
				failures.append("possessed_dog_social_vomit_missing")
			state = dogs[0]
			state["alien_possessed"] = false
			dogs[0] = state

			freya_hunger = 0.0
			Input.action_press("friendly_social")
			for step in range(int(ceil((DOG_ARMY_ALIGN_TIME + 0.25) / 0.2))):
				_update_dogs(0.2)
			Input.action_release("friendly_social")
			state = dogs[0]
			if not bool(state.get("army_aligned", false)):
				failures.append("dog_not_army_aligned_after_socializing")
			if _count_nodes_named(dog, "ArmyCamoCollar") != 1:
				failures.append("army_camo_collar_missing")
			elif not dog.has_method("army_collar_is_neck_mounted") or not bool(dog.call("army_collar_is_neck_mounted")):
				failures.append("army_camo_collar_not_neck_mounted_or_has_indicator")
			elif not dog.has_method("army_collar_is_clearly_visible") or not bool(dog.call("army_collar_is_clearly_visible")):
				failures.append("army_camo_collar_not_visually_obvious")
			if state.has("relation") or state.has("wing_node") or _count_nodes_named(dog, "DogRelationWings") > 0:
				failures.append("legacy_dog_relation_or_wings_present")
			interact_highlight_update_timer = 0.0
			_update_interactable_highlights(1.0)
			for highlight_id in interact_highlights.keys():
				if str(highlight_id).begins_with("dog_"):
					failures.append("friendly_dog_overhead_indicator_present")
					break

			if dog.has_method("set_army_aligned"):
				dog.call("set_army_aligned", false)
			state["army_aligned"] = false
			state["socialization_progress"] = 1.0
			dogs[0] = state
			freya_hunger = 100.0
			Input.action_press("friendly_social")
			_update_dogs(0.5)
			Input.action_release("friendly_social")
			state = dogs[0]
			if float(state.get("socialization_progress", 0.0)) > 1.001:
				failures.append("full_hunger_did_not_block_socialization")

			var transfers_before_wrong_guess = alien_transfers.size()
			var army_before_wrong_guess = bool(state.get("army_aligned", false))
			state["alien_possessed"] = false
			state["exorcism_latched"] = false
			state["exorcism_progress"] = 0.0
			state = _update_exorcism_for_dog(state, 0, ALIEN_EXPEL_BARK_TIME, true, true)
			dogs[0] = state
			if float(state.get("flee_timer", 0.0)) < DOG_WRONG_GUESS_FLEE_TIME - 0.01:
				failures.append("real_dog_wrong_guess_flee_missing")
			if bool(state.get("alien_possessed", true)) or bool(state.get("army_aligned", false)) != army_before_wrong_guess:
				failures.append("wrong_guess_changed_dog_state")
			if alien_transfers.size() != transfers_before_wrong_guess:
				failures.append("wrong_guess_spawned_alien")
			for other_index in range(1, dogs.size()):
				var restored_state: Dictionary = dogs[other_index]
				restored_state["alien_possessed"] = saved_other_possession[other_index - 1]
				dogs[other_index] = restored_state
	else:
		failures.append("no_dogs_spawned")

	var near_threshold = maxf(dog_park.size.x, dog_park.size.y) * 0.85 + 3.8
	if initial_spawn_distance > near_threshold:
		failures.append("freya_spawn_not_near_park_%.2f" % initial_spawn_distance)

	# Layout checks
	var over_three_story = 0
	var one_story_buildings = 0
	for b in buildings:
		var floor_count = int(b.get("floors", 0))
		if floor_count > 3:
			over_three_story += 1
		elif floor_count == 1:
			one_story_buildings += 1
	if over_three_story > 0:
		failures.append("buildings_over_three_stories_%d" % over_three_story)
	if buildings.size() > 0 and float(one_story_buildings) / float(buildings.size()) < 0.45:
		failures.append("single_family_home_mix_too_low_%d" % one_story_buildings)
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
	_append_size_validation_failures(failures)
	for issue in _breed_definition_issues():
		failures.append(issue)

	# Street + distribution checks
	if not _road_sidewalk_coverage_ok():
		failures.append("sidewalk_coverage_incomplete")
	var park_count = 0
	var park_breeds := {}
	var park_models := {}
	var park_styles := {}
	var park_shapes := {}
	var park_coats := {}
	var non_voxel_style_dogs = 0
	var nonpark_sidewalk_pref = 0
	var nonpark_total = 0
	for d in dogs:
		if bool(d.get("park", false)):
			park_count += 1
			park_breeds[str(d.get("breed_id", "unknown"))] = true
			park_models[str(d.get("model_path", "procedural"))] = true
			park_styles[str(d.get("visual_style", "unknown"))] = true
			park_shapes[str(d.get("shape_signature", "unknown"))] = true
			park_coats[str(d.get("coat_signature", "unknown"))] = true
		else:
			nonpark_total += 1
			if str(d.get("pref_surface", "")) == "sidewalk":
				nonpark_sidewalk_pref += 1
		if str(d.get("visual_style", "unknown")) != "freya_voxel_rig":
			non_voxel_style_dogs += 1
	if park_count < DOG_PARK_NPC_COUNT:
		failures.append("dog_park_population_low_%d" % park_count)
	if park_breeds.size() < 5:
		failures.append("dog_park_breed_variety_low_%d" % park_breeds.size())
	if park_models.size() != 1 or not park_models.has(FREYA_PRIMARY_MODEL):
		failures.append("dog_park_mixed_art_styles_%d" % park_models.size())
	if park_styles.size() != 1 or not park_styles.has("freya_voxel_rig") or non_voxel_style_dogs > 0:
		failures.append("npc_voxel_style_inconsistent_%d" % non_voxel_style_dogs)
	if park_shapes.size() < 5:
		failures.append("dog_park_voxel_shape_variety_low_%d" % park_shapes.size())
	if park_coats.size() < 5:
		failures.append("dog_park_voxel_coat_variety_low_%d" % park_coats.size())
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
			failures.append("nonpark_sidewalk_usage_low_%.3f" % sidewalk_ratio)
		if grass_ratio < 0.003:
			failures.append("nonpark_grass_venturing_low")
	if not _nonpark_dogs_distributed():
		failures.append("nonpark_distribution_uneven")

	# Pause menu check
	_toggle_pause_menu(1)
	if not get_tree().paused:
		failures.append("pause_menu_not_pausing")
	if pause_intro_button == null or pause_intro_button.text != "Watch Intro":
		failures.append("pause_intro_button_missing")
	elif not pause_intro_button.pressed.is_connected(_on_pause_intro_pressed):
		failures.append("pause_intro_button_signal_missing")
	if INTRO_SCENE_PATH != "res://scenes/IntroCutscene.tscn" or not ResourceLoader.exists(INTRO_SCENE_PATH) or not (load(INTRO_SCENE_PATH) is PackedScene):
		failures.append("pause_intro_route_missing")
	_toggle_pause_menu(0)
	if get_tree().paused:
		failures.append("pause_menu_not_resuming")
	if objectives_panel == null or objectives_list_label == null:
		failures.append("objectives_ui_missing")
	elif objectives_panel.visible:
		failures.append("objectives_panel_initial_visibility_bad")

	if failures.is_empty():
		print("SMOKE_OK: gameplay + layout + animation checks passed")
		return true
	else:
		push_error("SMOKE_FAIL: " + ", ".join(failures))
		return false

func _update_camera(delta: float) -> void:
	if alien_model_preview_node != null and is_instance_valid(alien_model_preview_node) and freya != null:
		var preview_midpoint = (freya.global_position + alien_model_preview_node.global_position) * 0.5
		camera_focus = preview_midpoint + Vector3(0.0, 0.62, 0.0)
		camera_node.global_position = camera_focus + Vector3(2.55, 1.35, -3.15)
		camera_node.look_at(camera_focus + Vector3(0.0, -0.04, 0.0), Vector3.UP)
		return
	if not army_collar_preview_nodes.is_empty():
		var preview_center = Vector3.ZERO
		var preview_count = 0
		for preview_dog in army_collar_preview_nodes:
			if preview_dog != null and is_instance_valid(preview_dog):
				preview_center += preview_dog.global_position
				preview_count += 1
		if preview_count > 0:
			preview_center /= float(preview_count)
			camera_focus = preview_center + Vector3(0.0, 0.55, 0.0)
			camera_node.global_position = camera_focus + Vector3(0.0, 2.35, -6.45)
			camera_node.look_at(camera_focus + Vector3(0.0, -0.08, 0.0), Vector3.UP)
			return
	var look_ahead = freya_move_dir * 1.3
	var target: Vector3 = freya.global_position + Vector3(0.0, 1.0, 0.0) + look_ahead
	if delta <= 0.0:
		camera_focus = target
		camera_planar_distance = camera_zoom_target
	else:
		camera_focus = camera_focus.lerp(target, clamp(delta * 5.2, 0.0, 1.0))
		camera_planar_distance = lerpf(
			camera_planar_distance,
			camera_zoom_target,
			clampf(delta * CAMERA_ZOOM_SMOOTH, 0.0, 1.0)
		)

	var base_planar = Vector3(-1.0, 0.0, 1.0).normalized() * camera_planar_distance
	var planar_offset = base_planar.rotated(Vector3.UP, camera_orbit_angle)
	var zoom_ratio = camera_planar_distance / CAMERA_PLANAR_BASE
	var cam_height = CAMERA_HEIGHT_BASE * clampf(pow(zoom_ratio, 0.88), 0.68, 1.58)
	var offset = Vector3(planar_offset.x, cam_height, planar_offset.z)
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

func _collect_occlusion_candidate_indices(cam_pos: Vector3, target_pos: Vector3) -> Array:
	var out: Array = []
	if buildings.is_empty():
		return out
	var cam2 = Vector2(cam_pos.x, cam_pos.z)
	var target2 = Vector2(target_pos.x, target_pos.z)
	var min_x = minf(cam2.x, target2.x) - 0.6
	var min_z = minf(cam2.y, target2.y) - 0.6
	var max_x = maxf(cam2.x, target2.x) + 0.6
	var max_z = maxf(cam2.y, target2.y) + 0.6
	var corridor = Rect2(Vector2(min_x, min_z), Vector2(maxf(0.001, max_x - min_x), maxf(0.001, max_z - min_z)))
	for i in range(buildings.size()):
		var b: Dictionary = buildings[i]
		var rect: Rect2 = b.get("collision_rect", b["footprint"])
		var expanded = rect.grow(0.2)
		if not corridor.intersects(expanded):
			continue
		var hit = _segment_rect_intersection_2d(cam2, target2, expanded)
		if bool(hit.get("hit", false)) or expanded.has_point(cam2) or expanded.has_point(target2):
			out.append(i)
	return out

func _freya_occluded_by_buildings(cam_pos: Vector3, freya_pos: Vector3, candidate_indices: Array = []) -> bool:
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
	var use_candidates = not candidate_indices.is_empty()
	for sample_idx in range(samples.size()):
		var sample = samples[sample_idx]
		var blocked = false
		if use_candidates:
			for c in candidate_indices:
				var b_idx = int(c)
				if b_idx < 0 or b_idx >= buildings.size():
					continue
				if inside_active_store and active_store_index >= 0 and b_idx == active_store_index:
					continue
				var b: Dictionary = buildings[b_idx]
				if _building_blocks_view_to_target(b, cam_pos, sample):
					blocked = true
					break
		else:
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

func _near_enterable_doorway(building: Dictionary, p: Vector2, margin: float = 1.12) -> bool:
	if not bool(building.get("enterable", false)):
		return false
	if bool(building.get("alien_occupied", false)):
		return false
	var layout: Dictionary = building.get("home_layout", {}) if bool(building.get("is_freya_home", false)) else building.get("store_layout", {})
	if layout.is_empty():
		return false
	var inside: Vector2 = layout.get("entry_inside_pos", Vector2(-1000.0, -1000.0))
	var outside: Vector2 = layout.get("entry_outside_pos", inside)
	var segment = outside - inside
	var closest = inside
	if segment.length_squared() > 0.0001:
		var t = clampf((p - inside).dot(segment) / segment.length_squared(), 0.0, 1.0)
		closest = inside + segment * t
	return p.distance_to(closest) <= margin

func _update_roof_occlusion(delta: float) -> void:
	var cam_pos = camera_node.global_position
	var freya_pos = freya.global_position
	var freya_pos_2d = Vector2(freya_pos.x, freya_pos.z)
	var store_idx_now = active_store_index
	var store_changed = false
	var inside_active_store = _is_inside_store_index(active_store_index, freya_pos_2d)
	occlusion_update_timer = maxf(0.0, occlusion_update_timer - delta)
	var move_eps_sq = OCCLUSION_MOVE_EPS * OCCLUSION_MOVE_EPS
	var cam_moved = cam_pos.distance_squared_to(last_occlusion_cam_pos) > move_eps_sq
	var freya_moved = freya_pos.distance_squared_to(last_occlusion_freya_pos) > move_eps_sq
	if (not store_changed) and occlusion_update_timer > 0.0 and (not cam_moved) and (not freya_moved):
		return
	occlusion_update_timer = OCCLUSION_UPDATE_INTERVAL
	last_occlusion_cam_pos = cam_pos
	last_occlusion_freya_pos = freya_pos
	var occlusion_candidates = _collect_occlusion_candidate_indices(cam_pos, freya_pos + Vector3(0.0, 0.8, 0.0))
	var candidate_set := {}
	for c in occlusion_candidates:
		candidate_set[int(c)] = true

	for i in range(buildings.size()):
		var b: Dictionary = buildings[i]
		var roof_parts: Array = b["roof_parts"]
		var hide_roof = false
		if candidate_set.has(i):
			hide_roof = _building_blocks_view(b, cam_pos, freya_pos)
		if _near_enterable_doorway(b, freya_pos_2d):
			hide_roof = true
		if store_idx_now >= 0 and i == store_idx_now and bool(b.get("is_store", false)):
			hide_roof = inside_active_store or hide_roof

		for part in roof_parts:
			(part as Node3D).visible = not hide_roof

	_clear_occlusion_outlines()
	var occluded_building = _freya_occluded_by_buildings(cam_pos, freya_pos, occlusion_candidates)
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
	# Keep focus logic hooks but no fullscreen gray tint while inside stores.
	store_focus_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	store_focus_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	store_focus_overlay.visible = false
	store_focus_layer.add_child(store_focus_overlay)

	ui_layer = CanvasLayer.new()
	ui_layer.layer = 2
	add_child(ui_layer)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(16, 16)
	panel.size = Vector2(370, 198)
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

	var strength_label = Label.new()
	strength_label.text = "Strength"
	strength_label.position = Vector2(18, 142)
	strength_label.add_theme_font_size_override("font_size", 15)
	panel.add_child(strength_label)
	strength_value_label = Label.new()
	strength_value_label.position = Vector2(292, 142)
	strength_value_label.size = Vector2(72, 20)
	strength_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	strength_value_label.add_theme_font_size_override("font_size", 14)
	panel.add_child(strength_value_label)
	unease_label = Label.new()
	unease_label.position = Vector2(18, 170)
	unease_label.size = Vector2(336, 20)
	unease_label.text = "Freya feels uneasy nearby…"
	unease_label.add_theme_font_size_override("font_size", 14)
	unease_label.add_theme_color_override("font_color", Color(0.62, 1.0, 0.83, 0.98))
	unease_label.visible = false
	panel.add_child(unease_label)

	status_label = Label.new()
	status_label.position = Vector2(16, 231)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.98, 0.95))
	ui_layer.add_child(status_label)

	claim_meter_panel = Panel.new()
	claim_meter_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	claim_meter_panel.size = Vector2(214.0, 68.0)
	var claim_style = StyleBoxFlat.new()
	claim_style.bg_color = Color(0.05, 0.08, 0.09, 0.94)
	claim_style.border_color = Color(0.63, 0.82, 0.87, 0.88)
	claim_style.border_width_left = 2
	claim_style.border_width_top = 2
	claim_style.border_width_right = 2
	claim_style.border_width_bottom = 2
	claim_style.corner_radius_top_left = 8
	claim_style.corner_radius_top_right = 8
	claim_style.corner_radius_bottom_left = 8
	claim_style.corner_radius_bottom_right = 8
	claim_meter_panel.add_theme_stylebox_override("panel", claim_style)
	claim_meter_panel.visible = false
	ui_layer.add_child(claim_meter_panel)

	var claim_wrap = VBoxContainer.new()
	claim_wrap.anchor_right = 1.0
	claim_wrap.anchor_bottom = 1.0
	claim_wrap.offset_left = 11.0
	claim_wrap.offset_top = 7.0
	claim_wrap.offset_right = -11.0
	claim_wrap.offset_bottom = -9.0
	claim_wrap.add_theme_constant_override("separation", 6)
	claim_meter_panel.add_child(claim_wrap)

	claim_meter_label = Label.new()
	claim_meter_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	claim_meter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	claim_meter_label.add_theme_font_size_override("font_size", 14)
	claim_meter_label.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0, 0.98))
	claim_wrap.add_child(claim_meter_label)

	claim_meter_bar = TextureProgressBar.new()
	claim_meter_bar.custom_minimum_size = Vector2(0.0, 17.0)
	claim_meter_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	claim_meter_bar.min_value = 0.0
	claim_meter_bar.max_value = 100.0
	claim_meter_bar.step = 0.1
	claim_meter_bar.texture_under = _make_solid_ui_texture(Color(0.12, 0.15, 0.17, 0.92), Vector2i(512, 18))
	claim_meter_bar.texture_progress = _make_gradient_ui_texture(
		Color(0.2, 0.77, 0.68, 0.98),
		Color(0.98, 0.82, 0.34, 0.98),
		Vector2i(512, 18)
	)
	claim_meter_bar.texture_over = _make_gradient_ui_texture(
		Color(1.0, 1.0, 1.0, 0.16),
		Color(1.0, 1.0, 1.0, 0.03),
		Vector2i(512, 18)
	)
	claim_meter_bar.tint_under = Color(1.0, 1.0, 1.0, 1.0)
	claim_meter_bar.tint_progress = Color(1.0, 1.0, 1.0, 1.0)
	claim_meter_bar.tint_over = Color(1.0, 1.0, 1.0, 1.0)
	claim_wrap.add_child(claim_meter_bar)

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

	var minimap_header = VBoxContainer.new()
	minimap_header.anchor_left = 0.0
	minimap_header.anchor_top = 0.0
	minimap_header.anchor_right = 1.0
	minimap_header.anchor_bottom = 0.0
	minimap_header.offset_left = 10.0
	minimap_header.offset_top = 8.0
	minimap_header.offset_right = -10.0
	minimap_header.offset_bottom = 56.0
	minimap_header.add_theme_constant_override("separation", 4)
	minimap_header.z_index = 2
	minimap_panel.add_child(minimap_header)

	var top_row = HBoxContainer.new()
	top_row.custom_minimum_size = Vector2(0.0, 22.0)
	top_row.add_theme_constant_override("separation", 6)
	minimap_header.add_child(top_row)

	var mini_title = Label.new()
	mini_title.text = "Minimap"
	mini_title.add_theme_font_size_override("font_size", 16)
	mini_title.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 0.98))
	top_row.add_child(mini_title)

	var header_spacer = Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(header_spacer)

	var zoom_label = Label.new()
	zoom_label.text = "Zoom"
	zoom_label.add_theme_font_size_override("font_size", 13)
	zoom_label.add_theme_color_override("font_color", Color(0.9, 0.94, 0.97, 0.95))
	top_row.add_child(zoom_label)

	minimap_zoom_slider = HSlider.new()
	minimap_zoom_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	minimap_zoom_slider.custom_minimum_size = Vector2(0.0, 16.0)
	minimap_zoom_slider.min_value = 1.0
	minimap_zoom_slider.max_value = 4.5
	minimap_zoom_slider.step = 0.05
	minimap_zoom_slider.value = 2.6
	minimap_zoom_slider.value_changed.connect(_on_minimap_zoom_changed)
	minimap_header.add_child(minimap_zoom_slider)

	minimap = MiniMapScript.new()
	minimap.anchor_left = 0.0
	minimap.anchor_top = 0.0
	minimap.anchor_right = 1.0
	minimap.anchor_bottom = 1.0
	minimap.offset_left = 10.0
	minimap.offset_top = 64.0
	minimap.offset_right = -10.0
	minimap.offset_bottom = -10.0
	minimap_panel.add_child(minimap)
	minimap.set_zoom(minimap_zoom_slider.value)

	_create_objectives_overlay()
	_create_stats_overlay()
	_create_pause_menu()

func _create_objectives_overlay() -> void:
	objectives_panel = Panel.new()
	objectives_panel.anchor_left = 0.5
	objectives_panel.anchor_top = 0.5
	objectives_panel.anchor_right = 0.5
	objectives_panel.anchor_bottom = 0.5
	objectives_panel.offset_left = -250.0
	objectives_panel.offset_top = -122.0
	objectives_panel.offset_right = 250.0
	objectives_panel.offset_bottom = 122.0
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
	objectives_list_label.size = Vector2(470.0, 186.0)
	objectives_list_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	objectives_list_label.add_theme_font_size_override("font_size", 15)
	objectives_panel.add_child(objectives_list_label)

func _update_objectives_overlay() -> void:
	if objectives_panel == null:
		return
	var should_show = (not pause_menu_open) and Input.is_action_pressed("objectives")
	objectives_panel.visible = should_show
	if should_show and objectives_list_label != null:
		objectives_list_label.text = _objectives_text()

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
		+ "- %s Claim 8 fire hydrants (%d/%d)\n" % [hydrants_state, hydrants_claimed, OBJECTIVE_HYDRANT_TARGET]
		+ "- Trust Freya's unease; hold X to bark near suspicious dogs\n"
		+ "- Expelled aliens: %d | Free aliens: %d/%d\n" % [alien_expulsion_count, free_aliens.size(), MAX_FREE_ALIENS]
		+ "- Alien buildings: %d | Occupants inside: %d\n" % [_alien_occupied_building_count(), _alien_total_occupant_count()]
		+ "- Hold R beside an alien wall to weaken its hold"
	)

func _create_stats_overlay() -> void:
	stats_panel = Panel.new()
	stats_panel.anchor_left = 0.5
	stats_panel.anchor_top = 0.0
	stats_panel.anchor_right = 0.5
	stats_panel.anchor_bottom = 0.0
	stats_panel.offset_left = -230.0
	stats_panel.offset_top = 178.0
	stats_panel.offset_right = 230.0
	stats_panel.offset_bottom = 272.0
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
	stats_panel.add_theme_stylebox_override("panel", panel_style)
	stats_panel.visible = false
	ui_layer.add_child(stats_panel)

	var title = Label.new()
	title.text = "Stats"
	title.position = Vector2(14.0, 8.0)
	title.add_theme_font_size_override("font_size", 18)
	stats_panel.add_child(title)

	stats_list_label = Label.new()
	stats_list_label.text = _stats_text()
	stats_list_label.position = Vector2(16.0, 34.0)
	stats_list_label.size = Vector2(426.0, 58.0)
	stats_list_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stats_list_label.add_theme_font_size_override("font_size", 15)
	stats_panel.add_child(stats_list_label)

func _stats_text() -> String:
	return (
		"- Strength Level: %d/%d\n" % [freya_strength, FREYA_STRENGTH_MAX_LEVEL]
		+ "- Bones Needed For Max: %d" % max(0, FREYA_STRENGTH_MAX_LEVEL - freya_strength)
	)

func _update_stats_overlay() -> void:
	if stats_panel == null:
		return
	# Strength is now in the upper-left HUD; keep this panel hidden.
	stats_panel.visible = false

func _claimed_light_pole_count() -> int:
	var total = 0
	for pole in street_poles:
		if _entry_is_claimed_by(pole, CLAIM_OWNER_FREYA):
			total += 1
	return total

func _claimed_tree_count() -> int:
	var total = 0
	for tree in trees:
		if _entry_is_claimed_by(tree, CLAIM_OWNER_FREYA):
			total += 1
	return total

func _claimed_fire_hydrant_count() -> int:
	var total = 0
	for hydrant in fire_hydrants:
		if _entry_is_claimed_by(hydrant, CLAIM_OWNER_FREYA):
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
	pause_menu_panel.offset_top = -235.0
	pause_menu_panel.offset_right = 285.0
	pause_menu_panel.offset_bottom = 235.0
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
	resume_btn.size = Vector2(166, 44)
	resume_btn.pressed.connect(_on_pause_resume_pressed)
	pause_menu_panel.add_child(resume_btn)

	pause_controls_button = Button.new()
	pause_controls_button.text = "Controls"
	pause_controls_button.position = Vector2(202, 62)
	pause_controls_button.size = Vector2(166, 44)
	pause_controls_button.pressed.connect(_on_pause_controls_pressed)
	pause_menu_panel.add_child(pause_controls_button)

	pause_howto_button = Button.new()
	pause_howto_button.text = "How To Play"
	pause_howto_button.position = Vector2(382, 62)
	pause_howto_button.size = Vector2(166, 44)
	pause_howto_button.pressed.connect(_on_pause_howto_pressed)
	pause_menu_panel.add_child(pause_howto_button)

	pause_intro_button = Button.new()
	pause_intro_button.name = "WatchIntroButton"
	pause_intro_button.text = "Watch Intro"
	pause_intro_button.position = Vector2(22, 114)
	pause_intro_button.size = Vector2(256, 44)
	pause_intro_button.tooltip_text = "Replay the intro cut-scene. A new game begins when it ends or is skipped."
	pause_intro_button.pressed.connect(_on_pause_intro_pressed)
	pause_menu_panel.add_child(pause_intro_button)

	var exit_btn = Button.new()
	exit_btn.text = "Quit Game"
	exit_btn.position = Vector2(292, 114)
	exit_btn.size = Vector2(256, 44)
	exit_btn.pressed.connect(_on_pause_exit_pressed)
	pause_menu_panel.add_child(exit_btn)

	pause_controls_panel = Panel.new()
	pause_controls_panel.position = Vector2(22, 172)
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
	controls.text = "WASD / Arrows: Move\nShift: Run (raises Hunger faster than walking)\nQ / E: Rotate camera\nF: Eat / use Freya's home bowl / pick up a stick\nV: Drop carried stick\nHold R: Claim trees, poles, fire hydrants, and mailboxes\nHold R by an alien wall: Weaken its hold\nHold R near dumpster: Search dumpster\nSpace: Vomit (when meter is full)\nHold C near dogs: Socialize at a Hunger cost; possessed dogs also raise Vomit\nHold X near dogs: Expel an alien or scare a real dog away\nApproach free aliens: Make them flee to the nearest building\nTab (hold): Objectives\nEsc: Pause / resume"
	controls.custom_minimum_size = Vector2(482, 420)
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD
	controls.add_theme_font_size_override("font_size", 16)
	controls_scroll.add_child(controls)

	pause_howto_panel = Panel.new()
	pause_howto_panel.position = Vector2(22, 172)
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
	howto_text.text = "You are Freya, the world's best dog, on a mission to protect and claim this neighborhood. Hunger barely changes while Freya rests; walking raises it faster, and running or taking sustained actions raises it faster still. Hold R beside a tree, pole, fire hydrant, or mailbox to pee on and claim it; claimed targets get Freya's ring and minimap marker, and can be reclaimed from aliens. Some ordinary-looking dogs secretly carry aliens. They never look different, but Freya automatically crouches, shivers, and tucks her tail when one is close. Hold X near a suspicious dog: a possessed dog is cleansed, while a real dog flees from the wrong guess. Hold C to socialize at a Hunger cost; socializing with a possessed dog also raises Vomit, and after enough time a real dog joins Freya's army and receives a camouflage collar. Press F beside the food bowl in Ryah Diane's house to reset Hunger to zero; the bowl is always available. Expelled aliens race toward buildings, and occupied storefronts lock, reinforce nearby alien buildings, and generate at most eight free aliens across the map. Approach a free alien to send it fleeing to the nearest building. Ryah Diane's crying protects Freya's home. Hold R beside an alien wall to permanently weaken its hold."
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

func _on_pause_intro_pressed() -> void:
	# The pause menu owns SceneTree.paused. Clear it before changing scenes so
	# the intro and the fresh gameplay scene it launches both advance normally.
	_toggle_pause_menu(0)
	var error = get_tree().change_scene_to_file(INTRO_SCENE_PATH)
	if error != OK:
		push_error("Could not open intro from the in-game menu (error %d)." % error)
		_toggle_pause_menu(1)

func _on_pause_exit_pressed() -> void:
	get_tree().quit()

func _make_solid_ui_texture(color: Color, size: Vector2i) -> Texture2D:
	var w = maxi(2, size.x)
	var h = maxi(2, size.y)
	var image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

func _make_gradient_ui_texture(left_color: Color, right_color: Color, size: Vector2i) -> Texture2D:
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([left_color, right_color])
	var texture = GradientTexture2D.new()
	texture.width = maxi(2, size.x)
	texture.height = maxi(2, size.y)
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.0, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	return texture

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
	hud_update_timer = maxf(0.0, hud_update_timer - get_process_delta_time())
	if hud_update_timer > 0.0:
		return
	hud_update_timer = HUD_UPDATE_INTERVAL
	hunger_bar.value = freya_hunger
	vomit_bar.value = freya_vomit
	social_bar.value = freya_social

	hunger_value_label.text = "%d%%" % int(round(freya_hunger))
	vomit_value_label.text = "%d%%" % int(round(freya_vomit))
	social_value_label.text = "%d%%" % int(round(freya_social))
	if strength_value_label != null:
		strength_value_label.text = "%d/%d" % [freya_strength, FREYA_STRENGTH_MAX_LEVEL]
	if unease_label != null:
		unease_label.visible = freya_alien_discomfort > 0.12
		if unease_label.visible:
			var intensity_word = "very uneasy" if freya_alien_discomfort > 0.62 else "uneasy"
			unease_label.text = "Freya feels %s nearby…" % intensity_word

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
	var home_rect = Rect2()
	for b in buildings:
		building_rects.append(b["footprint"])
		if bool(b.get("is_freya_home", false)):
			home_rect = b["footprint"]
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
	minimap.home_building = home_rect
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

	var claim_points = _collect_claimed_minimap_points()
	var alien_building_rects: Array[Rect2] = []
	var alien_building_integrities = PackedFloat32Array()
	for building in buildings:
		if not bool(building.get("alien_occupied", false)):
			continue
		alien_building_rects.append(building.get("footprint", Rect2()))
		alien_building_integrities.append(float(building.get("alien_integrity", 1.0)))

	var map_forward = -camera_node.global_transform.basis.z
	map_forward.y = 0.0
	if map_forward.length_squared() < 0.000001:
		map_forward = Vector3(1.0, 0.0, -1.0)
	map_forward = map_forward.normalized()
	var freya_forward = -freya.global_transform.basis.z
	freya_forward.y = 0.0
	if freya_forward.length_squared() < 0.000001:
		freya_forward = map_forward
	freya_forward = freya_forward.normalized()

	minimap.update_dynamic(
		Vector2(freya.global_position.x, freya.global_position.z),
		dog_points,
		poop_points,
		vomit_points,
		Vector2(map_forward.x, map_forward.z),
		Vector2(freya_forward.x, freya_forward.z),
		claim_points["poles_freya"],
		claim_points["trees_freya"],
		claim_points["hydrants_freya"],
		claim_points["mailboxes_freya"],
		claim_points["poles_enemy"],
		claim_points["trees_enemy"],
		claim_points["hydrants_enemy"],
		claim_points["mailboxes_enemy"],
		alien_building_rects,
		alien_building_integrities
	)

func _collect_claimed_minimap_points() -> Dictionary:
	var poles_freya = PackedVector2Array()
	var trees_freya = PackedVector2Array()
	var hydrants_freya = PackedVector2Array()
	var mailboxes_freya = PackedVector2Array()
	var poles_enemy = PackedVector2Array()
	var trees_enemy = PackedVector2Array()
	var hydrants_enemy = PackedVector2Array()
	var mailboxes_enemy = PackedVector2Array()

	for pole in street_poles:
		var pos: Vector2 = pole.get("pos", Vector2.ZERO)
		var owner = _claim_owner_from_entry(pole)
		if owner == CLAIM_OWNER_FREYA:
			poles_freya.append(pos)
		elif owner == CLAIM_OWNER_ENEMY:
			poles_enemy.append(pos)
	for tree in trees:
		var pos: Vector2 = tree.get("pos", Vector2.ZERO)
		var owner = _claim_owner_from_entry(tree)
		if owner == CLAIM_OWNER_FREYA:
			trees_freya.append(pos)
		elif owner == CLAIM_OWNER_ENEMY:
			trees_enemy.append(pos)
	for hydrant in fire_hydrants:
		var pos: Vector2 = hydrant.get("pos", Vector2.ZERO)
		var owner = _claim_owner_from_entry(hydrant)
		if owner == CLAIM_OWNER_FREYA:
			hydrants_freya.append(pos)
		elif owner == CLAIM_OWNER_ENEMY:
			hydrants_enemy.append(pos)
	for mailbox in mailboxes:
		var pos: Vector2 = mailbox.get("pos", Vector2.ZERO)
		var owner = _claim_owner_from_entry(mailbox)
		if owner == CLAIM_OWNER_FREYA:
			mailboxes_freya.append(pos)
		elif owner == CLAIM_OWNER_ENEMY:
			mailboxes_enemy.append(pos)

	return {
		"poles_freya": poles_freya,
		"trees_freya": trees_freya,
		"hydrants_freya": hydrants_freya,
		"mailboxes_freya": mailboxes_freya,
		"poles_enemy": poles_enemy,
		"trees_enemy": trees_enemy,
		"hydrants_enemy": hydrants_enemy,
		"mailboxes_enemy": mailboxes_enemy
	}

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
