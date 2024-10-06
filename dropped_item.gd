extends Node2D

const ItemVariant = preload("res://item_variants.gd").ItemVariant

@export var decay_duration_secs: float = 1.0

@onready var sprite_node: Sprite2D = get_node("Sprite2D")
@onready var collision_area: Area2D = get_node("Area2D")

var item_variant: ItemVariant

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide() # Hide initially until variant is set

func set_item_properties(variant: ItemVariant, sprite_options, decay_time_secs: float = 0) -> void:
	item_variant = variant
	global_position = sprite_options['position']
	sprite_node.texture = sprite_options['texture']
	sprite_node.scale = sprite_options['scale']
	sprite_node.rotate(randf_range(-45, 45)) # Random rotation
	show() # Show the node after setting the variant

	if decay_time_secs > 0:
		await get_tree().create_timer(decay_time_secs).timeout
		var tween = create_tween()
		tween.tween_property(sprite_node, "modulate:a", 0, decay_duration_secs)
		await get_tree().create_timer(decay_duration_secs).timeout
		queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if !body.is_in_group("ants"):
		return

	var did_pickup_item = body.maybe_pickup_item(item_variant)
	if did_pickup_item:
		queue_free() # Remove the item from the scene
