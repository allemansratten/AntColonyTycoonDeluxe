extends Sprite2D

const ItemVariant = preload("res://item_variants.gd").ItemVariant

@export var variant: ItemVariant = ItemVariant.NONE
var base_scale

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	base_scale = Vector2(scale.x, scale.y) # copy (not sure if needed)
	scale = Vector2.ZERO


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_variant(new_variant: ItemVariant) -> void:
	variant = new_variant

	scale = Vector2.ZERO
	var tween = create_tween()

	if new_variant != ItemVariant.NONE:
		tween.tween_property(
			self,
			"scale",
			base_scale,
			0.3
		)
	else:
		tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
		tween.tween_callback(reset_carried_item)


func reset_carried_item():
	texture = null
	scale = Vector2(1.0, 1.0)
