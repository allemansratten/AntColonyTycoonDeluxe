extends Node

func _ready() -> void:
	var rock_scene = preload("res://rock.tscn")
	var anthill = get_node("../Anthill")
	var anthill_position = anthill.position
	var viewport_size = get_viewport().size
	var placed_positions: Array = []
	randomize()

	for i in range(50):
		var rock_instance: Node = rock_scene.instantiate()
		var random_position: Vector2 = generate_random_position(anthill_position, viewport_size, placed_positions)
		rock_instance.position = random_position
		placed_positions.append(random_position)
		add_child(rock_instance)
		rock_instance.add_to_group("rocks")


func generate_random_position(anthill_position: Vector2, viewport_size: Vector2, placed_positions: Array) -> Vector2:
	var random_position: Vector2
	while true:
		random_position = Vector2(randf() * viewport_size.x, randf() * viewport_size.y)
		var valid_position = true

		if random_position.distance_to(anthill_position) < 128:
			valid_position = false

		for placed_position in placed_positions:
			if random_position.distance_to(placed_position) < 96:
				valid_position = false
				break

		if valid_position:
			break
	return random_position
