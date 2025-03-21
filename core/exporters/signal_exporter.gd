@tool
extends BaseExporter
class_name SignalExporter

"""
SignalExporter formats information about connected signals between nodes.
This helps provide better understanding of scene interactions and event flow.
"""

# Constants - Formatting
const BULLET_POINT: String = "    • "
const DIRECTION_ARROW: String = " → "
const DOT_SEPARATOR: String = "."

# Constants - Headers
const EMITS_HEADER: String = "  Emits Signals:\n"
const RECEIVES_HEADER: String = "  Receives Signals:\n"

# Constants - Signal Direction
const DIRECTION_INCOMING: String = "incoming"

func format_node_content(node_data: NodeData) -> String:
	"""
	Formats the signal connections for a node, both incoming and outgoing.

	Args:
		node_data: The NodeData object containing signals to format

	Returns:
		A formatted string containing the node's signal connections,
		or an empty string if the node has no signals
	"""
	# Return early if no signals are available
	if not node_data.signals or node_data.signals.is_empty():
		return ""

	# Separate signals by direction
	var categorized_signals = _categorize_signals_by_direction(node_data.signals)

	# Format each direction of signals
	return _format_signals_by_direction(categorized_signals, node_data.depth)

func _categorize_signals_by_direction(signals: Array) -> Dictionary:
	"""
	Separates signals into incoming and outgoing categories.

	Args:
		signals: Array of signal information dictionaries

	Returns:
		Dictionary with keys 'incoming' and 'outgoing', each containing
		an array of the corresponding signal info dictionaries
	"""
	var categorized = {
		"incoming": [],
		"outgoing": []
	}

	for signal_info in signals:
		if "direction" in signal_info and signal_info.direction == DIRECTION_INCOMING:
			categorized.incoming.append(signal_info)
		else:
			categorized.outgoing.append(signal_info)

	return categorized

func _format_signals_by_direction(categorized_signals: Dictionary, depth: int) -> String:
	"""
	Formats both incoming and outgoing signals with proper indentation.

	Args:
		categorized_signals: Dictionary of signals categorized by direction
		depth: The depth level for proper indentation

	Returns:
		A formatted string containing both incoming and outgoing signals
	"""
	var output = ""
	var indent = get_indent(depth)

	# Format outgoing signals (signals this node emits)
	if not categorized_signals.outgoing.is_empty():
		output += indent + EMITS_HEADER
		output += _format_outgoing_signals(categorized_signals.outgoing, indent)

	# Format incoming signals (signals connected to this node)
	if not categorized_signals.incoming.is_empty():
		output += indent + RECEIVES_HEADER
		output += _format_incoming_signals(categorized_signals.incoming, indent)

	return output

func _format_outgoing_signals(outgoing_signals: Array, indent: String) -> String:
	"""
	Formats outgoing signals (signals the node emits).

	Args:
		outgoing_signals: Array of outgoing signal information
		indent: Base indentation string for the node

	Returns:
		Formatted string of outgoing signals
	"""
	var output = ""

	for signal_info in outgoing_signals:
		output += indent + BULLET_POINT + signal_info.signal_name + DIRECTION_ARROW + signal_info.target

		# Add method if available
		if signal_info.method:
			output += DOT_SEPARATOR + signal_info.method

		output += "\n"

	return output

func _format_incoming_signals(incoming_signals: Array, indent: String) -> String:
	"""
	Formats incoming signals (signals connected to the node).

	Args:
		incoming_signals: Array of incoming signal information
		indent: Base indentation string for the node

	Returns:
		Formatted string of incoming signals
	"""
	var output = ""

	for signal_info in incoming_signals:
		output += indent + BULLET_POINT + signal_info.source + DOT_SEPARATOR + signal_info.signal_name + DIRECTION_ARROW

		# Add method if available
		if signal_info.method:
			output += signal_info.method

		output += "\n"

	return output
