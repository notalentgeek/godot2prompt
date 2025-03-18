@tool
extends RefCounted

# Try to get an actual screenshot if possible
func try_capture_viewport(editor_interface) -> Image:
	# Try different viewport capture methods
	var image = _try_main_screen_viewport(editor_interface)

	if not image or image.is_empty():
		image = _try_editor_viewports(editor_interface)

	if not image or image.is_empty():
		image = _try_root_viewport(editor_interface)

	return image

# Try to capture from the main editor screen
func _try_main_screen_viewport(editor_interface) -> Image:
	if editor_interface.get_editor_main_screen():
		var editor_viewport = editor_interface.get_editor_main_screen()

		# Try direct viewport capture if it's a Viewport
		if editor_viewport is Viewport:
			var viewport_texture = editor_viewport.get_texture()
			if viewport_texture:
				return viewport_texture.get_image()

		# Try to find a SubViewport within the main screen
		for child in editor_viewport.get_children():
			if child is SubViewport:
				var viewport_texture = child.get_texture()
				if viewport_texture:
					var image = viewport_texture.get_image()
					if image and not image.is_empty():
						return image

	return null

# Try to find and capture viewports in the editor
func _try_editor_viewports(editor_interface) -> Image:
	var base_control = editor_interface.get_base_control()
	var viewports = _find_viewports_recursive(base_control)

	for viewport in viewports:
		var viewport_texture = viewport.get_texture()
		if viewport_texture:
			var image = viewport_texture.get_image()
			if image and not image.is_empty() and image.get_width() > 50 and image.get_height() > 50:
				return image

	return null

# Try to use the root viewport as fallback
func _try_root_viewport(editor_interface) -> Image:
	var base_control = editor_interface.get_base_control()
	if base_control and base_control.get_viewport():
		var viewport = base_control.get_viewport()
		var viewport_texture = viewport.get_texture()
		if viewport_texture:
			var image = viewport_texture.get_image()
			if image and not image.is_empty():
				return image

	return null

# Helper function to recursively find viewport nodes
func _find_viewports_recursive(node) -> Array:
	var result = []

	if node is Viewport or node is SubViewport:
		result.append(node)

	for child in node.get_children():
		result.append_array(_find_viewports_recursive(child))

	return result
