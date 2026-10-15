extends "res://tests/dejank_flow.gd"

# Sweeps generated homes, cinematic transitions, building types, orbit and zoom.
# Optional graphical evidence: FREYA_REVIEW_DIR=/absolute/existing/directory
# Run without --headless for PNGs; scenes and interactions below are staged.
var review_directory = OS.get_environment("FREYA_REVIEW_DIR")

func capture_frame(label: String) -> void:
	if review_directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	await frames(2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(review_directory.path_join(label + ".png"))

func check_framing(s: Node, subject: Vector3, bottom: float, context: String) -> void:
	check(not s.camera_node.is_position_behind(subject), context + " subject behind camera")
	var position: Vector2 = s.camera_node.unproject_position(subject) / root.get_visible_rect().size
	check(position.x > 0.035 and position.x < 0.965 and position.y > 0.07 and position.y < bottom, context + " subject outside safe picture area: " + str(position))

func check_camera_clear(s: Node, context: String) -> void:
	# Inspect the rendered meshes, not the runtime's approximate building boxes.
	var subjects: Array[Vector3] = [s.freya.head_world_position()]
	var cinematic = s.family_intro_active or s.first_exit_abduction_active
	if cinematic:
		check(s.outlined_freya_meshes.is_empty(), context + " retained gameplay ghost material")
	if s.family_intro_active:
		subjects.append(s.ryah_diane_node.global_position + Vector3.UP * 0.7)
	if s.first_exit_abduction_active and s.first_exit_abduction_time < s.FIRST_EXIT_FREYA_TARGET_START:
		for pair in s.first_exit_abduction_pairs:
			subjects.append(s.dogs[pair.dog_index].node.head_world_position())
			if pair.owner.visible:
				subjects.append(pair.owner.global_position + Vector3.UP * 1.8)
	var stack: Array[Node] = []
	for building in s.buildings:
		for field in ["node", "store_shell_root", "detail_batch_root", "store_interior_root", "alien_visual_root"]:
			var node = building.get(field)
			if node != null:
				stack.append(node)
	stack.append(s.freya_home_exterior_root)
	stack.append(s.freya_home_interior_root)
	if cinematic:
		for batch_name in ["BatchedForest", "BatchedStreetPoles", "BatchedFireHydrants", "BatchedDumpsters", "BatchedMailboxes", "BatchedSuburbanYards"]:
			stack.append(s.static_root.get_node(batch_name))
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.name in ["LiveHomeFamilyIntro", "Ryah Diane"]:
			continue
		if node is Node3D and not node.is_visible_in_tree():
			continue
		if node is MeshInstance3D or node is MultiMeshInstance3D:
			var boxes: Array[AABB] = []
			if node is MultiMeshInstance3D:
				for index in range(node.multimesh.instance_count):
					var transform: Transform3D = node.multimesh.get_instance_transform(index)
					if absf(transform.basis.determinant()) > 0.000001:
						boxes.append(node.global_transform * transform * node.multimesh.mesh.get_aabb())
			else:
				boxes.append(node.global_transform * node.get_aabb())
			for box in boxes:
				if box.end.y <= 0.22:
					continue
				check(not box.has_point(s.camera_node.global_position), context + " camera inside visible " + str(node.name))
				for subject in subjects:
					check(box.intersects_segment(s.camera_node.global_position, subject) == null, context + " subject hidden by " + str(node.get_path()))
		for child in node.get_children():
			stack.append(child)

func run() -> void:
	for city_seed in [819267867711688713, 20260831, 20260916]:
		OS.set_environment("FREYA_WORLD_SEED", str(city_seed))
		set_meta("friendly_freya_family_intro_pending", true)
		await open_scene("res://scenes/Main.tscn")
		var s = current_scene
		s.set_process(false)
		check(s.family_intro_active, "seed %d family did not start" % city_seed)
		s.family_intro_time = 2.0
		s._apply_family_intro_time(s.family_intro_time)
		s._update_family_intro(5.0)
		var reading_hold_time: float = s.family_intro_time
		check(reading_hold_time < 6.5 and s.family_dialogue_label.text == str(s.FamilyIntroTimeline.SCENES[1]["text"]), "long family line did not stop at full text")
		s._update_family_intro(5.0)
		check(is_equal_approx(s.family_intro_time, reading_hold_time), "long family line advanced without player input")
		s._on_family_intro_advance_requested()
		check(s.family_intro_current_scene_id == "family_02_gene_new_job", "Next did not release family reading hold")
		for frame in range(192):
			var time = float(frame) / 3.0
			s._apply_family_intro_time(time)
			var bottom = 0.70 if s.family_dialogue_panel.visible else 0.92
			check_framing(s, s.freya.head_world_position(), bottom, "family %.2f" % time)
			check_framing(s, s.freya.global_position + Vector3.UP * 0.05, bottom, "family feet %.2f" % time)
			check_framing(s, s.ryah_diane_node.global_position + Vector3.UP * 0.7, bottom, "Ryah %.2f" % time)
			check(not s.freya_home_interior_root.get_node("HomeInteriorExitLabel").is_visible_in_tree(), "family shows Outside label")
		for time in [1.0, 30.0, 46.0, 50.3, 54.2, 57.0, 62.0]:
			s._apply_family_intro_time(time)
			check_camera_clear(s, "family %.2f" % time)
			await capture_frame("seed%d_family_%04.1f" % [city_seed, time])
		s._finish_family_intro()
		check(s.sightline_cutaway.hidden_instances.is_empty(), "family did not restore batched scenery")
		check(is_equal_approx(s.camera_node.fov, 40.0) and s.ui_layer.visible, "family handoff did not restore gameplay camera/UI")
		check(s.freya_home_interior_root.get_node("HomeInteriorExitLabel").visible, "family left gameplay label hidden")
		s._complete_post_intro_meal_tutorial()
		var outside: Vector2 = s.buildings[s.freya_home_index].home_layout.entry_outside_pos
		s.freya.global_position = Vector3(outside.x, 0, outside.y)
		s._apply_freya_home_focus_visuals()
		s._begin_first_exit_abduction()
		check(s.first_exit_abduction_active, "seed %d first-exit staging failed" % city_seed)
		for frame in range(84):
			var time = float(frame) / 6.0
			s.first_exit_abduction_time = time
			s._apply_first_exit_abduction_time(time)
			var bottom = 0.70 if s.first_exit_thought_panel.visible else 0.92
			check_framing(s, s.freya.head_world_position(), bottom, "first exit %.2f" % time)
			check_framing(s, s.freya.global_position + Vector3.UP * 0.05, bottom, "first exit feet %.2f" % time)
			if time < s.FIRST_EXIT_FREYA_TARGET_START:
				for pair in s.first_exit_abduction_pairs:
					check_framing(s, pair.dog_base + Vector3.UP * 0.5, bottom, "leashed dog %.2f" % time)
		for time in [0.1, 0.3, 2.5, 5.5, 6.5, 6.85, 7.3, 9.2, 12.0]:
			# Match the normal update's clock so sightline assertions follow the
			# shot's subjects when focus moves from the walkers to Freya.
			s.first_exit_abduction_time = time
			s._apply_first_exit_abduction_time(time)
			check_camera_clear(s, "first exit %.2f" % time)
			await capture_frame("seed%d_exit_%04.1f" % [city_seed, time])
		s.first_exit_abduction_time = s.FIRST_EXIT_MONOLOGUE_START + 0.1
		s._apply_first_exit_abduction_time(s.first_exit_abduction_time)
		check(not s.first_exit_continue_button.visible, "first-exit Continue appeared before thought completed")
		s._on_first_exit_advance_requested()
		check(s.first_exit_abduction_active and s.first_exit_thought_label.text == s.FIRST_EXIT_IMMUNITY_TEXT, "first advance did not reveal complete immunity thought")
		check(s.first_exit_continue_button.visible, "completed immunity thought has no Continue button")
		s._update_first_exit_abduction(30.0)
		check(s.first_exit_abduction_active, "first-exit thought advanced without player input")
		s._on_first_exit_advance_requested()
		check(s.sightline_cutaway.hidden_instances.is_empty(), "first exit did not restore batched scenery")
		check(s.possessed_dog_behavior_enabled and not s.first_exit_abduction_pending, "first-exit handoff left gameplay locked")
		check(is_equal_approx(s.camera_node.fov, 40.0), "first-exit handoff retained cinematic FOV")
		var tested_types: Dictionary = {}
		for index in range(s.buildings.size()):
			var building: Dictionary = s.buildings[index]
			var kind = str(building.get("building_type", "home"))
			if bool(building.get("is_freya_home", false)):
				kind = "home"
			if tested_types.has(kind):
				continue
			tested_types[kind] = true
			var positions: Array[Vector2] = []
			if kind == "home":
				positions.append(s.freya_home_bowl_position + Vector2(0.65, 0.65))
			else:
				var reachable: PackedVector2Array = building.get("store_reachable_points", PackedVector2Array())
				if not reachable.is_empty():
					positions.append(reachable[reachable.size() / 2])
			for service in s.building_services:
				if service.building_index == index:
					positions.append(service.pos)
			var layout: Dictionary = building.get("home_layout", {}) if kind == "home" else building.get("store_layout", {})
			positions.append(layout.get("entry_inside_pos", Vector2.ZERO))
			positions.append(layout.get("entry_outside_pos", Vector2.ZERO))
			for point_index in range(positions.size()):
				var point: Vector2 = positions[point_index]
				s.freya.global_position = Vector3(point.x, 0, point.y)
				s.active_store_index = index if kind != "home" else -1
				s._apply_store_focus_visuals()
				s._apply_freya_home_focus_visuals()
				for angle in [0.4, 1.9, 3.5, 5.0]:
					for zoom in [s.CAMERA_ZOOM_MIN, s.CAMERA_ZOOM_MAX]:
						s.camera_focus = s.freya.global_position + Vector3.UP * 0.95
						s.camera_orbit_angle = angle
						s.camera_planar_distance = zoom
						s.camera_zoom_target = zoom
						s._update_camera(0.0)
						s._update_roof_occlusion(0.0)
						check_framing(s, s.freya.head_world_position(), 0.94, "interior " + kind)
						check_camera_clear(s, "interior " + kind)
						# Capture the closest zoom at the first two angles; sweep both
						# extremes and all four angles numerically, including door sides.
						if point_index == 0 and zoom == s.CAMERA_ZOOM_MIN and angle < 2.0:
							await capture_frame("seed%d_%s_orbit%.1f" % [city_seed, kind, angle])
		var occupied_index: int = s.store_building_indices[0]
		check(s._occupy_building_with_alien(occupied_index, 900001), "occupied camera setup")
		var outside_occupied: Vector2 = s.buildings[occupied_index].store_layout.entry_outside_pos
		s.freya.global_position = Vector3(outside_occupied.x, 0, outside_occupied.y)
		s._update_store_focus(1.0)
		for angle in [0.4, 1.9, 3.5, 5.0]:
			s.camera_focus = s.freya.global_position + Vector3.UP * 0.95
			s.camera_orbit_angle = angle
			s._update_camera(0.0)
			s._update_roof_occlusion(0.0)
			check_camera_clear(s, "occupied building")
			if angle < 2.0:
				await capture_frame("seed%d_occupied_orbit%.1f" % [city_seed, angle])
		print("CAMERA_SEED_OK: ", city_seed, " home_front_south=", s.buildings[s.freya_home_index].front_is_south, " types=", tested_types.size())
		await open_scene("res://scenes/Main.tscn")
		check_skip(current_scene, "seed %d skip" % city_seed)
		await tap(KEY_F)
		check(current_scene.freya_hunger < 0.2 and current_scene.post_intro_meal_tutorial_completed, "seed %d skip spawn cannot reach food" % city_seed)
	OS.unset_environment("FREYA_WORLD_SEED")
	if failures.is_empty():
		print("DEJANK_CAMERA_OK: three generated layouts, full timeline sweeps, all building types, both entrance sides, four orbits, and both zoom extremes")
	else:
		push_error("DEJANK_CAMERA_FAIL: " + ", ".join(failures))
	quit(0 if failures.is_empty() else 1)
