extends ColorRect

@export var grid_size = Vector2(16 * 2, 9 * 2)
@export var overlay_color: Color = Color(1, 0, 0, 0.5)

var grid_data = []

func _ready():
	material = ShaderMaterial.new()
	material.shader = preload("res://pheromone.gdshader")
	
	# Initialize grid_data with default values
	grid_data.resize(int(grid_size.x * grid_size.y))
	grid_data.fill(0.0)
	
	# Make sure the ColorRect covers the entire screen
	anchor_right = 1
	anchor_bottom = 1
	
	# Connect to the viewport size changed signal
	get_tree().root.connect("size_changed", Callable(self, "update_shader"))

	update_shader()

func set_random_data():
	for i in range(grid_data.size()):
		grid_data[i] = randf()
	update_shader()


func update_shader():
	var image = Image.create(int(grid_size.x), int(grid_size.y), false, Image.FORMAT_RF)
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var value = grid_data[y * int(grid_size.x) + x]
			image.set_pixel(x, y, Color(value, 0, 0))
	#
	var texture = ImageTexture.create_from_image(image)
	
	material.set_shader_parameter("grid_texture", texture)
	material.set_shader_parameter("grid_size", grid_size)
	material.set_shader_parameter("overlay_color", overlay_color)
	material.set_shader_parameter("screen_size", get_viewport().get_visible_rect().size)
