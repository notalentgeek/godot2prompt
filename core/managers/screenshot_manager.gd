@tool
extends RefCounted
class_name ScreenshotManager

"""
ScreenshotManager handles the creation of scene screenshots and visual representations.
In editor context, it generates a placeholder image representing the scene structure.
"""

# Constants - Colors
const COLOR_BACKGROUND: Color = Color(0.15, 0.17, 0.21)
const COLOR_BOX: Color = Color(0.25, 0.27, 0.32)
const COLOR_HEADER: Color = Color(0.2, 0.22, 0.28)
const COLOR_INFO_AREA: Color = Color(0.18, 0.2, 0.25)
const COLOR_TREE_AREA: Color = Color(0.18, 0.2, 0.25)
const COLOR_WATERMARK: Color = Color(0.22, 0.24, 0.28)

# Constants - Dimensions
const DEFAULT_IMAGE_HEIGHT: int = 600
const DEFAULT_IMAGE_WIDTH: int = 800
const DEFAULT_NODE_COUNT: int = 5
const HEADER_HEIGHT: int = 80

# Constants - Paths
const SCREENSHOT_PATH: String = "res://scene_screenshot.png"

# Constants - Strings
const LOG_CREATING_IMAGE: String = "Godot2Prompt: Creating placeholder image..."
const LOG_CREATING_SCREENSHOT: String = "Godot2Prompt: Creating placeholder screenshot..."
const LOG_FAILED_CREATE_IMAGE: String = "Godot2Prompt: Failed to create image"
const LOG_FAILED_SAVE: String = "Godot2Prompt: Failed to save placeholder screenshot, error code: %s"
const LOG_FAILED_VALID_IMAGE: String = "Godot2Prompt: Failed to create valid image"
const LOG_IMAGE_CREATED: String = "Godot2Prompt: Placeholder image created successfully"
const LOG_SCREENSHOT_SAVED: String = "Godot2Prompt: Placeholder screenshot saved to %s"

func capture_editor_screenshot(editor_interface: EditorInterface) -> String:
	"""
	Captures or creates a screenshot from the editor.
	In editor mode, generates a placeholder image representing the scene.

	Args:
		editor_interface: The EditorInterface instance

	Returns:
		Path to the saved screenshot image, or empty string if failed
	"""
	print(LOG_CREATING_SCREENSHOT)

	# Create the placeholder image
	var image = _create_informative_placeholder(editor_interface)

	# Ensure the image is valid
	if not _is_valid_image(image):
		print(LOG_FAILED_VALID_IMAGE)
		return ""

	# Save the image to file
	var err = image.save_png(SCREENSHOT_PATH)
	if err == OK:
		print(LOG_SCREENSHOT_SAVED % SCREENSHOT_PATH)
		return SCREENSHOT_PATH
	else:
		print(LOG_FAILED_SAVE % str(err))
		return ""

func _create_informative_placeholder(editor_interface: EditorInterface) -> Image:
	"""
	Creates an informative placeholder image with visual elements representing the scene.

	Args:
		editor_interface: The EditorInterface instance used to get scene information

	Returns:
		Image object with visual representation of the scene, or null if failed
	"""
	print(LOG_CREATING_IMAGE)

	# Create a new image with default dimensions
	var image = Image.create(DEFAULT_IMAGE_WIDTH, DEFAULT_IMAGE_HEIGHT, false, Image.FORMAT_RGBA8)

	if image == null:
		print(LOG_FAILED_CREATE_IMAGE)
		return null

	# Get current scene information
	var scene_info = _get_scene_info(editor_interface)

	# Draw the image components
	_draw_background(image)
	_draw_header(image)
	_draw_scene_info_area(image)
	_draw_node_tree(image, scene_info.node_count)
	_draw_watermark(image)

	print(LOG_IMAGE_CREATED)
	return image

func _get_scene_info(editor_interface: EditorInterface) -> Dictionary:
	"""
	Retrieves information about the current scene.

	Args:
		editor_interface: The EditorInterface instance

	Returns:
		Dictionary with scene name and node count
	"""
	var info = {
		"scene_name": "Unknown Scene",
		"node_count": DEFAULT_NODE_COUNT
	}

	# Safely try to access the edited scene
	if editor_interface == null or not editor_interface.has_method("get_edited_scene_root"):
		return info

	var current_scene = editor_interface.get_edited_scene_root()
	if current_scene == null:
		return info

	info.scene_name = current_scene.get_name()
	info.node_count = _count_nodes(current_scene)

	return info

func _draw_background(image: Image) -> void:
	"""
	Fills the image with the background color.

	Args:
		image: The image to draw on
	"""
	image.fill(COLOR_BACKGROUND)

func _draw_header(image: Image) -> void:
	"""
	Draws the header area on the image.

	Args:
		image: The image to draw on
	"""
	_safe_draw_rect(image, Rect2i(0, 0, DEFAULT_IMAGE_WIDTH, HEADER_HEIGHT), COLOR_HEADER)

func _draw_scene_info_area(image: Image) -> void:
	"""
	Draws the scene information area on the image.

	Args:
		image: The image to draw on
	"""
	_safe_draw_rect(
		image,
		Rect2i(50, 120, DEFAULT_IMAGE_WIDTH - 100, 100),
		COLOR_INFO_AREA
	)

func _draw_node_tree(image: Image, node_count: int) -> void:
	"""
	Draws a visual representation of the node tree.

	Args:
		image: The image to draw on
		node_count: The number of nodes to represent
	"""
	var tree_rect = Rect2i(50, 250, DEFAULT_IMAGE_WIDTH - 100, 300)
	_safe_draw_rect(image, tree_rect, COLOR_TREE_AREA)

	# Draw individual node boxes
	var box_spacing = 40
	var box_height = 30
	var indent = 30

	for i in range(min(node_count, 7)):
		var indent_level = i % 3
		var x_pos = tree_rect.position.x + 20 + (indent_level * indent)
		var y_pos = tree_rect.position.y + 20 + (i * box_spacing)
		var box_width = 120 + (3 - indent_level) * 40

		_safe_draw_rect(
			image,
			Rect2i(x_pos, y_pos, box_width, box_height),
			COLOR_BOX
		)

func _draw_watermark(image: Image) -> void:
	"""
	Draws the Godot2Prompt watermark on the image.

	Args:
		image: The image to draw on
	"""
	_safe_draw_rect(
		image,
		Rect2i(DEFAULT_IMAGE_WIDTH - 200, DEFAULT_IMAGE_HEIGHT - 40, 190, 30),
		COLOR_WATERMARK
	)

func _count_nodes(node: Node) -> int:
	"""
	Recursively counts the total number of nodes in a scene.

	Args:
		node: The root node to start counting from

	Returns:
		Total number of nodes in the hierarchy
	"""
	if node == null:
		return 0

	var count = 1 # Count the node itself

	if node.has_method("get_children"):
		for child in node.get_children():
			count += _count_nodes(child)

	return count

func _safe_draw_rect(image: Image, rect: Rect2i, color: Color) -> void:
	"""
	Safely draws a filled rectangle on an image with bounds checking.

	Args:
		image: The image to draw on
		rect: The rectangle coordinates and dimensions
		color: The color to fill the rectangle with
	"""
	if image == null:
		return

	# Validate image dimensions
	var img_width = image.get_width()
	var img_height = image.get_height()

	if img_width <= 0 or img_height <= 0:
		return

	# Clamp rectangle to image bounds
	var start_x = max(0, rect.position.x)
	var start_y = max(0, rect.position.y)
	var end_x = min(img_width, rect.position.x + rect.size.x)
	var end_y = min(img_height, rect.position.y + rect.size.y)

	# Draw filled rectangle with bounds checking
	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			if x >= 0 and x < img_width and y >= 0 and y < img_height:
				image.set_pixel(x, y, color)

func _is_valid_image(image: Image) -> bool:
	"""
	Validates that an image exists and has valid dimensions.

	Args:
		image: The image to validate

	Returns:
		True if the image is valid, False otherwise
	"""
	return image != null and image.get_size().x > 0 and image.get_size().y > 0
