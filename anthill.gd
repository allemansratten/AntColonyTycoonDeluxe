extends Area2D

@export var pheromone_strength: float = 0.5

@onready var pheromone_layer = get_node("/root/Game/PheromoneLayer")

var item_count: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pheromone_layer.draw_pheromone_at_position(position, delta * pheromone_strength, true, 1.5)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("ants"):
		if body.maybe_deposit_item():
			item_count += 1
			$RichTextLabel.text = str(item_count)
