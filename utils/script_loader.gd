@tool
extends RefCounted
class_name ScriptLoader

"""
Utility class for robustly loading and instantiating scripts
with proper error handling and fallback mechanisms.
"""

static func load_script(path: String) -> GDScript:
    """
    Loads a script from a path with error checking.

    Args:
        path: Path to the script to load

    Returns:
        The loaded GDScript or null if loading failed
    """
    var script = load(path)
    if script == null:
        push_error("ScriptLoader: Failed to load script from: " + path)
        return null

    if not script is GDScript:
        push_error("ScriptLoader: Loaded resource is not a GDScript: " + path)
        return null

    return script

static func instantiate_script(path: String) -> Object:
    """
    Loads a script from a path and instantiates it with proper error handling.

    Args:
        path: Path to the script to load and instantiate

    Returns:
        New instance of the script or null if instantiation failed
    """
    var script = load_script(path)
    if script == null:
        return null

    # Try standard instantiation first
    var instance = null

    if script.can_instantiate():
        # GDScript doesn't have try/except, so we can't catch instantiation errors directly
        # Using a simple approach here
        instance = script.new()
        if instance == null:
            push_error("ScriptLoader: Failed to instantiate script: " + path)

    # If standard instantiation failed, try alternative approach
    if instance == null:
        instance = RefCounted.new()
        if instance.set_script(script):
            print("ScriptLoader: Successfully set script using alternative method: " + path)
        else:
            push_error("ScriptLoader: Failed to set script on instance: " + path)
            return null

    return instance
