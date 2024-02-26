class_name RiftComponent
extends Node

# EXPORTS
@export var destination_rift: Rift

@export var area: Area2D
@export var special_sprite_group: CanvasGroup
@export var mask: Sprite2D

@export var enabled: bool = true

# CONSTANTS
const VELOCITY_RETAIN_FACTOR: float = 0.97
const TELEPORTATION_DISTANCE_THRESHOLD: float = 0.0
const MINIMUM_DESTINATION_DISTANCE: float = 4.0

const ENVIRONMENT_COLLISION_MASK_VALUE: int = 1

# VARIABLES
@onready var current_travellers: Array = []
@onready var projected_sprites: Dictionary = { null: [] }

var rift_to_traveller: Vector2 = Vector2()
var previous_velocity: Vector2 = Vector2()

var last_relative_rotation: float = 0.0 # will implement later: add lerping to the original sprite after it has left the portal

func handle_rift_teleportation(_delta: float) -> void:
	for traveller: PhysicsBody2D in current_travellers:
		if not (traveller is RigidBody2D or traveller is CharacterBody2D):
			return

		rift_to_traveller = traveller.global_position - area.global_position
		var rift_to_traveller_normalized: Vector2 = area.global_position.direction_to(traveller.global_position)

		if rift_to_traveller_normalized.dot(area.global_transform.x) < TELEPORTATION_DISTANCE_THRESHOLD:
			# teleport to new position plus a minimum distance
			traveller.global_position = destination_rift.global_position + Vector2.RIGHT.rotated(destination_rift.global_rotation) * MINIMUM_DESTINATION_DISTANCE
			
			# ensure velocity is transferred completely
			previous_velocity = traveller.velocity
			traveller.velocity = Vector2.RIGHT.rotated(destination_rift.global_rotation) * previous_velocity.length() * VELOCITY_RETAIN_FACTOR

func handle_rift_sprite_clipping(_delta: float) -> void:
	for traveller: PhysicsBody2D in current_travellers:
		if not (traveller is RigidBody2D or traveller is CharacterBody2D):
			return
		
		if not (traveller.has_node("SpecialSpriteGroup") and traveller.get_node("SpecialSpriteGroup") is CanvasGroup):
			return
		
		var _special_sprite_group: CanvasGroup = traveller.get_node("SpecialSpriteGroup")
		var mask_sprite: Sprite2D = _special_sprite_group.get_node("Mask")

		if not mask_sprite.visible:
			mask_sprite.visible = true

		mask_sprite.global_rotation = area.global_rotation
		mask_sprite.global_position = area.global_position

		for sprite_owner in projected_sprites:
			if sprite_owner == traveller.name:
				for projected_sprite in projected_sprites[sprite_owner]:

					for original_sprite in _special_sprite_group.get_children():
						if original_sprite == mask_sprite:
							continue
						
						if original_sprite.name == projected_sprite.name:
							projected_sprite.rotation = original_sprite.rotation - area.rotation
							last_relative_rotation = projected_sprite.rotation

					# flip sprite when rotation is in a certain way
					var rounded_rotation_degrees: float = round(destination_rift.global_rotation_degrees)
					var rift_is_flipped: bool = (rounded_rotation_degrees >= -180.0 and rounded_rotation_degrees <= -90.0) or (rounded_rotation_degrees <= 180.0 and rounded_rotation_degrees >= 90.0)

					projected_sprite.flip_v = rift_is_flipped
					projected_sprite.flip_h = rift_is_flipped

					projected_sprite.global_position = destination_rift.global_position - (rift_to_traveller.length() * Vector2.RIGHT.rotated(destination_rift.global_rotation))

func duplicate_sprite(_sprite: Node2D, _traveller: Node2D) -> void:
	if not (_sprite is Sprite2D or _sprite is AnimatedSprite2D):
		return
		
	var duplicated_sprite: Node2D
		
	if _sprite is Sprite2D:
		duplicated_sprite = Sprite2D.new()

		duplicated_sprite.texture_filter = _sprite.texture_filter
		duplicated_sprite.texture = _sprite.texture

	elif _sprite is AnimatedSprite2D:
		pass

	duplicated_sprite.name = _sprite.name
	
	destination_rift.rift_component.special_sprite_group.add_child(duplicated_sprite)
	destination_rift.rift_component.special_sprite_group.move_child(duplicated_sprite, 0)

	projected_sprites[_traveller.name] = []
	projected_sprites[_traveller.name].append(duplicated_sprite)

func _process(delta) -> void:
	if not enabled or not destination_rift:
		return
	
	handle_rift_sprite_clipping(delta)

func _physics_process(delta: float) -> void:
	if not enabled or not destination_rift:
		return

	handle_rift_teleportation(delta)

func _on_rift_entered(traveller: Node2D) -> void:
	if not (traveller.has_node("SpecialSpriteGroup") and traveller.get_node("SpecialSpriteGroup") is CanvasGroup):
		return
		
	var _special_sprite_group: CanvasGroup = traveller.get_node("SpecialSpriteGroup")
	var mask_sprite: Sprite2D = _special_sprite_group.get_node("Mask")

	for sprite in _special_sprite_group.get_children():
		if sprite == mask_sprite:
			continue

		duplicate_sprite(sprite, traveller)
	
	current_travellers.append(traveller)
	traveller.set_collision_mask_value(ENVIRONMENT_COLLISION_MASK_VALUE, false)

func _on_rift_exited(traveller: Node2D) -> void:
	if not (traveller.has_node("SpecialSpriteGroup") and traveller.get_node("SpecialSpriteGroup") is CanvasGroup):
		return
		
	var _special_sprite_group: CanvasGroup = traveller.get_node("SpecialSpriteGroup")
	var mask_sprite: Sprite2D = _special_sprite_group.get_node("Mask")

	if mask_sprite.visible:
		mask_sprite.visible = false

	for sprite_owner in projected_sprites:
		if sprite_owner == traveller.name:
			for sprite in projected_sprites[sprite_owner]:
				sprite.queue_free()

	current_travellers.erase(traveller)

	traveller.set_collision_mask_value(ENVIRONMENT_COLLISION_MASK_VALUE, true)