extends ColorRect

@export var grid_size = Vector2(16 * 2, 9 * 2)
@export var overlay_color: Color = Color(1, 0, 0, 0.5)

var grid_data = []
var is_drawing = false  # To track if the user is currently drawing


func _ready():
	material = ShaderMaterial.new()
	material.shader = preload("res://pheromone.gdshader")
	
	# Initialize grid_data with default values as a 2D array
	for y in range(int(grid_size.y)):
		grid_data.append([])
		for x in range(int(grid_size.x)):
			grid_data[y].append(0.0)
	
	# Make sure the ColorRect covers the entire screen
	anchor_right = 1
	anchor_bottom = 1
	
	# Connect to the viewport size changed signal
	get_tree().root.connect("size_changed", Callable(self, "update_shader"))

	update_shader()

func set_random_data():
	for y in range(int(grid_size.y)):
		for x in range(int(grid_size.x)):
			grid_data[y][x] = randf()
	update_shader()

func update_shader():
	var image = Image.create(int(grid_size.x), int(grid_size.y), false, Image.FORMAT_RF)
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var value = grid_data[y][x]
			image.set_pixel(x, y, Color(value, 0, 0))
	#
	var texture = ImageTexture.create_from_image(image)
	
	material.set_shader_parameter("grid_texture", texture)
	material.set_shader_parameter("grid_size", grid_size)
	material.set_shader_parameter("overlay_color", overlay_color)
	material.set_shader_parameter("screen_size", get_viewport().get_visible_rect().size)


# Add pheromone at the mouse position
func draw_pheromone_at_mouse(mouse_pos):
	# Convert mouse position to grid position
	var rect_size: Vector2 = get_viewport_rect().size
	var grid_x: int = int(mouse_pos.x / rect_size.x * grid_size.x)
	var grid_y: int = int(mouse_pos.y / rect_size.y * grid_size.y)

	# Make sure the position is within the grid bounds
	if grid_x >= 0 and grid_x < grid_size.x and grid_y >= 0 and grid_y < grid_size.y:
		grid_data[grid_y][grid_x] = 1.0  # Set pheromone value to 1.0 (max)
		update_shader()


# Track mouse button input for drawing
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_drawing = true
			else:
				is_drawing = false
	elif event is InputEventMouseMotion and is_drawing:
		draw_pheromone_at_mouse(event.position)
