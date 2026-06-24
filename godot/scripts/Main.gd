extends Node2D

const PLAYER_TEXTURE := "res://assets/art/player_avatar.png"
const SCHOLAR_TEXTURE := "res://assets/art/scholar_npc.png"

var scenes: Dictionary = {}
var scene_id := "village"
var scene_data: Dictionary = {}
var player_position := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var tap_target: Variant = null
var facing := 1.0
var camera_zoom := 1.0
var active_portal: Dictionary = {}
var active_character: Dictionary = {}

var world: Node2D
var background: Sprite2D
var player: CharacterBody2D
var player_sprite: Sprite2D
var player_shadow: Polygon2D
var camera: Camera2D
var scene_content: Node2D
var title_label: Label
var status_label: Label
var interact_button: Button
var quiz_panel: Control

@export var player_speed := 210.0
@export var portal_range := 105.0
@export var character_range := 112.0

func _ready() -> void:
    randomize()
    _build_scene_data()
    _build_world()
    _build_ui()
    _load_scene("village", scenes["village"]["spawn"])


func _process(delta: float) -> void:
    _update_movement(delta)
    _update_player_visual(delta)
    _update_camera()
    _update_interaction()


func _unhandled_input(event: InputEvent) -> void:
    if quiz_panel != null and quiz_panel.visible:
        return

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        tap_target = get_global_mouse_position()


func _build_world() -> void:
    world = Node2D.new()
    add_child(world)

    background = Sprite2D.new()
    background.centered = false
    background.z_index = -100
    world.add_child(background)

    scene_content = Node2D.new()
    world.add_child(scene_content)

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


func _build_scene_data() -> void:
    scenes = {
        "village": {
            "title": "Pueblo Espanol",
            "subtitle": "Move freely around the village. Enter buildings to find new scenes.",
            "background": "res://assets/art/village_map_sim.png",
            "size": Vector2(1254, 1254),
            "spawn": Vector2(625, 700),
            "walkable": [
                {"type": "ellipse", "rect": Rect2(390, 430, 480, 360)},
                {"type": "rect", "rect": Rect2(485, 250, 280, 520)},
                {"type": "rect", "rect": Rect2(430, 720, 250, 540)},
                {"type": "rect", "rect": Rect2(210, 560, 370, 160)},
                {"type": "rect", "rect": Rect2(675, 575, 360, 155)},
                {"type": "rect", "rect": Rect2(775, 815, 260, 250)},
                {"type": "rect", "rect": Rect2(500, 360, 230, 80)},
                {"type": "rect", "rect": Rect2(915, 620, 120, 120)},
                {"type": "rect", "rect": Rect2(840, 980, 120, 95)}
            ],
            "portals": [
                {"id": "school-door", "title": "School", "action": "Enter School", "rect": Rect2(535, 250, 180, 155), "destination": "school", "spawn": Vector2(625, 980)},
                {"id": "cafe-door", "title": "Cafe", "action": "Enter Cafe", "rect": Rect2(920, 490, 180, 155), "destination": "cafe", "spawn": Vector2(625, 880)},
                {"id": "library-door", "title": "Library", "action": "Enter Library", "rect": Rect2(820, 860, 210, 170), "destination": "library", "spawn": Vector2(625, 930)}
            ],
            "characters": []
        },
        "school": {
            "title": "Village School",
            "subtitle": "A future classroom scene for lessons and mini games.",
            "background": "res://assets/art/school_interior_sim.png",
            "size": Vector2(1254, 1254),
            "spawn": Vector2(625, 980),
            "walkable": [
                {"type": "rect", "rect": Rect2(350, 520, 560, 600)},
                {"type": "rect", "rect": Rect2(455, 1025, 345, 180)}
            ],
            "portals": [
                {"id": "school-exit", "title": "Village Plaza", "action": "Exit School", "rect": Rect2(455, 1025, 345, 180), "destination": "village", "spawn": Vector2(625, 410)}
            ],
            "characters": []
        },
        "cafe": {
            "title": "Village Cafe",
            "subtitle": "A future conversation scene for ordering food in Spanish.",
            "background": "res://assets/art/cafe_interior_sim.png",
            "size": Vector2(1254, 1254),
            "spawn": Vector2(625, 880),
            "walkable": [
                {"type": "rect", "rect": Rect2(290, 470, 560, 550)},
                {"type": "rect", "rect": Rect2(555, 235, 190, 280)}
            ],
            "portals": [
                {"id": "cafe-exit", "title": "Village Plaza", "action": "Exit Cafe", "rect": Rect2(555, 235, 190, 210), "destination": "village", "spawn": Vector2(990, 650)}
            ],
            "characters": []
        },
        "library": {
            "title": "Village Library",
            "subtitle": "Walk close to the scholar to practice Spanish.",
            "background": "res://assets/art/library_interior_sim.png",
            "size": Vector2(1254, 1254),
            "spawn": Vector2(625, 930),
            "walkable": [
                {"type": "rect", "rect": Rect2(350, 520, 590, 555)},
                {"type": "rect", "rect": Rect2(450, 1050, 360, 165)}
            ],
            "portals": [
                {"id": "library-exit", "title": "Village Plaza", "action": "Exit Library", "rect": Rect2(450, 1050, 360, 165), "destination": "village", "spawn": Vector2(900, 1000)}
            ],
            "characters": [
                {"id": "scholar", "name": "Scholar", "role": "Spanish Tutor", "greeting": "Bienvenido. Let's practice Spanish in the library.", "position": Vector2(650, 610), "texture": SCHOLAR_TEXTURE}
            ]
        }
    }


func _load_scene(next_scene_id: String, spawn: Vector2) -> void:
    scene_id = next_scene_id
    scene_data = scenes[scene_id]
    background.texture = load(scene_data["background"])
    player_position = _clamp_to_scene(spawn)
    joystick_vector = Vector2.ZERO
    tap_target = null
    camera_zoom = 1.08 if scene_id != "village" else 0.96

    for child in scene_content.get_children():
        child.queue_free()

    for portal in scene_data["portals"]:
        _add_portal_marker(portal)

    for character in scene_data["characters"]:
        _add_character(character)

    _set_player_position(player_position)
    title_label.text = scene_data["title"]
    status_label.text = _default_status()
    _update_camera(true)
    _update_interaction(true)


func _add_portal_marker(portal: Dictionary) -> void:
    var rect: Rect2 = portal["rect"]
    var marker := Node2D.new()
    marker.position = rect.get_center()
    marker.z_index = 50
    scene_content.add_child(marker)

    var dot := _ellipse_polygon(Vector2(46, 46), Color(0, 0, 0, 0.46))
    marker.add_child(dot)

    var label := Label.new()
    label.text = portal["title"]
    label.position = Vector2(-40, 24)
    marker.add_child(label)


func _add_character(character: Dictionary) -> void:
    var node := Node2D.new()
    node.position = character["position"]
    node.z_index = int(node.position.y)
    scene_content.add_child(node)

    node.add_child(_ellipse_polygon(Vector2(44, 13), Color(0, 0, 0, 0.24)))

    var sprite := Sprite2D.new()
    sprite.texture = load(character["texture"])
    sprite.position = Vector2(0, -56)
    sprite.z_index = 10
    node.add_child(sprite)
    _fit_sprite_height(sprite, 106.0)

    var label := Label.new()
    label.text = character["name"]
    label.position = Vector2(-34, -118)
    node.add_child(label)


func _update_movement(delta: float) -> void:
    if quiz_panel.visible:
        return

    var input_vector := joystick_vector
    if input_vector.length() < 0.05:
        input_vector = _keyboard_vector()

    if input_vector.length() > 0.05:
        tap_target = null
        _move_by(input_vector.normalized() * player_speed * delta)
    elif tap_target != null:
        var to_target: Vector2 = tap_target - player_position
        if to_target.length() <= 8.0:
            tap_target = null
        else:
            _move_by(to_target.normalized() * min(player_speed * delta, to_target.length()))


func _move_by(delta: Vector2) -> void:
    var proposed := _clamp_to_scene(player_position + delta)
    if _is_walkable(proposed):
        _commit_move(proposed)
        return

    var horizontal := _clamp_to_scene(Vector2(proposed.x, player_position.y))
    if _is_walkable(horizontal):
        _commit_move(horizontal)
        return

    var vertical := _clamp_to_scene(Vector2(player_position.x, proposed.y))
    if _is_walkable(vertical):
        _commit_move(vertical)
        return

    status_label.text = "Stay on the paths." if scene_id == "village" else "Walk through the open floor area."


func _commit_move(next_position: Vector2) -> void:
    if abs(next_position.x - player_position.x) > 0.5:
        facing = 1.0 if next_position.x > player_position.x else -1.0

    player_position = next_position
    _set_player_position(player_position)


func _set_player_position(position: Vector2) -> void:
    player.global_position = position
    player.z_index = int(position.y)


func _update_player_visual(_delta: float) -> void:
    var moving := joystick_vector.length() > 0.05 or tap_target != null or _keyboard_vector().length() > 0.05
    var bob := sin(Time.get_ticks_msec() / 1000.0 * 15.0) * 4.0 if moving else 0.0
    player_sprite.position.y = -58 + bob
    player_sprite.scale.x = abs(player_sprite.scale.x) * facing


func _update_camera(force_camera := false) -> void:
    var target := _clamped_camera_position(player_position)
    camera.zoom = Vector2.ONE * camera_zoom
    if force_camera:
        camera.global_position = target
    else:
        camera.global_position = camera.global_position.lerp(target, 0.18)


func _update_interaction(force := false) -> void:
    active_character = {}
    active_portal = {}

    for character in scene_data["characters"]:
        if player_position.distance_to(character["position"]) <= character_range:
            active_character = character
            break

    if active_character.is_empty():
        for portal in scene_data["portals"]:
            var rect: Rect2 = portal["rect"]
            if rect.grow(portal_range).has_point(player_position):
                active_portal = portal
                break

    if not active_character.is_empty():
        interact_button.disabled = false
        interact_button.text = "Talk"
        status_label.text = "You are near %s. Tap Talk to practice Spanish." % active_character["name"]
    elif not active_portal.is_empty():
        interact_button.disabled = false
        interact_button.text = active_portal["action"]
        status_label.text = "You are near %s. Tap %s." % [active_portal["title"], active_portal["action"]]
    else:
        interact_button.disabled = true
        interact_button.text = "Explore"
        if force or status_label.text.begins_with("You are near"):
            status_label.text = _default_status()


func _use_primary_action() -> void:
    if not active_character.is_empty():
        quiz_panel.start(active_character["name"])
        return

    if not active_portal.is_empty():
        _load_scene(active_portal["destination"], active_portal["spawn"])


func _change_zoom(delta: float) -> void:
    camera_zoom = clamp(camera_zoom + delta, 0.72, 1.55)
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


func _clamp_to_scene(point: Vector2) -> Vector2:
    var size: Vector2 = scene_data["size"]
    return Vector2(clamp(point.x, 48.0, size.x - 48.0), clamp(point.y, 58.0, size.y - 58.0))


func _is_walkable(point: Vector2) -> bool:
    for area in scene_data["walkable"]:
        var rect: Rect2 = area["rect"]
        if area["type"] == "rect" and rect.has_point(point):
            return true
        if area["type"] == "ellipse":
            var normalized := Vector2((point.x - rect.get_center().x) / (rect.size.x / 2.0), (point.y - rect.get_center().y) / (rect.size.y / 2.0))
            if normalized.length_squared() <= 1.0:
                return true
    return false


func _clamped_camera_position(target: Vector2) -> Vector2:
    var map_size: Vector2 = scene_data["size"]
    var visible_size := get_viewport_rect().size / camera_zoom
    return Vector2(
        clamp(target.x, visible_size.x / 2.0, map_size.x - visible_size.x / 2.0),
        clamp(target.y, visible_size.y / 2.0, map_size.y - visible_size.y / 2.0)
    )


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


func _default_status() -> String:
    match scene_id:
        "village":
            return "Explore the village. School, cafe, and library are enterable."
        "school":
            return "This classroom can host future lessons. Exit near the bottom door."
        "cafe":
            return "Cafe conversations can be added here later. Exit through the open door."
        "library":
            return "Walk close to the scholar to start Spanish practice. Exit near the bottom."
    return ""
