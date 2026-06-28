extends Node2D

const PLAYER_TEXTURE := "res://assets/art/player_avatar.png"
const PLAYER_RUN_TEXTURE := "res://assets/art/player_run_spritesheet.png"
const PLAYER_SPRITE_HEIGHT := 142.0
const PLAYER_RUN_FRAME_COUNT := 6
const CAMERA_EDGE_PADDING := 12.0
const MIN_CAMERA_ZOOM := 0.58
const MOVEMENT_COLLISION_LAYER := 1
const DEBUG_COLLISION_COLOR := Color(1.0, 0.26, 0.12, 0.32)
const DEBUG_COLLISION_OUTLINE_COLOR := Color(1.0, 0.9, 0.25, 0.72)
const DEBUG_WALKABLE_COLOR := Color(0.2, 0.95, 0.45, 0.22)
const DEBUG_WALKABLE_OUTLINE_COLOR := Color(0.45, 1.0, 0.65, 0.72)
const DEBUG_COLLISION_Z_INDEX := 4090

const LOCATION_SCENES := {
	"village": "res://scenes/locations/Village.tscn",
	"school": "res://scenes/locations/School.tscn",
	"cafe": "res://scenes/locations/Cafe.tscn",
	"library": "res://scenes/locations/Library.tscn"
}

var joystick_vector := Vector2.ZERO
var facing := 1.0
var camera_zoom := 1.0
var player_is_moving := false
var active_portal: Area2D
var active_character: Area2D
var ignored_spawn_portal: Area2D

var world: Node2D
var location_holder: Node2D
var current_location: Node2D
var player: CharacterBody2D
var player_sprite: AnimatedSprite2D
var player_sprite_base_scale := 1.0
var player_shadow: Polygon2D
var collision_debug_root: Node2D
var camera: Camera2D
var title_label: Label
var status_label: Label
var interact_button: Button
var quiz_panel: Control

@export var player_speed := 210.0
@export var show_collision_debug := false

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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		show_collision_debug = not show_collision_debug
		_refresh_collision_debug_overlay()


func _build_world() -> void:
	world = Node2D.new()
	add_child(world)

	location_holder = Node2D.new()
	location_holder.name = "LocationHolder"
	world.add_child(location_holder)

	player = CharacterBody2D.new()
	player.name = "Player"
	player.collision_layer = MOVEMENT_COLLISION_LAYER
	player.collision_mask = MOVEMENT_COLLISION_LAYER
	world.add_child(player)

	player_shadow = _ellipse_polygon(Vector2(60, 18), Color(0, 0, 0, 0.28))
	player_shadow.z_index = 9
	player.add_child(player_shadow)

	player_sprite = AnimatedSprite2D.new()
	player_sprite.sprite_frames = _build_player_sprite_frames()
	player_sprite.play("idle")
	player_sprite.position = Vector2(0, -PLAYER_SPRITE_HEIGHT / 2.0)
	player_sprite.z_index = 20
	player.add_child(player_sprite)
	player_sprite_base_scale = _scale_for_texture_height(load(PLAYER_TEXTURE), PLAYER_SPRITE_HEIGHT)
	player_sprite.scale = Vector2.ONE * player_sprite_base_scale

	var shape := CollisionShape2D.new()
	shape.name = "FootCollision"
	var circle := CircleShape2D.new()
	circle.radius = 16
	shape.shape = circle
	player.add_child(shape)

	collision_debug_root = Node2D.new()
	collision_debug_root.name = "CollisionDebugOverlay"
	collision_debug_root.z_index = DEBUG_COLLISION_Z_INDEX
	collision_debug_root.visible = show_collision_debug
	world.add_child(collision_debug_root)

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
	_refresh_collision_debug_overlay()

	joystick_vector = Vector2.ZERO
	player.velocity = Vector2.ZERO
	camera_zoom = max(float(current_location.initial_zoom), _minimum_camera_zoom())
	_set_player_position(current_location.get_spawn_position(spawn_name))
	ignored_spawn_portal = _find_portal_at_player_position()

	title_label.text = current_location.title
	status_label.text = current_location.default_status
	_update_camera(true)
	_update_interaction(true)


func _update_movement(_delta: float) -> void:
	if quiz_panel.visible:
		player_is_moving = false
		player.velocity = Vector2.ZERO
		return

	var input_vector := joystick_vector
	if input_vector.length() < 0.05:
		input_vector = _keyboard_vector()

	player_is_moving = input_vector.length() > 0.05
	if player_is_moving:
		var direction := input_vector.normalized()
		player.velocity = direction * player_speed
		if abs(direction.x) > 0.05:
			facing = 1.0 if direction.x > 0.0 else -1.0
	else:
		player.velocity = Vector2.ZERO

	var previous_position := player.global_position
	player.move_and_slide()
	_clamp_player_to_map()
	_constrain_player_to_walkable_area(previous_position)
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


func _refresh_collision_debug_overlay() -> void:
	if collision_debug_root == null:
		return

	for child in collision_debug_root.get_children():
		child.queue_free()

	collision_debug_root.visible = show_collision_debug
	if not show_collision_debug or current_location == null:
		return

	var collision_root := current_location.get_node_or_null("Collision")
	if collision_root != null:
		for collision_polygon in collision_root.find_children("*", "CollisionPolygon2D", true, false):
			if collision_polygon.disabled:
				continue

			_add_debug_polygon(
				collision_polygon.polygon,
				collision_polygon.global_transform,
				DEBUG_COLLISION_COLOR,
				DEBUG_COLLISION_OUTLINE_COLOR
			)

	if current_location.has_method("get_walkable_areas"):
		for walkable_area in current_location.get_walkable_areas():
			_add_debug_polygon(
				walkable_area.polygon,
				walkable_area.global_transform,
				DEBUG_WALKABLE_COLOR,
				DEBUG_WALKABLE_OUTLINE_COLOR
			)


func _add_debug_polygon(polygon: PackedVector2Array, transform: Transform2D, fill_color: Color, outline_color: Color) -> void:
	var fill := Polygon2D.new()
	fill.polygon = polygon
	fill.color = fill_color
	fill.z_index = DEBUG_COLLISION_Z_INDEX
	collision_debug_root.add_child(fill)
	fill.global_transform = transform

	var outline := Line2D.new()
	outline.points = polygon
	outline.closed = true
	outline.width = 2.0
	outline.default_color = outline_color
	outline.z_index = DEBUG_COLLISION_Z_INDEX + 1
	collision_debug_root.add_child(outline)
	outline.global_transform = transform


func _constrain_player_to_walkable_area(previous_position: Vector2) -> void:
	if current_location == null or not current_location.has_method("is_position_walkable"):
		return
	if not current_location.has_walkable_areas():
		return
	if current_location.is_position_walkable(player.global_position):
		return

	var target_position := player.global_position
	var horizontal_position := Vector2(target_position.x, previous_position.y)
	var vertical_position := Vector2(previous_position.x, target_position.y)

	if current_location.is_position_walkable(horizontal_position):
		player.global_position = horizontal_position
	elif current_location.is_position_walkable(vertical_position):
		player.global_position = vertical_position
	elif current_location.is_position_walkable(previous_position):
		player.global_position = previous_position
	else:
		player.velocity = Vector2.ZERO


func _update_player_visual(_delta: float) -> void:
	var moving := player_is_moving
	var stride := sin(Time.get_ticks_msec() / 1000.0 * 16.0)
	var squash: float = 0.975 + abs(stride) * 0.035 if moving else 1.0
	var stretch: float = 1.02 - abs(stride) * 0.025 if moving else 1.0

	if moving and player_sprite.sprite_frames.has_animation("run") and player_sprite.animation != "run":
		player_sprite.play("run")
	elif not moving and player_sprite.animation != "idle":
		player_sprite.play("idle")

	player_sprite.speed_scale = 1.35 if moving else 1.0
	player_sprite.flip_h = facing < 0.0
	player_sprite.scale = Vector2(player_sprite_base_scale * stretch, player_sprite_base_scale * squash)
	player_sprite.position.x = stride * 2.0 if moving else 0.0
	player_sprite.position.y = -(PLAYER_SPRITE_HEIGHT * squash) / 2.0
	player_sprite.rotation_degrees = stride * 2.8 if moving else 0.0
	player_shadow.scale = Vector2(1.0 + abs(stride) * 0.08, 1.0) if moving else Vector2.ONE


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

	active_character = _find_overlapping_character()

	if active_character == null:
		if ignored_spawn_portal != null and not _portal_contains_point(ignored_spawn_portal, player.global_position):
			ignored_spawn_portal = null

		active_portal = _find_portal_at_player_position()
		if active_portal == ignored_spawn_portal:
			active_portal = null

	if active_character != null:
		interact_button.disabled = false
		interact_button.text = "Talk"
		status_label.text = "You are near %s. Tap Talk to practice Spanish." % active_character.character_name
	elif active_portal != null:
		interact_button.disabled = true
		interact_button.text = "Explore"
		status_label.text = "Entering %s..." % active_portal.portal_title
		_enter_portal(active_portal)
	else:
		interact_button.disabled = true
		interact_button.text = "Explore"
		if force or status_label.text.begins_with("You are near") or status_label.text.begins_with("Entering"):
			status_label.text = current_location.default_status


func _use_primary_action() -> void:
	if active_character != null:
		quiz_panel.start(active_character.character_name)


func _enter_portal(portal: Area2D) -> void:
	if portal == null:
		return

	_load_scene(portal.destination_scene, portal.destination_spawn)


func _find_overlapping_character() -> Area2D:
	if current_location == null:
		return null

	for character in current_location.get_characters():
		if character.overlaps_body(player):
			return character

	return null


func _find_portal_at_player_position() -> Area2D:
	if current_location == null:
		return null

	for portal in current_location.get_portals():
		if _portal_contains_point(portal, player.global_position):
			return portal

	return null


func _portal_contains_point(portal: Area2D, world_position: Vector2) -> bool:
	for collision_polygon in portal.find_children("*", "CollisionPolygon2D", true, false):
		if collision_polygon.disabled:
			continue
		if Geometry2D.is_point_in_polygon(collision_polygon.to_local(world_position), collision_polygon.polygon):
			return true

	return false


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


func _build_player_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var idle_texture: Texture2D = load(PLAYER_TEXTURE)
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 1.0)
	frames.set_animation_loop("idle", true)
	frames.add_frame("idle", idle_texture)

	var run_texture: Texture2D = load(PLAYER_RUN_TEXTURE)
	if run_texture == null:
		return frames

	var frame_width := float(run_texture.get_width()) / float(PLAYER_RUN_FRAME_COUNT)
	frames.add_animation("run")
	frames.set_animation_speed("run", 10.0)
	frames.set_animation_loop("run", true)
	for frame_index in range(PLAYER_RUN_FRAME_COUNT):
		var frame := AtlasTexture.new()
		frame.atlas = run_texture
		frame.region = Rect2(frame_width * frame_index, 0, frame_width, run_texture.get_height())
		frames.add_frame("run", frame)

	return frames


func _scale_for_texture_height(texture: Texture2D, height: float) -> float:
	if texture == null:
		return 1.0

	var texture_size := texture.get_size()
	if texture_size.y <= 0:
		return 1.0

	return height / texture_size.y


func _ellipse_polygon(size: Vector2, color: Color) -> Polygon2D:
	var polygon := Polygon2D.new()
	var points := PackedVector2Array()
	for index in range(32):
		var angle := TAU * float(index) / 32.0
		points.append(Vector2(cos(angle) * size.x / 2.0, sin(angle) * size.y / 2.0))
	polygon.polygon = points
	polygon.color = color
	return polygon
