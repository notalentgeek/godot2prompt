@tool
extends RefCounted
class_name SignalsExtractor

"""
SignalsExtractor extracts signal connections from nodes in a scene.
It identifies both outgoing signals (emitted by the node) and
incoming signals (connected to the node's methods).
"""

# Constants
const DIRECTION_INCOMING: String = "incoming"
const DIRECTION_OUTGOING: String = "outgoing"
const UNKNOWN_NAME: String = "Unknown"

func extract_node_signals(node: Node) -> Array:
    """
    Extracts all signal connections from a node.

    Args:
        node: The node to extract signals from

    Returns:
        Array of dictionaries containing signal connection information
    """
    var signals_data = []

    # Extract both outgoing and incoming connections
    _get_outgoing_connections(node, signals_data)
    _get_incoming_connections(node, signals_data)

    return signals_data

func _get_outgoing_connections(node: Node, signals_data: Array) -> void:
    """
    Extracts signals that this node emits (outgoing connections).

    Args:
        node: The node to extract signals from
        signals_data: Array to append signal information to
    """
    var signals_list = _get_node_signals_list(node)

    # Check each signal for connections
    for signal_name in signals_list:
        if not _is_valid_signal(node, signal_name):
            continue

        # Convert signal_name to StringName if it's a Dictionary or String
        var signal_name_to_use = _get_signal_name_as_string_name(signal_name)

        # Get connections list safely
        var connections = []
        if signal_name_to_use != &"": # Using empty StringName instead of null
            connections = node.get_signal_connection_list(signal_name_to_use)

        # Process each connection
        for connection in connections:
            var connection_info = _extract_outgoing_connection_info(connection, String(signal_name_to_use))
            if connection_info:
                signals_data.append(connection_info)

func _get_incoming_connections(node: Node, signals_data: Array) -> void:
    """
    Extracts signals connected to this node's methods (incoming connections).

    Args:
        node: The node to extract signals for
        signals_data: Array to append signal information to
    """
    var root = node.get_tree().get_root() if node.get_tree() else null
    if root:
        _find_signals_targeting_node(root, node, signals_data)

func _find_signals_targeting_node(search_node: Node, target_node: Node, signals_data: Array) -> void:
    """
    Recursively searches for signals targeting the specified node.

    Args:
        search_node: The node to search for outgoing signals
        target_node: The target node to check connections against
        signals_data: Array to append signal information to
    """
    if search_node == target_node:
        return

    var signals_list = _get_node_signals_list(search_node)

    # Check each signal for connections to our target node
    for signal_name in signals_list:
        if not _is_valid_signal(search_node, signal_name):
            continue

        # Convert signal_name to StringName if it's a Dictionary or String
        var signal_name_to_use = _get_signal_name_as_string_name(signal_name)

        # Get connections list safely
        var connections = []
        if signal_name_to_use != &"": # Using empty StringName instead of null
            connections = search_node.get_signal_connection_list(signal_name_to_use)

        # See if any connection points to our target node
        for connection in connections:
            _extract_incoming_connection_info(
                connection,
                String(signal_name_to_use),
                search_node,
                target_node,
                signals_data
            )

    # Check all children recursively
    for child in search_node.get_children():
        _find_signals_targeting_node(child, target_node, signals_data)

func _get_signal_name_as_string_name(signal_name: Variant) -> StringName:
    """
    Converts a signal name to StringName format.

    Args:
        signal_name: Signal name to convert (Dictionary, String, or StringName)

    Returns:
        The signal name as StringName, or an empty StringName if conversion not possible
    """
    if signal_name is Dictionary and "name" in signal_name:
        return StringName(signal_name.name)
    elif signal_name is String:
        return StringName(signal_name)
    elif signal_name is StringName:
        return signal_name

    # Return empty StringName instead of null since function returns StringName
    return &"" # Using &"" for empty StringName

func _get_node_signals_list(node: Node) -> Array:
    """
    Gets a list of all signals that a node can emit.

    Args:
        node: The node to get signals from

    Returns:
        Array of signal names
    """
    var signals_list = []

    # Get script signals if available
    if node.get_script():
        signals_list.append_array(node.get_script().get_script_signal_list())

    # Use ClassDB to get all signals for this node type
    var node_type = node.get_class()
    var class_signals = ClassDB.class_get_signal_list(node_type)

    # Add class signals to our list
    for signal_dict in class_signals:
        signals_list.append(signal_dict.name)

    return signals_list

func _is_valid_signal(node: Node, signal_name: Variant) -> bool:
    """
    Checks if a signal name is valid and exists on the node.

    Args:
        node: The node to check
        signal_name: The signal name to validate

    Returns:
        True if the signal is valid, false otherwise
    """
    if signal_name is Dictionary and "name" in signal_name:
        signal_name = signal_name.name

    return node.has_signal(signal_name)

func _extract_outgoing_connection_info(connection: Dictionary, signal_name: String) -> Dictionary:
    """
    Extracts information about an outgoing signal connection.

    Args:
        connection: The connection dictionary
        signal_name: The name of the signal

    Returns:
        Dictionary with connection information, or empty if invalid
    """
    if not "callable" in connection:
        return {}

    var callable = connection.callable
    if not callable.get_object() or not is_instance_valid(callable.get_object()):
        return {}

    var target_obj = callable.get_object()
    var target_name = _get_object_name(target_obj)
    var method_name = callable.get_method()

    return {
        "direction": DIRECTION_OUTGOING,
        "method": method_name,
        "signal_name": signal_name,
        "target": target_name
    }

func _extract_incoming_connection_info(
    connection: Dictionary,
    signal_name: String,
    source_node: Node,
    target_node: Node,
    signals_data: Array
) -> void:
    """
    Extracts information about an incoming signal connection.

    Args:
        connection: The connection dictionary
        signal_name: The name of the signal
        source_node: The node emitting the signal
        target_node: The node receiving the signal
        signals_data: Array to append signal information to
    """
    if not "callable" in connection:
        return

    var callable = connection.callable
    if callable.get_object() != target_node:
        return

    signals_data.append({
        "direction": DIRECTION_INCOMING,
        "method": callable.get_method(),
        "signal_name": signal_name,
        "source": source_node.name
    })

func _get_object_name(obj: Object) -> String:
    """
    Gets a displayable name for an object.

    Args:
        obj: The object to get the name for

    Returns:
        The name of the object
    """
    # Different objects have different ways to identify them
    if obj is Node:
        return obj.name
    elif "name" in obj:
        return obj.name
    else:
        return obj.get_class()
