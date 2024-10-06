extends Node2D

const ItemVariant = preload("res://item_variants.gd").ItemVariant

@onready var sprite_node: Sprite2D = get_node("Sprite2D")
@onready var collision_area: Area2D = get_node("Area2D")

var item_variant: ItemVariant

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide() # Hide initially until variant is set

func set_item_properties(variant: ItemVariant, sprite_options) -> void:
	item_variant = variant
	global_position = sprite_options['position']
	sprite_node.texture = sprite_options['texture']
	sprite_node.scale = sprite_options['scale']
	sprite_node.rotate(randf_range(-45, 45)) # Random rotation
	show() # Show the node after setting the variant


func _on_area_2d_body_entered(body: Node2D) -> void:
	if !body.is_in_group("ants"):
		return

	var did_pickup_item = body.maybe_pickup_item(item_variant, sprite_node.texture)
	if did_pickup_item:
		queue_free() # Remove the item from the scene
