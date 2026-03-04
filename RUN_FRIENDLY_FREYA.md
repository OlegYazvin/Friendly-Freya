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

## Required Before Deploy

Run the size/animation/layout guardrail checks before every deploy:

```sh
./scripts/predeploy_size_checks.sh
```

This runs headless smoke + targeted validations, including dog/building relative-size checks.
