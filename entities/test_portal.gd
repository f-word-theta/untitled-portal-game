class_name Portal
extends Area2D

const VELOCITY_RETAIN_FACTOR: float = 0.97

@onready var portal_travellers: Array = []
@onready var projected_sprites: Dictionary = {}

@onready var label: Label = get_node("../DebugUI/Label")
@onready var behindArea: Area2D = get_node("BehindArea")

@export var destination_portal: Portal = null
@export var enabled: bool = true

var previous_velocity: Vector2 = Vector2()


func _physics_process(_delta: float) -> void:
	if not enabled or not destination_portal:
		return

	for traveller: PhysicsBody2D in portal_travellers:
		if not (traveller is RigidBody2D or traveller is CharacterBody2D):
			return

		var vector_from_portal_to_traveller: Vector2 = traveller.global_position - global_position
		var vector_from_portal_to_traveller_normalized: Vector2 = global_position.direction_to(traveller.global_position)

		if vector_from_portal_to_traveller_normalized.dot(global_transform.x) < 0.0:
			previous_velocity = traveller.velocity

			traveller.global_position = destination_portal.global_position + destination_portal.global_transform.x * 4 + vector_from_portal_to_traveller
			traveller.velocity = destination_portal.global_transform.x.normalized() * previous_velocity.length() * VELOCITY_RETAIN_FACTOR

		if not (traveller.has_node("SpecialSpriteGroup")):
			return
		
		var special_sprite_group = traveller.get_node("SpecialSpriteGroup")
		var mask_sprite = special_sprite_group.get_node("Mask")

		if not mask_sprite.visible:
			mask_sprite.visible = true

		for sprite_owner in projected_sprites:
			for sprite in projected_sprites[sprite_owner]:
				sprite.global_position = destination_portal.global_position

		mask_sprite.global_rotation = global_rotation
		mask_sprite.global_position = global_position

		

func _on_body_entered(body: PhysicsBody2D) -> void:
	var special_sprite_group = body.get_node("SpecialSpriteGroup")
	var mask_sprite = special_sprite_group.get_node("Mask")
		
	for sprite in special_sprite_group.get_children():
		if sprite == mask_sprite:
			continue
		
		var duplicated_sprite: AnimatedSprite2D = AnimatedSprite2D.new()
		add_child(duplicated_sprite)

		duplicated_sprite.texture_filter = sprite.texture_filter
		duplicated_sprite.name = sprite.name

		duplicated_sprite.global_rotation = sprite.global_rotation

		duplicated_sprite.sprite_frames = sprite.sprite_frames
		duplicated_sprite.animation = sprite.animation

		duplicated_sprite.play()

		duplicated_sprite.frame = sprite.frame
		duplicated_sprite.frame_progress = sprite.frame_progress

		projected_sprites[body.name] = []

		projected_sprites[body.name].append(duplicated_sprite)
	
	portal_travellers.append(body)

	body.set_collision_mask_value(1, false)

func _on_body_exited(body: PhysicsBody2D) -> void:
	var special_sprite_group = body.get_node("SpecialSpriteGroup")
	var mask_sprite = special_sprite_group.get_node("Mask")

	if mask_sprite.visible:
		mask_sprite.visible = false

	for sprite in special_sprite_group.get_children():
		if sprite == mask_sprite:
			continue

	portal_travellers.erase(body)

	body.set_collision_mask_value(1, true)


	
