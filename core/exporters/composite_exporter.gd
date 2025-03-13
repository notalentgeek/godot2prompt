@tool
extends "res://addons/godot2prompt/core/exporters/base_exporter.gd"

# Composite Exporter
# Combines multiple exporters to create a unified output

var exporters = []

# Add an exporter to the composition
func add_exporter(exporter):
	exporters.append(exporter)

# Override to use the composition pattern
func generate_output(node_data) -> String:
	var output = format_node_line(node_data)
	
	# Apply all exporters' content formatting
	for exporter in exporters:
		output += exporter.format_node_content(node_data)
	
	# Process children
	for child in node_data.children:
		# Create a new composite for each child with the same exporters
		var child_composite = get_script().new()
		for exporter in exporters:
			child_composite.add_exporter(exporter)
		
		# Generate output for the child using the child's composite
		output += child_composite.generate_output(child)
	
	return output

# We don't need to add content directly in the composite
func format_node_content(node_data) -> String:
	return ""
