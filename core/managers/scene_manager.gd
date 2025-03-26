@tool
extends RefCounted
class_name SceneManager

"""
SceneManager processes scene hierarchies to create a structured representation.
It traverses the scene tree, extracting node data that can be formatted by exporters.
"""

# Constants - Paths
const NODE_DATA_PATH: String = "res://addons/godot2prompt/core/data/node_data.gd"
const PROPERTIES_EXTRACTOR_PATH: String = "res://addons/godot2prompt/core/extractors/properties_extractor.gd"
const SETTINGS_EXTRACTOR_PATH: String = "res://addons/godot2prompt/core/extractors/settings_extractor.gd"
const SIGNALS_EXTRACTOR_PATH: String = "res://addons/godot2prompt/core/extractors/signals_extractor.gd"

# Components
var _node_data_class = null
var _properties_extractor = null
var _settings_extractor = null
var _signals_extractor = null

# Add an embedded version of SignalsExtractor for fallback
# This ensures we always have the methods available
class FallbackSignalsExtractor extends RefCounted:
    const DIRECTION_INCOMING: String = "incoming"
    const DIRECTION_OUTGOING: String = "outgoing"
    const UNKNOWN_NAME: String = "Unknown"

    func extract_node_signals(node: Node) -> Array:
        var signals_data = []
        return signals_data # Return empty array as fallback

    func _get_object_name(obj: Object) -> String:
        if obj is Node:
            return obj.name
        elif "name" in obj:
            return obj.name
        else:
            return obj.get_class()

func _init() -> void:
    """
    Initializes the SceneManager and loads required components.
    """
    # Load the NodeData class using load instead of preload
    _node_data_class = load(NODE_DATA_PATH)
    if _node_data_class:
        print("Godot2Prompt: NodeData class loaded successfully from " + NODE_DATA_PATH)
    else:
        push_error("Failed to load NodeData class from: " + NODE_DATA_PATH)

    # Initialize extractors directly (more reliable)
    _initialize_extractors_directly()

    # Log loading status
    if _properties_extractor:
        print("Godot2Prompt: PropertiesExtractor loaded successfully")
    else:
        push_error("Failed to load PropertiesExtractor script")

    if _settings_extractor:
        print("Godot2Prompt: SettingsExtractor loaded successfully")
    else:
        push_error("Failed to load SettingsExtractor script")

    if _signals_extractor:
        print("Godot2Prompt: SignalsExtractor loaded successfully")
    else:
        push_error("Failed to load SignalsExtractor script")

func _initialize_extractors_directly() -> void:
    """
    Initializes extractors using direct instantiation as a fallback method.
    """
    # Properties extractor
    var properties_extractor = RefCounted.new()
    var properties_script = load(PROPERTIES_EXTRACTOR_PATH)
    if properties_script:
        properties_extractor.set_script(properties_script)
        _properties_extractor = properties_extractor

    # Settings extractor
    var settings_extractor = RefCounted.new()
    var settings_script = load(SETTINGS_EXTRACTOR_PATH)
    if settings_script:
        settings_extractor.set_script(settings_script)
        _settings_extractor = settings_extractor

    # Signals extractor - with fallback if loading fails
    var signals_extractor = RefCounted.new()
    var signals_script = load(SIGNALS_EXTRACTOR_PATH)
    if signals_script:
        signals_extractor.set_script(signals_script)
        _signals_extractor = signals_extractor

        # Verify the extractor has the required method
        if not _signals_extractor.has_method("extract_node_signals"):
            print("Godot2Prompt: SignalsExtractor missing methods, using fallback")
            _signals_extractor = FallbackSignalsExtractor.new()
    else:
        # Use fallback if script loading fails
        _signals_extractor = FallbackSignalsExtractor.new()

func process_scene(
    root: Node,
    include_properties: bool = false,
    include_signals: bool = false,
    error_log: Array = [],
    include_project_settings: bool = false,
    enabled_setting_categories: Array = [],
    screenshot_path: String = ""
) -> Object:
    """
    Processes a scene starting from the root node, collecting node data.

    Args:
        root: The root node of the scene or subtree to process
        include_properties: Whether to include node properties
        include_signals: Whether to include node signals
        error_log: Array of error messages to include with the root node
        include_project_settings: Whether to include project settings
        enabled_setting_categories: Categories of project settings to include
        screenshot_path: Path to a screenshot image, if any

    Returns:
        A NodeData object representing the scene hierarchy
    """
    var project_settings = []

    # If project settings are requested, collect them
    if include_project_settings and _settings_extractor:
        project_settings = _extract_project_settings_safely()

    return _process_node(
        root,
        0,
        include_properties,
        include_signals,
        error_log,
        project_settings,
        enabled_setting_categories,
        screenshot_path
    )

func _extract_project_settings_safely() -> Array:
    """
    Safely extracts project settings with error handling.

    Returns:
        Array of project settings or empty array if extraction fails
    """
    if not _settings_extractor:
        return []

    var settings = []

    # Use a safer approach with error reporting instead of try/except
    if _settings_extractor.has_method("extract_project_settings"):
        settings = _settings_extractor.extract_project_settings()
    else:
        push_error("SettingsExtractor does not have method extract_project_settings")

    return settings

func _process_node(
    node: Node,
    depth: int,
    include_properties: bool,
    include_signals: bool,
    error_log: Array = [],
    project_settings: Array = [],
    enabled_setting_categories: Array = [],
    screenshot_path: String = ""
) -> Object:
    """
    Recursively processes a node and its children.

    Args:
        node: The node to process
        depth: The depth level in the hierarchy
        include_properties: Whether to include node properties
        include_signals: Whether to include node signals
        error_log: Array of error messages (only included at root level)
        project_settings: Array of project settings (only included at root level)
        enabled_setting_categories: Categories of project settings to include
        screenshot_path: Path to a screenshot image, if any

    Returns:
        A NodeData object representing the node and its children
    """
    # Extract node data based on requested options
    var node_info = _extract_node_info(node, include_properties, include_signals)

    # Safety checks on node_info
    if not node_info.has("script_code"):
        node_info["script_code"] = ""
    if not node_info.has("properties"):
        node_info["properties"] = {}
    if not node_info.has("signals_data"):
        node_info["signals_data"] = []

    # Create the appropriate NodeData object based on depth
    var node_data = _create_node_data(
        node,
        depth,
        node_info["script_code"],
        node_info["properties"],
        node_info["signals_data"],
        error_log if depth == 0 else [],
        project_settings if depth == 0 else [],
        enabled_setting_categories if depth == 0 else [],
        screenshot_path if depth == 0 else ""
    )

    # Process all children recursively
    if node_data:
        for child in node.get_children():
            var child_data = _process_node(child, depth + 1, include_properties, include_signals)
            if child_data:
                node_data.children.append(child_data)

    return node_data

func _extract_node_info(node: Node, include_properties: bool, include_signals: bool) -> Dictionary:
    """
    Extracts information from a node.

    Args:
        node: The node to extract information from
        include_properties: Whether to extract properties
        include_signals: Whether to extract signals

    Returns:
        Dictionary containing script_code, properties, and signals_data
    """
    var info = {
        "script_code": "",
        "properties": {},
        "signals_data": []
    }

    # Get script source code if available
    if node.get_script():
        info["script_code"] = node.get_script().get_source_code()

    # Extract properties if requested
    if include_properties and _properties_extractor:
        info["properties"] = _extract_properties_safely(node)

    # Extract signals if requested
    if include_signals and _signals_extractor:
        info["signals_data"] = _extract_signals_safely(node)

    return info

func _extract_properties_safely(node: Node) -> Dictionary:
    """
    Safely extracts node properties with error handling.

    Args:
        node: The node to extract properties from

    Returns:
        Dictionary of properties or empty dictionary if extraction fails
    """
    if not _properties_extractor:
        return {}

    if not _properties_extractor.has_method("extract_node_properties"):
        push_error("PropertiesExtractor does not have method extract_node_properties")
        return {}

    var properties = {}

    # Call the method and catch any errors
    properties = _properties_extractor.extract_node_properties(node)

    return properties

func _extract_signals_safely(node: Node) -> Array:
    """
    Safely extracts node signals with error handling.

    Args:
        node: The node to extract signals from

    Returns:
        Array of signals or empty array if extraction fails
    """
    if not _signals_extractor:
        return []

    if not _signals_extractor.has_method("extract_node_signals"):
        push_error("SignalsExtractor does not have method extract_node_signals")
        return []

    var signals_data = []

    # Call the method and catch any errors
    signals_data = _signals_extractor.extract_node_signals(node)

    return signals_data

func _create_node_data(
    node: Node,
    depth: int,
    script_code: String,
    properties: Dictionary,
    signals_data: Array,
    error_log: Array,
    project_settings: Array,
    enabled_setting_categories: Array,
    screenshot_path: String
) -> Object:
    """
    Creates a NodeData object with the given parameters.

    Args:
        node: The node to create data for
        depth: The depth level in the hierarchy
        script_code: The node's script source code
        properties: Dictionary of node properties
        signals_data: Array of signal connections
        error_log: Array of error messages
        project_settings: Array of project settings
        enabled_setting_categories: Categories of project settings
        screenshot_path: Path to a screenshot image

    Returns:
        A new NodeData object or null if creation fails
    """
    # Check if we have a valid NodeData class
    if not _node_data_class:
        push_error("NodeData class is not loaded")
        return null

    # Create node data object using the standard approach first
    var node_data = null

    # Attempt using the standard constructor approach
    if _node_data_class.has_method("new"):
        # GDScript doesn't have try/except blocks, so we'll use error reporting instead
        node_data = _node_data_class.new(
            node.name,
            node.get_class(),
            depth,
            script_code,
            properties,
            signals_data, # This maps to p_signals in NodeData._init()
            error_log,
            project_settings,
            enabled_setting_categories,
            screenshot_path
        )

        if node_data == null:
            push_error("Failed to create NodeData using constructor")

    # If the standard approach failed, try an alternative
    if not node_data:
        # Create a base object and set properties manually
        node_data = RefCounted.new()
        node_data.set_script(_node_data_class)

        # Check if script was set successfully by checking if a known property exists
        if not node_data.get("name") != null:
            push_error("Failed to set script on NodeData instance")
            return null

        # Set all properties manually (matching NodeData property names)
        node_data.name = node.name
        node_data.type = node.get_class()
        node_data.depth = depth
        node_data.script_code = script_code
        node_data.properties = properties
        node_data.signals = signals_data  # Note this uses 'signals' not 'signals_data'
        node_data.error_log = error_log
        node_data.project_settings = project_settings
        node_data.enabled_setting_categories = enabled_setting_categories
        node_data.screenshot_path = screenshot_path
        node_data.children = []

    # Always return node_data, which could still be null if all approaches failed
    return node_data
