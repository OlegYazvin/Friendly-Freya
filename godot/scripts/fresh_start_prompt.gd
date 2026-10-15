extends Control

# A keyboard-accessible confirmation shared by the title and pause menus.
signal accepted
signal canceled

var title_label: Label
var detail_label: Label
var cancel_button: Button
var confirm_button: Button
var panel: PanelContainer
var handle_escape := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100

	var shade = ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.07, 0.10, 0.98)
	style.border_color = Color(0.77, 0.88, 0.91)
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	panel.add_child(content)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 25)
	title_label.add_theme_color_override("font_color", Color(0.98, 0.87, 0.56))
	content.add_child(title_label)

	detail_label = Label.new()
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_font_size_override("font_size", 18)
	detail_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	content.add_child(detail_label)

	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)
	cancel_button = Button.new()
	cancel_button.name = "CancelButton"
	cancel_button.text = "Keep Playing"
	cancel_button.custom_minimum_size = Vector2(174, 46)
	cancel_button.add_theme_font_size_override("font_size", 17)
	cancel_button.pressed.connect(_cancel)
	actions.add_child(cancel_button)
	confirm_button = Button.new()
	confirm_button.name = "ConfirmButton"
	confirm_button.text = "Start New Game"
	confirm_button.custom_minimum_size = Vector2(174, 46)
	confirm_button.add_theme_font_size_override("font_size", 17)
	confirm_button.pressed.connect(_accept)
	actions.add_child(confirm_button)

	get_viewport().size_changed.connect(_layout)
	_layout()
	hide()


func show_decision(title: String, detail: String, accept_text: String, cancel_text: String) -> void:
	title_label.text = title
	detail_label.text = detail
	confirm_button.text = accept_text
	confirm_button.show()
	cancel_button.text = cancel_text
	_layout()
	show()
	cancel_button.grab_focus()


func show_notice(title: String, detail: String) -> void:
	title_label.text = title
	detail_label.text = detail
	confirm_button.hide()
	cancel_button.text = "Back"
	_layout()
	show()
	cancel_button.grab_focus()


func _layout() -> void:
	if panel == null:
		return
	var viewport_width = get_viewport().get_visible_rect().size.x
	var width = maxf(280.0, minf(520.0, viewport_width - 32.0))
	panel.custom_minimum_size = Vector2(width, 0.0)
	detail_label.custom_minimum_size = Vector2(width - 40.0, 0.0)


static func incompatible_save_detail(path: String, newer: bool) -> String:
	var filename = path.get_file()
	var kind = "newer" if newer else "incompatible"
	return "A %s game save is in the main or backup slot. This build cannot save progress while it remains. Open the matching newer build, or close this game and copy both %s and %s.bak out of the folder below before starting fresh here:\n%s" % [
		kind, filename, filename, ProjectSettings.globalize_path(path).get_base_dir()
	]


static func unreadable_save_detail(path: String) -> String:
	var filename = path.get_file()
	return "The existing save cannot be read. Starting a new game may replace it. To keep a copy first, close this game and copy %s and %s.bak from:\n%s" % [
		filename, filename, ProjectSettings.globalize_path(path).get_base_dir()
	]


func _unhandled_input(event: InputEvent) -> void:
	if handle_escape and visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		cancel_prompt()
		get_viewport().set_input_as_handled()


func _accept() -> void:
	if not visible or not confirm_button.visible:
		return
	hide()
	accepted.emit()


func _cancel() -> void:
	cancel_prompt()


func cancel_prompt() -> void:
	if not visible:
		return
	hide()
	canceled.emit()
