extends SceneTree

# Capture-only launcher: signal after the requested scene has actually rendered,
# rather than taking a screenshot after a machine-dependent startup delay.
func _initialize() -> void:
	call_deferred("launch")

func launch() -> void:
	var scene_path = OS.get_environment("FREYA_CAPTURE_SCENE")
	var ready_path = OS.get_environment("FREYA_CAPTURE_READY_FILE")
	if scene_path.is_empty() or ready_path.is_empty() or change_scene_to_file(scene_path) != OK:
		push_error("Capture launcher requires a loadable scene and readiness path.")
		quit(1)
		return
	for frame in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	var marker = FileAccess.open(ready_path, FileAccess.WRITE)
	if marker == null:
		push_error("Could not write capture readiness marker: " + ready_path)
		quit(1)
		return
	marker.store_string(scene_path)
