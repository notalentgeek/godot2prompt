@tool
extends BaseModel
class_name ExportDialogModel

# Constants - File Paths
const ERROR_MANAGER_PATH: String = "res://addons/godot2prompt/core/managers/error_manager.gd"
const SCENE_MANAGER_PATH: String = "res://addons/godot2prompt/core/managers/scene_manager.gd"
const COMPOSITE_EXPORTER_PATH: String = "res://addons/godot2prompt/core/exporters/composite_exporter.gd"

# Constants - Exporter Paths
const CODE_EXPORTER_PATH: String = "res://addons/godot2prompt/core/exporters/code_exporter.gd"
const TREE_EXPORTER_PATH: String = "res://addons/godot2prompt/core/exporters/tree_exporter.gd"
const PROPERTIES_EXPORTER_PATH: String = "res://addons/godot2prompt/core/exporters/properties_exporter.gd"
const SIGNAL_EXPORTER_PATH: String = "res://addons/godot2prompt/core/exporters/signal_exporter.gd"
const ERROR_CONTEXT_EXPORTER_PATH: String = "res://addons/godot2prompt/core/exporters/error_context_exporter.gd"
const PROJECT_CONFIG_EXPORTER_PATH: String = "res://addons/godot2prompt/core/exporters/project_config_exporter.gd"
const SCREENSHOT_EXPORTER_PATH: String = "res://addons/godot2prompt/core/exporters/screenshot_exporter.gd"

# Signals
signal export_completed()
signal export_requested(export_data)

# Properties
var _current_root: Node = null
var _export_options: Dictionary = {}
var _selected_node: Node = null

func set_current_root(root_node: Node) -> void:
    _current_root = root_node
    notify_changed()

func get_current_root() -> Node:
    return _current_root

func set_export_options(options: Dictionary) -> void:
    _export_options = options.duplicate()
    notify_changed()

func get_export_options() -> Dictionary:
    return _export_options.duplicate()

func set_selected_node(node: Node) -> void:
    _selected_node = node
    notify_changed()

func get_selected_node() -> Node:
    return _selected_node

func prepare_export_data() -> Dictionary:
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
        "include_screenshot": _export_options.get("include_screenshot", false),
        "screenshot_path": _export_options.get("screenshot_path", "")
    }

    # Add settings categories if needed
    if export_data.include_project_settings:
        export_data.enabled_setting_categories = _export_options.get("enabled_setting_categories", [])

    return export_data

func request_export() -> void:
    var export_data = prepare_export_data()
    if not export_data.is_empty():
        emit_signal("export_requested", export_data)

func process_export_to_clipboard(export_data: Dictionary) -> String:
    # Create error log if needed
    var error_log = []

    # Load error manager with error handling
    if export_data.include_errors:
        var error_manager_script = load(ERROR_MANAGER_PATH)
        if error_manager_script:
            var error_manager = error_manager_script.new()
            error_log = error_manager.get_errors()
        else:
            push_error("Failed to load ErrorManager from: " + ERROR_MANAGER_PATH)

    # Process the scene with error handling
    var node_data = null
    var scene_manager_script = load(SCENE_MANAGER_PATH)

    if scene_manager_script:
        var scene_manager = scene_manager_script.new()
        node_data = scene_manager.process_scene(
            export_data.selected_node,
            export_data.include_properties,
            export_data.include_signals,
            error_log,
            export_data.include_project_settings,
            export_data.enabled_setting_categories,
            "" # No screenshot for clipboard export
        )
    else:
        push_error("Failed to load SceneManager from: " + SCENE_MANAGER_PATH)
        return "Error: Failed to load scene manager"

    # Configure exporters and generate output
    if node_data:
        var exporter = _create_configured_exporter(export_data, node_data)
        if exporter:
            var output_text = exporter.generate_output(node_data)
            emit_signal("export_completed")
            return output_text
        else:
            return "Error: Failed to create exporter"
    else:
        return "Error: Failed to process scene data"

func _create_configured_exporter(export_data: Dictionary, node_data) -> Object:
    var exporter_script = load(COMPOSITE_EXPORTER_PATH)
    if not exporter_script:
        push_error("Failed to load CompositeExporter from: " + COMPOSITE_EXPORTER_PATH)
        return null

    var composite_exporter = exporter_script.new()

    # Configure exporters based on options
    if export_data.include_scripts:
        var code_exporter_script = load(CODE_EXPORTER_PATH)
        if code_exporter_script:
            var code_exporter = code_exporter_script.new()
            composite_exporter.add_exporter(code_exporter)
        else:
            push_error("Failed to load CodeExporter from: " + CODE_EXPORTER_PATH)

    # Add tree structure exporter (always included as the base representation)
    var tree_exporter_script = load(TREE_EXPORTER_PATH)
    if tree_exporter_script:
        var tree_exporter = tree_exporter_script.new()
        composite_exporter.add_exporter(tree_exporter)
    else:
        push_error("Failed to load TreeExporter from: " + TREE_EXPORTER_PATH)

    if export_data.include_properties:
        var properties_exporter_script = load(PROPERTIES_EXPORTER_PATH)
        if properties_exporter_script:
            var properties_exporter = properties_exporter_script.new()
            composite_exporter.add_exporter(properties_exporter)
        else:
            push_error("Failed to load PropertiesExporter from: " + PROPERTIES_EXPORTER_PATH)

    if export_data.include_signals:
        var signal_exporter_script = load(SIGNAL_EXPORTER_PATH)
        if signal_exporter_script:
            var signal_exporter = signal_exporter_script.new()
            composite_exporter.add_exporter(signal_exporter)
        else:
            push_error("Failed to load SignalExporter from: " + SIGNAL_EXPORTER_PATH)

    if export_data.include_errors:
        var error_context_exporter_script = load(ERROR_CONTEXT_EXPORTER_PATH)
        if error_context_exporter_script:
            var error_context_exporter = error_context_exporter_script.new()
            composite_exporter.add_exporter(error_context_exporter)
        else:
            push_error("Failed to load ErrorContextExporter from: " + ERROR_CONTEXT_EXPORTER_PATH)

    if export_data.include_project_settings:
        var project_config_exporter_script = load(PROJECT_CONFIG_EXPORTER_PATH)
        if project_config_exporter_script:
            var project_config_exporter = project_config_exporter_script.new()
            project_config_exporter.set_enabled_categories(export_data.enabled_setting_categories)
            composite_exporter.add_exporter(project_config_exporter)
        else:
            push_error("Failed to load ProjectConfigExporter from: " + PROJECT_CONFIG_EXPORTER_PATH)

    if export_data.include_screenshot and export_data.screenshot_path:
        var screenshot_exporter_script = load(SCREENSHOT_EXPORTER_PATH)
        if screenshot_exporter_script:
            var screenshot_exporter = screenshot_exporter_script.new()
            screenshot_exporter.set_screenshot_path(export_data.screenshot_path)
            composite_exporter.add_exporter(screenshot_exporter)
        else:
            push_error("Failed to load ScreenshotExporter from: " + SCREENSHOT_EXPORTER_PATH)

    return composite_exporter
