extends Node2D

const PLAYER_TEXTURE := "res://assets/art/player_avatar.png"
const PLAYER_RUN_TEXTURE := "res://assets/art/player_run_spritesheet.png"
const PLAYER_SPRITE_HEIGHT := 142.0
const PLAYER_RUN_FRAME_COUNT := 6
const CAMERA_EDGE_PADDING := 12.0
const MIN_CAMERA_ZOOM := 0.58
const MAX_CAMERA_ZOOM := 1.8
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
var active_touch_positions := {}
var pinch_distance := 0.0
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
var number_lesson_panel: Control
var practice_prompt_panel: PanelContainer
var practice_prompt_title: Label
var practice_prompt_body: Label
var practice_prompt_primary_button: Button
var practice_prompt_secondary_button: Button
var practice_prompt_decline_button: Button
var prompted_character_id := ""
var prompted_character_name := ""
var practice_prompt_mode := "practice"

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
		return

	if event is InputEventMagnifyGesture:
		_set_zoom(camera_zoom * event.factor)
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			active_touch_positions[event.index] = event.position
		else:
			active_touch_positions.erase(event.index)
		_update_pinch_state()
		return

	if event is InputEventScreenDrag:
		if active_touch_positions.has(event.index):
			active_touch_positions[event.index] = event.position
			_update_pinch_zoom()


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
	interact_button.text = "Talk"
	interact_button.disabled = true
	interact_button.visible = false
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

	var number_lesson_script := load("res://scripts/NumberLessonPanel.gd")
	number_lesson_panel = number_lesson_script.new()
	number_lesson_panel.anchor_left = 0.5
	number_lesson_panel.anchor_top = 0.5
	number_lesson_panel.anchor_right = 0.5
	number_lesson_panel.anchor_bottom = 0.5
	number_lesson_panel.offset_left = -270
	number_lesson_panel.offset_top = -300
	number_lesson_panel.offset_right = 270
	number_lesson_panel.offset_bottom = 300
	number_lesson_panel.back_requested.connect(_open_course_menu)
	number_lesson_panel.closed.connect(_on_number_lesson_closed)
	layer.add_child(number_lesson_panel)

	_build_practice_prompt(layer)


func _build_practice_prompt(layer: CanvasLayer) -> void:
	practice_prompt_panel = PanelContainer.new()
	practice_prompt_panel.visible = false
	practice_prompt_panel.anchor_left = 0.5
	practice_prompt_panel.anchor_top = 0.5
	practice_prompt_panel.anchor_right = 0.5
	practice_prompt_panel.anchor_bottom = 0.5
	practice_prompt_panel.offset_left = -180
	practice_prompt_panel.offset_top = -160
	practice_prompt_panel.offset_right = 180
	practice_prompt_panel.offset_bottom = 160
	practice_prompt_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(practice_prompt_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	practice_prompt_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	practice_prompt_title = Label.new()
	practice_prompt_title.text = "Scholar"
	practice_prompt_title.add_theme_font_size_override("font_size", 24)
	box.add_child(practice_prompt_title)

	practice_prompt_body = Label.new()
	practice_prompt_body.text = "Do you want to practice Spanish?\n¿Quieres practicar español?"
	practice_prompt_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	practice_prompt_body.add_theme_font_size_override("font_size", 18)
	box.add_child(practice_prompt_body)

	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)

	practice_prompt_primary_button = Button.new()
	practice_prompt_primary_button.text = "Practice / Practicar"
	practice_prompt_primary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	practice_prompt_primary_button.pressed.connect(_accept_practice_prompt)
	actions.add_child(practice_prompt_primary_button)

	practice_prompt_secondary_button = Button.new()
	practice_prompt_secondary_button.text = "Number Practice / Números"
	practice_prompt_secondary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	practice_prompt_secondary_button.pressed.connect(_open_number_practice_menu)
	actions.add_child(practice_prompt_secondary_button)

	practice_prompt_decline_button = Button.new()
	practice_prompt_decline_button.text = "No thanks / No, gracias"
	practice_prompt_decline_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	practice_prompt_decline_button.pressed.connect(_decline_practice_prompt)
	actions.add_child(practice_prompt_decline_button)


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
	camera_zoom = _minimum_camera_zoom()
	_set_player_position(current_location.get_spawn_position(spawn_name))
	ignored_spawn_portal = _find_portal_at_player_position()

	title_label.text = current_location.title
	status_label.text = current_location.default_status
	_update_camera(true)
	_update_interaction(true)


func _update_movement(_delta: float) -> void:
	if quiz_panel.visible or practice_prompt_panel.visible or number_lesson_panel.visible:
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
		interact_button.visible = true
		interact_button.text = "Talk"
		status_label.text = "You are near %s. Tap Talk." % active_character.character_name
	elif active_portal != null:
		interact_button.disabled = true
		interact_button.visible = false
		status_label.text = "Entering %s..." % active_portal.portal_title
		_enter_portal(active_portal)
	else:
		interact_button.disabled = true
		interact_button.visible = false
		if force or status_label.text.begins_with("You are near") or status_label.text.begins_with("Entering"):
			status_label.text = current_location.default_status


func _use_primary_action() -> void:
	if active_character != null:
		_open_practice_prompt(active_character)


func _open_practice_prompt(character: Area2D) -> void:
	prompted_character_id = character.character_id
	prompted_character_name = character.character_name
	practice_prompt_title.text = character.character_name
	if prompted_character_id == "teacher":
		_open_teacher_course_prompt(character.greeting)
		return
	else:
		practice_prompt_mode = "practice"
		practice_prompt_body.text = "Do you want to practice Spanish?\n¿Quieres practicar español?"
		practice_prompt_primary_button.text = "Practice / Practicar"
		practice_prompt_secondary_button.visible = false
	practice_prompt_decline_button.text = "No thanks / No, gracias"
	if not character.greeting.is_empty():
		practice_prompt_body.text = "%s\n\n%s" % [character.greeting, practice_prompt_body.text]
	practice_prompt_panel.visible = true


func _accept_practice_prompt() -> void:
	if practice_prompt_mode == "teacher_intro":
		_open_course_menu()
		return
	if practice_prompt_mode == "teacher_courses":
		_open_number_practice_menu()
		return

	practice_prompt_panel.visible = false

	var character_name := prompted_character_name
	if character_name.is_empty():
		character_name = "Scholar"
	quiz_panel.start(character_name)


func _open_teacher_course_prompt(greeting := "") -> void:
	practice_prompt_mode = "teacher_intro"
	practice_prompt_title.text = "Teacher"
	practice_prompt_body.text = "Would you like to study a course?\n¿Quieres estudiar un curso?"
	practice_prompt_primary_button.text = "1. Course Study / Estudio de cursos"
	practice_prompt_secondary_button.visible = false
	practice_prompt_decline_button.text = "2. No thanks / No, gracias"
	if not greeting.is_empty():
		practice_prompt_body.text = "%s\n\n%s" % [greeting, practice_prompt_body.text]
	practice_prompt_panel.visible = true


func _open_course_menu() -> void:
	if number_lesson_panel.visible:
		number_lesson_panel.visible = false
	practice_prompt_mode = "teacher_courses"
	prompted_character_id = "teacher"
	prompted_character_name = "Teacher"
	practice_prompt_title.text = "Course Study / Estudio de cursos"
	practice_prompt_body.text = "Choose a course.\nElige un curso."
	practice_prompt_primary_button.text = "1. Number Course / Curso de números"
	practice_prompt_secondary_button.visible = false
	practice_prompt_decline_button.text = "Back / Volver"
	practice_prompt_panel.visible = true


func _open_number_practice_menu() -> void:
	practice_prompt_panel.visible = false
	number_lesson_panel.open_menu()


func _on_number_lesson_closed() -> void:
	status_label.text = "Teacher is ready when you want more number practice."


func _decline_practice_prompt() -> void:
	if practice_prompt_mode == "teacher_courses":
		_open_teacher_course_prompt("Welcome to class.\nBienvenidos a clase.")
		return

	practice_prompt_panel.visible = false
	var character_name := prompted_character_name
	if character_name.is_empty():
		character_name = "Teacher"
	status_label.text = "%s nods. Come back anytime to practice Spanish." % character_name


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


func _set_zoom(value: float) -> void:
	camera_zoom = clamp(value, _minimum_camera_zoom(), MAX_CAMERA_ZOOM)
	_update_camera(true)


func _update_pinch_state() -> void:
	pinch_distance = _current_pinch_distance()


func _update_pinch_zoom() -> void:
	var current_distance := _current_pinch_distance()
	if pinch_distance <= 0.0 or current_distance <= 0.0:
		pinch_distance = current_distance
		return

	_set_zoom(camera_zoom * (current_distance / pinch_distance))
	pinch_distance = current_distance


func _current_pinch_distance() -> float:
	if active_touch_positions.size() < 2:
		return 0.0

	var touch_positions := active_touch_positions.values()
	return touch_positions[0].distance_to(touch_positions[1])


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
