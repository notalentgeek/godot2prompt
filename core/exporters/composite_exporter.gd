@tool
extends BaseExporter
class_name CompositeExporter

"""
CompositeExporter implements the Composite pattern to combine multiple exporters.
It aggregates output from each exporter to create a unified formatted output.
"""

# Properties
var _exporters: Array = []

func add_exporter(exporter: BaseExporter) -> void:
	"""
	Adds an exporter to the composition.

	Args:
		exporter: The BaseExporter instance to add to the collection
	"""
	_exporters.append(exporter)

func generate_output(node_data: NodeData) -> String:
	"""
	Generates output by combining results from all child exporters.
	Overrides the base implementation to implement the Composite pattern.

	Args:
		node_data: The NodeData object to process

	Returns:
		A string containing the combined output from all exporters
	"""
	var output = format_node_line(node_data)

	# Add content from all registered exporters
	output += _generate_content_from_exporters(node_data)

	# Process all children recursively
	output += _process_children(node_data)

	return output

func format_node_content(node_data: NodeData) -> String:
	"""
	The composite itself doesn't add content directly.
	This is intentionally empty as content comes from child exporters.

	Args:
		node_data: The NodeData object

	Returns:
		An empty string as the composite adds no direct content
	"""
	return ""

# Private Methods

func _generate_content_from_exporters(node_data: NodeData) -> String:
	"""
	Collects and concatenates content from all registered exporters.

	Args:
		node_data: The NodeData object to format

	Returns:
		A string containing the combined content from all exporters
	"""
	var content = ""

	for exporter in _exporters:
		content += exporter.format_node_content(node_data)

	return content

func _process_children(node_data: NodeData) -> String:
	"""
	Recursively processes all children of the given node using the same
	exporter configuration.

	Args:
		node_data: The NodeData object whose children should be processed

	Returns:
		A string containing the combined output from all children
	"""
	var children_output = ""

	for child in node_data.children:
		# Create a new composite for each child with the same exporters
		var child_composite = CompositeExporter.new()

		# Add all the same exporters to the child composite
		for exporter in _exporters:
			child_composite.add_exporter(exporter)

		# Generate output for the child using the child's composite
		children_output += child_composite.generate_output(child)

	return children_output
