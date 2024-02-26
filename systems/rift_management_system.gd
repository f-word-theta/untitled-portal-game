extends Node

const RIFT_SCENE: PackedScene = preload("res://entities/base_rift.tscn")

var first_rift: Rift = null
var second_rift: Rift = null

func _unhandled_input(event: InputEvent):
	if GameStateSystem.current_state != GameStateSystem.GameState.MAIN:
		return

	handle_rift_placement(event)

func handle_rift_placement(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("primary_fire"):
		if first_rift == null:
			first_rift = RIFT_SCENE.instantiate()
			first_rift.name = "FirstRift"
			
			GameStateSystem.current_scene.add_child(first_rift)
		
		first_rift.global_position = GameStateSystem.current_scene.get_global_mouse_position()
		
		if second_rift != null:
			first_rift.rift_component.destination_rift = second_rift
			second_rift.rift_component.destination_rift = first_rift
			
	elif Input.is_action_just_pressed("secondary_fire"):
		if second_rift == null:
			second_rift = RIFT_SCENE.instantiate()
			second_rift.name = "SecondRift"
			second_rift.rotation_degrees = -180.0
			second_rift.get_node("RiftCollisionShape").debug_color = Color(1, .847, .996, .145)
			
			GameStateSystem.current_scene.add_child(second_rift)
		
		second_rift.global_position = GameStateSystem.current_scene.get_global_mouse_position()

		if first_rift != null:
			second_rift.rift_component.destination_rift = first_rift
			first_rift.rift_component.destination_rift = second_rift

func _process(_delta: float) -> void:
	if GameStateSystem.current_state != GameStateSystem.GameState.MAIN:
		return