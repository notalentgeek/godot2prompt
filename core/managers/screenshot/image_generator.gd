@tool
extends RefCounted

# Create a placeholder image with visual indicators
func create_placeholder_image(scene_name: String, node_count: int) -> Image:
	# Create a simple image
	var width = 800
	var height = 600
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)

	# Fill with a better background color
	image.fill(Color(0.15, 0.17, 0.21))

	# Draw informative elements (simulating text since we can't draw text directly)
	# Draw header area
	_draw_rect(image, Rect2i(0, 0, width, 80), Color(0.2, 0.22, 0.28))

	# Draw scene info area
	_draw_rect(image, Rect2i(50, 120, width - 100, 100), Color(0.18, 0.2, 0.25))

	# Draw a simple node tree representation
	var tree_rect = Rect2i(50, 250, width - 100, 300)
	_draw_rect(image, tree_rect, Color(0.18, 0.2, 0.25))

	# Draw a few node boxes inside the tree - one per 10 nodes, up to 20 boxes
	var boxes_to_draw = min(20, max(5, node_count / 10))
	var box_spacing = 40
	var box_height = 30
	var indent = 30

	for i in range(boxes_to_draw):
		var indent_level = i % 3
		var x_pos = tree_rect.position.x + 20 + (indent_level * indent)
		var y_pos = tree_rect.position.y + 20 + (i * box_spacing)
		var box_width = 120 + (3 - indent_level) * 40

		_draw_rect(image, Rect2i(x_pos, y_pos, box_width, box_height),
				  Color(0.25, 0.27, 0.32))

	# Draw Godot2Prompt watermark
	_draw_rect(image, Rect2i(width - 200, height - 40, 190, 30),
			  Color(0.22, 0.24, 0.28))

	return image

# Helper to draw a rectangle on the image
func _draw_rect(image: Image, rect: Rect2i, color: Color) -> void:
	# Draw filled rectangle
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, color)
