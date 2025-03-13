@tool
extends "res://addons/ascii_export/core/exporters/base_exporter.gd"

# Code exporter - enhances the tree structure with script code
# This builds upon the basic tree visualization by adding code blocks

func generate_output(node_data) -> String:
    return _format_node_with_scripts(node_data)

# Format a single node with script code and its children
func _format_node_with_scripts(node_data) -> String:
    var indent = get_indent(node_data.depth)
    var output = indent + "- " + node_data.name + " (" + node_data.type + ")\n"

    # Add script code if available
    if node_data.script_code and node_data.script_code.length() > 0:
        var script_text = "```gdscript\n" + node_data.script_code + "\n```\n"
        output += indent + "  " + script_text.replace("\n", "\n" + indent + "  ") + "\n"

    # Process children
    for child in node_data.children:
        output += _format_node_with_scripts(child)

    return output
