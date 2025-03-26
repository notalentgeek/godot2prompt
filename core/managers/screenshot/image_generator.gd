@tool
extends RefCounted

"""
ImageGenerator creates images from Godot viewports.
It handles capturing viewport content into Image objects.
"""

func capture_viewport(viewport: Viewport) -> Image:
    """
    Capture the content of a viewport as an Image.

    Args:
        viewport: The Viewport to capture

    Returns:
        An Image containing the viewport content, or a fallback image if failed
    """
    if not viewport:
        print("Godot2Prompt: ERROR - No viewport provided for capture")
        return _create_fallback_image()

    print("Godot2Prompt: Attempting to capture viewport: " + viewport.name)

    # Try to get texture from viewport using various methods
    var image = _capture_from_viewport_texture(viewport)
    if image and !image.is_empty():
        print("Godot2Prompt: Successfully captured viewport texture")
        return image

    # If that fails, try to get a screenshot
    image = _capture_from_viewport_screenshot(viewport)
    if image and !image.is_empty():
        print("Godot2Prompt: Successfully captured viewport screenshot")
        return image

    # If viewport capture methods fail, try a direct screen capture
    image = _capture_screen_directly()
    if image and !image.is_empty():
        print("Godot2Prompt: Successfully captured screen directly")
        return image

    # If all methods fail, create a blank image
    print("Godot2Prompt: WARNING - All capture methods failed, creating fallback image")
    return _create_fallback_image()

func _create_fallback_image() -> Image:
    """
    Create a simple gradient fallback image when screenshot capture fails.

    Returns:
        A basic gradient image
    """
    var image = Image.new()
    var width = 800
    var height = 600

    # Create a blank image
    image.create(width, height, false, Image.FORMAT_RGBA8)

    # Draw a simple gradient pattern
    for y in range(height):
        for x in range(width):
            var r = float(x) / width
            var g = float(y) / height
            var b = 0.5
            var color = Color(r, g, b)
            image.set_pixel(x, y, color)

    print("Godot2Prompt: Created fallback image " + str(width) + "x" + str(height))
    return image


func _capture_from_viewport_texture(viewport: Viewport) -> Image:
    """
    Capture viewport content using get_texture().get_image()

    Args:
        viewport: The Viewport to capture

    Returns:
        An Image from the viewport texture, or null if failed
    """
    if not viewport.has_method("get_texture"):
        return null

    # Get the viewport texture
    var texture = viewport.get_texture()
    if not texture:
        return null

    # Convert the texture to an image
    var image = texture.get_image()
    if not image:
        return null

    return image

func _capture_from_viewport_screenshot(viewport: Viewport) -> Image:
    """
    Capture viewport content using get_viewport_texture() or .get_screenshot()

    Args:
        viewport: The Viewport to capture

    Returns:
        An Image from the viewport screenshot, or null if failed
    """
    # Method 1: Try get_viewport_texture (Godot 4.x)
    if viewport.has_method("get_viewport_texture"):
        var texture = viewport.get_viewport_texture()
        if texture:
            var image = texture.get_image()
            if image:
                return image

    # Method 2: Try get_screenshot
    if viewport.has_method("get_screenshot"):
        var image = viewport.get_screenshot()
        if image:
            return image

    # Method 3: Create an image from the texture using alternate method
    var texture = viewport.get_texture()
    if texture:
        var image = Image.new()
        var size = texture.get_size()
        image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
        image.copy_from(texture.get_image())
        return image

    return null
