# Friendly Freya Codebase Map

[Documentation hub](../README.md) · [Run and validation](../RUN_FRIENDLY_FREYA.md) ·
[Gameplay direction](../GAMEPLAY_AUDIT.md) · [Intro guide](../INTRO_CUTSCENE.md)

This is the cross-system map for the current Godot project. It identifies
ownership and useful search anchors; the runtime code and executable checks
remain authoritative when implementation details change.

## Runtime Flow

```text
Startup.tscn / startup.gd
├── Watch Intro → IntroCutscene.tscn / intro_cutscene.gd
│                  └── natural completion → Main.tscn with one-shot family flag
└── Skip To Game ─────────────────────────→ Main.tscn / main.gd

Main.tscn
├── generates the neighborhood and live Freya home
├── optionally runs the family prologue in that same home
└── releases control to normal gameplay

KennelConcept.tscn / kennel_concept.gd
└── standalone placement-ready archetype preview; never entered by normal flow
```

The project entry point is `res://scenes/Startup.tscn`, configured by
`run/main_scene` in [project.godot](../godot/project.godot).
`Startup.tscn` contains authored UI; `IntroCutscene.tscn` and `Main.tscn` are
thin scene shells whose scripts construct most runtime content.

## Primary Edit Surfaces

| Area | Owning files | Useful symbols or notes |
| --- | --- | --- |
| Startup routes | `godot/scenes/Startup.tscn`, `godot/scripts/startup.gd` | Authored startup UI, `_select_destination`, `_run_startup_validation` |
| UFO intro timing/text | `godot/scripts/intro_timeline.gd` | Stable scene dictionaries and `time_for_view`; expected lines are also asserted by the renderer's validator |
| UFO intro rendering | `godot/scripts/intro_cutscene.gd` | Camera, bubbles, Earth, fleet, audio events, and duplicated validation expectations |
| UFO geometry | `godot/scripts/ufo_visual_factory.gd` | Bridge interior and opaque exterior factories |
| Family intro timing/text | `godot/scripts/family_intro_timeline.gd`, `godot/scripts/main.gd` | Twenty stable beats/view times; Main owns effect/audio thresholds and duplicated validation expectations |
| Family visuals | `godot/scripts/family_visual_factory.gd` | Gene, Zoe, pill bottles, transfer rings, bark waves |
| Family staging/handoff | `godot/scripts/main.gd` | Search for `_begin_family_intro` and `_run_family_intro_validation` |
| Main gameplay/world | `godot/scripts/main.gd` | Procedural layout, all-building interior roster, pharmacy/grocery/police services, interactions, AI, audio mappings, UI, and validation |
| Dogs and animation | `godot/scripts/dog_agent.gd`, `godot/scripts/main.gd` | DogAgent owns visuals/animation; Main owns definitions, spawn, state, and AI |
| Alien character art/lifecycle | `godot/scripts/alien_visual_factory.gd`, `godot/scripts/main.gd` | Factory owns imp mesh/pose; Main owns movement, transfers, and occupation |
| Residential shells/roofs | `godot/scripts/building_factory.gd` | Hollow procedural residential walls, transparent openings, ground/upper-floor separation, materials, roofs, porches, and metrics; Main owns interiors, yards, and alien mutations |
| Unplaced dog kennel archetype | `godot/scripts/kennel_factory.gd`, `godot/scripts/kennel_building.gd`, `godot/scripts/kennel_concept.gd`, `godot/scenes/KennelConcept.tscn` | Reusable clean/possessed visuals, canonical voxel dogs, six initially possessed/de-possessable captives, entry-once dialogue, possessed-dog spawn handshake, partial-cleanse forfeiture, lifetime cap of six, and isolated preview/validation |
| Claims | `godot/scripts/claim_utils.gd`, `godot/scripts/main.gd` | Ownership constants, hold-`R` object claims, building-claim eligibility/progress/decay, territory tint, Ryah stake markers, win condition, and alien-wall weakening |
| Minimap | `godot/scripts/minimap.gd`, `godot/scripts/main.gd` | Minimap draws supplied data; Main owns state and synchronization |
| Trees | `godot/scripts/tree_factory.gd`, `godot/scripts/main.gd` | Factory owns visual batching; Main owns placement, collision, and claims |
| Runtime assets | `godot/assets/` | Read the local model/audio Markdown before changing assets |
| Regression automation | `scripts/`, `visual_regressions/` | Headless checks and deterministic screenshot baselines |
| Windows releases | `godot/export_presets.cfg`, `scripts/build_windows_release.sh`, `packaging/windows/`, `.github/workflows/windows-release.yml` | Filtered export, player/legal files, Windows startup smoke, and GitHub Release publication |

`godot/scripts/main.gd` is intentionally the integration point and is much
larger than the focused factories. Search for the owning function or constant
before editing broad sections of that file.

## State Model

### Dogs

Possession and army membership are independent. The canonical design is in
[GAMEPLAY_AUDIT.md](../GAMEPLAY_AUDIT.md#dogs-have-two-independent-states), and
breed schema/art rules are in [godot/BREEDS.md](../godot/BREEDS.md).

Runtime dog dictionaries are created and updated in `main.gd`; the visible rig,
motion, accessories, and pose APIs live in `dog_agent.gd`.

### Buildings and Aliens

`buildings` in `main.gd` is the central runtime collection. Each building keeps
its base identity through fields such as `is_store` and `is_freya_home`, while
occupation uses `alien_occupied`, `alien_integrity`, and
`alien_occupant_count`. Store indices, `free_aliens`, and `alien_transfers` are
separate state; `_alien_total_occupant_count()` computes the map total on
demand.

Alien visuals come from one shared imp factory. Travel uses the same cached
walkability/collision conventions as other characters; building possession is
the explicit handoff at a reachable exterior point.

### Freya Home and Family Intro

The home is a selected procedural building, not a separate cinematic scene.
`_build_freya_home_interior` builds the persistent home and Ryah. The family
intro temporarily adds Gene, Zoe, UI, effects, selected walls, and the back roof
surface beneath the live home interior root, then removes only those temporary
objects at handoff. See [INTRO_CUTSCENE.md](../INTRO_CUTSCENE.md).

## Validation Entry Points

Use the wrapper rather than invoking individual validation flags manually:

```sh
./scripts/predeploy_size_checks.sh
```

It runs four Godot processes and covers:

1. startup route/focus/selection locking;
2. UFO intro timeline, cast, audio mapping, Earth, and fleet;
3. the placement-ready, unplaced kennel contract and finite spawn cap;
4. gameplay smoke checks, targeted gameplay/visual invariants, and the family
   intro timeline/handoff.

Successful output contains `STARTUP_OK`, `INTRO_OK`, `KENNEL_OK`, `SMOKE_OK`,
`TARGET_OK`, and `FAMILY_INTRO_OK` before the wrapper reports
`Predeploy checks passed.`

Deterministic visual output is a separate form of evidence. See
[visual_regressions/README.md](../visual_regressions/README.md) and inspect the
PNG after regenerating it; successful capture alone does not prove the frame is
visually correct.

## Environment Variables

These are automation interfaces, not player settings.

| Variable | Purpose | Normal entry point |
| --- | --- | --- |
| `FREYA_STARTUP_VALIDATE` | Startup checks | `predeploy_size_checks.sh` |
| `FREYA_INTRO_VALIDATE` | UFO intro checks | `predeploy_size_checks.sh` |
| `FREYA_SMOKE` | Gameplay smoke checks | `predeploy_size_checks.sh` |
| `FREYA_VALIDATE` | Targeted gameplay checks | `predeploy_size_checks.sh` |
| `FREYA_INTRO_VIEW` | Seek a deterministic UFO-intro beat | `capture_intro_regressions.sh` |
| `FREYA_FAMILY_INTRO_VIEW` | Seek a deterministic live-home family beat | `capture_intro_regressions.sh` |
| `FREYA_VISUAL_VIEW` | Stage a deterministic world/gameplay view | `capture_visual_regressions.sh` |
| `FREYA_ALIEN_VIEW` | Stage a deterministic alien-system view | `capture_visual_regressions.sh` |
| `FREYA_KENNEL_VALIDATE` | Validate the unplaced kennel contract and finite spawn behavior | `predeploy_size_checks.sh` |
| `FREYA_KENNEL_VIEW` | Stage the clean, interior, or possessed kennel concept | `capture_visual_regressions.sh` |
| `FREYA_CAPTURE_ONLY` | Limit gameplay/world capture output | `capture_visual_regressions.sh` |
| `FREYA_INTRO_CAPTURE_ONLY` | Limit startup/intro capture output | `capture_intro_regressions.sh` |
| `FREYA_START_AT_HOME` | Development spawn override | Direct development launch |
| `FREYA_INTRO_SHOW_SCENE_ID` | Show stable scene-ID overlays in the UFO or family intro | Direct development launch |
| `FREYA_PERF_BENCHMARK` | Emit aggregate rendering/runtime metrics | Direct benchmark launch |
| `FREYA_PERF_PROFILE_GAMEPLAY` | Include categorized gameplay timing | Use with the performance benchmark |
| `GODOT_BIN` | Select a direct Godot executable for validation/export automation | CI or local release tooling |
| `FREYA_RELEASE_OUTPUT_DIR` | Override the Windows ZIP output directory | `build_windows_release.sh` |
| `FREYA_EXPORT_GODOT_VERSION` | Override the build script's expected Godot version | Controlled release testing only |

Headless validation and static-view modes use the fixed regression seed; normal
graphical gameplay remains randomized.

## Change-to-Check Routing

| Changed area | Minimum verification |
| --- | --- |
| Any GDScript, scene, timeline, or gameplay constant | `./scripts/predeploy_size_checks.sh` |
| Startup or UFO intro visuals | Relevant `intro_01`–`intro_05` capture |
| Family intro staging, characters, effects, dialogue UI | Relevant `intro_06`–`intro_13` capture |
| Buildings, home, dogs, aliens, collars, kennel concept, or pause UI | Relevant gameplay/world/concept capture |
| Audio file or mapping | Predeploy checks plus attribution update; missing audio must remain silent |
| Model policy or breed schema | Predeploy checks plus model/breed documentation update |
| Export preset, packaging, or release workflow | Full predeploy checks, local package inspection, and a successful Windows Actions smoke run |

## Search Recipes

```sh
# List current/historical source documentation without generated or packaged copies.
rg --files -g '*.md' -g '!godot/.godot/**' -g '!Logs and Monitoring/**'

# Find validation failures and their owning checks.
rg -n 'failures\.append|_run_.*validation|SMOKE_|TARGET_|INTRO_' godot/scripts

# Find every automation environment variable read by GDScript.
rg -n 'OS\.get_environment' godot/scripts

# Inspect the current worktree before editing.
git status --short
```
