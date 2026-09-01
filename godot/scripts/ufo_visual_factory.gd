extends RefCounted

## Shared, named UFO geometry for the intro cut-scene.
## Keeping the bridge and opaque fleet shell here gives Codex one small file for
## future ship-art changes without touching timeline or startup logic.

static func create_bridge_interior(materials: Dictionary) -> Node3D:
	var root = Node3D.new()
	root.name = "HeroUFOInterior"

	_cylinder(root, "BridgeFloor", 4.45, 4.45, 0.34, Vector3(0.0, -0.2, -0.45), materials["hull"])
	_cylinder(root, "BridgeFloorInset", 3.55, 3.55, 0.08, Vector3(0.0, 0.01, -0.42), materials["floor"])
	_torus(root, "PanoramicWindowFrame", 3.72, 4.12, Vector3(0.0, 2.45, -3.72), Vector3(90.0, 0.0, 0.0), materials["trim"])
	_box(root, "WindowLowerFrame", Vector3(7.7, 0.28, 0.3), Vector3(0.0, 0.4, -3.68), materials["trim"])
	_box(root, "WindowUpperFrame", Vector3(7.35, 0.2, 0.26), Vector3(0.0, 4.5, -3.68), materials["trim"])
	_box(root, "WindowLeftFrame", Vector3(0.24, 4.2, 0.28), Vector3(-3.78, 2.45, -3.68), materials["trim"])
	_box(root, "WindowRightFrame", Vector3(0.24, 4.2, 0.28), Vector3(3.78, 2.45, -3.68), materials["trim"])

	# Low consoles keep all three crew members readable while selling the bridge.
	for console_index in range(3):
		var x = [-1.65, 0.0, 1.65][console_index]
		var z = [0.6, -0.65, 0.6][console_index]
		_box(root, "ConsoleBase%02d" % console_index, Vector3(1.22, 0.48, 0.72), Vector3(x, 0.28, z), materials["console"])
		var screen = _box(root, "ConsoleScreen%02d" % console_index, Vector3(0.86, 0.08, 0.42), Vector3(x, 0.57, z - 0.08), materials["screen"])
		screen.rotation.x = -0.32
		for light_index in range(3):
			_box(
				root,
				"ConsoleLight%02d_%02d" % [console_index, light_index],
				Vector3(0.1, 0.035, 0.08),
				Vector3(x - 0.25 + light_index * 0.25, 0.63, z - 0.18),
				materials["light_a"] if light_index % 2 == 0 else materials["light_b"]
			)

	for rail_side in [-1.0, 1.0]:
		_box(root, "BridgeRailPost", Vector3(0.12, 0.86, 0.12), Vector3(rail_side * 3.5, 0.46, -1.25), materials["trim"])
		_box(root, "BridgeRail", Vector3(0.12, 0.12, 4.1), Vector3(rail_side * 3.5, 0.87, 0.72), materials["trim"])

	# Ceiling ribs frame the cockpit without closing the Earth-facing window.
	for rib_index in range(5):
		var rib_x = -3.0 + rib_index * 1.5
		_box(root, "CeilingRib%02d" % rib_index, Vector3(0.13, 0.13, 3.9), Vector3(rib_x, 4.62, -1.75), materials["trim"])
	_box(root, "CeilingSpine", Vector3(6.2, 0.16, 0.2), Vector3(0.0, 4.62, 0.08), materials["trim"])
	return root

static func create_opaque_exterior(materials: Dictionary, ship_index: int = 0) -> Node3D:
	var root = Node3D.new()
	root.name = "UFO_%02d" % ship_index
	root.set_meta("visual_signature", "friendly_freya_opaque_ufo_v1")
	root.set_meta("opaque_exterior", true)

	_cylinder(root, "HullLower", 2.35, 1.42, 0.5, Vector3(0.0, -0.16, 0.0), materials["hull_dark"])
	_cylinder(root, "HullUpper", 1.65, 2.35, 0.34, Vector3(0.0, 0.2, 0.0), materials["hull"])
	_torus(root, "HullRim", 1.86, 2.42, Vector3(0.0, 0.1, 0.0), Vector3.ZERO, materials["trim"])
	var dome = _sphere(root, "OpaqueDome", 1.28, Vector3(0.0, 0.62, 0.0), materials["dome"])
	dome.scale = Vector3(1.0, 0.48, 1.0)
	_cylinder(root, "UndersideCore", 0.62, 0.84, 0.34, Vector3(0.0, -0.47, 0.0), materials["core"])

	for light_index in range(8):
		var angle = TAU * float(light_index) / 8.0
		_sphere(
			root,
			"RimLight%02d" % light_index,
			0.11,
			Vector3(cos(angle) * 2.12, 0.02, sin(angle) * 2.12),
			materials["light_a"] if light_index % 2 == 0 else materials["light_b"]
		)
	return root

static func _box(parent: Node3D, node_name: String, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.name = node_name
	var mesh = BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = position
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node, true)
	return node

static func _cylinder(parent: Node3D, node_name: String, top_radius: float, bottom_radius: float, height: float, position: Vector3, material: Material) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.name = node_name
	var mesh = CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 32
	node.mesh = mesh
	node.position = position
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node, true)
	return node

static func _sphere(parent: Node3D, node_name: String, radius: float, position: Vector3, material: Material) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.name = node_name
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 18
	mesh.rings = 10
	node.mesh = mesh
	node.position = position
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node, true)
	return node

static func _torus(parent: Node3D, node_name: String, inner_radius: float, outer_radius: float, position: Vector3, rotation_degrees_value: Vector3, material: Material) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.name = node_name
	var mesh = TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 32
	mesh.ring_segments = 10
	node.mesh = mesh
	node.position = position
	node.rotation_degrees = rotation_degrees_value
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node, true)
	return node
