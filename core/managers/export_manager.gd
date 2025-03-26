@tool
extends RefCounted
class_name ExportManager

"""
ExportManager orchestrates the scene export process in the Godot2Prompt plugin.
It coordinates between UI, export options, and various exporters to generate
formatted output of scene hierarchies with their properties and related context.
"""

# Constants - File Paths
const DEFAULT_EXPORT_PATH: String = "res://scene_hierarchy.txt"

# Constants - Paths
const COMPOSITE_EXPORTER_PATH: String = "res://addons/godot2prompt/core/exporters/composite_exporter.gd"
const TREE_EXPORTER_PATH: String = "res://addons/godot2prompt/core/exporters/tree_exporter.gd"
const CODE_EXPORTER_PATH: String = "res://addons/godot2prompt/core/exporters/code_exporter.gd"
const ERROR_CONTEXT_EXPORTER_PATH: String = "res://addons/godot2prompt/core/exporters/error_context_exporter.gd"
const PROJECT_CONFIG_EXPORTER_PATH: String = "res://addons/godot2prompt/core/exporters/project_config_exporter.gd"
const PROPERTIES_EXPORTER_PATH: String = "res://addons/godot2prompt/core/exporters/properties_exporter.gd"
const SCREENSHOT_EXPORTER_PATH: String = "res://addons/godot2prompt/core/exporters/screenshot_exporter.gd"
const SIGNAL_EXPORTER_PATH: String = "res://addons/godot2prompt/core/exporters/signal_exporter.gd"

# Core components
var _editor_interface = null
var _error_manager = null
var _file_system = null
var _scene_manager = null
var _screenshot_manager = null
var _ui_manager = null

# Exporters
var _exporters: Dictionary = {}

# Timers
var _completion_timer = null
var _export_timer = null

func _init() -> void:
    """
    Default constructor - preloads exporters for basic functionality.
    """
    _initialize_exporters()

func initialize(
    editor_interface,
    error_manager,
    file_system,
    scene_manager,
    screenshot_manager,
    ui_manager
) -> void:
    """
    Initializes the ExportManager with all required dependencies.

    Args:
        editor_interface: Reference to the Godot editor interface
        error_manager: Manager for handling errors
        file_system: System for file operations
        scene_manager: Manager for processing scene data
        screenshot_manager: Manager for capturing screenshots
        ui_manager: Manager for UI operations
    """
    _editor_interface = editor_interface
    _error_manager = error_manager
    _file_system = file_system
    _scene_manager = scene_manager
    _screenshot_manager = screenshot_manager
    _ui_manager = ui_manager

    _connect_signals()

func set_timers(export_timer, completion_timer) -> void:
    """
    Sets the timers used for controlling UI display duration.

    Args:
        export_timer: Timer for standard export operations
        completion_timer: Timer for displaying completion messages
    """
    _export_timer = export_timer
    _completion_timer = completion_timer

func _initialize_exporters() -> void:
    """
    Loads and instantiates all exporters used in the export process.
    Exporters are stored in a dictionary for easy access by type.
    """
    # Load exporter scripts
    var TreeExporter = load(TREE_EXPORTER_PATH)
    var CodeExporter = load(CODE_EXPORTER_PATH)
    var ErrorContextExporter = load(ERROR_CONTEXT_EXPORTER_PATH)
    var ProjectConfigExporter = load(PROJECT_CONFIG_EXPORTER_PATH)
    var PropertiesExporter = load(PROPERTIES_EXPORTER_PATH)
    var ScreenshotExporter = load(SCREENSHOT_EXPORTER_PATH)
    var SignalExporter = load(SIGNAL_EXPORTER_PATH)

    # Create exporter instances if scripts loaded successfully
    _exporters = {}

    if TreeExporter:
        _exporters["tree"] = TreeExporter.new()

    if CodeExporter:
        _exporters["code"] = CodeExporter.new()

    if ErrorContextExporter:
        _exporters["error"] = ErrorContextExporter.new()

    if ProjectConfigExporter:
        _exporters["project_config"] = ProjectConfigExporter.new()

    if PropertiesExporter:
        _exporters["properties"] = PropertiesExporter.new()

    if ScreenshotExporter:
        _exporters["screenshot"] = ScreenshotExporter.new()

    if SignalExporter:
        _exporters["signal"] = SignalExporter.new()

func _connect_signals() -> void:
    """
    Connects signal handlers for UI events.
    """
    if _ui_manager and _ui_manager.has_signal("export_hierarchy") and not _ui_manager.is_connected("export_hierarchy", Callable(self, "_on_export_hierarchy")):
        _ui_manager.connect("export_hierarchy", Callable(self, "_on_export_hierarchy"))

# Simple export API for direct use without full initialization

func export_to_file(scene_data, file_path: String = DEFAULT_EXPORT_PATH) -> bool:
    """
    Exports scene data to a file directly, without requiring full initialization.
    This is a simplified API for basic export functionality.

    Args:
        scene_data: The scene data to export
        file_path: The path to save the file to

    Returns:
        True if the export was successful, false otherwise
    """
    if not scene_data:
        push_error("ExportManager: Cannot export null scene data")
        return false

    # Generate the text content
    var output_text = _format_scene_data(scene_data)

    # Save to file
    return _save_to_file(output_text, file_path)

func _format_scene_data(node_data) -> String:
    """
    Format scene data into text for export.

    Args:
        node_data: The scene data to format

    Returns:
        Formatted text
    """
    # Create a composite exporter for basic formatting
    var CompositeExporter = load(COMPOSITE_EXPORTER_PATH)

    if not CompositeExporter:
        # Fall back to simple formatting if composite exporter can't be loaded
        return _format_node_simple(node_data, 0)

    var exporter = CompositeExporter.new()

    # Always include tree exporter for basic structure
    if "tree" in _exporters:
        exporter.add_exporter(_exporters["tree"])

    # Add other exporters if we have them and data has relevant content
    # First, check if properties are accessible either directly or through getters
    var has_properties = _has_property_or_method(node_data, "properties")
    var has_signals = _has_property_or_method(node_data, "signals_data")
    var has_script = _has_property_or_method(node_data, "script_code")
    var has_errors = _has_property_or_method(node_data, "error_log")
    var has_project_settings = _has_property_or_method(node_data, "project_settings")
    var has_screenshot = _has_property_or_method(node_data, "screenshot_path")

    if "properties" in _exporters and has_properties:
        exporter.add_exporter(_exporters["properties"])

    if "signal" in _exporters and has_signals:
        exporter.add_exporter(_exporters["signal"])

    if "code" in _exporters and has_script:
        exporter.add_exporter(_exporters["code"])

    if "error" in _exporters and has_errors:
        exporter.add_exporter(_exporters["error"])

    if "project_config" in _exporters and has_project_settings:
        exporter.add_exporter(_exporters["project_config"])

    if "screenshot" in _exporters and has_screenshot:
        exporter.add_exporter(_exporters["screenshot"])

    # Generate output using the composite exporter
    return exporter.generate_output(node_data)

func _has_property_or_method(obj, property_name: String) -> bool:
    """
    Check if an object has a property or a getter method.

    Args:
        obj: The object to check
        property_name: The property name to look for

    Returns:
        True if the property exists or has a getter, false otherwise
    """
    if obj == null:
        return false

    # Check if property exists directly
    # We need to use the proper way to check property existence
    var properties = obj.get_property_list()
    for property in properties:
        if property.name == property_name:
            return true

    # Alternative check using 'in' operator safely
    var has_property = false
    if obj is Object:
        # For Object types, use has_method to check for getter first
        var getter_method = "get_" + property_name
        if obj.has_method(getter_method):
            return true

        # Try reflection for property access
        if property_name in obj:
            return true

    return false

func _get_property_value(obj, property_name: String):
    """
    Get a property value, trying direct access first, then getter methods.

    Args:
        obj: The object to get the property from
        property_name: The property name

    Returns:
        The property value, or null if not found
    """
    if obj == null:
        return null

    # Try getter method first
    var getter_method = "get_" + property_name
    if obj is Object and obj.has_method(getter_method):
        return obj.call(getter_method)

    # Try direct property access safely
    if obj is Object:
        # For Object types, check if the property exists
        if property_name in obj:
            # Use the property directly
            return obj.get(property_name)
    elif obj is Dictionary:
        # For dictionaries, check if the key exists
        if property_name in obj:
            return obj[property_name]

    return null

func _format_node_simple(node_data, indent: int) -> String:
    """
    Simple node formatting fallback if exporters aren't available.

    Args:
        node_data: The node data to format
        indent: The indentation level

    Returns:
        Formatted text for this node and its children
    """
    if node_data == null:
        return "null node_data"

    var output = ""
    var indent_str = "".repeat(indent * 2) # Two spaces per indent level

    # Format node name and type
    var node_name = _get_property_value(node_data, "name")
    var node_type = _get_property_value(node_data, "type")

    if not node_name:
        node_name = "Unnamed Node"
    if not node_type:
        node_type = "Unknown Type"

    output += indent_str + "- " + node_name + " (" + node_type + ")\n"

    # Format properties if available
    var properties = _get_property_value(node_data, "properties")
    if properties != null:
        if properties is Dictionary and not properties.is_empty():
            for prop_name in properties:
                var prop_value = properties[prop_name]
                output += indent_str + "  • " + str(prop_name) + ": " + str(prop_value) + "\n"

    # Format signals if available
    var signals_data = _get_property_value(node_data, "signals_data")
    if signals_data != null:
        if signals_data is Array and not signals_data.is_empty():
            output += indent_str + "  Emits Signals:\n"
            for signal_info in signals_data:
                if signal_info is Dictionary:
                    var signal_name = signal_info.get("signal_name", "unnamed")
                    var target = signal_info.get("target", "unknown")
                    output += indent_str + "    • " + signal_name + " → " + target + "\n"

    # Format script if available
    var script_code = _get_property_value(node_data, "script_code")
    if script_code != null:
        if script_code is String and not script_code.is_empty():
            output += indent_str + "  Script:\n"
            output += indent_str + "  " + script_code.replace("\n", "\n" + indent_str + "  ") + "\n"

    # Format children
    var children = _get_property_value(node_data, "children")
    if children != null:
        if children is Array and not children.is_empty():
            for child in children:
                output += _format_node_simple(child, indent + 1)

    # Add screenshot info if present
    if indent == 0:
        var screenshot_path = _get_property_value(node_data, "screenshot_path")
        if screenshot_path != null:
            if screenshot_path is String and not screenshot_path.is_empty():
                output += "\n# Screenshot\n"
                output += "A screenshot of the current scene has been saved at: `" + screenshot_path + "`\n"

        # Add error log if present
        var error_log = _get_property_value(node_data, "error_log")
        if error_log != null:
            if error_log is Array and not error_log.is_empty():
                output += "\nRecent Errors:\n"
                for error in error_log:
                    output += "- " + str(error) + "\n"

    return output

func _save_to_file(content: String, file_path: String) -> bool:
    """
    Save content to a file.

    Args:
        content: The text content to save
        file_path: The file path to save to

    Returns:
        True if successful, false otherwise
    """
    # Create the file for writing
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if not file:
        push_error("ExportManager: Failed to open file for writing: " + file_path)
        return false

    # Write the content
    file.store_string(content)

    # File is automatically closed when it goes out of scope
    return true
