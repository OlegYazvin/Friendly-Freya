# Friendly Freya (Godot 4 Migration)

This is the Godot-native version of Friendly Freya.

## Run (Linux Mint 21.3 with Flatpak Godot, OpenGL compatibility)

```bash
flatpak run org.godotengine.Godot --path ./godot
```

Project default renderer is set to `gl_compatibility` for Linux-native runs on this machine.

## Run (Windows 10/11)

If Godot is installed and on PATH:

```powershell
godot --path .\godot
```

Or open `godot/project.godot` from the Godot editor and press Play.

## Controls

- `WASD` / Arrow keys: move Freya (`Up` maps to up on screen)
- `Shift`: run
- `Q` / `E`: rotate camera
- `F`: eat nearby poop / pick up or drop stick
- `Space`: vomit when vomit meter is full

## Gameplay Systems Included

- Isometric overhead 3D camera with follow/zoom on Freya
- Freya (3-legged black Portuguese Water Dog style model)
- Hunger / Vomit / Social meters
- Bark socialization pulses when near other dogs
- Poop eating reduces hunger (lightly) and raises vomit meter
- Vomit puddles with irregular geometry
- Minimap in upper-right
- Subdivision layout with connected alleys and a north-corner dog park
- Roof occlusion handling with an indicator when Freya is hidden behind buildings

## Optional High-Quality Dog Models

- Put `.glb` dog models in `godot/assets/models/`
- Follow filename mapping in `godot/assets/models/README_MODELS.md`
- The game auto-loads those models for Freya/NPC dogs and falls back to built-in procedural dogs if none are present
