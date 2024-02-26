class_name RiftPlacerComponent
extends Node

# EXPORTS

@export var camera: Camera2D
@export var rift_placement_direction: RayCast2D

func _process(_delta):
    rift_placement_direction.global_rotation = atan2(camera.get_local_mouse_position().y, camera.get_local_mouse_position().x)