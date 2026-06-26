extends Area2D

const MOVEMENT_COLLISION_LAYER := 1
const INTERACTION_COLLISION_LAYER := 2

@export var portal_id := ""
@export var portal_title := ""
@export var action_title := ""
@export var destination_scene := ""
@export var destination_spawn := "Start"

func _ready() -> void:
	collision_layer = INTERACTION_COLLISION_LAYER
	collision_mask = MOVEMENT_COLLISION_LAYER
