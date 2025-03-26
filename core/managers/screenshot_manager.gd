@tool
extends RefCounted
class_name ScreenshotManager

"""
ScreenshotManager handles capturing screenshots of the editor viewport.
"""

# Capture a screenshot representation for the editor viewport
func capture_editor_screenshot(editor_interface) -> String:
	var screenshot_path = "res://scene_screenshot.png"
	print("Godot2Prompt: Creating enhanced placeholder screenshot...")

	# Try to get actual screenshot first
	var actual_screenshot = _try_actual_screenshot(editor_interface)
	if actual_screenshot and not actual_screenshot.is_empty():
		var err = actual_screenshot.save_png(screenshot_path)
		if err == OK:
			print("Godot2Prompt: Actual screenshot saved to " + screenshot_path)
			return screenshot_path

	# If actual screenshot failed, create an informative placeholder
	print("Godot2Prompt: Creating placeholder with current scene info")

	# Get current scene info
	var current_scene = editor_interface.get_edited_scene_root()
	var scene_name = "Unknown Scene"
	var node_count = 0

	if current_scene:
		scene_name = current_scene.get_name()
		node_count = _count_nodes(current_scene)

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

	# Draw a few node boxes inside the tree
	var box_spacing = 40
	var box_height = 30
	var indent = 30

	for i in range(5):
		var indent_level = i % 3
		var x_pos = tree_rect.position.x + 20 + (indent_level * indent)
		var y_pos = tree_rect.position.y + 20 + (i * box_spacing)
		var box_width = 120 + (3 - indent_level) * 40

		_draw_rect(image, Rect2i(x_pos, y_pos, box_width, box_height),
				  Color(0.25, 0.27, 0.32))

	# Draw Godot2Prompt watermark
	_draw_rect(image, Rect2i(width - 200, height - 40, 190, 30),
			  Color(0.22, 0.24, 0.28))

	# Save the image
	var err = image.save_png(screenshot_path)
	if err == OK:
		print("Godot2Prompt: Enhanced placeholder screenshot saved to " + screenshot_path)
		return screenshot_path
	else:
		print("Godot2Prompt: Failed to save enhanced placeholder screenshot, error code: " + str(err))

	return ""

# Try to get an actual screenshot if possible
func _try_actual_screenshot(editor_interface) -> Image:
	# Get the editor viewport
	var editor_viewport

	if editor_interface.get_editor_main_screen():
		editor_viewport = editor_interface.get_editor_main_screen()

		# Try to find a SubViewport within the main screen
		for child in editor_viewport.get_children():
			if child is SubViewport:
				var viewport_texture = child.get_texture()
				if viewport_texture:
					var image = viewport_texture.get_image()
					if image and not image.is_empty():
						return image

	# Try to use the root viewport as fallback
	var base_control = editor_interface.get_base_control()
	if base_control and base_control.get_viewport():
		var viewport = base_control.get_viewport()
		var viewport_texture = viewport.get_texture()
		if viewport_texture:
			var image = viewport_texture.get_image()
			if image and not image.is_empty():
				return image

	return null

# Count total nodes in a scene
func _count_nodes(node: Node) -> int:
	var count = 1 # Count the node itself

	for child in node.get_children():
		count += _count_nodes(child)

	return count

# Helper to draw a rectangle on the image
func _draw_rect(image: Image, rect: Rect2i, color: Color) -> void:
	# Draw filled rectangle
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, color)
