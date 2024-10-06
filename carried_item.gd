extends Sprite2D

const ItemVariant = preload("res://item_variants.gd").ItemVariant

@export var variant: ItemVariant = ItemVariant.NONE
var base_scale

const VARIANT_TO_TEXTURES = {
	ItemVariant.LEAF: [
		preload("res://resources/sprites/leaf_piece1.png"),
		preload("res://resources/sprites/leaf_piece2.png"),
		preload("res://resources/sprites/leaf_piece3.png"),
	],
	ItemVariant.MUSHROOM: [
		preload("res://resources/sprites/mushroom_piece1.png"),
		preload("res://resources/sprites/mushroom_piece2.png"),
		preload("res://resources/sprites/mushroom_piece3.png"),
	],
	ItemVariant.STICK: [
		preload("res://resources/sprites/stick_piece1.png"),
		preload("res://resources/sprites/stick_piece2.png"),
		preload("res://resources/sprites/stick_piece3.png"),
	],
	ItemVariant.ANT: [
		preload("res://resources/sprites/ant_dead_carried.png"),
	]
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	base_scale = Vector2(scale.x, scale.y) # copy (not sure if needed)
	scale = Vector2.ZERO


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func set_variant(new_variant: ItemVariant) -> void:
	variant = new_variant

	# for None, just keep the texture and scale to 0.
	if new_variant != ItemVariant.NONE:
		var textures = VARIANT_TO_TEXTURES[new_variant]
		texture = textures[randi() % textures.size()]

	var tween = create_tween()

	if new_variant != ItemVariant.NONE:
		scale = Vector2.ZERO
		tween.tween_property(
			self,
			"scale",
			base_scale,
			1.0,
		)
	else:
		tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
		tween.tween_callback(reset_carried_item)


func reset_carried_item():
	texture = null
	scale = Vector2.ONE
