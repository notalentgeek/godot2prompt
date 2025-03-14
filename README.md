# Godot2Prompt

<img src="icon.svg" width="128" height="128" align="left" style="margin-right: 20px;">

**Godot2Prompt** is a specialized Godot addon that transforms your scene hierarchies into LLM-ready prompts, creating perfectly formatted context for AI assistance with your Godot projects.

<br clear="left"/>

## Features

- **Scene Hierarchy Export**: Converts your Godot scenes into clearly formatted text representations
- **Script Inclusion**: Optionally embeds the GDScript code attached to nodes
- **Node Properties**: Extracts and includes relevant properties for each node type
- **Signal Connections**: Shows how nodes are connected through signals
- **Node Selection**: Choose which part of your scene to export
- **LLM Optimized**: Formats output specifically for language model context windows
- **Modular Design**: Well-organized codebase that's easy to extend with new exporters

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
5. The hierarchy will be exported to `res://scene_hierarchy.txt`
6. Use this file as context for your LLM prompts when seeking AI assistance

## Example

When you export a scene with all options enabled, you'll get output like this:

```
- Main (Node)
  Signals:
    • Signal: ready → _on_ready
  - Player (CharacterBody2D)
    • Position: (100, 200)
    • Scale: (1, 1)
    • Rotation: 0
    • Visible: true
    • Collision Layer: 1
    • Collision Mask: 1
    Signals:
      • Signal: area_entered → Main._on_player_area_entered
    ```gdscript
    extends CharacterBody2D

    const SPEED = 300.0
    const JUMP_VELOCITY = -400.0

    func _physics_process(delta):
        # Add gravity
        if not is_on_floor():
            velocity.y += gravity * delta

        # Jump logic
        if Input.is_action_just_pressed("ui_accept") and is_on_floor():
            velocity.y = JUMP_VELOCITY

        # Get input direction
        var direction = Input.get_axis("ui_left", "ui_right")
        if direction:
            velocity.x = direction * SPEED
        else:
            velocity.x = move_toward(velocity.x, 0, SPEED)

        move_and_slide()
    ```
    - Sprite (Sprite2D)
      • Position: (0, 0)
      • Scale: (1, 1)
      • Visible: true
    - CollisionShape (CollisionShape2D)
      • Position: (0, 0)
      • Shape Type: RectangleShape2D
  - TileMap (TileMap)
  - UI (CanvasLayer)
    - Score (Label)
      • Text: "Score: 0"
      • Size: (100, 50)
      Signals:
        • Signal: text_changed → Main._on_score_changed
```

This formatted output can be copied directly into your prompt when asking an LLM for help with your Godot project.

## Why Use Godot2Prompt?

- **Clearer Communication**: Helps language models understand your project structure
- **Context Optimization**: Formats scene data to maximize useful information in the LLM context window
- **Time Saving**: Quickly generate exportable scene documentation
- **Better AI Responses**: Receive more accurate and relevant assistance from AI tools
- **Selective Export**: Export only the parts of your scene that are relevant to your question

## Extending

Godot2Prompt uses a modular architecture that makes it easy to add new exporters:

1. Create a new script in the `core/exporters/` directory
2. Make it extend `base_exporter.gd`
3. Implement the `format_node_content(node_data)` method
4. Update plugin.gd to use your new exporter

To add support for additional node types or properties:

1. Modify the `_extract_node_properties` method in `scene_processor.gd`
2. Add conditionals for your specific node types
3. Extract the relevant properties

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

Made with ❤️ for the Godot.
