extends Node

const ItemVariant = preload("res://item_variants.gd").ItemVariant

@export var min_distance_from_anthill = 100

@onready var anthill = get_node("/root/Game/Anthill")
var scene_item: PackedScene

func get_random_position() -> Vector2:
	# Get the viewport size in pixels
	var viewport_size: Vector2 = get_viewport().size

	# Generate a random position within the viewport (screen space)
	var random_screen_x: float = randf_range(0, viewport_size.x)
	var random_screen_y: float = randf_range(0, viewport_size.y)
	var random_screen_position: Vector2 = Vector2(random_screen_x, random_screen_y)

	# Convert the random screen position to world coordinates using the canvas transform
	var world_position: Vector2 = get_viewport().canvas_transform.affine_inverse() * random_screen_position

	return world_position

func get_random_valid_position() -> Vector2:
	while true:
		var position = get_random_position()
		if position.distance_to(anthill.position) > min_distance_from_anthill:
			return position
	
	# raise an error if no valid position is found
	assert(false, "No valid position found")
	return Vector2.ZERO # unreachable, but the linter is dumb

func _ready():
	randomize()
	spawn_item(ItemVariant.LEAF, get_random_valid_position())
	spawn_item(ItemVariant.MUSHROOM, get_random_valid_position())


# Function to spawn an item at a given position
func spawn_item(variant: ItemVariant, position: Vector2):
	scene_item = load("res://scene_item.tscn")

	var new_item = scene_item.instantiate()
	new_item.position = position
	new_item.scale = Vector2.ZERO

	# Add the item to the scene first so the variants can be initialised
	add_child(new_item)
	new_item.set_variant(variant)

	var tween = create_tween()
	(tween
	.tween_property(new_item, "scale", Vector2.ONE, 1.0)
	.set_ease(Tween.EASE_OUT)
	.set_trans(Tween.TRANS_SPRING))


func get_random_variant() -> ItemVariant:
	var variants = [ItemVariant.LEAF, ItemVariant.MUSHROOM, ItemVariant.STICK]
	var random_variant = randi() % len(variants)
	return variants[random_variant]

func _on_item_spawn_timer_timeout() -> void:
	spawn_item(get_random_variant(), get_random_valid_position())
