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
