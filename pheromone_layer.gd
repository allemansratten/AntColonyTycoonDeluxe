extends ColorRect

@export var grid_size = Vector2(16 * 2, 9 * 2)
@export var overlay_color: Color = Color(1, 0, 0, 0.5)
@export var decay_rate = 0.03  # Decay by 1%

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
	$DecayTimer.connect("timeout", Callable(self, "decay_grid"))
	$DecayTimer.start()


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


func decay_grid():
	var new_grid = []
	
	# Symmetric 5x5 Gaussian kernel
	var kernel = [
		[1.0, 4.0, 6.0, 4.0, 1.0],
		[4.0, 16.0, 24.0, 16.0, 4.0],
		[6.0, 24.0, 36.0, 24.0, 6.0],
		[4.0, 16.0, 24.0, 16.0, 4.0],
		[1.0, 4.0, 6.0, 4.0, 1.0]
	]
	var kernel_sum = 256.0  # Sum of all kernel values
	
	# Create a new grid to store the blurred and decayed values
	for y in range(int(grid_size.y)):
		new_grid.append([])
		for x in range(int(grid_size.x)):
			var sum = 0.0
			var total_weight = 0.0
			
			# Apply Gaussian blur around the current cell
			for ky in range(-2, 3):
				for kx in range(-2, 3):
					var grid_x = x + kx
					var grid_y = y + ky
					
					# Ensure that the kernel doesn't go out of bounds
					if grid_x >= 0 and grid_x < int(grid_size.x) and grid_y >= 0 and grid_y < int(grid_size.y):
						var weight = kernel[ky + 2][kx + 2]
						sum += grid_data[grid_y][grid_x] * weight
			
			# Calculate the blurred value and apply decay
			var blurred_value = sum / kernel_sum
			new_grid[y].append(max(0, blurred_value * (1 - decay_rate)))  # Apply decay
	
	# Replace the old grid with the new one
	grid_data = new_grid
	
	# Update the shader with the new grid
	update_shader()
