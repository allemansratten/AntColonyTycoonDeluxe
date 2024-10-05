extends Node


@export var ant_scene: PackedScene
var screen_size

var pheromone_layer: ColorRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size

	# TODO: multiple pheromone layers if needed
	pheromone_layer = preload("res://pheromone_layer.tscn").instantiate()
	add_child(pheromone_layer)

	# spawn 100 ants on random positions
	for i in range(100):
		spawn_ant(false)



func spawn_ant(on_anthill: bool) -> void:
	var ant = ant_scene.instantiate()
	
	if on_anthill:
		ant.position = $Anthill.position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	else:
		ant.position = Vector2(randf_range(0, screen_size.x), randf_range(0, screen_size.y))

	ant.pheromone_layer = pheromone_layer
	add_child(ant)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_spawn_timer_timeout() -> void:
	spawn_ant(true)
