extends Node2D

const PLAYER_TEXTURE := "res://assets/art/player_avatar.png"
const CAMERA_EDGE_PADDING := 12.0
const MIN_CAMERA_ZOOM := 0.58

const LOCATION_SCENES := {
	"village": "res://scenes/locations/Village.tscn",
	"school": "res://scenes/locations/School.tscn",
	"cafe": "res://scenes/locations/Cafe.tscn",
	"library": "res://scenes/locations/Library.tscn"
}

var joystick_vector := Vector2.ZERO
var facing := 1.0
var camera_zoom := 1.0
var active_portal: Area2D
var active_character: Area2D

var world: Node2D
var location_holder: Node2D
var current_location: Node2D
var player: CharacterBody2D
var player_sprite: Sprite2D
var player_shadow: Polygon2D
var camera: Camera2D
var title_label: Label
var status_label: Label
var interact_button: Button
var quiz_panel: Control

@export var player_speed := 210.0

func _ready() -> void:
	randomize()
	_build_world()
	_build_ui()
	_load_scene("village", "Start")


func _physics_process(delta: float) -> void:
	_update_movement(delta)
	_update_interaction()


func _process(delta: float) -> void:
	_update_player_visual(delta)
	_update_camera()


func _build_world() -> void:
	world = Node2D.new()
	add_child(world)

	location_holder = Node2D.new()
	location_holder.name = "LocationHolder"
	world.add_child(location_holder)

	player = CharacterBody2D.new()
	player.name = "Player"
	world.add_child(player)

	player_shadow = _ellipse_polygon(Vector2(46, 14), Color(0, 0, 0, 0.28))
	player_shadow.z_index = 9
	player.add_child(player_shadow)

	player_sprite = Sprite2D.new()
	player_sprite.texture = load(PLAYER_TEXTURE)
	player_sprite.position = Vector2(0, -58)
	player_sprite.z_index = 20
	player.add_child(player_sprite)
	_fit_sprite_height(player_sprite, 108.0)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18
	shape.shape = circle
	player.add_child(shape)

	camera = Camera2D.new()
	camera.enabled = true
	add_child(camera)
	camera.make_current()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var top := HBoxContainer.new()
	top.anchor_left = 0.0
	top.anchor_top = 0.0
	top.anchor_right = 1.0
	top.anchor_bottom = 0.0
	top.offset_left = 14
	top.offset_top = 12
	top.offset_right = -14
	top.offset_bottom = 120
	top.add_theme_constant_override("separation", 10)
	root.add_child(top)

	var header := PanelContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(header)

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 12)
	header_margin.add_theme_constant_override("margin_right", 12)
	header_margin.add_theme_constant_override("margin_top", 10)
	header_margin.add_theme_constant_override("margin_bottom", 10)
	header.add_child(header_margin)

	var header_box := VBoxContainer.new()
	header_margin.add_child(header_box)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 22)
	header_box.add_child(title_label)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_box.add_child(status_label)

	var zoom_box := VBoxContainer.new()
	top.add_child(zoom_box)

	var zoom_in_button := Button.new()
	zoom_in_button.text = "+"
	zoom_in_button.custom_minimum_size = Vector2(48, 42)
	zoom_in_button.pressed.connect(func(): _change_zoom(0.12))
	zoom_box.add_child(zoom_in_button)

	var zoom_out_button := Button.new()
	zoom_out_button.text = "-"
	zoom_out_button.custom_minimum_size = Vector2(48, 42)
	zoom_out_button.pressed.connect(func(): _change_zoom(-0.12))
	zoom_box.add_child(zoom_out_button)

	var bottom := HBoxContainer.new()
	bottom.anchor_left = 0.0
	bottom.anchor_top = 1.0
	bottom.anchor_right = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_left = 14
	bottom.offset_top = -150
	bottom.offset_right = -14
	bottom.offset_bottom = -18
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(bottom)

	var joystick_script := load("res://scripts/VirtualJoystick.gd")
	var joystick: Control = joystick_script.new()
	joystick.vector_changed.connect(_on_joystick_vector_changed)
	bottom.add_child(joystick)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(spacer)

	interact_button = Button.new()
	interact_button.text = "Explore"
	interact_button.disabled = true
	interact_button.custom_minimum_size = Vector2(160, 56)
	interact_button.pressed.connect(_use_primary_action)
	bottom.add_child(interact_button)

	var quiz_script := load("res://scripts/QuizPanel.gd")
	quiz_panel = quiz_script.new()
	quiz_panel.anchor_left = 0.5
	quiz_panel.anchor_top = 0.5
	quiz_panel.anchor_right = 0.5
	quiz_panel.anchor_bottom = 0.5
	quiz_panel.offset_left = -172
	quiz_panel.offset_top = -235
	quiz_panel.offset_right = 172
	quiz_panel.offset_bottom = 235
	layer.add_child(quiz_panel)


func _load_scene(next_scene_id: String, spawn_name: String) -> void:
	if not LOCATION_SCENES.has(next_scene_id):
		push_warning("Unknown location: %s" % next_scene_id)
		return

	for child in location_holder.get_children():
		child.queue_free()

	var packed_scene: PackedScene = load(LOCATION_SCENES[next_scene_id])
	current_location = packed_scene.instantiate()
	location_holder.add_child(current_location)

	joystick_vector = Vector2.ZERO
	player.velocity = Vector2.ZERO
	camera_zoom = max(float(current_location.initial_zoom), _minimum_camera_zoom())
	_set_player_position(current_location.get_spawn_position(spawn_name))

	title_label.text = current_location.title
	status_label.text = current_location.default_status
	_update_camera(true)
	_update_interaction(true)


func _update_movement(_delta: float) -> void:
	if quiz_panel.visible:
		player.velocity = Vector2.ZERO
		return

	var input_vector := joystick_vector
	if input_vector.length() < 0.05:
		input_vector = _keyboard_vector()

	if input_vector.length() > 0.05:
		var direction := input_vector.normalized()
		player.velocity = direction * player_speed
		if abs(direction.x) > 0.05:
			facing = 1.0 if direction.x > 0.0 else -1.0
	else:
		player.velocity = Vector2.ZERO

	player.move_and_slide()
	_clamp_player_to_map()
	player.z_index = int(player.global_position.y)


func _set_player_position(spawn_position: Vector2) -> void:
	player.global_position = spawn_position
	player.z_index = int(spawn_position.y)


func _clamp_player_to_map() -> void:
	if current_location == null:
		return

	var map_size: Vector2 = current_location.get_world_size()
	player.global_position = Vector2(
		clamp(player.global_position.x, 48.0, map_size.x - 48.0),
		clamp(player.global_position.y, 58.0, map_size.y - 58.0)
	)


func _update_player_visual(_delta: float) -> void:
	var moving := player.velocity.length() > 0.05
	var bob := sin(Time.get_ticks_msec() / 1000.0 * 15.0) * 4.0 if moving else 0.0
	player_sprite.position.y = -58 + bob
	player_sprite.scale.x = abs(player_sprite.scale.x) * facing


func _update_camera(force_camera := false) -> void:
	if current_location == null:
		return

	var target := _clamped_camera_position(player.global_position)
	camera.zoom = Vector2.ONE * camera_zoom
	if force_camera:
		camera.global_position = target
	else:
		camera.global_position = camera.global_position.lerp(target, 0.18)


func _update_interaction(force := false) -> void:
	if current_location == null:
		return

	active_character = null
	active_portal = null

	for character in current_location.get_characters():
		if character.overlaps_body(player):
			active_character = character
			break

	if active_character == null:
		for portal in current_location.get_portals():
			if portal.overlaps_body(player):
				active_portal = portal
				break

	if active_character != null:
		interact_button.disabled = false
		interact_button.text = "Talk"
		status_label.text = "You are near %s. Tap Talk to practice Spanish." % active_character.character_name
	elif active_portal != null:
		interact_button.disabled = false
		interact_button.text = active_portal.action_title
		status_label.text = "You are near %s. Tap %s." % [active_portal.portal_title, active_portal.action_title]
	else:
		interact_button.disabled = true
		interact_button.text = "Explore"
		if force or status_label.text.begins_with("You are near"):
			status_label.text = current_location.default_status


func _use_primary_action() -> void:
	if active_character != null:
		quiz_panel.start(active_character.character_name)
		return

	if active_portal != null:
		_load_scene(active_portal.destination_scene, active_portal.destination_spawn)


func _change_zoom(delta: float) -> void:
	camera_zoom = clamp(camera_zoom + delta, _minimum_camera_zoom(), 1.8)
	_update_camera(true)


func _on_joystick_vector_changed(vector: Vector2) -> void:
	joystick_vector = vector


func _keyboard_vector() -> Vector2:
	var vector := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		vector.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		vector.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		vector.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		vector.y += 1
	return vector.normalized() if vector.length() > 1.0 else vector


func _clamped_camera_position(target: Vector2) -> Vector2:
	var map_size: Vector2 = current_location.get_world_size()
	var visible_size := get_viewport_rect().size / camera_zoom
	var center := map_size / 2.0
	var x: float = center.x if visible_size.x >= map_size.x else clamp(target.x, visible_size.x / 2.0, map_size.x - visible_size.x / 2.0)
	var y: float = center.y if visible_size.y >= map_size.y else clamp(target.y, visible_size.y / 2.0, map_size.y - visible_size.y / 2.0)
	return Vector2(x, y)


func _minimum_camera_zoom() -> float:
	if current_location == null:
		return MIN_CAMERA_ZOOM

	var map_size: Vector2 = current_location.get_world_size()
	var viewport_size := get_viewport_rect().size + Vector2.ONE * CAMERA_EDGE_PADDING
	return max(viewport_size.x / map_size.x, viewport_size.y / map_size.y, MIN_CAMERA_ZOOM)


func _fit_sprite_height(sprite: Sprite2D, height: float) -> void:
	if sprite.texture == null:
		return

	var texture_size := sprite.texture.get_size()
	if texture_size.y <= 0:
		return

	var scale_value := height / texture_size.y
	sprite.scale = Vector2(scale_value, scale_value)


func _ellipse_polygon(size: Vector2, color: Color) -> Polygon2D:
	var polygon := Polygon2D.new()
	var points := PackedVector2Array()
	for index in range(32):
		var angle := TAU * float(index) / 32.0
		points.append(Vector2(cos(angle) * size.x / 2.0, sin(angle) * size.y / 2.0))
	polygon.polygon = points
	polygon.color = color
	return polygon
