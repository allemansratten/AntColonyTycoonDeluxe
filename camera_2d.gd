extends Camera2D

@export var zoom_speed: float = 0.2 # Adjust this to control zoom speed
@export var min_zoom: float = 1.0 # Minimum zoom level
@export var max_zoom: float = 4.0 # Maximum zoom level

@onready var game = get_node("/root/Game")

func _ready():
	# Set the zoom value to the maximum zoom level
	zoom = Vector2(max_zoom, max_zoom)

func _process(delta: float):
	# `game` might not be ready at first
	if game and game.is_game_over:
		return

	# Gradually increase the zoom value.
	# Multiplicative and not additive increase because otherwise the zoom speeds up.
	# The time to zoom from 4 to 2 should be the same as from 2 to 1.
	zoom.x /= (1 + zoom_speed) ** delta
	zoom.y /= (1 + zoom_speed) ** delta
	
	# Clamp the zoom value between min and max
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)
