extends Control

@export var pheromone_available: float = 100.0
@export var depletion_speed: float = 5.0
@export var regeneration_speed: float = 5.0
@onready var progress_bar = $ProgressBar


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var t = progress_bar.value / progress_bar.max_value
	var color = lerp(Color.GRAY, Color.GREEN, t)
	progress_bar.modulate = color
	progress_bar.value = pheromone_available

	pheromone_available = min(100.0, pheromone_available + delta * regeneration_speed)


func deplete(amount: float) -> void:
	# We want to allow negative values here because we don't check the amount before
	# allowing a depletion, so if we clamp it, we're giving the user free pheromones.
	pheromone_available -= amount * depletion_speed
