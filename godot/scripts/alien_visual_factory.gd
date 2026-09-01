extends RefCounted


static func create_imp(palette: Dictionary, visual_scale: float) -> Node3D:
	var body_material: Material = palette.get("body", null)
	var face_material: Material = palette.get("face", null)
	var horn_material: Material = palette.get("horn", null)
	var eye_material: Material = palette.get("eye", null)
	var fang_material: Material = palette.get("fang", null)

	var root = Node3D.new()
	root.name = "AlienImp"

	var rig = Node3D.new()
	rig.name = "AlienRig"
	root.add_child(rig, true)
	rig.scale = Vector3.ONE * visual_scale

	_alien_box(rig, "AlienPelvis", Vector3(0.34, 0.2, 0.27), Vector3(0.0, 0.4, 0.025), body_material, 0.0, true)
	var body = _alien_box(rig, "AlienBody", Vector3(0.41, 0.42, 0.29), Vector3(0.0, 0.64, 0.0), body_material, 0.0, true)
	body.rotation.x = 0.08
	_alien_box(rig, "AlienBelly", Vector3(0.23, 0.25, 0.035), Vector3(0.0, 0.625, -0.158), face_material, 0.0, true)
	_alien_box(rig, "AlienChestRune", Vector3(0.045, 0.145, 0.024), Vector3(0.0, 0.67, -0.181), eye_material)
	_alien_box(rig, "AlienChestRuneBar", Vector3(0.13, 0.04, 0.024), Vector3(0.0, 0.64, -0.183), eye_material)

	var head_pivot = Node3D.new()
	head_pivot.name = "AlienHeadPivot"
	head_pivot.position = Vector3(0.0, 0.94, -0.045)
	rig.add_child(head_pivot, true)
	_alien_box(head_pivot, "AlienHead", Vector3(0.44, 0.34, 0.38), Vector3.ZERO, face_material, 0.0, true)
	_alien_box(head_pivot, "AlienMuzzle", Vector3(0.25, 0.105, 0.055), Vector3(0.0, -0.105, -0.205), body_material, 0.0, true)
	_alien_box(head_pivot, "AlienLeftBrow", Vector3(0.16, 0.052, 0.042), Vector3(-0.105, 0.07, -0.213), horn_material, -0.15, true)
	_alien_box(head_pivot, "AlienRightBrow", Vector3(0.16, 0.052, 0.042), Vector3(0.105, 0.07, -0.213), horn_material, 0.15, true)
	_alien_box(head_pivot, "AlienLeftEye", Vector3(0.07, 0.065, 0.032), Vector3(-0.105, 0.012, -0.225), eye_material)
	_alien_box(head_pivot, "AlienRightEye", Vector3(0.07, 0.065, 0.032), Vector3(0.105, 0.012, -0.225), eye_material)
	_alien_box(head_pivot, "AlienLeftFang", Vector3(0.035, 0.075, 0.034), Vector3(-0.072, -0.18, -0.215), fang_material, 0.0, true)
	_alien_box(head_pivot, "AlienRightFang", Vector3(0.035, 0.075, 0.034), Vector3(0.072, -0.18, -0.215), fang_material, 0.0, true)

	for side in [-1.0, 1.0]:
		var horn_pivot = Node3D.new()
		horn_pivot.name = "AlienLeftHornPivot" if side < 0.0 else "AlienRightHornPivot"
		horn_pivot.position = Vector3(side * 0.18, 0.135, 0.035)
		head_pivot.add_child(horn_pivot, true)
		_alien_box(
			horn_pivot,
			"AlienLeftHorn" if side < 0.0 else "AlienRightHorn",
			Vector3(0.1, 0.21, 0.11),
			Vector3(side * 0.075, 0.08, 0.025),
			horn_material,
			side * 0.55,
			true
		)
		_alien_box(
			horn_pivot,
			"AlienLeftHornTip" if side < 0.0 else "AlienRightHornTip",
			Vector3(0.075, 0.16, 0.085),
			Vector3(side * 0.165, 0.17, 0.055),
			horn_material,
			side * 0.82,
			true
		)

	for side in [-1.0, 1.0]:
		var arm_pivot = Node3D.new()
		arm_pivot.name = "AlienLeftArmPivot" if side < 0.0 else "AlienRightArmPivot"
		arm_pivot.position = Vector3(side * 0.25, 0.79, -0.005)
		arm_pivot.rotation.z = side * -0.08
		rig.add_child(arm_pivot, true)
		_alien_box(
			arm_pivot,
			"AlienLeftArm" if side < 0.0 else "AlienRightArm",
			Vector3(0.12, 0.43, 0.135),
			Vector3(0.0, -0.205, 0.0),
			body_material,
			0.0,
			true
		)
		_alien_box(
			arm_pivot,
			"AlienLeftHand" if side < 0.0 else "AlienRightHand",
			Vector3(0.155, 0.12, 0.17),
			Vector3(0.0, -0.435, -0.025),
			face_material,
			0.0,
			true
		)

	for side in [-1.0, 1.0]:
		var leg_pivot = Node3D.new()
		leg_pivot.name = "AlienLeftLegPivot" if side < 0.0 else "AlienRightLegPivot"
		leg_pivot.position = Vector3(side * 0.115, 0.4, 0.02)
		rig.add_child(leg_pivot, true)
		_alien_box(
			leg_pivot,
			"AlienLeftLeg" if side < 0.0 else "AlienRightLeg",
			Vector3(0.15, 0.32, 0.17),
			Vector3(0.0, -0.16, 0.0),
			body_material,
			0.0,
			true
		)
		_alien_box(
			leg_pivot,
			"AlienLeftFoot" if side < 0.0 else "AlienRightFoot",
			Vector3(0.18, 0.1, 0.29),
			Vector3(0.0, -0.35, -0.065),
			face_material,
			0.0,
			true
		)

	var tail_pivot = Node3D.new()
	tail_pivot.name = "AlienTailPivot"
	tail_pivot.position = Vector3(0.0, 0.47, 0.14)
	tail_pivot.rotation.x = -0.24
	rig.add_child(tail_pivot, true)
	_alien_box(tail_pivot, "AlienTailBase", Vector3(0.105, 0.1, 0.31), Vector3(0.0, 0.0, 0.145), body_material, 0.0, true)
	var tail_tip_pivot = Node3D.new()
	tail_tip_pivot.name = "AlienTailTipPivot"
	tail_tip_pivot.position = Vector3(0.0, 0.0, 0.29)
	tail_tip_pivot.rotation.x = -0.48
	tail_pivot.add_child(tail_tip_pivot, true)
	_alien_box(tail_tip_pivot, "AlienTailTip", Vector3(0.085, 0.085, 0.26), Vector3(0.0, 0.0, 0.12), body_material, 0.0, true)
	_alien_box(tail_tip_pivot, "AlienTailSpade", Vector3(0.19, 0.19, 0.1), Vector3(0.0, 0.0, 0.29), face_material, 0.78, true)
	return root


static func update_pose(
	node: Node3D,
	delta: float,
	move_direction: Vector3,
	moved_distance: float,
	phase: float,
	animation_time: float
) -> float:
	if node == null or not is_instance_valid(node):
		return phase
	var rig: Node3D = node.get_node_or_null("AlienRig")
	if rig == null:
		return phase
	var planar_direction = Vector3(move_direction.x, 0.0, move_direction.z)
	var moving = moved_distance > 0.0001 and planar_direction.length_squared() > 0.0001
	if moving:
		planar_direction = planar_direction.normalized()
		var actual_speed = moved_distance / maxf(delta, 0.0001)
		var cadence = clampf(7.0 + actual_speed * 0.9, 7.0, 13.0)
		phase = fposmod(phase + delta * cadence, TAU)
		var target_yaw = atan2(-planar_direction.x, -planar_direction.z)
		node.rotation.y = lerp_angle(node.rotation.y, target_yaw, clampf(delta * 12.0, 0.0, 1.0))

	var gait_strength = 1.0 if moving else 0.0
	var leg_swing = sin(phase) * 0.62 * gait_strength
	var arm_swing = sin(phase) * 0.48 * gait_strength
	var left_leg: Node3D = rig.get_node_or_null("AlienLeftLegPivot")
	var right_leg: Node3D = rig.get_node_or_null("AlienRightLegPivot")
	var left_arm: Node3D = rig.get_node_or_null("AlienLeftArmPivot")
	var right_arm: Node3D = rig.get_node_or_null("AlienRightArmPivot")
	var head: Node3D = rig.get_node_or_null("AlienHeadPivot")
	var body: Node3D = rig.get_node_or_null("AlienBody")
	var tail: Node3D = rig.get_node_or_null("AlienTailPivot")
	if left_leg != null:
		left_leg.rotation.x = leg_swing
	if right_leg != null:
		right_leg.rotation.x = -leg_swing
	if left_arm != null:
		left_arm.rotation.x = -arm_swing
	if right_arm != null:
		right_arm.rotation.x = arm_swing
	if head != null:
		head.rotation.x = -0.04 * sin(phase * 2.0) * gait_strength
	if body != null:
		body.rotation.x = 0.08 + 0.03 * sin(phase * 2.0) * gait_strength
		body.rotation.z = 0.035 * sin(phase) * gait_strength
	if tail != null:
		tail.rotation.y = sin(animation_time * 2.4 + phase * 0.65) * (0.28 if moving else 0.16)
	rig.position.y = absf(sin(phase * 2.0)) * 0.024 * gait_strength
	return phase


static func _alien_box(
	parent: Node3D,
	name: String,
	size: Vector3,
	position: Vector3,
	material: Material,
	rotation_z: float = 0.0,
	casts_shadow: bool = false
) -> MeshInstance3D:
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
