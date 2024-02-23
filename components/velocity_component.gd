class_name VelocityComponent
extends Node

const GRAVITY_ENABLED: bool = true
const GRAVITY: float = 120.0

const SPEED_MULTIPLIER: float = 100.0
const TERMINAL_SPEED: float = 1000.0 / 6

const GROUND_ACCELERATION_FACTOR: float = 10.0
const AIR_ACCELERATION_FACTOR: float = 0.9

@onready var character_body: CharacterBody2D = get_parent()

@export var is_controllable: bool = true

var velocity: Vector2 = Vector2():
	set = _set_velocity, get = _get_velocity
var input_vector: Vector2 = Vector2()

func _physics_process(delta: float) -> void:
	handle_input(delta)
	handle_movement(delta)

func handle_input(_delta) -> void:
	input_vector = Input.get_vector("left", "right", "up", "down")

func handle_movement(delta) -> void:
	if GRAVITY_ENABLED:
		velocity.y = clamp(velocity.y, -GRAVITY * 4, GRAVITY * 4)

		if character_body.is_on_floor():
			velocity.x = velocity.lerp(input_vector * SPEED_MULTIPLIER, GROUND_ACCELERATION_FACTOR * delta).x
			if Input.is_action_just_pressed("jump"):
				velocity.y = -75
			else:
				velocity.y = 0
		else:
			velocity.x = velocity.lerp(input_vector * SPEED_MULTIPLIER, AIR_ACCELERATION_FACTOR * delta).x
			velocity.y += GRAVITY * delta
	else:
		velocity = velocity.lerp(input_vector * SPEED_MULTIPLIER, 100 * delta)

	character_body.move_and_slide()

func _set_velocity(value: Vector2) -> void:
	if character_body:
		character_body.velocity = value

func _get_velocity() -> Vector2:
	if character_body:
		return character_body.velocity
	else:
		return Vector2()