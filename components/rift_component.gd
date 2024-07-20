class_name RiftComponent
extends Node

# EXPORTS
@export var destination_rift: Rift

@export var area: Area2D
@export var funneling_area: Area2D
@export var special_sprite_group: CanvasGroup

@export var enabled: bool = true

# CONSTANTS
const VELOCITY_RETAIN_FACTOR: float = 0.97
const TELEPORTATION_DISTANCE_THRESHOLD: float = 0.0
const MINIMUM_DESTINATION_DISTANCE: float = 2.0

const ENVIRONMENT_COLLISION_MASK_VALUE: int = 1

# VARIABLES
@onready var current_travellers: Array = []
@onready var bodies_in_funneling_area: Array = []
@onready var projected_sprites: Dictionary = { null: [] }

var body_entered_funneling_area: bool = false

var rift_to_traveller: Vector2 = Vector2()
var previous_velocity: Vector2 = Vector2()

var last_relative_rotation: float = 0.0 # will implement later: add lerping to the original sprite after it has left the portal

func handle_funneling(delta: float) -> void:
	if area.global_rotation_degrees == 0 or area.global_rotation_degrees == -180:
		return

	for body in bodies_in_funneling_area:
		if body.is_on_floor() == true:
			continue
		
		if body.velocity.length() <= 100.0:
			continue
		
		body.global_position = body.global_position.lerp(Vector2(funneling_area.global_position.x, body.global_position.y), 30.0 * delta)

func handle_teleportation(_delta: float) -> void:
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

func handle_sprite_clipping(_delta: float) -> void:
	for traveller: PhysicsBody2D in current_travellers:
		if not (traveller is RigidBody2D or traveller is CharacterBody2D):
			return
		
		if not (traveller.has_node("SpecialSpriteGroup") and traveller.get_node("SpecialSpriteGroup") is CanvasGroup):
			return
		
		var _special_sprite_group: CanvasGroup = traveller.get_node("SpecialSpriteGroup")
		var mask_sprite: Sprite2D = _special_sprite_group.get_node("Mask")

		mask_sprite.global_rotation = area.global_rotation
		mask_sprite.global_position = area.global_position

		if not mask_sprite.visible:
			mask_sprite.visible = true

		for sprite_owner in projected_sprites:
			if sprite_owner == traveller.name:
				for projected_sprite in projected_sprites[sprite_owner]:
					var rounded_rotation_degrees: float = round(destination_rift.global_rotation_degrees)
					var rift_is_flipped: bool = (rounded_rotation_degrees >= -180.0 and rounded_rotation_degrees <= -90.0) or (rounded_rotation_degrees <= 180.0 and rounded_rotation_degrees >= 90.0)

					for original_sprite in _special_sprite_group.get_children():
						if original_sprite == mask_sprite:
							continue
						
						if original_sprite.name == projected_sprite.name:
							#last_relative_rotation = projected_sprite.rotation
							if rift_is_flipped:
								projected_sprite.global_rotation = original_sprite.global_rotation - area.global_rotation - deg_to_rad(180)
							else:
								projected_sprite.global_rotation = original_sprite.global_rotation - area.global_rotation + deg_to_rad(180)

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
	
	handle_sprite_clipping(delta)

func _physics_process(delta: float) -> void:
	if not enabled or not destination_rift:
		return

	handle_teleportation(delta)
	handle_funneling(delta)

func _on_rift_entered(traveller: Node2D) -> void:
	traveller.set_collision_mask_value(ENVIRONMENT_COLLISION_MASK_VALUE, false)

	if not (traveller.has_node("SpecialSpriteGroup") and traveller.get_node("SpecialSpriteGroup") is CanvasGroup):
		return

	if destination_rift == null:
		return
		
	var _special_sprite_group: CanvasGroup = traveller.get_node("SpecialSpriteGroup")
	var mask_sprite: Sprite2D = _special_sprite_group.get_node("Mask")

	for sprite in _special_sprite_group.get_children():
		if sprite == mask_sprite:
			continue

		duplicate_sprite(sprite, traveller)
	
	if bodies_in_funneling_area.has(traveller):
		bodies_in_funneling_area.erase(traveller)

	if not current_travellers.has(traveller):
		current_travellers.append(traveller)

func _on_rift_exited(traveller: Node2D) -> void:
	traveller.set_collision_mask_value(ENVIRONMENT_COLLISION_MASK_VALUE, true)
	
	if not (traveller.has_node("SpecialSpriteGroup") and traveller.get_node("SpecialSpriteGroup") is CanvasGroup):
		return

	if destination_rift == null:
		return
		
	var _special_sprite_group: CanvasGroup = traveller.get_node("SpecialSpriteGroup")
	var mask_sprite: Sprite2D = _special_sprite_group.get_node("Mask")

	if mask_sprite.visible:
		mask_sprite.visible = false

	for sprite_owner in projected_sprites:
		if sprite_owner == traveller.name:
			for projected_sprite in projected_sprites[sprite_owner]:
				projected_sprite.queue_free()

	if current_travellers.has(traveller):
		current_travellers.erase(traveller)

func _on_funneling_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and (not bodies_in_funneling_area.has(body)):
		bodies_in_funneling_area.append(body as CharacterBody2D)

func _on_funneling_area_body_exited(body: Node2D) -> void:
	if bodies_in_funneling_area.has(body):
		bodies_in_funneling_area.erase(body)