extends Node2D

var sprite_node: Sprite2D = null

func _ready():
	sprite_node = get_node("Sprite2D")
	hide() # Hide initially until variant is set

# Function to set the item type
func set_variant(item_type: String):
	match item_type:
		"leaf":
			set_as_leaf()
		"mushroom":
			set_as_mushroom()
		_:
			print("Unknown variant:", item_type)
	show() # Show the node after setting the variant


# Define how to visually set up the Leaf
func set_as_leaf():
	sprite_node.texture = load("res://resources/sprites/leaf.png")
	sprite_node.scale = Vector2(0.5, 0.5) # Scale down the leaf
	sprite_node.rotate(randf_range(-45, 45)) # Random rotation

# Define how to visually set up the Berry
func set_as_mushroom():
	sprite_node.texture = load("res://resources/sprites/mushroom.png")
	sprite_node.scale = Vector2(0.5, 0.5) # Scale down the leaf
