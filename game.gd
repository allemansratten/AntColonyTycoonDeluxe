extends Node

@onready var anthill = get_node("Anthill")

@onready var screen_size = get_viewport().get_visible_rect().size
@onready var game_over_sound: AudioStreamPlayer = $GameOverSound

var is_drawing = false # To track if the user is currently drawing
var is_game_muted = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$UILayer/StartGameOverlay.show()
	get_tree().paused = true
	screen_size = get_viewport().get_visible_rect().size
	anthill.anthill_empty.connect(maybe_game_over)
	anthill.on_game_ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


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

			var added = $PheromoneLayer.draw_pheromone_at_position(world_position, 0.1)
			
			$UILayer/PheromoneBar.deplete(added)


func maybe_game_over() -> void:
	# This was called when there are no more ants in the anthill, check if there are any living ants left
	var living_ants = get_tree().get_nodes_in_group("ants")
	if living_ants.size() <= 0:
		game_over_sound.play()
		on_game_over()


func on_game_over() -> void:
	get_tree().paused = true
	$UILayer/GameOver.show()
	$UILayer/GameUIOverlay.hide()
	show_endgame_score(anthill.anthill_size)

	
func _on_play_again_button_pressed() -> void:
	get_tree().reload_current_scene()
	$UILayer/GameUIOverlay.show()


func _on_start_game_button_pressed() -> void:
	get_tree().paused = false
	$UILayer/StartGameOverlay.hide()
	$UILayer/GameUIOverlay.show()


func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	$UILayer/PauseOverlay.hide()
	$UILayer/GameUIOverlay.show()


func _on_pause_button_pressed() -> void:
	get_tree().paused = true
	$UILayer/PauseOverlay.show()
	$UILayer/GameUIOverlay.hide()


func _on_mute_button_pressed() -> void:
	if is_game_muted:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
		$UILayer/PauseOverlay/MuteButton.text = "Mute"
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
		$UILayer/PauseOverlay/MuteButton.text = "Unmute"
	is_game_muted = !is_game_muted


## Score milestones to show the player when the game ends
## TODO: Make these better, more options etc...
var SCORE_MILESTONES = [
	{
		"min_score": 0,
		"text": "That's barely an anthill...",
	},
	{
		"min_score": 20,
		"text": "You built a little pile of sticks.",
	},
	{
		"min_score": 50,
		"text": "That looks like an actual anthill!",
	},
	{
		"min_score": 200,
		"text": "Wow! That's an ant skyscraper!",
	},
]

func show_endgame_score(final_score: int) -> void:
	var score_milestone_reached = SCORE_MILESTONES.filter(
		func(milestone): return final_score >= milestone.min_score
	).front()
	$UILayer/GameOver/FinalScoreLabel.text = "Your final anthill size is %d.\n\n%s" % [final_score, score_milestone_reached.text]
