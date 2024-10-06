extends Node


@export var ant_scene: PackedScene
var screen_size

var is_drawing = false # To track if the user is currently drawing

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size

	# spawn 100 ants on random positions
	for i in range(100):
		spawn_ant(false)


func spawn_ant(on_anthill: bool) -> void:
	var ant = ant_scene.instantiate()
	
	if on_anthill:
		ant.position = $Anthill.position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	else:
		ant.position = Vector2(randf_range(0, screen_size.x), randf_range(0, screen_size.y))

	ant.pheromone_layer = $PheromoneLayer
	add_child(ant)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_ant_spawn_timer_timeout() -> void:
	spawn_ant(true)


# Track mouse button input for drawing
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_drawing = true
			else:
				is_drawing = false
	elif event is InputEventMouseMotion and is_drawing:
		if $UILayer/PheromoneBar.pheromone_available > 0:
			# Camera2D changes the viewport's `canvas_transform` so we need to convert
			# the mouse position to world position.
			var world_position = get_viewport().canvas_transform.affine_inverse() * event.position

			var added = $PheromoneLayer.draw_pheromone_at_position(world_position, 1.0)
			
			$UILayer/PheromoneBar.deplete(added)
