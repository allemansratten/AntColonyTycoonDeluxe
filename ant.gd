extends CharacterBody2D

const ItemVariant = preload("res://item_variants.gd").ItemVariant
const FoodItems = preload("res://item_variants.gd").foodItemVariants
enum AntType {HARVESTER, BUILDER, WARRIOR, FARMER, EXPLORER}

@export var ant_type: AntType = AntType.HARVESTER
@export var min_speed: float = 125.0
@export var max_speed: float = 200.0

@export var min_move_distance: float = 35.
@export var max_move_distance: float = 50.
@export var min_wait_time: float = 0.15
@export var max_wait_time: float = 0.3
@export var wait_probability: float = 0.03
@export var item_pickup_duration_secs: float = 1.5

@export var lifespan_min_secs: float = 40.0
@export var lifespan_max_secs: float = 60.0

@onready var _animated_sprite = $AnimatedSprite2D
@onready var lifespan_timer = get_node("LifespanTimer")
@onready var carried_item = get_node("CarriedItem")
@onready var dropped_items_layer = get_node("/root/Game/DroppedItemsLayer")
@onready var dropped_item_scene = load("res://dropped_item.tscn")

@export var pheromone_creation_when_carrying: float = 0.05
@export var pheromone_strength_on_death: float = 0.2

## positive = ants will tend to select directions similar to the ones they have
## 0 = they don't care
## negative = bigger turns are better
@export var angle_consistency_reward: float = 0.4
## must be strictly >0.
## close to 0 = always select the angle that maximizes the score
## infinite = select completely at random
@export var angle_sampling_temperature: float = 0.15

var target_position: Vector2
var is_moving: bool = false
var rotation_speed: float = 15.0 # Speed of rotation towards target
var food_pickup_sound: AudioStreamPlayer
var food_deposit_sound: AudioStreamPlayer
var stick_pickup_sound: AudioStreamPlayer
var stick_deposit_sound: AudioStreamPlayer
var death_sound: AudioStreamPlayer

@onready var pheromone_layer = get_node("/root/Game/PheromoneLayer")

func _ready():
	randomize()
	rotation = randf() * 2 * PI
	set_ant_type_properties(ant_type)
	add_to_group("ants")
	lifespan_timer.wait_time = randf_range(lifespan_min_secs, lifespan_max_secs)
	lifespan_timer.start()

	food_pickup_sound = $FoodPickupSound
	food_deposit_sound = $FoodDepositSound
	stick_pickup_sound = $StickPickupSound
	stick_deposit_sound = $StickDepositSound
	death_sound = $DeathSound

	# Start after a random delay to desync them at the beginning
	await get_tree().create_timer(randf_range(0.0, max_wait_time)).timeout
	start_new_movement()

## Adjust properties based on the ant type
func set_ant_type_properties(ant_type_to_Set: AntType):
	match ant_type_to_Set:
		AntType.HARVESTER:
			min_speed = 35.0
			max_speed = 75.0
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
	
	if carried_item.variant != ItemVariant.NONE:
		pheromone_layer.draw_pheromone_at_position(position, _delta * pheromone_creation_when_carrying, true)

## This method is intended to be overridden by subclasses for unique behaviors
func perform_special_action():
	pass # Each subclass will implement its own action

## Normalise probability distribution
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


var potential_movement_angles = range(0, 360, 10).map(func(x): return deg_to_rad(x))

func start_new_movement():
	var random_distance = randf_range(min_move_distance, max_move_distance)

	var scores = []
	for angle in potential_movement_angles:
		var direction = Vector2(cos(angle), sin(angle))
		var target = global_position + direction * random_distance
		# Scaled between 0 and 1
		var angular_difference = abs(angle_difference(angle, rotation)) / PI
		var score = pheromone_layer.get_value_at(target.x, target.y) - (angular_difference * angle_consistency_reward)
		if !is_on_screen(target):
			score = -100
		scores.append(score)

	scores = scores.map(func(x): return x / angle_sampling_temperature)
	scores = softmax(scores)

	var selected = sample_from_scores(scores)
	var angle = potential_movement_angles[selected]

	target_position = global_position + Vector2(cos(angle), sin(angle)) * random_distance
	is_moving = true


func start_waiting(time_to_wait: float = 0.0):
	if time_to_wait > 0 || randf() < wait_probability:
		# Use the provided time if its provided
		var wait_time: float = time_to_wait if time_to_wait > 0 else randf_range(min_wait_time, max_wait_time)
		await get_tree().create_timer(wait_time).timeout
	start_new_movement()

func to_world_position(screen_position: Vector2) -> Vector2:
	return get_viewport().canvas_transform.affine_inverse() * screen_position

func is_on_screen(point: Vector2) -> bool:
	var screen_rect: Rect2 = get_viewport().get_visible_rect()
	var top_left: Vector2 = to_world_position(screen_rect.position)
	var bottom_right: Vector2 = to_world_position(screen_rect.position + screen_rect.size)
	var world_rect: Rect2 = Rect2(top_left, bottom_right - top_left)

	return world_rect.has_point(point)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


## When the ants are picking up an item, wait for a while and then turn around
func handle_on_pickup_movement():
	_animated_sprite.speed_scale = 0.0 # Stop the walking animation
	is_moving = false

	var original_position = global_position
	var num_tween_loops = 4
	var tween_duration = item_pickup_duration_secs / (num_tween_loops * 2)
	var tween_target_position = target_position.normalized()

	var tween = get_tree().create_tween()
	for i in range(num_tween_loops):
		tween.tween_property(self, "global_position", original_position + tween_target_position, tween_duration)
		tween.tween_property(self, "global_position", original_position, tween_duration)

	# Turn the ant around
	target_position = global_position + (global_position - target_position)
	await get_tree().create_timer(item_pickup_duration_secs).timeout

	_animated_sprite.speed_scale = 1.0 # Resume the walking animation
	is_moving = true


func maybe_pickup_item(picked_item_variant: ItemVariant) -> bool:
	# If the ant is carrying an item, it can only pick up the same type
	if carried_item.variant != ItemVariant.NONE:
		return false

	handle_on_pickup_movement()
	carried_item.set_variant(picked_item_variant)

	play_pickup_sound(picked_item_variant)

	return true


func maybe_deposit_item() -> Dictionary:
	if carried_item.variant == ItemVariant.NONE:
		return {"success": false, "deposited_item_variant": ItemVariant.NONE}

	# Store the current item variant before resetting it
	var deposited_item_variant = carried_item.variant

	carried_item.set_variant(ItemVariant.NONE)

	play_deposit_sound(deposited_item_variant)
	
	# Return a dictionary containing success and deposited item variant
	return {"success": true, "deposited_item_variant": deposited_item_variant}


func drop_carried_item():
	if carried_item.variant == ItemVariant.NONE:
		return false

	var dropped_item = dropped_item_scene.instantiate()
	dropped_items_layer.add_child(dropped_item)
	dropped_item.set_item_properties(
		carried_item.variant, 
		{
			'texture': carried_item.texture,
			'scale': carried_item.scale,
			'position': global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		},
		60.0, # decay time
	)

	carried_item.set_variant(ItemVariant.NONE)

	return true


func die():
	pheromone_layer.draw_pheromone_at_position(position, pheromone_strength_on_death, true, 1.0)
	drop_carried_item()
	death_sound.play()
	await get_tree().create_timer(death_sound.stream.get_length()).timeout
	print("Ant is dying") # Debugging print statement
	var dropped_item = dropped_item_scene.instantiate()
	dropped_items_layer.add_child(dropped_item)
	dropped_item.set_item_properties(
		ItemVariant.ANT,
		{
			'texture': load("res://resources/sprites/ant_dead.png"),
			'scale': Vector2(0.1, 0.1),
			'position': global_position
		},
		30.0 # decay time
	)

	queue_free() # Free the node after the sound finishes playing


func _on_lifespan_timer_timeout() -> void:
	die()

func play_pickup_sound(inventory_item_variant: ItemVariant) -> void:
	# Check if the item is in the food item group
	if inventory_item_variant in FoodItems:
		food_pickup_sound.play() # Play food sound for food items
	elif inventory_item_variant == ItemVariant.STICK:
		stick_pickup_sound.play() # Play stick sound for non-food items
	else:
		print("No sound assigned for this item variant.")

func play_deposit_sound(inventory_item_variant: ItemVariant) -> void:
	# Check if the item is in the food item group
	if inventory_item_variant in FoodItems:
		food_deposit_sound.play() # Play food sound for food items
	elif inventory_item_variant == ItemVariant.STICK:
		stick_deposit_sound.play() # Play stick sound for non-food items
	else:
		print("No sound assigned for this item variant.")
