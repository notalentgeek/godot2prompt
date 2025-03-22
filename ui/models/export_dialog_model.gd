@tool
extends BaseModel
class_name ExportDialogModel

"""
ExportDialogModel represents the data model for the export dialog.
It manages export settings, node selection, and export processing.
"""

# Constants - File Paths
const ERROR_MANAGER_PATH: String = "res://addons/godot2prompt/core/managers/error_manager.gd"
const SCENE_MANAGER_PATH: String = "res://addons/godot2prompt/core/managers/scene_manager.gd"

# Signals
signal export_requested(export_data)
signal export_completed()

# Properties
var _current_root: Node = null
var _export_options: Dictionary = {}
var _selected_node: Node = null

func _init():
    """
    Initialize the export dialog model.
    """
    super._init()

func set_current_root(root_node: Node) -> void:
    """
    Set the current root node.

    Args:
        root_node: The root node of the scene
    """
    _current_root = root_node
    notify_changed()

func get_current_root() -> Node:
    """
    Get the current root node.

    Returns:
        The current root node
    """
    return _current_root

func set_export_options(options: Dictionary) -> void:
    """
    Set the export options.

    Args:
        options: Dictionary of export options
    """
    _export_options = options.duplicate()
    notify_changed()

func get_export_options() -> Dictionary:
    """
    Get the current export options.

    Returns:
        Dictionary of export options
    """
    return _export_options.duplicate()

func set_selected_node(node: Node) -> void:
    """
    Set the selected node for export.

    Args:
        node: The selected node
    """
    _selected_node = node
    notify_changed()

func get_selected_node() -> Node:
    """
    Get the currently selected node.

    Returns:
        The selected node
    """
    return _selected_node

func prepare_export_data() -> Dictionary:
    """
    Prepare the export data based on current selection and options.

    Returns:
        Dictionary containing all export parameters
    """
    if not _selected_node:
        return {}

    var export_data = {
        "selected_node": _selected_node,
        "include_scripts": _export_options.get("include_scripts", false),
        "include_properties": _export_options.get("include_properties", false),
        "include_signals": _export_options.get("include_signals", false),
        "include_errors": _export_options.get("include_errors", false),
        "include_project_settings": _export_options.get("include_project_settings", false),
        "enabled_setting_categories": [],
        "include_screenshot": _export_options.get("include_screenshot", false)
    }

    # Add settings categories if needed
    if export_data.include_project_settings:
        # This would come from a method call to get categories
        export_data.enabled_setting_categories = []

    return export_data

func request_export() -> void:
    """
    Request an export with the current settings.
    """
    var export_data = prepare_export_data()
    if not export_data.is_empty():
        emit_signal("export_requested", export_data)

func process_export_to_clipboard(export_data: Dictionary) -> String:
    """
    Process an export for clipboard.

    Args:
        export_data: Dictionary of export parameters

    Returns:
        The formatted export text
    """
    # Create error log if needed
    var error_log = []
    if export_data.include_errors:
        var error_manager = load(ERROR_MANAGER_PATH).new()
        error_log = error_manager.get_errors()

    # Process the scene
    var scene_manager = load(SCENE_MANAGER_PATH).new()
    var node_data = scene_manager.process_scene(
        export_data.selected_node,
        export_data.include_properties,
        export_data.include_signals,
        error_log,
        export_data.include_project_settings,
        export_data.enabled_setting_categories,
        "" # No screenshot for clipboard export
    )

    # Configure exporters and generate output
    var exporter = _create_configured_exporter(export_data, node_data)
    var output_text = exporter.generate_output(node_data)

    emit_signal("export_completed")
    return output_text

func _create_configured_exporter(export_data: Dictionary, node_data) -> Object:
    """
    Create and configure a composite exporter based on export options.

    Args:
        export_data: Dictionary of export parameters
        node_data: The node data to export

    Returns:
        A configured composite exporter
    """
    var composite_exporter = load("res://addons/godot2prompt/core/exporters/composite_exporter.gd").new()

    # Add tree exporter (always included)
    var tree_exporter = load("res://addons/godot2prompt/core/exporters/tree_exporter.gd").new()
    composite_exporter.add_exporter(tree_exporter)

    # Add optional exporters based on settings
    if export_data.include_properties:
        var properties_exporter = load("res://addons/godot2prompt/core/exporters/properties_exporter.gd").new()
        composite_exporter.add_exporter(properties_exporter)

    if export_data.include_signals:
        var signal_exporter = load("res://addons/godot2prompt/core/exporters/signal_exporter.gd").new()
        composite_exporter.add_exporter(signal_exporter)

    if export_data.include_scripts:
        var code_exporter = load("res://addons/godot2prompt/core/exporters/code_exporter.gd").new()
        composite_exporter.add_exporter(code_exporter)

    if export_data.include_errors:
        var error_context_exporter = load("res://addons/godot2prompt/core/exporters/error_context_exporter.gd").new()
        composite_exporter.add_exporter(error_context_exporter)

    if export_data.include_project_settings and not export_data.enabled_setting_categories.is_empty():
        var project_config_exporter = load("res://addons/godot2prompt/core/exporters/project_config_exporter.gd").new()
        composite_exporter.add_exporter(project_config_exporter)

    return composite_exporter
