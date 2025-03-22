@tool
extends RefCounted
class_name ScriptLoader

"""
ScriptLoader provides robust script loading and instantiation utilities
to handle common issues with GDScript class loading and instantiation.
"""

## Singleton pattern
static var _instance = null

static func get_instance():
    if not _instance:
        _instance = ScriptLoader.new()
    return _instance

## Script loading methods

# Load and instantiate a script robustly
static func instantiate(script_path: String, base_type: String = "RefCounted") -> Object:
    # First try the standard approach
    var script = preload_script(script_path)
    if not script:
        push_error("ScriptLoader: Failed to load script at " + script_path)
        return null

    # Create the base object
    var base_object = _create_base_object(base_type)
    if not base_object:
        push_error("ScriptLoader: Failed to create base object of type " + base_type)
        return null

    # Attach the script using set_script
    base_object.set_script(script)

    # Verify the script was attached properly
    if not _verify_script_methods(base_object, script):
        push_error("ScriptLoader: Script methods not properly attached, trying alternative approach")
        return _instantiate_alternative(script_path, base_type)

    return base_object

# Alternative instantiation method for troublesome scripts
static func _instantiate_alternative(script_path: String, base_type: String = "RefCounted") -> Object:
    var script_res = ResourceLoader.load(script_path)
    if not script_res:
        return null

    # Try direct instantiation
    if script_res.can_instantiate():
        return script_res.new()

    # If direct instantiation failed, try creating a new instance the manual way
    var base_object = _create_base_object(base_type)
    if not base_object:
        return null

    # Apply script in a different way
    base_object.set_script(script_res)

    # Force script resource to reload to ensure methods are attached
    script_res.reload()

    return base_object

# Verify that script methods are properly attached
static func _verify_script_methods(object: Object, script: Script) -> bool:
    # Get all methods from the script
    var script_methods = []

    # Try to get method list from script
    for method in script.get_script_method_list():
        if method is Dictionary and method.has("name"):
            script_methods.append(method.name)

    # If no methods found but script exists, consider it a success
    if script_methods.is_empty():
        return true

    # Check if at least one method exists on the object
    for method in script_methods:
        if object.has_method(method):
            return true

    # If we got here, methods weren't properly attached
    return false

# Preload a script resource
static func preload_script(script_path: String) -> Script:
    if ResourceLoader.exists(script_path):
        var script = ResourceLoader.load(script_path)
        if script is Script:
            return script

    return null

# Create a base object of specified type
static func _create_base_object(type_name: String) -> Object:
    match type_name:
        "RefCounted":
            return RefCounted.new()
        "Node":
            return Node.new()
        "Control":
            return Control.new()
        "Resource":
            return Resource.new()
        "Object":
            return Object.new()
        _:
            # Try to instantiate class by name
            if ClassDB.class_exists(type_name):
                if ClassDB.can_instantiate(type_name):
                    return ClassDB.instantiate(type_name)

    push_error("ScriptLoader: Unknown base type " + type_name)
    return null

# Create a dictionary of script instances from a directory
static func load_scripts_from_dir(dir_path: String, base_type: String = "RefCounted") -> Dictionary:
    var result = {}
    var dir = DirAccess.open(dir_path)

    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()

        while file_name != "":
            if file_name.ends_with(".gd") and not dir.current_is_dir():
                var script_path = dir_path.path_join(file_name)
                var instance = instantiate(script_path, base_type)

                if instance:
                    # Use filename without extension as key
                    var key = file_name.get_basename()
                    result[key] = instance

            file_name = dir.get_next()
    else:
        push_error("ScriptLoader: Failed to access directory " + dir_path)

    return result
