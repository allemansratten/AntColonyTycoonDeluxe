extends Control

@export var pheromone_available: float = 100.0
@export var depletion_speed: float = 4.0
@export var regeneration_speed: float = 0.5
@onready var progress_bar = $ProgressBar
@onready var game = get_node("/root/Game")

func _ready() -> void:
	scale = Vector2.ZERO

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var t = progress_bar.value / progress_bar.max_value
	var color = lerp(Color.GRAY, Color.GREEN, t)
	progress_bar.modulate = color
	progress_bar.value = pheromone_available

	pheromone_available = min(100.0, pheromone_available + delta * regeneration_speed)

	# if not game.is_drawing:
	# 	hide()

func deplete(amount: float) -> void:
	# We want to allow negative values here because we don't check the amount before
	# allowing a depletion, so if we clamp it, we're giving the user free pheromones.
	pheromone_available -= amount * depletion_speed


func add(amount: float) -> void:
	pheromone_available = min(100.0, pheromone_available + amount)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			if event.pressed:
				tween.tween_property(self, "scale", Vector2.ONE, 0.1)
			else:
				tween.tween_property(self, "scale", Vector2.ZERO, 0.1)

	if game.is_drawing:
		# show()
		if event is InputEventMouseMotion:
			position = event.position
	else:
		pass
