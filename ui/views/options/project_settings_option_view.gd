@tool
extends BaseOptionView
class_name ProjectSettingsOptionView

"""
ProjectSettingsOptionView provides the UI for the project settings option.
It displays the option checkbox and the list of project setting categories.
"""

# UI components
var categories_container: VBoxContainer = null
var categories_label: Label = null
var categories_scroll: ScrollContainer = null
var category_checkboxes: Dictionary = {} # Dictionary of category name to checkbox
var settings_categories_container: VBoxContainer = null

# Get typed access to the model
var project_settings_model: ProjectSettingsOptionModel:
	get: return model as ProjectSettingsOptionModel

func _init():
	"""
	Initialize with a new project settings option model.
	"""
	super._init(ProjectSettingsOptionModel.new())

	# Connect to model signals
	project_settings_model.categories_updated.connect(_on_categories_updated)

func _setup_control() -> void:
	"""
	Setup the UI controls for the project settings option.
	"""
	# Create categories container
	categories_container = VBoxContainer.new()
	categories_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	categories_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Create categories label (initially hidden)
	categories_label = Label.new()
	categories_label.text = "Project Settings Categories:"
	categories_label.visible = project_settings_model.is_enabled()
	categories_container.add_child(categories_label)

	# Create scrollable container for categories (initially hidden)
	categories_scroll = ScrollContainer.new()
	categories_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	categories_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	categories_scroll.visible = project_settings_model.is_enabled()
	categories_container.add_child(categories_scroll)

	# Create the container for the checkboxes
	settings_categories_container = VBoxContainer.new()
	settings_categories_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	categories_scroll.add_child(settings_categories_container)

	# Connect checkbox toggled signal
	checkbox.toggled.connect(_on_project_settings_toggled)

func get_categories_container() -> Control:
	"""
	Get the container for categories to add to the main options tab.

	Returns:
		The categories container control
	"""
	return categories_container

func get_enabled_categories() -> Array:
	"""
	Get a list of all enabled categories.

	Returns:
		Array of enabled category names
	"""
	return project_settings_model.get_enabled_categories()

func _on_project_settings_toggled(button_pressed: bool) -> void:
	"""
	Handle when the project settings checkbox is toggled.

	Args:
		button_pressed: The new state of the checkbox
	"""
	# Show/hide the categories section based on checkbox state
	categories_label.visible = button_pressed
	categories_scroll.visible = button_pressed

func _on_categories_updated() -> void:
	"""
	Update the UI when categories are loaded or changed.
	"""
	# Clear existing categories
	for child in settings_categories_container.get_children():
		child.queue_free()

	category_checkboxes.clear()

	# Get categories from the model
	var categories = project_settings_model.get_categories()

	# Create a checkbox for each category
	for category in categories:
		var checkbox = CheckBox.new()
		checkbox.text = project_settings_model.format_category_name(category)
		checkbox.set_pressed(project_settings_model.get_category_state(category))

		# Connect the checkbox to update the model
		checkbox.toggled.connect(_on_category_toggled.bind(category))

		settings_categories_container.add_child(checkbox)

		# Store reference to checkbox
		category_checkboxes[category] = checkbox

func _on_category_toggled(enabled: bool, category: String) -> void:
	"""
	Update the model when a category checkbox is toggled.

	Args:
		enabled: The new state of the checkbox
		category: The category name
	"""
	project_settings_model.set_category_state(category, enabled)

func _on_model_state_changed(is_enabled: bool) -> void:
	"""
	Override parent method to also update categories visibility.

	Args:
		is_enabled: The new state from the model
	"""
	# Call parent implementation first
	super._on_model_state_changed(is_enabled)

	# Update categories visibility
	if categories_label and categories_scroll:
		categories_label.visible = is_enabled
		categories_scroll.visible = is_enabled
