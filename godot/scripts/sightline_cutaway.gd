extends RefCounted

# Temporary render-only cutaways. Collision and authored node transforms never
# change. Cache actual mesh bounds, including shell overrides and batched parts.
var hidden: Dictionary = {}
var geometry_cache: Dictionary = {}
var bounds_cache: Dictionary = {}
var group_bounds_cache: Dictionary = {}
var instance_cache: Dictionary = {}
var hidden_instances: Dictionary = {}

func restore() -> void:
	for node in hidden_instances:
		if is_instance_valid(node):
			for index in hidden_instances[node]:
				node.multimesh.set_instance_transform(index, hidden_instances[node][index])
	hidden_instances.clear()
	for node in hidden:
		if is_instance_valid(node):
			node.visible = hidden[node]
	hidden.clear()

func hide(node: Node3D) -> void:
	if node == null or not is_instance_valid(node):
		return
	if not hidden.has(node):
		hidden[node] = node.visible
	node.visible = false

func _geometry(root: Node3D) -> Array:
	var id = root.get_instance_id()
	if geometry_cache.has(id):
		return geometry_cache[id]
	var result: Array = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node = stack.pop_back()
		if node.name in ["Ryah Diane", "LiveHomeFamilyIntro"] or node.has_method("update_motion"):
			continue
		if node is MeshInstance3D or node is MultiMeshInstance3D:
			var group: Node3D = node
			var parent = node.get_parent()
			while parent != null and parent != root:
				if parent.has_meta("home_cutaway_wall") or parent.has_meta("sightline_group"):
					group = parent
					break
				parent = parent.get_parent()
			var bounds: AABB = node.get_aabb()
			if node is MultiMeshInstance3D and node.multimesh != null and node.multimesh.mesh != null:
				# The renderer's aggregate AABB can still be stale during _ready or
				# just after restoring instances. Derive the static envelope from the
				# actual mesh/transforms so graphical and headless checks agree.
				var mesh_bounds: AABB = node.multimesh.mesh.get_aabb()
				for index in range(node.multimesh.instance_count):
					var instance_bounds: AABB = node.multimesh.get_instance_transform(index) * mesh_bounds
					bounds = instance_bounds if index == 0 else bounds.merge(instance_bounds)
			result.append({"node": node, "group": group, "bounds": node.global_transform * bounds})
		for child in node.get_children():
			stack.append(child)
	geometry_cache[id] = result
	if not result.is_empty():
		var bounds: AABB = result[0].bounds
		for entry in result:
			bounds = bounds.merge(entry.bounds)
		bounds_cache[id] = bounds
	return result

func hide_ceiling_attachments(root: Node3D) -> void:
	if root == null or not is_instance_valid(root):
		return
	for entry in _geometry(root):
		var group: Node3D = entry.group
		if group.has_meta("ceiling_attachment"):
			hide(group)

func clear_sightlines(root: Node3D, camera: Vector3, subjects: Array[Vector3], padding: float = 0.16) -> void:
	if root == null or not is_instance_valid(root) or not root.is_visible_in_tree():
		return
	var geometry = _geometry(root)
	if geometry.is_empty():
		return
	# Broad phase uses the rendered envelope, including porches and roof eaves
	# beyond the collision footprint. Architecture is static, so cache it once.
	var envelope: AABB = bounds_cache[root.get_instance_id()].grow(padding)
	var intersects = envelope.has_point(camera)
	for subject in subjects:
		if intersects or envelope.intersects_segment(camera, subject) != null:
			intersects = true
			break
	if not intersects:
		return
	for entry in geometry:
		var node: Node3D = entry.node
		if not is_instance_valid(node) or not node.is_visible_in_tree():
			continue
		var bounds: AABB = entry.bounds
		# Keep ground/floors intact. All other occluders, including a camera inside
		# a roof, use their rendered bounds instead of an approximate building box.
		if bounds.end.y < 0.22:
			continue
		bounds = bounds.grow(padding)
		for subject in subjects:
			if bounds.has_point(camera) or bounds.intersects_segment(camera, subject) != null:
				hide(entry.group)
				break

func clear_sightlines_group(group_id: int, roots: Array, camera: Vector3, subjects: Array[Vector3], padding: float = 0.16) -> void:
	# Most buildings cannot touch a camera-to-subject ray. One exact union of
	# their cached rendered bounds rejects all five roots before the per-mesh
	# checks. Keep the full 3D bounds: a footprint misses eaves and canopies.
	var signature := PackedInt64Array()
	for item in roots:
		var root: Node3D = item if item is Node3D and is_instance_valid(item) else null
		signature.append(root.get_instance_id() if root != null else 0)
		signature.append(1 if root != null and root.is_visible_in_tree() else 0)
	var cached: Dictionary = group_bounds_cache.get(group_id, {})
	if cached.get("signature", PackedInt64Array()) != signature:
		var merged := AABB()
		var has_bounds := false
		for item in roots:
			var root: Node3D = item if item is Node3D and is_instance_valid(item) else null
			if root == null or not root.is_visible_in_tree() or _geometry(root).is_empty():
				continue
			var root_bounds: AABB = bounds_cache[root.get_instance_id()]
			merged = merged.merge(root_bounds) if has_bounds else root_bounds
			has_bounds = true
		cached = {"signature": signature, "bounds": merged, "has_bounds": has_bounds}
		group_bounds_cache[group_id] = cached
	if not bool(cached.get("has_bounds", false)) or not _blocks_subject(cached["bounds"].grow(padding), camera, subjects):
		return
	for item in roots:
		if item is Node3D:
			clear_sightlines(item, camera, subjects, padding)

func _blocks_subject(bounds: AABB, camera: Vector3, subjects: Array[Vector3]) -> bool:
	if bounds.has_point(camera):
		return true
	for subject in subjects:
		if bounds.intersects_segment(camera, subject) != null:
			return true
	return false

func clear_batched_sightlines(root: Node3D, camera: Vector3, subjects: Array[Vector3]) -> void:
	if root == null or not root.is_visible_in_tree():
		return
	# Forest/street props share render batches. Cut only intersecting instances,
	# keeping distant members of the batch and every collision shape intact.
	for entry in _geometry(root):
		var node = entry.node
		if not node is MultiMeshInstance3D or not _blocks_subject(entry.bounds.grow(0.16), camera, subjects):
			continue
		var id = node.get_instance_id()
		if not instance_cache.has(id):
			var instances: Array = []
			for index in range(node.multimesh.instance_count):
				var transform: Transform3D = node.multimesh.get_instance_transform(index)
				instances.append({"transform": transform, "bounds": node.global_transform * transform * node.multimesh.mesh.get_aabb()})
			instance_cache[id] = instances
		var instances: Array = instance_cache[id]
		for index in range(instances.size()):
			var bounds: AABB = instances[index].bounds
			if bounds.end.y < 0.22 or not _blocks_subject(bounds.grow(0.16), camera, subjects):
				continue
			if not hidden_instances.has(node):
				hidden_instances[node] = {}
			hidden_instances[node][index] = instances[index].transform
			node.multimesh.set_instance_transform(index, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
