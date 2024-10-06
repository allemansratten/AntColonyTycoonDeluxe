extends Camera2D

@export var zoom_speed: float = 0.01 # Adjust this to control zoom speed
@export var min_zoom: float = 1.0 # Minimum zoom level
@export var max_zoom: float = 4.0 # Maximum zoom level

func _ready():
	# Set the zoom value to the maximum zoom level
	zoom = Vector2(max_zoom, max_zoom)

func _process(delta: float):
	# Gradually increase the zoom value
	zoom.x -= zoom_speed * delta
	zoom.y -= zoom_speed * delta
	
	# Clamp the zoom value between min and max
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)
