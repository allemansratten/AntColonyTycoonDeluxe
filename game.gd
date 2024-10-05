extends Node


@export var ant_scene: PackedScene
var screen_size

var pheromone_layer: ColorRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# spawn 100 ants on random positions
	screen_size = get_viewport().get_visible_rect().size

	for i in range(100):
		var ant = ant_scene.instantiate()
		ant.position = Vector2(randi() % int(screen_size.x), randi() % int(screen_size.y))
		add_child(ant)

	# TODO: multiple pheromone layers if needed
	pheromone_layer = preload("res://pheromone_layer.tscn").instantiate()
	add_child(pheromone_layer)

	pheromone_layer.set_random_data()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_spawn_timer_timeout() -> void:
	var ant = ant_scene.instantiate()
	add_child(ant)
