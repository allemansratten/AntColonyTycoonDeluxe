extends Node2D

var sprite_node: Sprite2D = null
var color_rect_node: ColorRect = null

func _ready():
	# Find the Sprite or ColorRect node
	color_rect_node = get_node("ColorRect")
	sprite_node = get_node("Sprite2D")
	print(color_rect_node)
	hide() # Hide initially until variant is set

# Function to set the item type (Leaf or Berry)
func set_variant(item_type: String):
	match item_type:
		"leaf":
			set_as_leaf()
		"berry":
			set_as_berry()
		_:
			print("Unknown variant:", item_type)
	show() # Show the node after setting the variant


# Define how to visually set up the Leaf
func set_as_leaf():
	sprite_node.texture = load("res://resources/sprites/leaf.png")
	sprite_node.scale = Vector2(0.5, 0.5) # Scale down the leaf
	color_rect_node.hide()

# Define how to visually set up the Berry
func set_as_berry():
	# sprite_node.texture = load("res://path_to_berry_texture.png")
	color_rect_node.color = Color(1, 0, 0) # Red color for berry
