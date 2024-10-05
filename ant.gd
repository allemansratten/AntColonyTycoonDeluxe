extends CharacterBody2D

@export var min_speed: float = 500.0
@export var max_speed: float = 800.0
@export var min_move_distance: float = 150.0
@export var max_move_distance: float = 200.0
@export var min_wait_time: float = 0.15
@export var max_wait_time: float = 0.3
@onready var _animated_sprite = $AnimatedSprite2D

# positive = ants will tend to select directions similar to the ones they have
# 0 = they don't care
# negative = bigger turns are better
const ANGLE_CONSISTENCY_REWARD: float = 0.5
# must be strictly >0.
# close to 0 = always select the angle that maximizes the score
# infinite = select completely at random
const ANGLE_SAMPLING_TEMPERATURE: float = 0.2

var target_position: Vector2
var is_moving: bool = false
var rotation_speed: float = 15.0 # Speed of rotation towards target

@export var pheromone_layer: ColorRect

func _ready():
	#position = Vector2(200, 200)
	randomize()

	# start after a random delay to desync them at the beginning
	await get_tree().create_timer(randf_range(0.0, max_wait_time)).timeout
	start_new_movement()


func _physics_process(_delta):
	if is_moving:
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)

		if distance > 5: # If not close enough to target
			velocity = direction * randf_range(min_speed, max_speed)
			move_and_slide()
			_animated_sprite.play("default")
			# Smooth rotation towards the target
			var target_angle = direction.angle()
			rotation = lerp_angle(rotation, target_angle, rotation_speed * _delta)
		else:
			is_moving = false
			_animated_sprite.stop()
			start_waiting()


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

		score -= angular_difference * ANGLE_CONSISTENCY_REWARD

		scores.append(score)

	scores = scores.map(func(x): return x / ANGLE_SAMPLING_TEMPERATURE)
	scores = softmax(scores)

	var selected = sample_from_scores(scores)
	var angle = angles[selected]

	target_position = global_position + Vector2(cos(angle), sin(angle)) * random_distance
	is_moving = true

func start_waiting():
	var wait_time = randf_range(min_wait_time, max_wait_time)
	await get_tree().create_timer(wait_time).timeout
	start_new_movement()
