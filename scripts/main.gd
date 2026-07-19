extends Node

const TOWN_POSITION := Vector3(-5.3, 0.55, 0.0)
const FOREST_POSITION := Vector3(5.3, 0.55, 0.0)
const ACCENT := Color("e6b86a")
const CREAM := Color("f4ecd7")
const INK := Color("122522")
const PANEL := Color("1a302cd9")

var state: Dictionary
var hero: Node3D
var axe: MeshInstance3D
var camera: Camera3D
var action_label: Label
var location_label: Label
var skill_label: Label
var inventory_label: Label
var queue_label: Label
var report_label: RichTextLabel
var progress_bar: ProgressBar
var plan_button: Button
var pause_button: Button
var offline_banner: PanelContainer
var offline_label: RichTextLabel
var save_timer := 0.0
var elapsed_visual := 0.0


func _ready() -> void:
	_build_world()
	_build_interface()
	var capture_preview := "--capture-preview" in OS.get_cmdline_user_args()
	if capture_preview:
		state = GameContent.new_state()
		_append_report("Welcome to Embervale. Plan your first journey.")
	else:
		_load_or_create_state()
	_update_interface()
	if capture_preview:
		_capture_preview.call_deferred()


func _process(delta: float) -> void:
	elapsed_visual += delta
	if not state.get("paused", false):
		var events := IdleSimulator.advance(state, delta)
		for event in events:
			_append_report(event)
	_update_hero(delta)
	_update_interface()
	save_timer += delta
	if save_timer >= 5.0:
		save_timer = 0.0
		SaveSystem.save_game(state)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not state.is_empty():
		SaveSystem.save_game(state)
		get_tree().quit()


func _load_or_create_state() -> void:
	state = SaveSystem.load_game()
	if state.is_empty() or int(state.get("version", 0)) != 1:
		state = GameContent.new_state()
		_append_report("Welcome to Embervale. Plan your first journey.")
		return
	var last_saved := float(state.get("last_saved_unix", 0.0))
	var now := Time.get_unix_time_from_system()
	var offline_seconds := clampf(now - last_saved, 0.0, GameContent.OFFLINE_CAP_SECONDS)
	var had_pending_plan: bool = state.get("current_action") != null or not state.get("queue", []).is_empty()
	if offline_seconds >= 1.0 and had_pending_plan:
		var before_logs := int(state.get("inventory", {}).get("pine_log", 0))
		var before_xp := int(state.get("skills", {}).get("woodcutting_xp", 0))
		var events := IdleSimulator.advance(state, offline_seconds)
		var gained_logs := int(state["inventory"].get("pine_log", 0)) - before_logs
		var gained_xp := int(state["skills"].get("woodcutting_xp", 0)) - before_xp
		_show_offline_report(offline_seconds, gained_logs, gained_xp, events)
		for event in events:
			_append_report(event)


func _build_world() -> void:
	var world := Node3D.new()
	world.name = "World"
	add_child(world)

	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("9fc6b5")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d7eadb")
	env.ambient_light_energy = 0.72
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	world.add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -34.0, 0.0)
	sun.light_color = Color("fff0c9")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	world.add_child(sun)

	_add_box(world, Vector3(0, -0.3, 0), Vector3(16, 0.6, 9), Color("6f9270"), "Valley")
	_add_box(world, Vector3(0, 0.02, 0), Vector3(9.0, 0.08, 1.15), Color("baa477"), "Old Road")
	_build_town(world)
	_build_forest(world)
	_build_waystone(world)

	hero = Node3D.new()
	hero.name = "Wayfarer"
	hero.position = TOWN_POSITION
	world.add_child(hero)
	_add_capsule(hero, Vector3.ZERO, 0.36, 1.05, Color("df7d4d"), "Body")
	_add_sphere(hero, Vector3(0, 0.82, 0), 0.29, Color("f0c39b"), "Head")
	_add_box(hero, Vector3(0, 0.48, -0.25), Vector3(0.42, 0.56, 0.15), Color("27463f"), "Pack")
	axe = _add_box(hero, Vector3(0.38, 0.35, 0), Vector3(0.08, 0.75, 0.08), Color("6d4934"), "Axe")
	var axe_head := _add_box(axe, Vector3(0.12, 0.34, 0), Vector3(0.33, 0.16, 0.10), Color("b7c5bd"), "Axe Head")
	axe_head.rotation_degrees.z = -12.0

	camera = Camera3D.new()
	camera.name = "DioramaCamera"
	camera.position = Vector3(0.0, 10.8, 13.5)
	camera.rotation_degrees = Vector3(-36.5, 0.0, 0.0)
	camera.fov = 47.0
	world.add_child(camera)


func _build_town(parent: Node3D) -> void:
	_add_box(parent, Vector3(-5.4, 0.65, -1.35), Vector3(2.2, 1.3, 1.8), Color("d4bd87"), "Workshop")
	var roof := _add_box(parent, Vector3(-5.4, 1.55, -1.35), Vector3(2.65, 0.35, 2.15), Color("6e3f32"), "Workshop Roof")
	roof.rotation_degrees.z = 4.0
	_add_box(parent, Vector3(-4.82, 0.48, -0.42), Vector3(0.58, 0.95, 0.16), Color("3b5b51"), "Door")
	_add_box(parent, Vector3(-6.4, 0.48, 1.38), Vector3(1.0, 0.15, 1.0), Color("485a53"), "Forge")
	_add_sphere(parent, Vector3(-6.4, 0.9, 1.38), 0.25, Color("f0a34b"), "Forge Flame")


func _build_forest(parent: Node3D) -> void:
	var tree_positions := [
		Vector3(4.4, 0, -1.8), Vector3(5.7, 0, -1.5), Vector3(6.5, 0, -0.2),
		Vector3(4.6, 0, 1.2), Vector3(6.4, 0, 1.6), Vector3(5.4, 0, 2.2),
	]
	for i in tree_positions.size():
		var p: Vector3 = tree_positions[i]
		_add_cylinder(parent, p + Vector3(0, 0.65, 0), 0.16, 1.3, Color("76523a"), "Pine Trunk %d" % i)
		_add_cone(parent, p + Vector3(0, 1.55, 0), 0.9, 1.8, Color("28584a"), "Pine Crown %d" % i)
	_add_box(parent, Vector3(5.35, 0.18, 0.0), Vector3(1.3, 0.25, 1.0), Color("3e6a53"), "Forest Activity Pad")


func _build_waystone(parent: Node3D) -> void:
	var stone := _add_box(parent, Vector3(0, 0.7, -2.5), Vector3(0.65, 1.4, 0.45), Color("6a8f88"), "Dormant Waystone")
	stone.rotation_degrees.z = -6.0
	_add_sphere(parent, Vector3(0, 1.45, -2.5), 0.16, ACCENT, "Waystone Ember")


func _build_interface() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var shade := ColorRect.new()
	shade.color = Color("10211f25")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)

	var header := PanelContainer.new()
	header.position = Vector2(24, 20)
	header.size = Vector2(1232, 76)
	header.add_theme_stylebox_override("panel", _panel_style(Color("102925ed"), 16, ACCENT, 1))
	root.add_child(header)
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 22)
	header_margin.add_theme_constant_override("margin_right", 22)
	header_margin.add_theme_constant_override("margin_top", 12)
	header_margin.add_theme_constant_override("margin_bottom", 10)
	header.add_child(header_margin)
	var header_box := HBoxContainer.new()
	header_margin.add_child(header_box)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.add_child(title_box)
	var title := _label("EMBERVALE IDLE", 26, CREAM)
	title_box.add_child(title)
	var subtitle := _label("Queue an adventure. Watch your wayfarer live it.", 13, Color("b8cdc2"))
	title_box.add_child(subtitle)
	location_label = _label("EMBERSTEAD", 15, ACCENT)
	location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	location_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_box.add_child(location_label)

	var info_panel := _make_panel(root, Vector2(24, 116), Vector2(282, 438), "WAYFARER")
	var info_box: VBoxContainer = info_panel.get_meta("content")
	action_label = _label("Resting in town", 19, CREAM)
	action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_box.add_child(action_label)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 14)
	progress_bar.max_value = 100.0
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", _panel_style(Color("354e4777"), 7))
	progress_bar.add_theme_stylebox_override("fill", _panel_style(ACCENT, 7))
	info_box.add_child(progress_bar)
	info_box.add_child(_divider())
	skill_label = _label("Woodcutting · Level 1", 15, CREAM)
	info_box.add_child(skill_label)
	inventory_label = _label("Pine logs · 0", 15, CREAM)
	info_box.add_child(inventory_label)
	info_box.add_child(_divider())
	var tip := _label("Your queue continues while the game is closed. The same simulation drives live and offline progress.", 13, Color("b8cdc2"))
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_box.add_child(tip)

	var plan_panel := _make_panel(root, Vector2(974, 116), Vector2(282, 438), "JOURNEY PLANNER")
	var plan_box: VBoxContainer = plan_panel.get_meta("content")
	var plan_copy := _label("Whisperwood supply run", 18, CREAM)
	plan_box.add_child(plan_copy)
	var plan_detail := _label("Travel · Chop 10 pine logs · Return", 13, Color("b8cdc2"))
	plan_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	plan_box.add_child(plan_detail)
	plan_button = _button("QUEUE FIRST JOURNEY", ACCENT, INK)
	plan_button.pressed.connect(_queue_plan)
	plan_box.add_child(plan_button)
	pause_button = _button("PAUSE", Color("31534b"), CREAM)
	pause_button.pressed.connect(_toggle_pause)
	plan_box.add_child(pause_button)
	var simulate_button := _button("SIMULATE 10 MIN OFFLINE", Color("31534b"), CREAM)
	simulate_button.pressed.connect(_simulate_offline)
	plan_box.add_child(simulate_button)
	var save_button := _button("SAVE NOW", Color("31534b"), CREAM)
	save_button.pressed.connect(_save_now)
	plan_box.add_child(save_button)
	var reset_button := _button("RESET PROTOTYPE", Color("482e2b"), Color("efc5b8"))
	reset_button.pressed.connect(_reset_prototype)
	plan_box.add_child(reset_button)

	var bottom := PanelContainer.new()
	bottom.position = Vector2(24, 574)
	bottom.size = Vector2(1232, 122)
	bottom.add_theme_stylebox_override("panel", _panel_style(PANEL, 16, Color("35564e"), 1))
	root.add_child(bottom)
	var bottom_margin := MarginContainer.new()
	bottom_margin.add_theme_constant_override("margin_left", 18)
	bottom_margin.add_theme_constant_override("margin_right", 18)
	bottom_margin.add_theme_constant_override("margin_top", 12)
	bottom_margin.add_theme_constant_override("margin_bottom", 12)
	bottom.add_child(bottom_margin)
	var bottom_box := HBoxContainer.new()
	bottom_box.add_theme_constant_override("separation", 18)
	bottom_margin.add_child(bottom_box)
	var queue_box := VBoxContainer.new()
	queue_box.custom_minimum_size = Vector2(590, 0)
	bottom_box.add_child(queue_box)
	queue_box.add_child(_label("ACTIVE PLAN", 12, ACCENT))
	queue_label = _label("No journey queued", 14, CREAM)
	queue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	queue_box.add_child(queue_label)
	var report_box := VBoxContainer.new()
	report_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_box.add_child(report_box)
	report_box.add_child(_label("JOURNEY LOG", 12, ACCENT))
	report_label = RichTextLabel.new()
	report_label.bbcode_enabled = true
	report_label.fit_content = false
	report_label.scroll_active = true
	report_label.custom_minimum_size = Vector2(0, 70)
	report_label.add_theme_font_size_override("normal_font_size", 13)
	report_label.add_theme_color_override("default_color", Color("c9d8d0"))
	report_box.add_child(report_label)

	offline_banner = PanelContainer.new()
	offline_banner.position = Vector2(340, 160)
	offline_banner.size = Vector2(600, 330)
	offline_banner.visible = false
	offline_banner.add_theme_stylebox_override("panel", _panel_style(Color("102925fb"), 22, ACCENT, 2))
	root.add_child(offline_banner)
	var offline_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		offline_margin.add_theme_constant_override(side, 26)
	offline_banner.add_child(offline_margin)
	var offline_box := VBoxContainer.new()
	offline_box.add_theme_constant_override("separation", 14)
	offline_margin.add_child(offline_box)
	offline_box.add_child(_label("WELCOME BACK, WAYFARER", 23, ACCENT))
	offline_label = RichTextLabel.new()
	offline_label.bbcode_enabled = true
	offline_label.fit_content = false
	offline_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	offline_label.add_theme_font_size_override("normal_font_size", 16)
	offline_label.add_theme_color_override("default_color", CREAM)
	offline_box.add_child(offline_label)
	var continue_button := _button("CONTINUE", ACCENT, INK)
	continue_button.pressed.connect(func(): offline_banner.visible = false)
	offline_box.add_child(continue_button)


func _update_hero(delta: float) -> void:
	var target := TOWN_POSITION if state.get("location", "emberstead") == "emberstead" else FOREST_POSITION
	var current: Variant = state.get("current_action")
	if current != null and current.get("type") == "travel":
		var from_pos := TOWN_POSITION if current.get("from") == "emberstead" else FOREST_POSITION
		var to_pos := TOWN_POSITION if current.get("to") == "emberstead" else FOREST_POSITION
		target = from_pos.lerp(to_pos, IdleSimulator.current_progress(state))
		hero.rotation.y = lerp_angle(hero.rotation.y, atan2(to_pos.x - from_pos.x, to_pos.z - from_pos.z), delta * 7.0)
		hero.position.y = 0.55 + absf(sin(elapsed_visual * 7.0)) * 0.08
	elif current != null and current.get("type") == "gather":
		hero.rotation.y = lerp_angle(hero.rotation.y, -PI * 0.5, delta * 5.0)
		axe.rotation.z = sin(elapsed_visual * 5.2) * 0.65
		hero.position.y = 0.55
	else:
		axe.rotation.z = lerpf(axe.rotation.z, 0.0, delta * 6.0)
		hero.position.y = 0.55
	hero.position.x = lerpf(hero.position.x, target.x, minf(delta * 10.0, 1.0))
	hero.position.z = lerpf(hero.position.z, target.z, minf(delta * 10.0, 1.0))


func _update_interface() -> void:
	var xp := int(state.get("skills", {}).get("woodcutting_xp", 0))
	var logs := int(state.get("inventory", {}).get("pine_log", 0))
	var location: String = state.get("location", "emberstead")
	location_label.text = GameContent.LOCATION_NAMES.get(location, "Unknown").to_upper()
	action_label.text = GameContent.action_label(state.get("current_action"))
	progress_bar.value = IdleSimulator.current_progress(state) * 100.0
	skill_label.text = "Woodcutting · Level %d · %d XP" % [GameContent.woodcutting_level(xp), xp]
	inventory_label.text = "Pine logs · %d" % logs
	var parts: Array[String] = []
	if state.get("current_action") != null:
		parts.append("1. %s" % GameContent.action_label(state["current_action"]))
	var index := parts.size() + 1
	for action: Dictionary in state.get("queue", []):
		parts.append("%d. %s" % [index, GameContent.action_label(action)])
		index += 1
	queue_label.text = "No journey queued" if parts.is_empty() else "  →  ".join(parts)
	var busy: bool = state.get("current_action") != null or not state.get("queue", []).is_empty()
	plan_button.disabled = busy
	plan_button.text = "JOURNEY IN PROGRESS · %ds LEFT" % int(ceil(IdleSimulator.seconds_remaining(state))) if busy else "QUEUE FIRST JOURNEY"
	pause_button.text = "RESUME" if state.get("paused", false) else "PAUSE"


func _queue_plan() -> void:
	if IdleSimulator.queue_starter_plan(state, 10):
		_append_report("Journey queued: Whisperwood supply run.")
		SaveSystem.save_game(state)


func _toggle_pause() -> void:
	state["paused"] = not state.get("paused", false)
	_append_report("Journey paused." if state["paused"] else "Journey resumed.")


func _simulate_offline() -> void:
	if state.get("current_action") == null and state.get("queue", []).is_empty():
		IdleSimulator.queue_starter_plan(state, 10)
	var before_logs := int(state["inventory"].get("pine_log", 0))
	var before_xp := int(state["skills"].get("woodcutting_xp", 0))
	var events := IdleSimulator.advance(state, 600.0)
	var gained_logs := int(state["inventory"].get("pine_log", 0)) - before_logs
	var gained_xp := int(state["skills"].get("woodcutting_xp", 0)) - before_xp
	_show_offline_report(600.0, gained_logs, gained_xp, events)
	for event in events:
		_append_report(event)
	SaveSystem.save_game(state)


func _save_now() -> void:
	_append_report("Progress saved locally." if SaveSystem.save_game(state) else "Save failed.")


func _reset_prototype() -> void:
	SaveSystem.delete_save()
	state = GameContent.new_state()
	report_label.clear()
	_append_report("Prototype reset. Embervale awaits a new plan.")


func _show_offline_report(seconds: float, logs: int, xp: int, events: Array[String]) -> void:
	var completion := "Your plan is still running."
	if state.get("current_action") == null and state.get("queue", []).is_empty():
		completion = "Your plan finished safely in Emberstead."
	offline_label.text = "[font_size=28]%s[/font_size]\n\n[b]+%d[/b] pine logs    [b]+%d[/b] Woodcutting XP\n\n[i]%d journey events processed in %.0f seconds.[/i]" % [completion, logs, xp, events.size(), seconds]
	offline_banner.visible = true


func _append_report(message: String) -> void:
	if report_label == null:
		return
	report_label.append_text("• %s\n" % message)
	report_label.scroll_to_line(maxi(report_label.get_line_count() - 1, 0))


func _capture_preview() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var result := image.save_png("res://docs/images/prototype-preview.png")
	print("Preview capture: %s" % error_string(result))
	get_tree().quit(0 if result == OK else 1)


func _make_panel(parent: Control, position: Vector2, size: Vector2, heading: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.size = size
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, 16, Color("35564e"), 1))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	box.add_child(_label(heading, 12, ACCENT))
	panel.set_meta("content", box)
	return panel


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, background: Color, foreground: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 42)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", foreground)
	button.add_theme_color_override("font_hover_color", foreground)
	button.add_theme_color_override("font_pressed_color", foreground)
	button.add_theme_color_override("font_focus_color", foreground)
	button.add_theme_color_override("font_disabled_color", foreground.darkened(0.25))
	button.add_theme_stylebox_override("normal", _panel_style(background, 10))
	button.add_theme_stylebox_override("hover", _panel_style(background.lightened(0.12), 10))
	button.add_theme_stylebox_override("pressed", _panel_style(background.darkened(0.10), 10))
	button.add_theme_stylebox_override("disabled", _panel_style(background.darkened(0.35), 10))
	return button


func _divider() -> HSeparator:
	var divider := HSeparator.new()
	divider.add_theme_stylebox_override("separator", _panel_style(Color("5471684f"), 1))
	return divider


func _panel_style(color: Color, radius: int, border_color: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	return style


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material


func _add_box(parent: Node3D, position: Vector3, size: Vector3, color: Color, node_name: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(color)
	node.mesh = mesh
	node.position = position
	parent.add_child(node)
	return node


func _add_capsule(parent: Node3D, position: Vector3, radius: float, height: float, color: Color, node_name: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.material = _material(color)
	node.mesh = mesh
	node.position = position
	parent.add_child(node)
	return node


func _add_sphere(parent: Node3D, position: Vector3, radius: float, color: Color, node_name: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.material = _material(color)
	node.mesh = mesh
	node.position = position
	parent.add_child(node)
	return node


func _add_cylinder(parent: Node3D, position: Vector3, radius: float, height: float, color: Color, node_name: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.material = _material(color)
	node.mesh = mesh
	node.position = position
	parent.add_child(node)
	return node


func _add_cone(parent: Node3D, position: Vector3, radius: float, height: float, color: Color, node_name: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.05
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.material = _material(color)
	node.mesh = mesh
	node.position = position
	parent.add_child(node)
	return node
