# Run Friendly Freya

[Documentation hub](README.md) · [Codebase map](docs/CODEBASE_MAP.md) ·
[Godot overview and controls](godot/README_GODOT.md)

Last verified: September 1, 2026 with Godot `4.7.2.stable.flathub`.
The project declares the Godot `4.6` feature target in
[project.godot](godot/project.godot).

Run commands from the repository root unless a section says otherwise.

## Launch in This Codex Environment

Use host Flatpak (not sandbox `flatpak`):

```sh
host-spawn flatpak run org.godotengine.Godot --path "$PWD/godot"
```

The first screen should offer `Watch Intro` and `Skip To Game`.

Why `host-spawn` is required here:

- `flatpak` is not available directly in the sandbox shell.
- Godot and the X11 capture tools run on the host.
- The workspace path is shared with the host.

Verify the process:

```sh
host-spawn flatpak ps
```

You should see `org.godotengine.Godot` in the list.

Stop the current Godot process before a capture run or when explicitly requested:

```sh
host-spawn flatpak kill org.godotengine.Godot
```

## Other Environments

Linux with Flatpak available directly:

```sh
flatpak run org.godotengine.Godot --path "$PWD/godot"
```

Windows with Godot on `PATH`, from the repository root:

```powershell
godot --path .\godot
```

Alternatively, open `godot/project.godot` in the editor and press Play.

## Required Validation

Run the complete guardrail suite after gameplay, scene, timeline, startup, or
validation changes and before packaging/deploying:

```sh
./scripts/predeploy_size_checks.sh
```

It runs:

1. startup-choice route, focus, loadability, and selection-lock validation;
2. UFO intro scene/cast/dialogue/audio/Earth/fleet validation;
3. gameplay smoke and targeted validation, including the three bark pools and
   their no-repeat shuffle behavior, plus family-intro staging, dialogue,
   effects, exact audio mapping, and handoff checks.

Successful output includes `STARTUP_OK`, `INTRO_OK`, `SMOKE_OK`, `TARGET_OK`,
and `FAMILY_INTRO_OK`, followed by `Predeploy checks passed.`

A passing command is required evidence, but visual changes also require an
inspected deterministic capture.

## Visual Regression Captures

The capture scripts require host `wmctrl` and `xwd`, local `ffmpeg`, an X11
display, and no running `org.godotengine.Godot` process.

Regenerate all gameplay/world views:

```sh
./scripts/capture_visual_regressions.sh
```

Regenerate one gameplay/world view:

```sh
FREYA_CAPTURE_ONLY=home_inside ./scripts/capture_visual_regressions.sh
```

Regenerate all startup/UFO/family-intro views:

```sh
./scripts/capture_intro_regressions.sh
```

Regenerate one startup/intro view:

```sh
FREYA_INTRO_CAPTURE_ONLY=intro_09_family_pills ./scripts/capture_intro_regressions.sh
```

The checked-in outputs and accepted names are cataloged in
[visual_regressions/README.md](visual_regressions/README.md). Always open the
changed PNG and inspect composition, visibility, scale, and overlap.

## Release and Export

Windows releases use the tracked `Windows Desktop` preset in
`godot/export_presets.cfg` and Godot `4.7.2` editor/export templates. The export
contains `FriendlyFreya.exe` plus a separate `FriendlyFreya.pck`; players must
keep those files together, but do not need Godot installed.

To build locally after installing matching export templates:

```sh
./scripts/predeploy_size_checks.sh
./scripts/build_windows_release.sh v0.1.0
```

The build script verifies the executable and PCK, confirms the active CC0 dog
resource and all 24 runtime bark recordings are present, proves inactive model
references are absent, adds the player instructions and legal notices, creates
a ZIP, and writes its SHA-256 manifest under `dist/`.

Pushing a `v*` tag runs `.github/workflows/windows-release.yml`. That workflow
downloads checksum-pinned official Godot files, repeats the full project
validation and export, launches the package on `windows-latest`, and publishes
the ZIP and checksum only after the Windows smoke test passes. This repository
is private, so only people granted repository access can download its Release
assets.

Existing bundles under `Logs and Monitoring/` remain historical artifacts. Do
not describe or distribute them as current builds.

## Troubleshooting

### Capture says Godot is already running

Confirm the active process with `host-spawn flatpak ps`. Close the window or use
the explicit kill command above, then rerun the capture. Do not run captures
against an unrelated active Godot session.

### A capture cannot find the window

Confirm the game launches normally and that `wmctrl -lx` can see a window whose
class includes `Godot_Engine.Friendly Freya`. The scripts cannot capture in a
headless-only environment.

### Audio is missing

Check the exact file mapping and license record in
[godot/assets/audio/ATTRIBUTION.md](godot/assets/audio/ATTRIBUTION.md). Missing or
invalid audio must remain silent; never synthesize or select substitute audio.
The recorded conversational and excited-social trims can be reproduced from
their hash-checked source WAVs with `./scripts/build_bark_library.sh`.

### Documentation and runtime disagree

Use the source-of-truth order in [README.md](README.md#source-of-truth-order),
verify runtime behavior, and update the current reference alongside the fix.
