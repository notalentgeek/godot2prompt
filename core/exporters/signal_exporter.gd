@tool
extends "res://addons/godot2prompt/core/exporters/base_exporter.gd"

# Signal exporter - adds connected signals information
# Shows signal connections between nodes for better understanding of scene interactions

# Format the signals content for a node
func format_node_content(node_data) -> String:
	var output = ""
	var indent = get_indent(node_data.depth)

	# Add signals if available
	if node_data.signals and node_data.signals.size() > 0:
		# Group signals by direction
		var outgoing_signals = []
		var incoming_signals = []

		for signal_info in node_data.signals:
			if "direction" in signal_info and signal_info.direction == "incoming":
				incoming_signals.append(signal_info)
			else:
				outgoing_signals.append(signal_info)

		# Format outgoing signals (signals this node emits)
		if outgoing_signals.size() > 0:
			output += indent + "  Emits Signals:\n"
			for signal_info in outgoing_signals:
				output += indent + "    • " + signal_info.signal_name + " → " + signal_info.target
				if signal_info.method:
					output += "." + signal_info.method
				output += "\n"

		# Format incoming signals (signals connected to this node)
		if incoming_signals.size() > 0:
			output += indent + "  Receives Signals:\n"
			for signal_info in incoming_signals:
				output += indent + "    • " + signal_info.source + "." + signal_info.signal_name + " → "
				if signal_info.method:
					output += signal_info.method
				output += "\n"

	return output
