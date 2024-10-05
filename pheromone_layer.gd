extends ColorRect

const BLUR_SPEED = 0.1
const DECAY_SPEED = 0.03

@export var grid_size_coef: int = 2
@export var grid_size = Vector2(16 * grid_size_coef, 9 * grid_size_coef)
@export var overlay_color: Color = Color(1, 0, 0, 0.5)

var grid_data = []

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

	connect_pheromone_emitters()


func connect_pheromone_emitters():
	var emitters = get_tree().get_nodes_in_group("pheromone_emitters")
	for emitter in emitters:
		emitter.connect("emit_pheromones", Callable(self, "handle_pheromone_emission"))


func _notification(what):
	if what == NOTIFICATION_PARENTED:
		if is_in_group("pheromone_emitters"):
			connect("emit_pheromones", Callable(self, "handle_pheromone_emission"))


func handle_pheromone_emission(position: Vector2, strength: float, radius: float):
	var rect_size: Vector2 = get_viewport_rect().size
	var grid_x: int = int(position.x / rect_size.x * grid_size.x)
	var grid_y: int = int(position.y / rect_size.y * grid_size.y)

	# Iterate through all grid points within the bounding box of the circle's diameter
	for y_offset in range(-int(radius), int(radius) + 1):
		var max_x_offset = int(sqrt(radius * radius - y_offset * y_offset)) # Calculate the horizontal limit based on the circle equation
		for x_offset in range(-max_x_offset, max_x_offset + 1):
			var current_x = grid_x + x_offset
			var current_y = grid_y + y_offset

			# Ensure the position is within grid bounds
			if current_x >= 0 and current_x < grid_size.x and current_y >= 0 and current_y < grid_size.y:
				# Calculate the distance from the center of the emission
				var distance: float = Vector2(x_offset, y_offset).length()

				# Apply pheromones only if within the circle radius
				if distance <= radius:
					# Optionally adjust strength based on distance (linear decay)
					var adjusted_strength: float = strength * (1.0 - (distance / radius))
					grid_data[current_y][current_x] = min(1.0, grid_data[current_y][current_x] + adjusted_strength)

	# aaa
	update_shader()


func set_random_data():
	for y in range(int(grid_size.y)):
		for x in range(int(grid_size.x)):
			grid_data[y][x] = randf()
	update_shader()

func set_demo_data():
	for y in range(int(grid_size.y)):
		for x in range(int(grid_size.x)):
			grid_data[y][x] = (sin(0.5 + y * 1) * 0.5 + 0.5) ** 3
	
	update_shader()

func get_value_at(x: float, y: float) -> float:
	# TODO: something smarter

	# to grid position
	x = x / get_viewport().get_visible_rect().size.x * grid_size.x
	y = y / get_viewport().get_visible_rect().size.y * grid_size.y

	if x < 0 or x >= grid_size.x or y < 0 or y >= grid_size.y:
		return 0.0
	return grid_data[int(y)][int(x)]

func update_shader():
	var image = Image.create(int(grid_size.x), int(grid_size.y), false, Image.FORMAT_RF)
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var value = grid_data[y][x]
			image.set_pixel(x, y, Color(value, 0, 0))
	

	var texture = ImageTexture.create_from_image(image)

	material.set_shader_parameter("grid_texture", texture)
	material.set_shader_parameter("grid_size", grid_size)
	material.set_shader_parameter("overlay_color", overlay_color)
	material.set_shader_parameter("screen_size", get_viewport().get_visible_rect().size)


func draw_pheromone_at_position(pos: Vector2):
	var rect_size: Vector2 = get_viewport_rect().size
	var grid_x_float: float = pos.x / rect_size.x * grid_size.x - 0.5
	var grid_y_float: float = pos.y / rect_size.y * grid_size.y - 0.5

	var grid_x_low: int = int(grid_x_float)
	var grid_y_low: int = int(grid_y_float)
	var grid_x_high: int = min(grid_x_low + 1, grid_size.x - 1)
	var grid_y_high: int = min(grid_y_low + 1, grid_size.y - 1)

	var fx: float = grid_x_float - grid_x_low
	var fy: float = grid_y_float - grid_y_low

	var pheromone_value: float = 1.0 # Max pheromone value

	# Apply bilinear interpolation to distribute the pheromone value smoothly
	grid_data[grid_y_low][grid_x_low] += pheromone_value * (1 - fx) * (1 - fy)
	grid_data[grid_y_low][grid_x_high] += pheromone_value * fx * (1 - fy)
	grid_data[grid_y_high][grid_x_low] += pheromone_value * (1 - fx) * fy
	grid_data[grid_y_high][grid_x_high] += pheromone_value * fx * fy

	# Clamp values to ensure they don't exceed 1.0
	grid_data[grid_y_low][grid_x_low] = min(grid_data[grid_y_low][grid_x_low], 1.0)
	grid_data[grid_y_low][grid_x_high] = min(grid_data[grid_y_low][grid_x_high], 1.0)
	grid_data[grid_y_high][grid_x_low] = min(grid_data[grid_y_high][grid_x_low], 1.0)
	grid_data[grid_y_high][grid_x_high] = min(grid_data[grid_y_high][grid_x_high], 1.0)

	update_shader()


func decay_grid(delta: float):
	var new_grid = []
	
	# Softer 3x3 Gaussian kernel for a very soft blur
# Properly normalized symmetric 3x3 Gaussian kernel
	var kernel = [
		[0.025, 0.05, 0.025], # Weights for neighboring cells
		[0.05, 0.7, 0.05], # 0.7 for the center cell, ensuring it's dominant
		[0.025, 0.05, 0.025] # Weights for neighboring cells
	]

	
	# Create a new grid to store the blurred and decayed values
	for y in range(int(grid_size.y)):
		new_grid.append([])
		for x in range(int(grid_size.x)):
			var sum = 0.0
			
			# Apply Gaussian blur around the current cell
			for ky in range(-1, 2): # Iterate over the 3x3 kernel
				for kx in range(-1, 2):
					var grid_x = x + kx
					var grid_y = y + ky
					
					# Ensure that the kernel doesn't go out of bounds
					if grid_x >= 0 and grid_x < int(grid_size.x) and grid_y >= 0 and grid_y < int(grid_size.y):
						var weight = kernel[ky + 1][kx + 1]
						sum += grid_data[grid_y][grid_x] * weight
			
			# Calculate the blurred value and apply decay
			var blurred_value = sum # No need to divide by kernel sum since it is already normalized
			new_grid[y].append(blurred_value)
	
	# Replace the old grid with the new one
	var blur_coef: float = 1.0 - (1.0 - BLUR_SPEED) ** delta
	for y in range(int(grid_size.y)):
		for x in range(int(grid_size.x)):
			grid_data[y][x] = lerp(grid_data[y][x], new_grid[y][x], blur_coef)

	var decay_coef: float = (1.0 - DECAY_SPEED) ** delta
	for y in range(int(grid_size.y)):
		for x in range(int(grid_size.x)):
			grid_data[y][x] = max(0.0, grid_data[y][x] * decay_coef)

	# Update the shader with the new grid
	update_shader()

func _process(delta: float) -> void:
	decay_grid(delta)
