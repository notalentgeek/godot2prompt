@tool
extends BaseExporter
class_name TreeExporter

"""
TreeExporter provides the base tree structure formatting for a node hierarchy.
It focuses solely on the hierarchical organization of nodes, serving as the
foundation that other exporters can enhance with additional details.
"""

func format_node_content(node_data: NodeData) -> String:
	"""
	Formats additional content for a node.
	For the TreeExporter, no additional content is needed beyond the basic node
	identification line that is already handled by the BaseExporter.

	Args:
		node_data: The NodeData object to process

	Returns:
		An empty string as this exporter only handles basic tree structure
	"""
	return ""
