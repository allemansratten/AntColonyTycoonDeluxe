extends Area2D

var item_count: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("ants"):
		if body.maybe_deposit_item():
			item_count += 1
			$RichTextLabel.text = str(item_count)
