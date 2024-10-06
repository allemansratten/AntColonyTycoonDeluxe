extends Control

@export var pheromone_available: float = 100.0
@export var depletion_speed: float = 3.0
@export var regeneration_speed: float = 0.5
@onready var progress_bar = $ProgressBar
@onready var game = get_node("/root/Game")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var t = progress_bar.value / progress_bar.max_value
	var color = lerp(Color.GRAY, Color.GREEN, t)
	progress_bar.modulate = color
	progress_bar.value = pheromone_available

	pheromone_available = min(100.0, pheromone_available + delta * regeneration_speed)

	if not game.is_drawing:
		position = Vector2.ZERO

func deplete(amount: float) -> void:
	# We want to allow negative values here because we don't check the amount before
	# allowing a depletion, so if we clamp it, we're giving the user free pheromones.
	pheromone_available -= amount * depletion_speed

func add(amount: float) -> void:
	pheromone_available = min(100.0, pheromone_available + amount)

# TODO(vv): Draw circular progress bar instead of moving the rectangluar one
# func _draw() -> void:
# 	draw_circle(Vector2(42.479, 65.4825), 9.3905, Color.WHITE)

func _input(event: InputEvent) -> void:
	if game.is_drawing:
		if event is InputEventMouseMotion:
			position = event.position
	else:
		position = Vector2.ZERO
