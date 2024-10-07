extends Node2D

const ItemVariant = preload("res://item_variants.gd").ItemVariant

## The number of resources remaining in the item
@export var resources_remaining: int
@export var pheromone_strength: float = 0.1
@onready var pheromone_layer = get_node("/root/Game/PheromoneLayer")

var sprite_node: Sprite2D = null
var item_variant: ItemVariant
var spawn_sound: AudioStreamPlayer

const VARIANT_CONFIGS = {
	ItemVariant.LEAF: {
		"textures": [
			preload("res://resources/sprites/leaf.png"),
			preload("res://resources/sprites/leaf2.png"),
		],
		"can_rotate": true,
		"resources": 20,
	},
	ItemVariant.MUSHROOM: {
		"textures": [
			preload("res://resources/sprites/mushroom.png"),
			preload("res://resources/sprites/mushroom2.png"),
			preload("res://resources/sprites/mushroom3.png"),
		],
		"can_rotate": false,
		"resources": 30,
	},
	ItemVariant.STICK: {
		"textures": [
			# do we want to include stick.png too?
			preload("res://resources/sprites/stick.png"),
			preload("res://resources/sprites/stick2.png"),
		],
		"can_rotate": true,
		"resources": 30,
	},
}

func _ready():
	sprite_node = get_node("Sprite2D")
	hide() # Hide initially until variant is set

# Function to set the item type
func set_variant(variant_to_use: ItemVariant):
	item_variant = variant_to_use

	var config = VARIANT_CONFIGS[variant_to_use]
	sprite_node.texture = config["textures"][randi() % config["textures"].size()]
	sprite_node.scale = Vector2(0.25, 0.25)

	resources_remaining = config["resources"]

	if config["can_rotate"]:
		sprite_node.rotate(randf_range(-45, 45)) # Random rotation

	show()


# Collision detection function
func _on_area_2d_body_entered(body: Node2D) -> void:
	if !body.is_in_group("ants"):
		return

	var did_pickup_item = body.maybe_pickup_item(item_variant)
	if did_pickup_item:
		resources_remaining -= 1
	if resources_remaining <= 0:
		queue_free() # Remove the item from the scene

func _process(delta: float) -> void:
	pheromone_layer.draw_pheromone_at_position(position, delta * pheromone_strength, true, 0.5)
