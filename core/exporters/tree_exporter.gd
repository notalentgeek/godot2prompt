@tool
extends "res://addons/godot2prompt/core/exporters/base_exporter.gd"

# Tree exporter - provides basic tree structure formatting
# This is the base visualization format that other exporters may enhance

func generate_output(node_data) -> String:
    return _format_node(node_data)

# Format a single node and its children
func _format_node(node_data) -> String:
    var indent = get_indent(node_data.depth)
    var output = indent + "- " + node_data.name + " (" + node_data.type + ")\n"

    # Process children
    for child in node_data.children:
        output += _format_node(child)

    return output
