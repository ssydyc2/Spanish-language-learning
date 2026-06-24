extends Control

signal vector_changed(vector: Vector2)

var knob_offset := Vector2.ZERO
var active := false
var active_touch_index := -1

@export var pad_radius := 56.0
@export var knob_radius := 21.0

func _ready() -> void:
    custom_minimum_size = Vector2(pad_radius * 2.0, pad_radius * 2.0)
    mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
    var center := size * 0.5
    draw_circle(center, pad_radius, Color(0.02, 0.03, 0.03, 0.42))
    draw_arc(center, pad_radius, 0.0, TAU, 64, Color(1, 1, 1, 0.26), 2.0)
    draw_circle(center, pad_radius * 0.68, Color(1, 1, 1, 0.08))
    draw_circle(center + knob_offset, knob_radius, Color(0.17, 0.56, 0.48, 0.95))
    draw_arc(center + knob_offset, knob_radius, 0.0, TAU, 32, Color(1, 1, 1, 0.65), 2.0)


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            active = true
            _set_from_local_position(event.position)
        else:
            _release()
        accept_event()
        return

    if event is InputEventMouseMotion and active:
        _set_from_local_position(event.position)
        accept_event()
        return

    if event is InputEventScreenTouch:
        if event.pressed and active_touch_index == -1:
            active_touch_index = event.index
            active = true
            _set_from_local_position(event.position)
        elif not event.pressed and event.index == active_touch_index:
            active_touch_index = -1
            _release()
        accept_event()
        return

    if event is InputEventScreenDrag and event.index == active_touch_index:
        _set_from_local_position(event.position)
        accept_event()


func _set_from_local_position(position: Vector2) -> void:
    var raw := position - size * 0.5
    knob_offset = raw.limit_length(pad_radius)
    vector_changed.emit(knob_offset / pad_radius)
    queue_redraw()


func _release() -> void:
    active = false
    knob_offset = Vector2.ZERO
    vector_changed.emit(Vector2.ZERO)
    queue_redraw()
