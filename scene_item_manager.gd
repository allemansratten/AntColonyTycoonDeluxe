extends Node

const ItemVariant = preload("res://item_variants.gd").ItemVariant

var scene_item: PackedScene

func get_random_position() -> Vector2:
	# Get the size of the current viewport
	var viewport_size = get_viewport().size
	var random_x = randf() * viewport_size.x
	var random_y = randf() * viewport_size.y
	return Vector2(random_x, random_y)

func _ready():
	randomize()
	spawn_item(ItemVariant.LEAF, get_random_position())
	spawn_item(ItemVariant.LEAF, get_random_position())
	spawn_item(ItemVariant.LEAF, get_random_position())
	spawn_item(ItemVariant.LEAF, get_random_position())
	spawn_item(ItemVariant.MUSHROOM, get_random_position())
	spawn_item(ItemVariant.MUSHROOM, get_random_position())
	spawn_item(ItemVariant.MUSHROOM, get_random_position())


# Function to spawn an item at a given position
func spawn_item(variant: ItemVariant, position: Vector2):
	scene_item = load("res://scene_item.tscn")

	var new_item = scene_item.instantiate()
	new_item.position = position
	# Add the item to the scene first so the variants can be initialised
	add_child(new_item)
	new_item.set_variant(variant)
