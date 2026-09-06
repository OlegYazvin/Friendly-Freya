extends Node3D
class_name KennelBuilding

signal possessed_dog_spawn_requested(spawn_world_position: Vector3, spawn_number: int)
signal freya_first_entry_message_requested(text: String)
signal caged_dog_depossessed(cage_index: int, dog: Node3D)

const KennelFactoryScript = preload("res://scripts/kennel_factory.gd")

const FIRST_ENTRY_TEXT = "I'll find a way to free you!"
const POSSESSED_DOG_SPAWN_LIMIT = KennelFactoryScript.POSSESSED_DOG_LIFETIME_SPAWN_LIMIT
const DEFAULT_POSSESSED_DOG_SPAWN_INTERVAL = 8.0

@export var preview_cutaway = false
@export_range(1.0, 60.0, 0.5) var possessed_dog_spawn_interval = DEFAULT_POSSESSED_DOG_SPAWN_INTERVAL

var possessed = false
var enterable = true
var total_possessed_dogs_spawned = 0
var spawn_budget_closed = false
var spawn_timer = DEFAULT_POSSESSED_DOG_SPAWN_INTERVAL
var spawn_request_pending = false
var pending_spawn_number = 0
var freya_has_entered = false
var visual_data: Dictionary = {}


func _ready() -> void:
	if visual_data.is_empty():
		_build_visual()
	set_process(true)


func configure(config: Dictionary = {}) -> void:
	preview_cutaway = bool(config.get("cutaway", preview_cutaway))
	possessed_dog_spawn_interval = maxf(1.0, float(config.get("possessed_dog_spawn_interval", possessed_dog_spawn_interval)))
	if visual_data.is_empty():
		_build_visual()
	set_possessed(bool(config.get("possessed", possessed)))


func _build_visual() -> void:
	visual_data = KennelFactoryScript.create_kennel(preview_cutaway)
	var visual_root: Node3D = visual_data.get("node", null)
	if visual_root != null:
		add_child(visual_root, true)
	set_meta("visual_signature", "friendly_freya_kennel_building_v1")
	set_meta("building_archetype", KennelFactoryScript.ARCHETYPE_ID)
	set_meta("placement_ready", true)
	set_meta("possessed_dog_spawn_limit", POSSESSED_DOG_SPAWN_LIMIT)
	set_meta("caged_dog_count", KennelFactoryScript.CAGED_DOG_COUNT)
	set_meta("canonical_dog_model", KennelFactoryScript.CANONICAL_DOG_MODEL)
	set_meta("freya_first_entry_text", FIRST_ENTRY_TEXT)
	spawn_timer = possessed_dog_spawn_interval
	_reset_caged_dog_possession()
	_update_state_visuals()


func _process(delta: float) -> void:
	for dog in visual_data.get("caged_dogs", []):
		if dog is Node3D and is_instance_valid(dog) and dog.has_method("update_motion"):
			dog.call("update_motion", delta, Vector3.ZERO, false, false)
	advance_spawn_clock(delta)


func set_possessed(value: bool) -> void:
	var was_possessed = possessed
	possessed = value
	enterable = not possessed
	if not possessed:
		spawn_request_pending = false
		pending_spawn_number = 0
		if was_possessed:
			# Cleansing ends this kennel's production run. Unspawned dogs are
			# deliberately forfeited instead of waiting for a later re-possession.
			spawn_budget_closed = true
	if possessed and spawn_timer <= 0.0:
		spawn_timer = possessed_dog_spawn_interval
	set_meta("alien_possessed", possessed)
	set_meta("enterable", enterable)
	_update_state_visuals()


func cleanse_kennel_possession() -> bool:
	if not possessed:
		return false
	set_possessed(false)
	return true


func set_cutaway(value: bool) -> void:
	preview_cutaway = value
	var facade: Node3D = visual_data.get("facade", null)
	var roof_root: Node3D = visual_data.get("roof_root", null)
	var cutaway_side_wall: Node3D = visual_data.get("cutaway_side_wall", null)
	if facade != null:
		facade.visible = not value
	if roof_root != null:
		roof_root.visible = not value
	if cutaway_side_wall != null:
		cutaway_side_wall.visible = not value
	var visual_root: Node3D = visual_data.get("node", null)
	if visual_root != null:
		visual_root.set_meta("cutaway_enabled", value)
	_update_state_visuals()


func notify_freya_entered() -> String:
	if not enterable or possessed or freya_has_entered:
		return ""
	freya_has_entered = true
	set_meta("freya_first_entry_seen", true)
	freya_first_entry_message_requested.emit(FIRST_ENTRY_TEXT)
	return FIRST_ENTRY_TEXT


func depossess_caged_dog(cage_index: int) -> bool:
	var caged_dogs: Array = visual_data.get("caged_dogs", [])
	if cage_index < 0 or cage_index >= caged_dogs.size():
		return false
	var dog = caged_dogs[cage_index]
	if not (dog is Node3D) or not is_instance_valid(dog) or not bool(dog.get_meta("alien_possessed", false)):
		return false
	dog.set_meta("alien_possessed", false)
	dog.set_meta("alien_expelled", true)
	_update_caged_dog_possession_metadata()
	caged_dog_depossessed.emit(cage_index, dog)
	return true


func advance_spawn_clock(delta: float) -> int:
	if not possessed or spawn_budget_closed or total_possessed_dogs_spawned >= POSSESSED_DOG_SPAWN_LIMIT or delta <= 0.0 or spawn_request_pending:
		return 0
	spawn_timer -= delta
	var requests = 0
	while spawn_timer <= 0.0 and total_possessed_dogs_spawned < POSSESSED_DOG_SPAWN_LIMIT:
		spawn_request_pending = true
		pending_spawn_number = total_possessed_dogs_spawned + 1
		set_meta("possessed_dog_spawn_request_pending", true)
		requests += 1
		possessed_dog_spawn_requested.emit(get_possessed_dog_spawn_world_position(), pending_spawn_number)
		if spawn_request_pending:
			# The placement owner must explicitly confirm a successfully registered
			# dog or reject a request when it cannot safely place another character.
			spawn_timer = 0.0
			break
		spawn_timer += possessed_dog_spawn_interval
	return requests


func confirm_possessed_dog_spawned(spawn_number: int) -> bool:
	if spawn_budget_closed or not spawn_request_pending or spawn_number != pending_spawn_number or total_possessed_dogs_spawned >= POSSESSED_DOG_SPAWN_LIMIT:
		return false
	total_possessed_dogs_spawned += 1
	spawn_request_pending = false
	pending_spawn_number = 0
	_update_capacity_pods()
	return true


func reject_possessed_dog_spawn_request(retry_delay: float = 1.5) -> void:
	if not spawn_request_pending:
		return
	spawn_request_pending = false
	pending_spawn_number = 0
	spawn_timer = maxf(0.25, retry_delay)
	_update_capacity_pods()


func reset_for_new_level() -> void:
	possessed = false
	enterable = true
	total_possessed_dogs_spawned = 0
	spawn_budget_closed = false
	spawn_timer = possessed_dog_spawn_interval
	spawn_request_pending = false
	pending_spawn_number = 0
	freya_has_entered = false
	set_meta("alien_possessed", false)
	set_meta("enterable", true)
	set_meta("freya_first_entry_seen", false)
	_reset_caged_dog_possession()
	_update_state_visuals()


func remaining_possessed_dog_spawn_capacity() -> int:
	if spawn_budget_closed:
		return 0
	return maxi(0, POSSESSED_DOG_SPAWN_LIMIT - total_possessed_dogs_spawned)


func forfeited_possessed_dog_spawn_count() -> int:
	if not spawn_budget_closed:
		return 0
	return maxi(0, POSSESSED_DOG_SPAWN_LIMIT - total_possessed_dogs_spawned)


func get_possessed_dog_spawn_world_position() -> Vector3:
	return to_global(visual_data.get("possessed_dog_spawn_local", KennelFactoryScript.POSSESSED_DOG_SPAWN_LOCAL))


func placement_contract() -> Dictionary:
	return {
		"archetype_id": KennelFactoryScript.ARCHETYPE_ID,
		"display_name": KennelFactoryScript.DISPLAY_NAME,
		"footprint_size": visual_data.get("footprint_size", KennelFactoryScript.FOOTPRINT_SIZE),
		"interior_rect_local": visual_data.get("interior_rect_local", KennelFactoryScript.INTERIOR_RECT_LOCAL),
		"entry_inside_local": visual_data.get("entry_inside_local", KennelFactoryScript.ENTRY_INSIDE_LOCAL),
		"entry_outside_local": visual_data.get("entry_outside_local", KennelFactoryScript.ENTRY_OUTSIDE_LOCAL),
		"possessed_dog_spawn_local": visual_data.get("possessed_dog_spawn_local", KennelFactoryScript.POSSESSED_DOG_SPAWN_LOCAL),
		"wall_blockers_local": visual_data.get("wall_blockers_local", []),
		"fixture_blockers_local": visual_data.get("fixture_blockers_local", []),
		"transparent_window_count": int(visual_data.get("transparent_window_count", 0)),
		"caged_dog_count": int(visual_data.get("caged_dog_count", 0)),
		"canonical_dog_model": KennelFactoryScript.CANONICAL_DOG_MODEL,
		"clean_enterable": true,
		"possessed_enterable": false,
		"first_entry_text": FIRST_ENTRY_TEXT,
		"possessed_dog_spawn_interval": possessed_dog_spawn_interval,
		"possessed_dog_lifetime_spawn_limit": POSSESSED_DOG_SPAWN_LIMIT,
		"spawn_signal": "possessed_dog_spawn_requested",
		"spawn_success_method": "confirm_possessed_dog_spawned",
		"spawn_retry_method": "reject_possessed_dog_spawn_request",
		"kennel_cleanse_method": "cleanse_kennel_possession",
		"caged_dog_depossession_method": "depossess_caged_dog",
		"cleansing_forfeits_unspawned_dogs": true
	}


func _update_state_visuals() -> void:
	var clean_details: Node3D = visual_data.get("clean_details", null)
	var possession_overlay: Node3D = visual_data.get("possession_overlay", null)
	if clean_details != null:
		clean_details.visible = not possessed and not preview_cutaway
	if possession_overlay != null:
		possession_overlay.visible = possessed
	_update_capacity_pods()


func _update_capacity_pods() -> void:
	var capacity_pods: Array = visual_data.get("capacity_pods", [])
	for pod_index in range(capacity_pods.size()):
		var pod: Node3D = capacity_pods[pod_index]
		if pod != null and is_instance_valid(pod):
			pod.visible = not spawn_budget_closed and pod_index >= total_possessed_dogs_spawned
	set_meta("possessed_dog_total_spawned", total_possessed_dogs_spawned)
	set_meta("possessed_dog_spawn_capacity_remaining", remaining_possessed_dog_spawn_capacity())
	set_meta("possessed_dog_spawn_count_forfeited", forfeited_possessed_dog_spawn_count())
	set_meta("possessed_dog_spawn_budget_closed", spawn_budget_closed)
	set_meta("possessed_dog_spawn_request_pending", spawn_request_pending)


func _reset_caged_dog_possession() -> void:
	for dog in visual_data.get("caged_dogs", []):
		if dog is Node3D and is_instance_valid(dog):
			dog.set_meta("alien_possessed", true)
			dog.set_meta("alien_origin_possessed", true)
			dog.set_meta("alien_expelled", false)
	_update_caged_dog_possession_metadata()


func _update_caged_dog_possession_metadata() -> void:
	var possessed_count = 0
	for dog in visual_data.get("caged_dogs", []):
		if dog is Node3D and is_instance_valid(dog) and bool(dog.get_meta("alien_possessed", false)):
			possessed_count += 1
	set_meta("caged_dogs_possessed", possessed_count)
	set_meta("caged_dogs_depossessed", KennelFactoryScript.CAGED_DOG_COUNT - possessed_count)
