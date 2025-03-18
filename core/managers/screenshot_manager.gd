@tool
extends RefCounted

# Capture a screenshot from the editor viewport
func capture_editor_screenshot(editor_interface) -> String:
    var screenshot_path = "res://scene_screenshot.png"
    print("Godot2Prompt: Creating placeholder screenshot...")

    var image = null

    # Use a try/except approach to prevent errors from bubbling up
    if OS.has_feature("editor"):
        # We're in the editor, create a placeholder
        image = _create_informative_placeholder(editor_interface)
    else:
        # In a running game/app, we could actually take a screenshot
        # But this is not likely to be used in that context
        image = _create_informative_placeholder(editor_interface)

    # Verify image is valid before saving
    if image != null and image.get_size().x > 0 and image.get_size().y > 0:
        # Save the image
        var err = image.save_png(screenshot_path)
        if err == OK:
            print("Godot2Prompt: Placeholder screenshot saved to " + screenshot_path)
            return screenshot_path
        else:
            print("Godot2Prompt: Failed to save placeholder screenshot, error code: " + str(err))
    else:
        print("Godot2Prompt: Failed to create valid image")

    return ""

# Create an informative placeholder image with visual elements
func _create_informative_placeholder(editor_interface) -> Image:
    print("Godot2Prompt: Creating placeholder image...")

    # Create a simple image
    var width = 800
    var height = 600
    var image = Image.create(width, height, false, Image.FORMAT_RGBA8)

    if image == null:
        print("Godot2Prompt: Failed to create image")
        return null

    # Get current scene info for context (with error protection)
    var scene_name = "Unknown Scene"
    var node_count = 5 # Default to 5 nodes if we can't get actual count

    if editor_interface != null:
        var current_scene = null

        # Protected access to edited scene root
        if editor_interface.has_method("get_edited_scene_root"):
            current_scene = editor_interface.get_edited_scene_root()

            if current_scene != null:
                scene_name = current_scene.get_name()
                node_count = _count_nodes(current_scene)

    # Fill with a background color
    image.fill(Color(0.15, 0.17, 0.21))

    # Draw header area
    _safe_draw_rect(image, Rect2i(0, 0, width, 80), Color(0.2, 0.22, 0.28))

    # Draw scene info area
    _safe_draw_rect(image, Rect2i(50, 120, width - 100, 100), Color(0.18, 0.2, 0.25))

    # Draw a simple node tree representation
    var tree_rect = Rect2i(50, 250, width - 100, 300)
    _safe_draw_rect(image, tree_rect, Color(0.18, 0.2, 0.25))

    # Draw a few node boxes inside the tree
    var box_spacing = 40
    var box_height = 30
    var indent = 30

    for i in range(min(node_count, 7)):
        var indent_level = i % 3
        var x_pos = tree_rect.position.x + 20 + (indent_level * indent)
        var y_pos = tree_rect.position.y + 20 + (i * box_spacing)
        var box_width = 120 + (3 - indent_level) * 40

        _safe_draw_rect(image, Rect2i(x_pos, y_pos, box_width, box_height),
                  Color(0.25, 0.27, 0.32))

    # Draw Godot2Prompt watermark
    _safe_draw_rect(image, Rect2i(width - 200, height - 40, 190, 30),
              Color(0.22, 0.24, 0.28))

    print("Godot2Prompt: Placeholder image created successfully")
    return image

# Count total nodes in a scene with error protection
func _count_nodes(node: Node) -> int:
    if node == null:
        return 0

    var count = 1 # Count the node itself

    if node.has_method("get_children"):
        for child in node.get_children():
            count += _count_nodes(child)

    return count

# Helper to draw a rectangle on the image with error protection
func _safe_draw_rect(image: Image, rect: Rect2i, color: Color) -> void:
    if image == null:
        return

    # Make sure the rectangle is valid
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
