extends Area2D

@export var pheromone_strength: float = 0.5

@onready var pheromone_layer = get_node("/root/Game/PheromoneLayer")
@onready var pheromone_bar = get_node("/root/Game/UILayer/PheromoneBar")
@onready var ant_spawner = get_node("/root/Game")
@export var pheromone_per_item = 1.0

var item_count: int = 0

# Preload ItemVariant enum from item_variants.gd
const ItemVariant = preload("res://item_variants.gd").ItemVariant

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pheromone_layer.draw_pheromone_at_position(position, delta * pheromone_strength, true, 1.5)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("ants"):
		var deposit_result = body.maybe_deposit_item()
		
		# Check the success flag and the deposited item variant from the dictionary
		if deposit_result["success"]:
			var deposited_item_variant = deposit_result["deposited_item_variant"]
			
			if deposited_item_variant == ItemVariant.LEAF or deposited_item_variant == ItemVariant.MUSHROOM:
				ant_spawner.call_deferred("spawn_ant", true)
			
			item_count += 1
			$RichTextLabel.text = str(item_count)
			pheromone_bar.add(pheromone_per_item)
