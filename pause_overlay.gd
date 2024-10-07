extends Control

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		if get_tree().paused and visible:
			get_node("/root/Game")._on_resume_button_pressed()
		elif not get_tree().paused and not get_node("../StartGameOverlay").visible and not get_node("../GameOver").visible:
			get_node("/root/Game")._on_pause_button_pressed()
