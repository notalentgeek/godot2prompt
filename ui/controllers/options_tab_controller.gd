@tool
extends BaseController
class_name OptionsTabController

"""
OptionsTabController manages the options tab of the export dialog.
It handles the various export options like scripts, properties, signals, etc.
"""

# Constants - Paths
const OPTIONS_TAB_MODEL_PATH: String = "res://addons/godot2prompt/ui/models/options_tab_model.gd"

# Option views
var _error_option_view = null
var _project_settings_option_view = null
var _properties_option_view = null
var _screenshot_option_view = null
var _scripts_option_view = null
var _signals_option_view = null

func _init():
    """
    Initialize the controller with model but without view.
    View will be created in create_options_tab() method.
    """
    super._init()

    # Only initialize the model, view will be created later
    var OptionsTabModel = load(OPTIONS_TAB_MODEL_PATH)
    _model = OptionsTabModel.new()

    # Initialize option views
    _initialize_option_views()

func _initialize_option_views():
    """
    Initialize the various option views.
    """
    # Load view classes
    var ErrorOptionView = load("res://addons/godot2prompt/ui/views/options/error_option_view.gd")
    var ProjectSettingsOptionView = load("res://addons/godot2prompt/ui/views/options/project_settings_option_view.gd")
    var PropertiesOptionView = load("res://addons/godot2prompt/ui/views/options/properties_option_view.gd")
    var ScreenshotOptionView = load("res://addons/godot2prompt/ui/views/options/screenshot_option_view.gd")
    var ScriptsOptionView = load("res://addons/godot2prompt/ui/views/options/scripts_option_view.gd")
    var SignalsOptionView = load("res://addons/godot2prompt/ui/views/options/signals_option_view.gd")

    # Create view instances
    # We'll use try/catch for each to handle different constructor signatures

    # Error option view
    _error_option_view = ErrorOptionView.new()

    # Project settings option view requires model parameter
    var ProjectSettingsOptionModel = load("res://addons/godot2prompt/ui/models/options/project_settings_option_model.gd")
    var project_settings_model = ProjectSettingsOptionModel.new()
    _project_settings_option_view = ProjectSettingsOptionView.new(project_settings_model)

    # Other option views - without model parameters
    _properties_option_view = PropertiesOptionView.new()
    _screenshot_option_view = ScreenshotOptionView.new()
    _scripts_option_view = ScriptsOptionView.new()
    _signals_option_view = SignalsOptionView.new()

    # Note: We removed the add_option_view calls as they don't exist in the model

func create_options_tab() -> Control:
    """
    Create the options tab control manually without relying on view.

    Returns:
        A Control node representing the options tab
    """
    # Create a container for options
    var options_tab = VBoxContainer.new()
    options_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    options_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL

    # Add label for options section
    var options_label = Label.new()
    options_label.text = "Export options:"
    options_tab.add_child(options_label)

    # Create options container (for checkboxes)
    var options_container = VBoxContainer.new()
    options_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    options_tab.add_child(options_container)

    # Add options controls to container
    if _error_option_view:
        var error_control = _error_option_view.create_control()
        if error_control:
            options_container.add_child(error_control)

    if _project_settings_option_view:
        var project_settings_control = _project_settings_option_view.create_control()
        if project_settings_control:
            options_container.add_child(project_settings_control)

    if _properties_option_view:
        var properties_control = _properties_option_view.create_control()
        if properties_control:
            options_container.add_child(properties_control)

    if _screenshot_option_view:
        var screenshot_control = _screenshot_option_view.create_control()
        if screenshot_control:
            options_container.add_child(screenshot_control)

    if _scripts_option_view:
        var scripts_control = _scripts_option_view.create_control()
        if scripts_control:
            options_container.add_child(scripts_control)

    if _signals_option_view:
        var signals_control = _signals_option_view.create_control()
        if signals_control:
            options_container.add_child(signals_control)

    # Add categories container after all options
    if _project_settings_option_view:
        var categories_container = _project_settings_option_view.get_categories_container()
        if categories_container:
            options_container.add_child(categories_container)

    return options_tab

func get_export_options() -> Dictionary:
    """
    Get a dictionary of all export options and their values.

    Returns:
        Dictionary with export option values
    """
    var options = {
        "include_errors": false,
        "include_project_settings": false,
        "include_properties": false,
        "include_screenshot": false,
        "include_scripts": false,
        "include_signals": false,
        "enabled_setting_categories": []
    }

    if _error_option_view and _error_option_view.has_method("is_enabled"):
        options["include_errors"] = _error_option_view.is_enabled()

    if _project_settings_option_view:
        if _project_settings_option_view.has_method("is_enabled"):
            options["include_project_settings"] = _project_settings_option_view.is_enabled()

        if _project_settings_option_view.has_method("get_enabled_categories"):
            options["enabled_setting_categories"] = _project_settings_option_view.get_enabled_categories()

    if _properties_option_view and _properties_option_view.has_method("is_enabled"):
        options["include_properties"] = _properties_option_view.is_enabled()

    if _screenshot_option_view and _screenshot_option_view.has_method("is_enabled"):
        options["include_screenshot"] = _screenshot_option_view.is_enabled()

    if _scripts_option_view and _scripts_option_view.has_method("is_enabled"):
        options["include_scripts"] = _scripts_option_view.is_enabled()

    if _signals_option_view and _signals_option_view.has_method("is_enabled"):
        options["include_signals"] = _signals_option_view.is_enabled()

    return options

func populate_settings_categories() -> void:
    """
    Trigger loading of project settings categories.
    """
    # Force the model to load categories
    if _project_settings_option_view and _project_settings_option_view.has_method("load_categories"):
        _project_settings_option_view.load_categories()
    elif _project_settings_option_view and _project_settings_option_view.project_settings_model:
        # Try to load through the model
        _project_settings_option_view.project_settings_model.load_categories()
