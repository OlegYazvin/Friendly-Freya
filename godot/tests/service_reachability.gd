extends SceneTree

# Start at each service-store doorway and flood through the live Freya collision
# rules. The targeted smoke check only placed Freya at the service prop.
const SEEDS = [20260831, 1, 42, 20260916, 20261014]
const SERVICE_TYPES = ["infinite_dog_food", "possession_immunity_medicine", "dog_armor", "clinic_recovery_kit"]
const STEP = 0.1
var failures: Array[String] = []


func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	create_timer(180.0).timeout.connect(func():
		push_error("SERVICE_REACHABILITY_FAIL: timed out")
		quit(1)
	)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error("SERVICE_REACHABILITY: " + message)


func _grid_point(id: Vector2i) -> Vector2:
	return Vector2(float(id.x) * STEP, float(id.y) * STEP)


func _edge_walkable(scene: Node, from: Vector2, to: Vector2) -> bool:
	for i in range(1, 3):
		var point = from.lerp(to, float(i) * 0.5)
		if not scene._is_walkable(point.x, point.y, scene.FREYA_COLLISION_RADIUS):
			return false
	return true


func _reachable_service_point(scene: Node, building_index: int, service_position: Vector2) -> Dictionary:
	var building: Dictionary = scene.buildings[building_index]
	var entry: Vector2 = building.get("store_layout", {}).get("entry_inside_pos", Vector2.ZERO)
	var interior: Rect2 = building.get("store_interior_rect", Rect2())
	var search_rect = interior.grow(0.25)
	var entry_id = Vector2i(roundi(entry.x / STEP), roundi(entry.y / STEP))
	var queue: Array[Vector2i] = []
	var seen: Dictionary = {}
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var id = entry_id + Vector2i(dx, dz)
			var point = _grid_point(id)
			if point.distance_to(entry) > 0.17 or not search_rect.has_point(point):
				continue
			if not _edge_walkable(scene, entry, point):
				continue
			queue.append(id)
			seen[id] = true
	var cursor = 0
	var closest_distance = INF
	while cursor < queue.size():
		var id = queue[cursor]
		cursor += 1
		var point = _grid_point(id)
		var distance = point.distance_to(service_position)
		if interior.grow(-0.05).has_point(point):
			closest_distance = minf(closest_distance, distance)
			if distance <= scene.BUILDING_SERVICE_RANGE - 0.05 and scene._is_inside_store_index(building_index, point):
				return {"found": true, "pos": point, "distance": distance, "steps": cursor}
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next = id + offset
			if seen.has(next):
				continue
			var next_point = _grid_point(next)
			if not search_rect.has_point(next_point) or not _edge_walkable(scene, point, next_point):
				continue
			seen[next] = true
			queue.append(next)
	return {"found": false, "visited": cursor, "closest": closest_distance}


func _check_service_effect(scene: Node, service_type: String, position: Vector2) -> bool:
	scene.freya.global_position = Vector3(position.x, scene.freya.global_position.y, position.y)
	match service_type:
		"infinite_dog_food":
			scene.freya_hunger = 83.0
			return scene._try_use_building_service() and scene.freya_hunger <= 0.001
		"possession_immunity_medicine":
			scene.freya_carries_immunity_dose = false
			return scene._try_use_building_service() and scene.freya_carries_immunity_dose
		"dog_armor":
			scene.freya_carries_dog_armor = false
			return scene._try_use_building_service() and scene.freya_carries_dog_armor
		"clinic_recovery_kit":
			scene.freya_carries_clinic_kit = false
			return scene._try_use_building_service() and scene.freya_carries_clinic_kit
	return false


func _run() -> void:
	for seed in SEEDS:
		OS.set_environment("FREYA_WORLD_SEED", str(seed))
		_check(change_scene_to_file("res://scenes/Main.tscn") == OK, "seed %d failed to load Main" % seed)
		await scene_changed
		var scene = current_scene
		scene.set_process(false)
		scene.game_save_incompatible = true
		for service_type in SERVICE_TYPES:
			var service: Dictionary = {}
			for item in scene.building_services:
				if str(item.get("service_type", "")) == service_type:
					service = item
					break
			_check(not service.is_empty(), "seed %d missing %s" % [seed, service_type])
			if service.is_empty():
				continue
			var index = int(service.get("building_index", -1))
			if bool(scene.buildings[index].get("alien_occupied", false)):
				scene._clear_alien_occupation(index)
			var position: Vector2 = service.get("pos", Vector2.ZERO)
			var node: Node3D = service.get("node", null)
			_check(node != null and is_instance_valid(node) and Vector2(node.global_position.x, node.global_position.z).distance_to(position) < 0.01, "seed %d %s visual and F position differ" % [seed, service_type])
			_check(scene.buildings[index].get("store_interior_rect", Rect2()).grow(-0.05).has_point(position) and scene._is_walkable(position.x, position.y, scene.FREYA_COLLISION_RADIUS), "seed %d %s prop is outside walkable interior at %s" % [seed, service_type, position])
			var approach = _reachable_service_point(scene, index, position)
			_check(bool(approach.get("found", false)), "seed %d %s at %s has no doorway-connected true-interior F point: %s" % [seed, service_type, position, approach])
			if not bool(approach.get("found", false)):
				continue
			var target: Vector2 = approach.get("pos", Vector2.ZERO)
			_check(_check_service_effect(scene, service_type, target), "seed %d %s F failed from reachable %s" % [seed, service_type, target])
			print("SERVICE_REACHABILITY_POINT seed=%d type=%s pos=%s service=%s distance=%.3f steps=%d" % [seed, service_type, target, position, float(approach.get("distance", 0.0)), int(approach.get("steps", 0))])
		await process_frame
	if failures.is_empty():
		print("SERVICE_REACHABILITY_OK: five seeds, four services, doorway-connected Freya-radius routes and F effects")
		quit()
	else:
		push_error("SERVICE_REACHABILITY_FAIL: %d findings" % failures.size())
		quit(1)
