@tool
extends RefCounted

"""
ViewportHandler provides access to the editor viewport.
It retrieves the current editor viewport for screenshot capture.
"""

var _editor_interface = null

func _init(editor_interface):
    """
    Initialize with the editor interface.

    Args:
        editor_interface: The EditorInterface instance
    """
    _editor_interface = editor_interface

func get_editor_viewport() -> Viewport:
    """
    Get the current editor viewport.

    Returns:
        The current editor viewport, or null if not found
    """
    if not _editor_interface:
        print("Godot2Prompt: ERROR - No editor interface available")
        return null

    # Try to get the viewport directly
    var viewport = _get_viewport_direct()
    if viewport:
        return viewport

    # If that fails, try to find it in the scene tree
    viewport = _find_viewport_in_tree()
    if viewport:
        return viewport

    print("Godot2Prompt: ERROR - Could not find editor viewport")
    return null

func _get_viewport_direct() -> Viewport:
    """
    Try to get the viewport directly from the editor interface.

    Returns:
        The editor viewport, or null if not available
    """
    # Method 1: Try to get the viewport directly
    if _editor_interface.has_method("get_editor_viewport"):
        return _editor_interface.get_editor_viewport()

    # Method 2: Try to get it from the editor main screen
    if _editor_interface.has_method("get_editor_main_screen"):
        var main_screen = _editor_interface.get_editor_main_screen()
        if main_screen and main_screen is Viewport:
            return main_screen

    return null

func _find_viewport_in_tree() -> Viewport:
    """
    Find the editor viewport by searching through the scene tree.

    Returns:
        The editor viewport, or null if not found
    """
    # Get the base control
    var base_control = _editor_interface.get_base_control()
    if not base_control:
        return null

    # Find the main editor viewport in the scene tree
    var viewports = _find_all_viewports(base_control)

    # Return the most likely candidate (typically the largest viewport)
    if viewports.size() > 0:
        return _get_best_viewport_candidate(viewports)

    return null

func _find_all_viewports(node: Node) -> Array:
    """
    Recursively find all viewports in the scene tree.

    Args:
        node: The node to start searching from

    Returns:
        Array of found viewports
    """
    var viewports = []

    # Check if this node is a viewport
    if node is Viewport and node.name != "root":
        viewports.append(node)

    # Check all children
    for child in node.get_children():
        viewports.append_array(_find_all_viewports(child))

    return viewports

func _get_best_viewport_candidate(viewports: Array) -> Viewport:
    """
    Select the best viewport candidate from a list of viewports.
    We prioritize viewports that are likely to be the editor's main display.

    Args:
        viewports: Array of viewport candidates

    Returns:
        The best viewport candidate, or null if none found
    """
    if viewports.size() == 0:
        return null

    # If there's only one viewport, return it
    if viewports.size() == 1:
        return viewports[0]

    # Look for viewports with specific names that are likely to be the editor viewport
    for viewport in viewports:
        var name_lower = viewport.name.to_lower()
        if "editor" in name_lower or "main" in name_lower:
            return viewport

    # If no specific names found, return the first one
    return viewports[0]
