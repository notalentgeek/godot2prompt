# Godot2Prompt

<img src="icon.svg" width="128" height="128" align="left" style="margin-right: 20px;">

**Godot2Prompt** is a specialized Godot addon that transforms your scene hierarchies into LLM-ready prompts, creating perfectly formatted context for AI assistance with your Godot projects.

<br clear="left"/>

## Features

- **Scene Hierarchy Export**: Converts your Godot scenes into clearly formatted text representations
- **Script Inclusion**: Optionally embeds the GDScript code attached to nodes
- **Node Properties**: Extracts and includes relevant properties for each node type
- **Signal Connections**: Shows how nodes are connected through signals
- **Error Context**: Includes recent error messages to help debug issues
- **Project Settings**: Exports relevant project configuration for better context
- **Node Selection**: Choose which part of your scene to export
- **LLM Optimized**: Formats output specifically for language model context windows
- **Modular Design**: Well-organized codebase that's easy to extend with new exporters
- **Visual Progress Tracking**: Progress bar displays export status in real-time

## Installation

1. Download or clone this repository
2. Copy the `addons/godot2prompt` directory into your Godot project's `addons` folder
3. Enable the plugin in Godot by going to Project → Project Settings → Plugins
4. Restart Godot if necessary

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
6. Once complete, your scene data will be exported to a text file at the project root

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

## Compatibility

Tested and working with Godot 4.4.

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests to enhance the functionality of this plugin.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
