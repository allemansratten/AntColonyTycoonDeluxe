extends Area2D

@export var pheromone_strength: float = 0.15
@export var initial_pheromone_strength: float = 10.0
@export var ant_manual_spawn_delay_secs: float = 0.5

@onready var pheromone_layer = get_node("/root/Game/PheromoneLayer")
@onready var pheromone_bar = get_node("/root/Game/UILayer/PheromoneBar")
@onready var game = get_node("/root/Game")
@onready var ant_spawn_timer = get_node("AntSpawnTimer")
@onready var ants_count_label = get_node("AntsCountLabel")
@export var pheromone_per_item = 0.0

@export var ant_scene: PackedScene

var anthill_size: int = 0
var num_ants_ready: int = 1

signal anthill_empty

# Preload ItemVariant enum from item_variants.gd
const ItemVariant = preload("res://item_variants.gd").ItemVariant

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Just to make sure the label is updated
	set_ready_ants_count(num_ants_ready)
	# Spawn the first batch of ants immediately
	debug_spawn_initial_ants()
	ant_spawn_timer.start()

## Called by Game when it's ready.
func on_game_ready() -> void:
	for _i in range(5):
		spawn_ant()
	
	pheromone_layer.draw_pheromone_at_position(position, initial_pheromone_strength, true, 2.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pheromone_layer.draw_pheromone_at_position(position, delta * pheromone_strength, true, 1.5)

func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("ants"):
		return

	var deposit_result = body.maybe_deposit_item()
	# Check the success flag and the deposited item variant from the dictionary
	if !deposit_result["success"]:
		return

	pheromone_bar.add(pheromone_per_item)
	
	match deposit_result["deposited_item_variant"]:
		ItemVariant.LEAF, ItemVariant.MUSHROOM, ItemVariant.ANT:
			set_ready_ants_count(num_ants_ready + 1)
		ItemVariant.STICK:
			anthill_size += 1
			$AnthillSizeLabel.text = "[center]Anthill size: %d[/center]" % anthill_size


## Spawn a batch of ants on every timeout
@warning_ignore("integer_division")
func _on_ant_spawn_timer_timeout() -> void:
	if num_ants_ready <= 0:
		anthill_empty.emit()
		return
	var num_ants_to_spawn = max(num_ants_ready / 20, 1) # always spawn at least 1 ant

	for _n in range(num_ants_to_spawn):
		spawn_ant()

	set_ready_ants_count(num_ants_ready - num_ants_to_spawn)


func set_ready_ants_count(count: int) -> void:
	num_ants_ready = count
	ants_count_label.text = "[center]Hatching ants: %d[/center]" % count


## Debug function to spawn a bunch of ants at the start
## TODO: delete this
func debug_spawn_initial_ants() -> void:
	for _n in range(20):
		spawn_ant()


func spawn_ant() -> void:
	var ant = ant_scene.instantiate()
	
	ant.position = position + Vector2(randf_range(-30, 30), randf_range(-30, 30))

	game.add_child.call_deferred(ant)
