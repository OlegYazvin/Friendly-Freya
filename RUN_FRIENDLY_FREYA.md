# Run Friendly Freya

Last verified: March 4, 2026

## Working launch command (this environment)

Use host Flatpak (not sandbox `flatpak`):

```sh
host-spawn flatpak run org.godotengine.Godot --path "/data/projects/Friendly Freya/godot"
```

## Why this command

- `flatpak` is not available directly in the sandbox shell.
- `host-spawn flatpak` works and successfully launches Godot/Friendly Freya.

## Verify it launched

```sh
host-spawn flatpak ps
```

You should see `org.godotengine.Godot` in the list.
