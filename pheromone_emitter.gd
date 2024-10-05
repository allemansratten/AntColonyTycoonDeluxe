extends Node2D

signal emit_pheromones(position: Vector2, strength: float, radius: float)
@export var emission_strength: float = 0.1
@export var emission_interval_ms: int = 1000
@export var emission_position: Vector2 = Vector2()
@export var emission_radius: float = 5.0

var emission_timer = null


func _ready():
	add_to_group("pheromone_emitters")
	emission_timer = Timer.new()
	emission_timer.wait_time = emission_interval_ms / 1000.0
	emission_timer.connect("timeout", Callable(self, "emit_pheromones_timer"))
	add_child(emission_timer)


func emit_pheromones_timer():
	emit_signal("emit_pheromones", emission_position, emission_strength, emission_radius)


func start_emission(position: Vector2):
	emission_position = position
	emission_timer.start()


func stop_emission():
	emission_timer.stop()


func _exit_tree():
	if emission_timer:
		emission_timer.stop()
