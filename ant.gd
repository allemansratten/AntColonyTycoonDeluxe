extends CharacterBody2D

const ItemVariant = preload("res://item_variants.gd").ItemVariant
enum AntType {HARVESTER, BUILDER, WARRIOR, FARMER, EXPLORER}

@export var ant_type: AntType = AntType.HARVESTER
@export var min_speed: float = 500.0
@export var max_speed: float = 800.0

@export var inventory_num_items_carried: int = 0
@export var inventory_max_items: int = 1
@export var inventory_item_variant: ItemVariant = ItemVariant.NONE

var carried_item_sprite: Sprite2D
@export var min_move_distance: float = 150.0
@export var max_move_distance: float = 200.0
@export var min_wait_time: float = 0.15
@export var max_wait_time: float = 0.3
@export var wait_probability: float = 0.03
@onready var _animated_sprite = $AnimatedSprite2D

@export var carried_item_scale = 0.25
@export var pheromone_creation_when_carrying: float = 0.1

# positive = ants will tend to select directions similar to the ones they have
# 0 = they don't care
# negative = bigger turns are better
@export var angle_consistency_reward: float = 0.4
# must be strictly >0.
# close to 0 = always select the angle that maximizes the score
# infinite = select completely at random
@export var angle_sampling_temperature: float = 0.15

var target_position: Vector2
var is_moving: bool = false
var rotation_speed: float = 15.0 # Speed of rotation towards target

@export var pheromone_layer: ColorRect

func _ready():
	randomize()
	rotation = randf() * 2 * PI
	set_ant_type_properties(ant_type)
	add_to_group("ants")

	carried_item_sprite = Sprite2D.new()
	carried_item_sprite.position = Vector2(0, -20)
	carried_item_sprite.scale = Vector2(carried_item_scale, carried_item_scale)
	add_child(carried_item_sprite)
	
	# Start after a random delay to desync them at the beginning
	await get_tree().create_timer(randf_range(0.0, max_wait_time)).timeout
	start_new_movement()

# Adjust properties based on the ant type
func set_ant_type_properties(ant_type: AntType):
	match ant_type:
		AntType.HARVESTER:
			min_speed = 150.0
			max_speed = 300.0
			min_wait_time = 0.5
			max_wait_time = 0.7
			_animated_sprite.animation = "harvester"
		#Other Types have no animation yet
		AntType.BUILDER:
			_animated_sprite.animation = "builder"
		AntType.WARRIOR:
			_animated_sprite.animation = "warrior"
		AntType.FARMER:
			_animated_sprite.animation = "farmer"
		AntType.EXPLORER:
			_animated_sprite.animation = "explorer"

func _physics_process(_delta: float):
	if is_moving:
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)

		if distance > 5: # If not close enough to target
			velocity = direction * randf_range(min_speed, max_speed)
			move_and_slide()
			_animated_sprite.play()
			# Smooth rotation towards the target
			var target_angle = direction.angle()
			rotation = lerp_angle(rotation, target_angle, rotation_speed * _delta)
		else:
			is_moving = false
			_animated_sprite.stop()
			start_waiting()
	
	if inventory_num_items_carried > 0:
		pheromone_layer.draw_pheromone_at_position(position, _delta * pheromone_creation_when_carrying, true)

# This method is intended to be overridden by subclasses for unique behaviors
func perform_special_action():
	pass # Each subclass will implement its own action

func softmax(x: Array) -> Array:
	var max_value = x.max() # Find the maximum value in the input array
	var exp_values = []
	var sum_exp = 0.0

	# Calculate shifted exponentials and sum
	for value in x:
		var exp_value = exp(value - max_value)
		exp_values.append(exp_value)
		sum_exp += exp_value
		
	# Normalize
	var softmax_values = []
	for exp_value in exp_values:
		softmax_values.append(exp_value / sum_exp)

	return softmax_values


func sample_from_scores(scores: Array) -> int:
	var total_score = scores.reduce(func(acc, x): return acc + x)
	var random_value = randf() * total_score

	var sum = 0.0
	for i in range(scores.size()):
		sum += scores[i]
		if random_value < sum:
			return i

	return scores.size() - 1


func start_new_movement():
	var random_distance = randf_range(min_move_distance, max_move_distance)

	var angles = range(0, 360, 10).map(func(x): return deg_to_rad(x))
	
	var scores = []
	for angle in angles:
		var direction = Vector2(cos(angle), sin(angle))
		var target = global_position + direction * random_distance
		var score = pheromone_layer.get_value_at(target.x, target.y)

		# Scaled between 0 and 1
		var angular_difference = abs(angle_difference(angle, rotation)) / PI

		score -= angular_difference * angle_consistency_reward

		scores.append(score)

	scores = scores.map(func(x): return x / angle_sampling_temperature)
	scores = softmax(scores)

	var selected = sample_from_scores(scores)
	var angle = angles[selected]

	target_position = global_position + Vector2(cos(angle), sin(angle)) * random_distance
	is_moving = true

func start_waiting():
	if randf() < wait_probability:
		var wait_time = randf_range(min_wait_time, max_wait_time)
		await get_tree().create_timer(wait_time).timeout
	start_new_movement()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func maybe_pickup_item(picked_item_variant: ItemVariant, picked_item_texture: Texture) -> bool:
	# If the ant is carrying an item, it can only pick up the same type
	if inventory_item_variant != ItemVariant.NONE && inventory_item_variant != picked_item_variant:
		return false
	# If the ant is not carrying an item, it can pick up any type
	if inventory_num_items_carried >= inventory_max_items:
		return false

	inventory_num_items_carried += 1
	carried_item_sprite.texture = picked_item_texture
	inventory_item_variant = picked_item_variant

	carried_item_sprite.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(carried_item_sprite, "scale", Vector2(carried_item_scale, carried_item_scale), 0.3)

	return true

func maybe_deposit_item() -> bool:
	if inventory_num_items_carried == 0:
		return false

	inventory_num_items_carried -= 1
	if inventory_num_items_carried == 0:
		inventory_item_variant = ItemVariant.NONE
		var tween = create_tween()
		tween.tween_property(carried_item_sprite, "scale", Vector2.ZERO, 0.3)
		tween.tween_callback(reset_carried_item_sprite)

	return true

func reset_carried_item_sprite():
	carried_item_sprite.texture = null
	carried_item_sprite.scale = Vector2(carried_item_scale, carried_item_scale)
