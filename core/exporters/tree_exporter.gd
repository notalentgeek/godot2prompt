@tool
extends "res://addons/godot2prompt/core/exporters/base_exporter.gd"

# Tree exporter - provides basic tree structure formatting
# This is the base visualization format that other exporters may enhance

# For tree exporter, we don't need to add any content beyond the node line,
# so we can leave format_node_content empty or override it to return an empty string
func format_node_content(node_data) -> String:
	return ""
