@tool
extends RefCounted

# Base class for all exporters
# This establishes the contract that all exporters must follow

# Virtual method that all exporters must implement
func generate_output(node_data) -> String:
    push_error("Base exporter's generate_output called - this method should be overridden")
    return ""

# Common utility methods that all exporters might need
func get_indent(depth: int) -> String:
    return "  ".repeat(depth)
