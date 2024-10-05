extends CharacterBody2D

const ItemVariant = preload("res://item_variants.gd").ItemVariant
enum AntType { HARVESTER, BUILDER, WARRIOR, FARMER, EXPLORER }

@export var ant_type: AntType = AntType.HARVESTER
@export var min_speed: float = 500.0
@export var max_speed: float = 800.0
@export var min_move_distance: float = 250.0
@export var max_move_distance: float = 300.0
@export var min_wait_time: float = 0.3
@export var max_wait_time: float = 0.6

@export var inventory_num_items_carried: int = 0
@export var inventory_max_items: int = 1
@export var inventory_item_variant: ItemVariant

@onready var _animated_sprite = $AnimatedSprite2D

var carried_item_sprite: Sprite2D
var target_position: Vector2
var is_moving: bool = false
var rotation_speed: float = 15.0  # Speed of rotation towards target

func _ready():
	randomize()
	set_ant_type_properties(ant_type)

	carried_item_sprite = Sprite2D.new()
	carried_item_sprite.position = Vector2(0, -20)
	
	# Start after a random delay to desync them at the beginning
	await get_tree().create_timer(randf_range(0.0, max_wait_time)).timeout
	start_new_movement()

# Adjust properties based on the ant type
func set_ant_type_properties(ant_type: AntType):
	match ant_type:
		AntType.HARVESTER:
			min_speed = 400.0
			max_speed = 600.0
			min_wait_time = 0.5
			max_wait_time = 0.7
			_animated_sprite.animation = "harvester"
		#Other Types have no animation yet
		AntType.BUILDER:
			min_speed = 300.0
			max_speed = 500.0
			min_wait_time = 0.7
			max_wait_time = 1.0
			_animated_sprite.animation = "builder"
		AntType.WARRIOR:
			min_speed = 600.0
			max_speed = 900.0
			min_wait_time = 0.2
			max_wait_time = 0.5
			_animated_sprite.animation = "warrior"
		AntType.FARMER:
			min_speed = 350.0
			max_speed = 550.0
			min_wait_time = 0.6
			max_wait_time = 0.8
			_animated_sprite.animation = "farmer"
		AntType.EXPLORER:
			min_speed = 500.0
			max_speed = 800.0
			min_wait_time = 0.3
			max_wait_time = 0.6
			_animated_sprite.animation = "explorer"

func _physics_process(_delta):
	if is_moving:
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)

		if distance > 5:  # If not close enough to target
			velocity = direction * randf_range(min_speed, max_speed)
			move_and_slide()
			_animated_sprite.play()
			
			# Smooth rotation towards the target
			var target_angle = direction.angle() + PI / 2
			rotation = lerp_angle(rotation, target_angle, rotation_speed * _delta)
		else:
			is_moving = false
			_animated_sprite.stop()
			perform_special_action()
			start_waiting()

# This method is intended to be overridden by subclasses for unique behaviors
func perform_special_action():
	pass  # Each subclass will implement its own action

func start_new_movement():
	var random_angle = randf() * 2 * PI
	var random_distance = randf_range(min_move_distance, max_move_distance)
	target_position = global_position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
	is_moving = true

func start_waiting():
	var wait_time = randf_range(min_wait_time, max_wait_time)
	await get_tree().create_timer(wait_time).timeout
	start_new_movement()


func maybe_pickup_item(picked_item_variant: ItemVariant, picked_item_texture: Texture) -> bool:
	# If the ant is carrying an item, it can only pick up the same type
	if inventory_item_variant != null && inventory_item_variant != picked_item_variant:
		return false
	# If the ant is not carrying an item, it can pick up any type
	if inventory_num_items_carried >= inventory_max_items:
		return false

	inventory_num_items_carried += 1
	carried_item_sprite.texture = picked_item_texture
	inventory_item_variant = picked_item_variant
	print("Picking up item variant: ", picked_item_variant)
	return true
