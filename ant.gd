extends CharacterBody2D

@export var min_speed: float = 500.0
@export var max_speed: float = 800.0
@export var min_move_distance: float = 250.0
@export var max_move_distance: float = 300.0
@export var min_wait_time: float = 0.3
@export var max_wait_time: float = 0.6

var target_position: Vector2
var is_moving: bool = false

func _ready():
	#position = Vector2(200, 200)
	randomize()
	start_new_movement()

func _physics_process(_delta):
	if is_moving:
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)
		
		if distance > 5: # If not close enough to target
			velocity = direction * randf_range(min_speed, max_speed)
			move_and_slide()
		else:
			is_moving = false
			start_waiting()

func start_new_movement():
	var random_angle = randf() * 2 * PI
	var random_distance = randf_range(min_move_distance, max_move_distance)
	target_position = global_position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
	is_moving = true

func start_waiting():
	var wait_time = randf_range(min_wait_time, max_wait_time)
	await get_tree().create_timer(wait_time).timeout
	start_new_movement()
