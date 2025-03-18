@tool
extends RefCounted

# Components
var viewport_handler = load("res://addons/godot2prompt/core/managers/screenshot/viewport_handler.gd").new()
var image_generator = load("res://addons/godot2prompt/core/managers/screenshot/image_generator.gd").new()

# Capture a screenshot representation for the editor viewport
func capture_editor_screenshot(editor_interface) -> String:
	var screenshot_path = "res://scene_screenshot.png"
	print("Godot2Prompt: Attempting to capture screenshot...")

	# Try to get actual screenshot first
	var actual_screenshot = viewport_handler.try_capture_viewport(editor_interface)
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

	# Generate and save placeholder image
	var image = image_generator.create_placeholder_image(scene_name, node_count)
	var err = image.save_png(screenshot_path)

	if err == OK:
		print("Godot2Prompt: Enhanced placeholder screenshot saved to " + screenshot_path)
		return screenshot_path
	else:
		print("Godot2Prompt: Failed to save enhanced placeholder screenshot, error code: " + str(err))

	return ""

# Count total nodes in a scene
func _count_nodes(node: Node) -> int:
	var count = 1 # Count the node itself

	for child in node.get_children():
		count += _count_nodes(child)

	return count
