# Friendly Freya Godot Project

[Documentation hub](../README.md) · [Run and validation](../RUN_FRIENDLY_FREYA.md) ·
[Codebase map](../docs/CODEBASE_MAP.md) · [Gameplay direction](../GAMEPLAY_AUDIT.md) ·
[Intro guide](../INTRO_CUTSCENE.md)

This directory is the authoritative Godot source for Friendly Freya. The
project targets Godot's `4.6` feature set and uses the OpenGL compatibility
renderer. See the run guide for the editor version last used to validate it.

The copies beneath `../Logs and Monitoring/` and any packaged `.exe`, `.pck`, or
archive are historical build artifacts, not editable source.

## Start the Project

Run commands from the repository root.

Linux with Flatpak available in the current shell:

```sh
flatpak run org.godotengine.Godot --path "$PWD/godot"
```

The Codex workspace needs `host-spawn`; use the exact command in the
[run guide](../RUN_FRIENDLY_FREYA.md#launch-in-this-codex-environment).

Windows with Godot on `PATH`:

```powershell
godot --path .\godot
```

Alternatively, open [project.godot](project.godot) in the editor and press Play.
The configured entry scene is `Startup.tscn`: choose `Watch Intro` or
`Skip To Game`. Its background is generated cinematic key art of the real
three-legged Freya in a Northbrook-inspired brick town-center streetscape.

## Controls

- Startup: choose `Watch Intro` or `Skip To Game`; `Watch Intro` has keyboard
  focus by default.
- Intro: `Space`, `Esc`, or the on-screen button skips to gameplay.
- `WASD` or Arrow keys: move Freya; `Shift`: run.
- `Q` / `E`: rotate the camera; mouse wheel: zoom.
- `F`: eat nearby food or bones, use Freya's permanent home bowl, or pick up a
  stick; `V`: drop a carried stick.
- Hold `C` near a dog: socialize at a Hunger cost. A possessed dog also raises
  Vomit; sustained socializing recruits a real dog into Freya's army.
- Hold `X` near a dog: expel an alien or scare a real dog away.
- Hold `R`: claim trees, light poles, hydrants, and mailboxes; weaken an alien
  building beside its wall; or search a nearby dumpster.
- `Space`: vomit when the Vomit meter is full.
- Hold `Tab`: show objectives and alien/building counts.
- `Esc` during gameplay: pause. `Watch Intro` replays the cut-scene and begins a
  fresh game when it finishes or is skipped.

The in-game pause menu is the closest player-facing source for controls. Input
bindings are configured in `main.gd` under `_configure_input` and
`_unhandled_input`.

## Implemented Gameplay at a Glance

- A selectable UFO intro leads into a twenty-beat family prologue staged in the
  actual generated map home. Gene drops his pills during abduction; after
  saving Ryah, Freya eats them, has a comic convulsion, and discovers her
  internal monologue. Freya then starts fully hungry, and an authored-bark
  thought prompt plus a pulsing bowl pointer keeps her inside until she eats.
- On Freya's first exit, three temporary dog walkers appear with leashed city
  dogs. Alien beams abduct the people, then the leashes clear and the dogs
  resume their normal autonomous behavior.
- An isometric procedural suburban neighborhood surrounds a center-block dog
  park with six dogs, a complete gated fence, and varied agility equipment,
  plus furnished enterable buildings, storefronts, and Freya's persistent home.
- Freya is a black, three-legged Portuguese Water Dog rendered with the shared
  voxel dog rig. NPC breeds use that rig with distinct proportions, scale,
  coats, and ordinary accessories.
- Hunger starts at `100%`, rises very slowly at rest after eating, and rises
  faster while walking, running, or taking sustained actions. Home-bowl food
  resets Hunger to zero.
- Exactly 75% of NPC dogs begin secretly possessed. Possession never changes
  their appearance; Freya's unease supplies the indirect clue.
- Socialization costs Hunger and raises Vomit around a possessed dog. Recruited
  dogs wear a broad camouflage neck collar with no overhead indicator.
- Dog exchanges draw from independent recorded conversational, excited-social,
  and aggressive bark pools. Each pool cycles through every clip before reuse
  and prevents the same recording at a cycle boundary.
- Grounded voxel imp aliens use collision-aware movement. Expelled/free aliens
  travel to reachable exterior points before occupying buildings.
- Occupied storefronts lock their services, reinforce nearby alien buildings,
  and exclusively generate a map-wide maximum of eight free aliens. Approaching
  Freya sends a free alien toward the nearest building.
- Buildings track alien occupant counts. Alien architecture and minimap states
  are static, while holding `R` by an occupied wall weakens its integrity.
- Scent claims cover trees, light poles, hydrants, and residential mailboxes.
  Bones raise Strength; sticks can be carried and increase run speed.

For exact current/future distinctions, use
[GAMEPLAY_AUDIT.md](../GAMEPLAY_AUDIT.md). For breed details, use
[BREEDS.md](BREEDS.md).

## Architecture and Assets

The complete ownership map is in [docs/CODEBASE_MAP.md](../docs/CODEBASE_MAP.md).
The principal runtime flow is:

```text
Startup.tscn → IntroCutscene.tscn (optional) → Main.tscn
```

`scripts/main.gd` owns the integrated procedural world and gameplay state.
Focused factories own building, dog, alien, family, UFO, minimap, and tree
presentation. Runtime map visuals and materials are largely code-native rather
than prefab/image assets.

Before changing assets, read:

- [Dog breed and shared-rig policy](BREEDS.md)
- [Model inventory and provenance status](assets/models/README_MODELS.md)
- [Audio attribution and no-fallback mappings](assets/audio/ATTRIBUTION.md)

## Validation

From the repository root, run:

```sh
./scripts/predeploy_size_checks.sh
```

This is the authoritative startup, UFO intro, gameplay smoke/target, and family
intro validation gate. Visual changes additionally require regenerating and
inspecting the affected image described in the
[visual regression catalog](../visual_regressions/README.md).
