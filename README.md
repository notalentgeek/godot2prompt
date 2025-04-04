# Godot2Prompt

<img src="icon.svg" width="128" height="128" align="left" style="margin-right: 20px;">

**Godot2Prompt** is a specialized Godot addon that transforms your scene hierarchies into LLM-ready prompts, creating perfectly formatted context for AI assistance with your Godot projects.

<br clear="left"/>

## Features

- **Scene Hierarchy Export**: Converts your Godot scenes into clearly formatted text representations
- **Script Inclusion**: Embeds the GDScript code attached to nodes
- **Node Properties**: Extracts and includes relevant properties for each node type
- **Signal Connections**: Shows how nodes are connected through signals
- **Error Context**: Includes recent error messages to help debug issues
- **Project Settings**: Exports relevant project configuration for better context
- **Node Selection**: Choose which part of your scene to export
- **Screenshot Capture**: Includes visual representation of your scene
- **LLM Optimized**: Formats output specifically for language model context windows
- **Modular Design**: Well-organized codebase that's easy to extend with new exporters
- **Visual Progress Tracking**: Progress bar displays export status in real-time

## Installation

1. Download or clone this repository
2. Copy the entire repository into your Godot project's `addons` folder as `addons/godot2prompt`
3. Enable the plugin in Godot by going to Project → Project Settings → Plugins
4. Restart Godot editor

## Usage

1. Open the Godot scene you want to export
2. Navigate to Project → Tools → Scene to Prompt
3. Select which nodes to include from your scene hierarchy
4. Choose your export options:
   - Whether to include script code
   - Whether to include node properties
   - Whether to include signal connections
   - Whether to include error context
   - Whether to include project settings
   - Whether to include a visual screenshot
5. Click "Export" and monitor the progress via the progress bar
6. Once complete, your scene data will be exported to a text file at the specified location

## Quick Export

For faster workflows, you can also use the "Quick Scene Export with Screenshot" option from the Tools menu. This will export your entire scene with default settings and automatically include a screenshot.

## Example Outputs

### Basic Tree Export (Only Scene Hierarchy)

```
- Main (Node2D)
  - CardManager (Node2D)
    - Card (Node2D)
      - CardImage (Sprite2D)
      - Area2D (Area2D)
        - CollisionShape2D (CollisionShape2D)
    - Card2 (Node2D)
      - CardImage (Sprite2D)
      - Area2D (Area2D)
        - CollisionShape2D (CollisionShape2D)
  - CardSlot (Node2D)
    - CardSlotImage (Sprite2D)
    - Area2D (Area2D)
      - CollisionShape2D (CollisionShape2D)
```

### Complete Export (All Options Selected)

```
- CardManager (Node2D)
    • Position: (0.0, 0.0)
    • Scale: (1.0, 1.0)
    • Visible: true
  Emits Signals:
    • visibility_changed → SceneTreeEditor::_node_visibility_changed
    • child_order_changed → Viewport::canvas_parent_mark_dirty

  Script:
  extends Node2D

  var COLLISION_MASK_CARD = 1
  var COLLISION_MASK_CARD_SLOT = 2

  var card_being_dragged
  var is_hovering_on_card

  func _ready() -> void:
    screen_size = get_viewport_rect().size

  func _process(_delta: float) -> void:
    if card_being_dragged:
      var mouse_pos = get_global_mouse_position()
      card_being_dragged.position = Vector2(
        clamp(mouse_pos.x, 0, screen_size.x),
        clamp(mouse_pos.y, 0, screen_size.y)
      )

  # Additional methods...

  - Card (Node2D)
      • Position: (806.0, 208.0)
    Emits Signals:
      • hovered → Custom signal
      • hovered_off → Custom signal

    - CardImage (Sprite2D)
    - Area2D (Area2D)
      - CollisionShape2D (CollisionShape2D)
          • Shape Type: RectangleShape2D

Recent Errors:
- Sample error: Missing node reference in PlayerController.gd:34
- Sample error: Type mismatch in Enemy.gd:127 - Expected int but got String

# Screenshot
A screenshot of the current scene has been saved at: `res://scene_screenshot.png`
```

## Project Structure

The plugin follows a modular architecture:

```
godot2prompt/
├── core/                 # Core functionality
│   ├── data/             # Data structures
│   ├── exporters/        # Export functionality for different data types
│   ├── extractors/       # Extract information from Godot nodes
│   ├── io/               # File system operations
│   └── managers/         # Coordinate plugin operations
├── ui/                   # User interface components
│   ├── controllers/      # Handle UI logic
│   ├── models/           # Store UI data
│   └── views/            # UI elements
└── utils/                # Utility functions
```

## Compatibility

Tested and working with Godot 4.x. If you encounter any issues with specific Godot versions, please report them in the issues section.

## Contributing

Contributions are welcome! Here's how you can help improve Godot2Prompt:

### Getting Started

1. Fork the repository
2. Create a new branch for your feature: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Submit a pull request

### Types of Contributions Needed

- **New Exporters**: Add support for exporting additional node data
- **UI Improvements**: Enhance the user interface and experience
- **Bug Fixes**: Fix issues in the existing codebase
- **Documentation**: Improve this README or add code comments
- **Performance Optimizations**: Make the plugin faster and more efficient

### Contribution Guidelines

- Follow the existing code style and architecture
- Write descriptive commit messages
- Add comments to explain complex code sections
- Test your changes thoroughly before submitting
- Update the README if you add new features or change existing ones

## Development Tutorials

### Creating a New Exporter

Exporters are responsible for formatting and exporting specific types of data from the scene. Here's how to create a new one:

#### Step 1: Create the Exporter Script

Create a new file in `core/exporters/` (e.g., `my_custom_exporter.gd`):

```gdscript
@tool
extends "res://addons/godot2prompt/core/exporters/base_exporter.gd"

class_name MyCustomExporter

func _init():
    super._init()

func export_data(node_data):
    var output = ""

    # Process the node_data and format it accordingly
    output += "# Custom Info for " + node_data.name + "\n"
    output += "  • Custom field: " + str(node_data.get_custom_data()) + "\n"

    return output
```

#### Step 2: Register Your Exporter

Modify the `export_manager.gd` to include your new exporter:

```gdscript
# In export_manager.gd
func _setup_exporters():
    var composite = CompositeExporter.new()
    composite.add_exporter(TreeExporter.new())
    composite.add_exporter(PropertiesExporter.new())
    composite.add_exporter(SignalExporter.new())
    composite.add_exporter(CodeExporter.new())
    composite.add_exporter(MyCustomExporter.new()) # Add your exporter here

    return composite
```

#### Step 3: "Hello World" Example

The following simple exporter will add a "Hello World" message to each exported node:

```gdscript
@tool
extends "res://addons/godot2prompt/core/exporters/base_exporter.gd"

class_name HelloWorldExporter

func _init():
    super._init()

func export_data(node_data):
    return "  Hello World from " + node_data.name + "!\n"
```

#### LLM Prompt for Exporter Development

Use this prompt to get AI assistance with developing exporters:

```
I'm developing a new exporter for the Godot2Prompt plugin. I want to export [specific data type]
from Godot nodes and format it as [desired format].

Here's the base exporter class structure:
'''gdscript
@tool
extends "res://addons/godot2prompt/core/exporters/base_exporter.gd"

class_name BaseExporter

func _init():
    pass

func export_data(node_data):
    return ""
'''

Can you help me implement the export_data method to process and format [specific data type]?
```

### Creating a New Extractor

Extractors gather specific types of data from Godot nodes. Here's how to create a new one:

#### Step 1: Create the Extractor Script

Create a new file in `core/extractors/` (e.g., `my_custom_extractor.gd`):

```gdscript
@tool
extends RefCounted

class_name MyCustomExtractor

func extract_from_node(node: Node) -> Dictionary:
    var result = {}

    # Your extraction logic here
    # Example: Extract custom metadata
    if node.has_meta("custom_data"):
        result["custom_data"] = node.get_meta("custom_data")

    return result
```

#### Step 2: Use the Extractor in SceneManager

Modify `scene_manager.gd` to use your extractor:

```gdscript
# In scene_manager.gd
var _custom_extractor = MyCustomExtractor.new()

func _process_node(node: Node) -> NodeData:
    var node_data = NodeData.new()
    node_data.name = node.name
    node_data.type = node.get_class()

    # Use your custom extractor
    var custom_data = _custom_extractor.extract_from_node(node)
    node_data.set_custom_data(custom_data)

    return node_data
```

#### Step 3: "Hello World" Example

Here's a simple extractor that adds a "hello" field to each node:

```gdscript
@tool
extends RefCounted

class_name HelloExtractor

func extract_from_node(node: Node) -> Dictionary:
    return {
        "hello": "Hello from " + node.name
    }
```

#### LLM Prompt for Extractor Development

Use this prompt to get AI assistance with developing extractors:

```
I'm developing a new extractor for the Godot2Prompt plugin. I need to extract [specific information]
from Godot nodes.

Here's the basic structure I'm working with:
'''gdscript
@tool
extends RefCounted

class_name MyExtractor

func extract_from_node(node: Node) -> Dictionary:
    var result = {}

    # Extraction logic here

    return result
'''

How can I implement the extraction logic to gather [specific information] from different node types?
```

### Adding a UI Element

The UI follows an MVC pattern. Here's how to add a new UI element:

#### Step 1: Create Model, View, and Controller Files

Create three new files:

1. Model (`ui/models/my_feature_model.gd`):
```gdscript
@tool
extends "res://addons/godot2prompt/ui/models/base_model.gd"

class_name MyFeatureModel

signal value_changed(new_value)

var _value = false

func get_value() -> bool:
    return _value

func set_value(new_value: bool):
    if _value != new_value:
        _value = new_value
        emit_signal("value_changed", _value)
```

2. View (`ui/views/my_feature_view.gd`):
```gdscript
@tool
extends Control

class_name MyFeatureView

signal toggled(is_checked)

@onready var checkbox = $CheckBox

func _ready():
    checkbox.connect("toggled", _on_checkbox_toggled)

func _on_checkbox_toggled(is_checked):
    emit_signal("toggled", is_checked)

func set_checked(is_checked):
    checkbox.button_pressed = is_checked
```

3. Controller (`ui/controllers/my_feature_controller.gd`):
```gdscript
@tool
extends "res://addons/godot2prompt/ui/controllers/base_controller.gd"

class_name MyFeatureController

var _model: MyFeatureModel
var _view: MyFeatureView

func _init(model: MyFeatureModel, view: MyFeatureView):
    _model = model
    _view = view

    # Connect signals
    _view.connect("toggled", _on_view_toggled)
    _model.connect("value_changed", _on_model_value_changed)

func _on_view_toggled(is_checked):
    _model.set_value(is_checked)

func _on_model_value_changed(new_value):
    _view.set_checked(new_value)
```

#### Step 2: Create the UI Scene

Create a new scene with a checkbox:
1. Create a new Control node
2. Add a CheckBox as a child
3. Attach the `my_feature_view.gd` script to the Control node
4. Save the scene as `my_feature.tscn`

#### Step 3: Integrate with Existing UI

Modify the main export dialog to include your new feature:

```gdscript
# In export_dialog_controller.gd
var _my_feature_model = MyFeatureModel.new()
var _my_feature_view = load("res://addons/godot2prompt/ui/views/my_feature.tscn").instance()
var _my_feature_controller = MyFeatureController.new(_my_feature_model, _my_feature_view)

func _setup_ui():
    # Add your view to the options container
    _view.get_node("OptionsContainer").add_child(_my_feature_view)
```

#### Step 4: "Hello World" Example

Here's a simple checkbox UI element that displays "Hello World" when checked:

```gdscript
# HelloWorldView.gd
@tool
extends Control

@onready var checkbox = $CheckBox
@onready var label = $Label

func _ready():
    checkbox.connect("toggled", _on_checkbox_toggled)
    label.visible = false

func _on_checkbox_toggled(is_checked):
    label.visible = is_checked
```

The scene structure:
- Control (with HelloWorldView.gd attached)
  - CheckBox (text: "Show Hello World")
  - Label (text: "Hello World!", visible: false)

#### LLM Prompt for UI Development

Use this prompt to get AI assistance with developing UI elements:

```
I'm adding a new UI element to the Godot2Prompt plugin. I need to create a [describe UI element]
that allows users to [describe functionality].

The plugin uses an MVC pattern with:
- Model: Stores the data and business logic
- View: The visual elements and user interaction
- Controller: Connects the model and view

Can you help me implement the model, view, and controller scripts for this feature, and explain
how to create the scene in the Godot editor?
```

## Code Style Guidelines

To maintain code readability and consistency across the project, we recommend following these guidelines:

### Line Length
- **Recommended**: Keep code lines to 80 characters or less when possible
- This improves readability on split screens, code reviews, and terminal windows
- Not strictly mandatory, but highly encouraged for better code maintainability

### Code Formatting To-Do List
- [ ] Review existing code and identify files exceeding 80 characters per line
- [ ] Refactor long lines by:
  - Breaking chains of method calls into multiple lines
  - Moving long parameter lists to multiple lines
  - Simplifying complex expressions
  - Using appropriate variable names to reduce line length
- [ ] Set up your code editor to display a vertical ruler at 80 characters
- [ ] Consider using Godot's built-in code formatter with customized settings
- [ ] Update CI workflow to include optional line length warnings (not errors)

### Example of Good Formatting

```gdscript
# Instead of this:
func some_long_function_name(param1, param2, param3, param4, param5, param6, param7, param8):
    var result = some_object.do_something(param1, param2).then_do_something_else(param3, param4, param5)

# Prefer this:
func some_long_function_name(
    param1, param2, param3, param4,
    param5, param6, param7, param8
):
    var result = some_object.do_something(param1, param2)
        .then_do_something_else(
            param3, param4, param5
        )
```

These are guidelines rather than strict rules - the primary goal is to make the code more readable and maintainable for all contributors.

## Troubleshooting

If you encounter script loading issues, particularly with the `SignalsExtractor` class, refer to the embedded fallback implementation in the `SceneManager`. This issue is documented and handled automatically by the plugin.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
