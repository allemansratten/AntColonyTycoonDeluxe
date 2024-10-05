extends Node2D

const ItemVariant = preload("res://item_variants.gd").ItemVariant

## The number of resources remaining in the item
@export var resources_remaining: int

var sprite_node: Sprite2D = null
var pheromone_emitter: Node = null
var item_variant: ItemVariant

func _ready():
	sprite_node = get_node("Sprite2D")
	hide() # Hide initially until variant is set

# Function to set the item type
func set_variant(variant_to_use: ItemVariant):
	item_variant = variant_to_use
	match variant_to_use:
		ItemVariant.LEAF:
			set_as_leaf()
		ItemVariant.MUSHROOM:
			set_as_mushroom()
		_:
			print("Unknown variant:", variant_to_use)
	show() # Show the node after setting the variant


# Define how to visually set up the Leaf
func set_as_leaf():
	sprite_node.texture = load("res://resources/sprites/leaf.png")
	sprite_node.scale = Vector2(0.5, 0.5) # Scale down the leaf
	sprite_node.rotate(randf_range(-45, 45)) # Random rotation
	resources_remaining = 3
	create_pheromone_emitter()
	

# Define how to visually set up the Berry
func set_as_mushroom():
	sprite_node.texture = load("res://resources/sprites/mushroom.png")
	sprite_node.scale = Vector2(0.5, 0.5) # Scale down the leaf
	resources_remaining = 5
	create_pheromone_emitter()
	

# Collision detection function
func _on_area_2d_body_entered(ant_body: Node2D) -> void:
	var did_pickup_item = ant_body.maybe_pickup_item(item_variant, sprite_node.texture)
	if did_pickup_item:
		resources_remaining -= 1
	if resources_remaining <= 0:
		queue_free() # Remove the item from the scene

# Function to create and attach a pheromone emitter
func create_pheromone_emitter():
	# Preload the PheromoneEmitter scene (make sure it's correctly referenced)
	var emitter_scene: PackedScene = preload("res://pheromone_emitter.tscn")

	# Instance the PheromoneEmitter
	pheromone_emitter = emitter_scene.instantiate()

	# Set the emitter's initial position to match the leaf's position
	pheromone_emitter.position = self.position

	add_child(pheromone_emitter)
	pheromone_emitter.start_emission(self.position)
