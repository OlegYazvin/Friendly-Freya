extends RefCounted

# A sufficient static-route certificate for the generated city. Every
# non-home building is treated as occupied in the main flood, so a connected
# exterior path remains connected under any smaller occupation set. Clearing
# one target can only open its doorway and interior. This uses the same Freya
# collision predicate as movement; it does not mutate the live world.
const GRID_STEP = 0.5
const SERVICE_GRID_STEP = 0.1
const CARDINAL_OFFSETS = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const REQUIRED_SERVICE_TYPES = ["infinite_dog_food", "possession_immunity_medicine", "dog_armor", "clinic_recovery_kit"]
const SERVICE_BUILDING_TYPES = {
	"infinite_dog_food": "grocery",
	"possession_immunity_medicine": "pharmacy",
	"dog_armor": "police_station",
	"clinic_recovery_kit": "medical_clinic"
}


static func evaluate(scene: Node, extra_blockers: Array[Rect2] = []) -> Dictionary:
	var issues: Array[String] = []
	var result = {"ok": false, "issues": issues, "nodes": 0, "walls": 0, "marks": 0, "doors": 0, "cages": 0, "service_count": scene.building_services.size(), "services": 0}
	if scene.freya_home_index < 0 or scene.freya_home_index >= scene.buildings.size():
		issues.append("home_missing")
		return result
	if scene.kennel_building_index < 0 or scene.kennel_building_index >= scene.buildings.size() or scene.kennel == null:
		issues.append("lodge_missing")
		return result
	var home: Dictionary = scene.buildings[scene.freya_home_index]
	var home_layout: Dictionary = home.get("home_layout", {})
	var home_inside: Vector2 = home_layout.get("entry_inside_pos", Vector2.ZERO)
	var home_outside: Vector2 = home_layout.get("entry_outside_pos", Vector2.ZERO)
	var every_site_occupied = _occupation_grid(scene)
	if not _walk_segment(scene, home_inside, home_outside, every_site_occupied, extra_blockers):
		issues.append("home_door_blocked")
		return result
	if not _walkable(scene, home_outside, every_site_occupied, extra_blockers):
		issues.append("home_exterior_blocked")
		return result
	var exterior_grid = _connected_grid(scene, home_outside, every_site_occupied, extra_blockers)
	result["nodes"] = int(exterior_grid.get("nodes", 0))
	if int(result["nodes"]) == 0:
		issues.append("home_exterior_disconnected")
		return result

	for index in range(scene.buildings.size()):
		if index == scene.freya_home_index:
			continue
		if _wall_has_approach(scene, exterior_grid, every_site_occupied, extra_blockers, index):
			result["walls"] += 1
		else:
			issues.append("wall:%d" % index)

	var checked_marks: Dictionary = {}
	for index in range(scene.buildings.size()):
		if index == scene.freya_home_index or index == scene.kennel_building_index:
			continue
		for item in scene._building_surrounding_claimables(index):
			var key = "%d:%d" % [int(item.get("type", -1)), int(item.get("index", -1))]
			if checked_marks.has(key):
				continue
			checked_marks[key] = true
			if _mark_has_approach(scene, exterior_grid, every_site_occupied, extra_blockers, item):
				result["marks"] += 1
			else:
				issues.append("mark:%s" % key)

	for index in range(scene.buildings.size()):
		if index == scene.freya_home_index:
			continue
		var building: Dictionary = scene.buildings[index]
		var layout: Dictionary = building.get("store_layout", {})
		var inside: Vector2 = layout.get("entry_inside_pos", Vector2.ZERO)
		var outside: Vector2 = layout.get("entry_outside_pos", Vector2.ZERO)
		var self_cleared = _occupation_grid(scene, index)
		var blocking_override: Variant = _blocking_grid_without(scene, index) if index == scene.kennel_building_index else null
		if _connected_point(scene, exterior_grid, outside, self_cleared, extra_blockers, blocking_override) and _walk_segment(scene, outside, inside, self_cleared, extra_blockers, blocking_override):
			result["doors"] += 1
		else:
			issues.append("door:%d" % index)

	# F only uses live service records. Check their count and each cleared
	# building's doorway-to-interior route, rather than assuming that an
	# interior layout generated a usable service prop.
	var service_by_type: Dictionary = {}
	for item in scene.building_services:
		if not (item is Dictionary):
			issues.append("service_invalid")
			continue
		var service_type = str(item.get("service_type", ""))
		if not REQUIRED_SERVICE_TYPES.has(service_type):
			issues.append("service_unknown:%s" % service_type)
		elif service_by_type.has(service_type):
			issues.append("service_duplicate:%s" % service_type)
		else:
			service_by_type[service_type] = item
	for service_type in REQUIRED_SERVICE_TYPES:
		if not service_by_type.has(service_type):
			issues.append("service_missing:%s" % service_type)
		elif _service_has_approach(scene, exterior_grid, extra_blockers, service_type, service_by_type[service_type]):
			result["services"] += 1
		else:
			issues.append("service_unreachable:%s" % service_type)

	# The lodge is the only required interior with six distinct positional
	# interactions. Flood its local footprint after clearing only the lodge,
	# seeding the small search from the certified home-connected exterior.
	var kennel_index: int = scene.kennel_building_index
	var kennel_footprint: Rect2 = scene.buildings[kennel_index].get("footprint", Rect2())
	var kennel_open = _occupation_grid(scene, kennel_index)
	var kennel_blocking = _blocking_grid_without(scene, kennel_index)
	var kennel_grid = _open_local_grid(scene, exterior_grid, kennel_footprint.grow(3.0), kennel_open, extra_blockers, kennel_blocking)
	var kennel_center: Vector2 = kennel_footprint.get_center()
	for cage_index in range(6):
		var side = -1.0 if cage_index < 3 else 1.0
		var row = cage_index % 3
		var local_z = [-2.25, -0.25, 1.75][row]
		var cage_reachable = false
		for x_offset in [2.1, 2.4, 2.7, 3.0]:
			for z_offset in [-0.6, -0.3, 0.0, 0.3, 0.6]:
				var point = kennel_center + Vector2(side * x_offset, local_z + z_offset)
				if not _connected_point(scene, kennel_grid, point, kennel_open, extra_blockers, kennel_blocking):
					continue
				if int(scene._caged_kennel_dog_for_position(point, 2.35, false).get("index", -1)) == cage_index:
					cage_reachable = true
					break
			if cage_reachable:
				break
		if cage_reachable:
			result["cages"] += 1
		else:
			issues.append("cage:%d" % cage_index)
	result["ok"] = issues.is_empty()
	return result


static func _service_grid_point(id: Vector2i) -> Vector2:
	return Vector2(float(id.x) * SERVICE_GRID_STEP, float(id.y) * SERVICE_GRID_STEP)


static func _service_edge_walkable(scene: Node, start: Vector2, finish: Vector2, occupation: Dictionary, extra_blockers: Array[Rect2], blocking_override: Dictionary) -> bool:
	return _walkable(scene, (start + finish) * 0.5, occupation, extra_blockers, blocking_override) and _walkable(scene, finish, occupation, extra_blockers, blocking_override)


static func _service_has_approach(scene: Node, exterior_grid: Dictionary, extra_blockers: Array[Rect2], service_type: String, service: Dictionary) -> bool:
	var index = int(service.get("building_index", -1))
	if index < 0 or index >= scene.buildings.size() or index == scene.freya_home_index:
		return false
	var node: Node3D = service.get("node", null)
	if node == null or not is_instance_valid(node):
		return false
	var position: Vector2 = service.get("pos", Vector2(-1.0, -1.0))
	if Vector2(node.global_position.x, node.global_position.z).distance_to(position) > 0.01:
		return false
	var building: Dictionary = scene.buildings[index]
	if str(building.get("building_type", "")) != str(SERVICE_BUILDING_TYPES[service_type]):
		return false
	var interior: Rect2 = building.get("store_interior_rect", Rect2())
	if interior.size.x <= 0.0 or interior.size.y <= 0.0 or not interior.grow(-0.05).has_point(position):
		return false
	var layout: Dictionary = building.get("store_layout", {})
	var inside: Vector2 = layout.get("entry_inside_pos", Vector2.ZERO)
	var outside: Vector2 = layout.get("entry_outside_pos", Vector2.ZERO)
	var cleared = _occupation_grid(scene, index)
	var blocking = _blocking_grid_without(scene, index)
	if not _connected_point(scene, exterior_grid, outside, cleared, extra_blockers, blocking) or not _walk_segment(scene, outside, inside, cleared, extra_blockers, blocking):
		return false
	if not _walkable(scene, position, cleared, extra_blockers, blocking):
		return false
	var search_rect = interior.grow(0.25)
	var valid_interior = interior.grow(-0.05)
	var entry_id = Vector2i(roundi(inside.x / SERVICE_GRID_STEP), roundi(inside.y / SERVICE_GRID_STEP))
	var queue: Array[Vector2i] = []
	var seen: Dictionary = {}
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var id = entry_id + Vector2i(dx, dz)
			var point = _service_grid_point(id)
			if point.distance_to(inside) > 0.17 or not search_rect.has_point(point):
				continue
			if not _service_edge_walkable(scene, inside, point, cleared, extra_blockers, blocking):
				continue
			seen[id] = true
			queue.append(id)
	var cursor = 0
	while cursor < queue.size():
		var id = queue[cursor]
		cursor += 1
		var point = _service_grid_point(id)
		if valid_interior.has_point(point) and point.distance_to(position) <= scene.BUILDING_SERVICE_RANGE - 0.05:
			# F rejects an occupied store. Once this store is cleared,
			# _is_inside_store_index accepts every point in valid_interior.
			if bool(building.get("alien_occupied", false)) or scene._is_inside_store_index(index, point):
				return true
		for offset in CARDINAL_OFFSETS:
			var next = id + offset
			if seen.has(next):
				continue
			var next_point = _service_grid_point(next)
			if not search_rect.has_point(next_point) or not _service_edge_walkable(scene, point, next_point, cleared, extra_blockers, blocking):
				continue
			seen[next] = true
			queue.append(next)
	return false


static func _occupation_grid(scene: Node, except_index: int = -1) -> Dictionary:
	var grid: Dictionary = {}
	for index in range(scene.buildings.size()):
		if index == scene.freya_home_index or index == except_index:
			continue
		scene._index_collision_rect(grid, scene.buildings[index].get("footprint", Rect2()))
	return grid


static func _blocking_grid_without(scene: Node, except_index: int) -> Dictionary:
	var grid: Dictionary = {}
	for index in range(scene.buildings.size()):
		if index == except_index or bool(scene.buildings[index].get("enterable", false)):
			continue
		var building: Dictionary = scene.buildings[index]
		scene._index_collision_rect(grid, building.get("collision_rect", building.get("footprint", Rect2())))
	return grid


static func _walkable(scene: Node, point: Vector2, occupation: Dictionary, extra_blockers: Array[Rect2], blocking_override: Variant = null) -> bool:
	var radius: float = scene.FREYA_COLLISION_RADIUS
	if not scene._is_walkable(point.x, point.y, radius, occupation, blocking_override):
		return false
	for blocker in extra_blockers:
		if blocker.grow(radius).has_point(point):
			return false
	return true


static func _walk_segment(scene: Node, start: Vector2, finish: Vector2, occupation: Dictionary, extra_blockers: Array[Rect2], blocking_override: Variant = null) -> bool:
	for sample in range(9):
		var point = start.lerp(finish, float(sample) / 8.0)
		if not _walkable(scene, point, occupation, extra_blockers, blocking_override):
			return false
	return true


static func _grid_point(x: int, z: int) -> Vector2:
	return Vector2(float(x) * GRID_STEP, float(z) * GRID_STEP)


static func _connected_grid(scene: Node, start: Vector2, occupation: Dictionary, extra_blockers: Array[Rect2]) -> Dictionary:
	var width = int(ceilf(scene.MAP_W / GRID_STEP)) + 1
	var height = int(ceilf(scene.MAP_H / GRID_STEP)) + 1
	var seen = PackedByteArray()
	seen.resize(width * height)
	var walkable = PackedByteArray()
	walkable.resize(width * height)
	var queue = PackedInt32Array()
	var start_id = Vector2i(roundi(start.x / GRID_STEP), roundi(start.y / GRID_STEP))
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			var id = start_id + Vector2i(dx, dz)
			if id.x < 0 or id.y < 0 or id.x >= width or id.y >= height:
				continue
			var point = _grid_point(id.x, id.y)
			if point.distance_to(start) > GRID_STEP * 1.8 or not _walk_segment(scene, start, point, occupation, extra_blockers):
				continue
			var key = id.y * width + id.x
			seen[key] = 1
			walkable[key] = 1
			queue.append(key)
	var cursor = 0
	while cursor < queue.size():
		var key = queue[cursor]
		cursor += 1
		var x = key % width
		var z = int(key / width)
		var point = _grid_point(x, z)
		for offset in CARDINAL_OFFSETS:
			var nx = x + offset.x
			var nz = z + offset.y
			if nx < 0 or nz < 0 or nx >= width or nz >= height:
				continue
			var next_key = nz * width + nx
			if seen[next_key] == 1 or walkable[next_key] == 2:
				continue
			var next_point = _grid_point(nx, nz)
			if walkable[next_key] == 0:
				walkable[next_key] = 1 if _walkable(scene, next_point, occupation, extra_blockers) else 2
			if walkable[next_key] == 1 and _walkable(scene, (point + next_point) * 0.5, occupation, extra_blockers):
				seen[next_key] = 1
				queue.append(next_key)
	return {"seen": seen, "width": width, "height": height, "nodes": queue.size()}


static func _connected_point(scene: Node, grid: Dictionary, target: Vector2, occupation: Dictionary, extra_blockers: Array[Rect2], blocking_override: Variant = null) -> bool:
	if not _walkable(scene, target, occupation, extra_blockers, blocking_override):
		return false
	var width: int = grid["width"]
	var height: int = grid["height"]
	var seen: PackedByteArray = grid["seen"]
	var center = Vector2i(roundi(target.x / GRID_STEP), roundi(target.y / GRID_STEP))
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			var id = center + Vector2i(dx, dz)
			if id.x < 0 or id.y < 0 or id.x >= width or id.y >= height or seen[id.y * width + id.x] == 0:
				continue
			var point = _grid_point(id.x, id.y)
			if point.distance_to(target) <= GRID_STEP * 1.8 and _walk_segment(scene, target, point, occupation, extra_blockers, blocking_override):
				return true
	return false


static func _wall_has_approach(scene: Node, grid: Dictionary, occupation: Dictionary, extra_blockers: Array[Rect2], index: int) -> bool:
	var footprint: Rect2 = scene.buildings[index].get("footprint", Rect2())
	for fraction in [0.2, 0.4, 0.6, 0.8]:
		var x = lerpf(footprint.position.x, footprint.end.x, fraction)
		var z = lerpf(footprint.position.y, footprint.end.y, fraction)
		for distance in [0.65, 1.0, 1.35, 1.65]:
			for point in [
				Vector2(footprint.position.x - distance, z),
				Vector2(footprint.end.x + distance, z),
				Vector2(x, footprint.position.y - distance),
				Vector2(x, footprint.end.y + distance)
			]:
				if scene._point_distance_to_rect(point, footprint) < scene.CLAIM_RANGE and _connected_point(scene, grid, point, occupation, extra_blockers):
					return true
	return false


static func _mark_has_approach(scene: Node, grid: Dictionary, occupation: Dictionary, extra_blockers: Array[Rect2], item: Dictionary) -> bool:
	var world: Vector3 = scene._claim_target_base_world_position(int(item.get("type", -1)), int(item.get("index", -1)))
	var mark = Vector2(world.x, world.z)
	for radius in [0.55, 0.85, 1.2, 1.55]:
		for angle_index in range(24):
			var point = mark + Vector2.RIGHT.rotated(TAU * float(angle_index) / 24.0) * radius
			if _connected_point(scene, grid, point, occupation, extra_blockers):
				return true
	return false


static func _open_local_grid(scene: Node, base: Dictionary, area: Rect2, occupation: Dictionary, extra_blockers: Array[Rect2], blocking_override: Variant = null) -> Dictionary:
	var width: int = base["width"]
	var height: int = base["height"]
	var base_seen: PackedByteArray = base["seen"]
	var seen: PackedByteArray = base_seen.duplicate()
	var blocked = PackedByteArray()
	blocked.resize(width * height)
	var queue = PackedInt32Array()
	var min_x = clampi(floori(area.position.x / GRID_STEP) - 1, 0, width - 1)
	var max_x = clampi(ceili(area.end.x / GRID_STEP) + 1, 0, width - 1)
	var min_z = clampi(floori(area.position.y / GRID_STEP) - 1, 0, height - 1)
	var max_z = clampi(ceili(area.end.y / GRID_STEP) + 1, 0, height - 1)
	for z in range(min_z, max_z + 1):
		for x in range(min_x, max_x + 1):
			var key = z * width + x
			if seen[key] == 1:
				queue.append(key)
	var cursor = 0
	while cursor < queue.size():
		var key = queue[cursor]
		cursor += 1
		var x = key % width
		var z = int(key / width)
		var point = _grid_point(x, z)
		for offset in CARDINAL_OFFSETS:
			var nx = x + offset.x
			var nz = z + offset.y
			if nx < min_x or nx > max_x or nz < min_z or nz > max_z:
				continue
			var next_key = nz * width + nx
			if seen[next_key] == 1 or blocked[next_key] == 1:
				continue
			var next_point = _grid_point(nx, nz)
			if not _walkable(scene, next_point, occupation, extra_blockers, blocking_override):
				blocked[next_key] = 1
				continue
			if _walkable(scene, (point + next_point) * 0.5, occupation, extra_blockers, blocking_override):
				seen[next_key] = 1
				queue.append(next_key)
	return {"seen": seen, "width": width, "height": height, "nodes": queue.size()}
