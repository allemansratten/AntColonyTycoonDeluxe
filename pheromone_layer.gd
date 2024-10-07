extends ColorRect

const BLUR_SPEED = 0.125
const DECAY_SPEED = 0.018
const DECAY_MIN_DELAY_SECS = 0.1
const MIN_PHEROMONE_FOR_BLUR: float = 0.01

@export var grid_size_coef: int = 8
@export var grid_size = Vector2(16 * grid_size_coef, 9 * grid_size_coef)
@export var overlay_color: Color = Color(1, 0, 0, 0.5)

var grid_data = []
var time_since_last_decay: float = 0.0

func _ready():
	# material = ShaderMaterial.new()
	# material.shader = preload("res://pheromone.gdshader")
	
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


func gaussian_density(sigma: float, x: float, y: float) -> float:
	var exponent = -(x * x + y * y) / (2 * sigma * sigma)
	return exp(exponent) / (2 * PI * sigma * sigma)


func get_reasonable_kernel_size(sigma: float) -> int:
	# Calculate the kernel size to cover 3 standard deviations (99.7% of the distribution)
	var n = int(ceil(6 * sigma))
		
	# Ensure the size is odd (common practice for symmetric kernels)
	if n % 2 == 0:
		n += 1

	return n

## Draws pheromone at a position, with a Gaussian blur
## 
## 	Args:
## 		pos: The position to draw pheromone at.
## 		max_value: The maximum value the pheromone will be set to. Note that
## 			we first apply Gaussian blur so the actual value will be lower.
## 			`max_value` is the total applied.
## 		additive: If true, will set the value to `old + new` rather than
## 			`max(new, old)`.
## 		sigma: The standard deviation of the Gaussian kernel used for interpolation.
## 			Bigger = more blurry.
## 
## 	Returns:
## 		The total number of pheromone added.
func draw_pheromone_at_position(
	pos: Vector2,
	value: float,
	additive: bool = true,
	sigma: float = 0.5,
) -> float:
	var rect_size: Vector2 = get_viewport_rect().size
	var grid_x_float: float = pos.x / rect_size.x * grid_size.x - 0.5
	var grid_y_float: float = pos.y / rect_size.y * grid_size.y - 0.5

	var grid_x_low: int = int(grid_x_float)
	var grid_y_low: int = int(grid_y_float)

	var kernel_size = get_reasonable_kernel_size(sigma)

	var to_update = []

	for y in range(grid_y_low - kernel_size, grid_y_low + kernel_size):
		for x in range(grid_x_low - kernel_size, grid_x_low + kernel_size):
			if x < 0 or x >= grid_size.x or y < 0 or y >= grid_size.y:
				continue
			var strength = gaussian_density(sigma, x + 0.5 - grid_x_float, y + 0.5 - grid_y_float)
			to_update.append([y, x, strength])

	var added_total: float = 0

	for data in to_update:
		var y = data[0]
		var x = data[1]
		var interpolation_value = data[2]

		if x < 0 or x >= grid_size.x or y < 0 or y >= grid_size.y:
			continue

		if additive:
			var previous_value = grid_data[y][x]
			var new_value = min(1.0, previous_value + interpolation_value * value)
			added_total += new_value - previous_value
			grid_data[y][x] = new_value
		else:
			var new_value = interpolation_value * value
			var added = new_value - grid_data[y][x]
			if added > 0:
				grid_data[y][x] = new_value
				added_total += added

	return added_total


func decay_grid(delta: float):
	# This kernel will be applied to each cell to blur the pheromone
	var kernel = [
		[0.025, 0.05, 0.025],
		[0.05, 0.7, 0.05],
		[0.025, 0.05, 0.025],
	]

	# Create a new grid of the same size filled with zeroes
	var new_grid = []
	for y in range(int(grid_size.y)):
		new_grid.append([])
		for x in range(int(grid_size.x)):
			new_grid[y].append(0.0)
	
	# Create a new grid to store the blurred and decayed values
	for y in range(int(grid_size.y)):
		new_grid.append([])
		for x in range(int(grid_size.x)):
			# Optimization: Blurring matters little for low values. Remember, in
			# each iteration we're spreading the pheromone from the current cell
			# to the neighbors, so if it's low, it has little effect.
			if grid_data[y][x] <= MIN_PHEROMONE_FOR_BLUR:
				new_grid[y][x] = grid_data[y][x]
				continue

			# Take the current value and increase the values of its neighbors
			for ky in range(-1, 2):
				for kx in range(-1, 2):
					var target_x = x + kx
					var target_y = y + ky
					
					# Ensure that the kernel doesn't go out of bounds
					if (
						target_x >= 0 and
						target_x < int(grid_size.x) and
						target_y >= 0 and
						target_y < int(grid_size.y)
					):
						var weight = kernel[ky + 1][kx + 1]
						new_grid[target_y][target_x] += grid_data[y][x] * weight
	
	# Replace the old grid with the new one
	var blur_coef: float = 1.0 - (1.0 - BLUR_SPEED) ** delta
	var decay_coef: float = (1.0 - DECAY_SPEED) ** delta
	for y in range(int(grid_size.y)):
		for x in range(int(grid_size.x)):
			var blurred_value = lerp(grid_data[y][x], new_grid[y][x], blur_coef)
			grid_data[y][x] = max(0.0, blurred_value * decay_coef)


func _process(delta: float) -> void:
	time_since_last_decay += delta
	if time_since_last_decay > DECAY_MIN_DELAY_SECS:
		decay_grid(time_since_last_decay)
		time_since_last_decay = 0.0
		# Update the shader with the new grid
		update_shader()
