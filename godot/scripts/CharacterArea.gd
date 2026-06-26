extends Area2D

const MOVEMENT_COLLISION_LAYER := 1
const INTERACTION_COLLISION_LAYER := 2

@export var character_id := ""
@export var character_name := ""
@export var role := ""
@export_multiline var greeting := ""

func _ready() -> void:
	collision_layer = INTERACTION_COLLISION_LAYER
	collision_mask = MOVEMENT_COLLISION_LAYER
