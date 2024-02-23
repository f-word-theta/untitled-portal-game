class_name Portal
extends Area2D

const VELOCITY_RETAIN_FACTOR: float = 0.97

@onready var portal_travellers: Array = []

# this is a 2d array btw
# [
#	sprite_owner_1: [...],
#	sprite_owner_2: [...],
#	...
# ]
@onready var projected_sprites: Dictionary = {}

@onready var label: Label = get_node("../DebugUI/Label")

@onready var portal_special_sprite_group: CanvasGroup = get_node("SpecialSpriteGroup")
@onready var portal_mask: Sprite2D = portal_special_sprite_group.get_node("Mask")

@export var destination_portal: Portal = null
@export var enabled: bool = true

var previous_velocity: Vector2 = Vector2()


func _physics_process(_delta: float) -> void:
	if not enabled or not destination_portal:
		return

	# iterate through all entities touching portal
	for traveller: PhysicsBody2D in portal_travellers:

		#skip if entity isnt controllable entity
		if not (traveller is RigidBody2D or traveller is CharacterBody2D):
			return

		# vector from center of portal to center of traveller
		var vector_from_portal_to_traveller: Vector2 = traveller.global_position - global_position
		var vector_from_portal_to_traveller_normalized: Vector2 = global_position.direction_to(traveller.global_position)
		
		# calc distance and teleport if player reaches center of portal
		if vector_from_portal_to_traveller_normalized.dot(global_transform.x) < 0.0:
			previous_velocity = traveller.velocity

			traveller.global_position = destination_portal.global_position + Vector2.RIGHT.rotated(destination_portal.global_rotation) * 5
			
			traveller.velocity = Vector2.RIGHT.rotated(destination_portal.global_rotation) * previous_velocity.length() * VELOCITY_RETAIN_FACTOR

		# portal visuals
		# specialspritegroup/mask is for sprite clipping
		if not (traveller.has_node("SpecialSpriteGroup")):
			return
		
		var traveller_special_sprite_group = traveller.get_node("SpecialSpriteGroup")
		var mask_sprite = traveller_special_sprite_group.get_node("Mask")

		if not mask_sprite.visible:
			mask_sprite.visible = true

		for sprite_owner in projected_sprites:
			if sprite_owner == traveller.name:
				for sprite in projected_sprites[sprite_owner]:

					#rotation done
					# flip sprite when rotation is in a certain way
					var rounded_rotation_degrees: float = round(destination_portal.global_rotation_degrees)

					if (rounded_rotation_degrees >= -180 and rounded_rotation_degrees <= -90) or (rounded_rotation_degrees <= 180 and rounded_rotation_degrees >= 90):
						sprite.flip_v = true
						sprite.flip_h = true
					else:
						sprite.flip_v = false
						sprite.flip_h = false
					
					#position done
					sprite.global_position = destination_portal.global_position - ( vector_from_portal_to_traveller.length() * Vector2.RIGHT.rotated(destination_portal.global_rotation))


		mask_sprite.global_rotation = global_rotation
		mask_sprite.global_position = global_position

		

func _on_body_entered(body: PhysicsBody2D) -> void:
	var body_special_sprite_group = body.get_node("SpecialSpriteGroup")
	var mask_sprite = body_special_sprite_group.get_node("Mask")
		
	for sprite in body_special_sprite_group.get_children():
		if sprite == mask_sprite:
			continue
		
		#for now its just sprite2d. will add support for other sprite types later
		var duplicated_sprite: Sprite2D = Sprite2D.new()
		
		destination_portal.portal_special_sprite_group.add_child(duplicated_sprite)
		destination_portal.portal_special_sprite_group.move_child(duplicated_sprite, 0)


		duplicated_sprite.texture_filter = sprite.texture_filter
		duplicated_sprite.name = sprite.name

		duplicated_sprite.texture = sprite.texture

		projected_sprites[body.name] = []

		projected_sprites[body.name].append(duplicated_sprite)
	
	portal_travellers.append(body)

	body.set_collision_mask_value(1, false)

func _on_body_exited(body: PhysicsBody2D) -> void:
	var body_special_sprite_group = body.get_node("SpecialSpriteGroup")
	var mask_sprite = body_special_sprite_group.get_node("Mask")

	if mask_sprite.visible:
		mask_sprite.visible = false

	for sprite_owner in projected_sprites:
		if sprite_owner == body.name:
			for sprite in projected_sprites[sprite_owner]:
				sprite.queue_free()

	portal_travellers.erase(body)

	body.set_collision_mask_value(1, true)


	
