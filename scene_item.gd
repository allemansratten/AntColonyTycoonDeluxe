extends Node2D

# var sprite_node: Sprite2D = null
var color_rect_node: ColorRect = null

func _ready():
	# Find the Sprite or ColorRect node
	color_rect_node = get_node("ColorRect")
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
	# sprite_node.texture = load("res://path_to_leaf_texture.png")
	color_rect_node.color = Color(0, 1, 0) # Green color for leaf

# Define how to visually set up the Berry
func set_as_berry():
	# sprite_node.texture = load("res://path_to_berry_texture.png")
	color_rect_node.color = Color(1, 0, 0) # Red color for berry
