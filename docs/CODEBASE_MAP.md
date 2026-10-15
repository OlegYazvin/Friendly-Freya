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
├── Skip To Game ─────────────────────────→ Main.tscn / main.gd
└── Resume Game (valid save) ─────────────→ Main.tscn / main.gd

Main.tscn
├── generates the neighborhood, live Freya home, and kennel
├── optionally runs the family prologue in that same home
├── releases control to normal gameplay and three campaign chapters
└── chapter 3 Continue Story → CampaignEnding.tscn

KennelConcept.tscn / kennel_concept.gd
└── standalone archetype preview; the normal map uses the same kennel factory
```

The project entry point is `res://scenes/Startup.tscn`, configured by
`run/main_scene` in [project.godot](../godot/project.godot).
`Startup.tscn` contains authored UI; `IntroCutscene.tscn` and `Main.tscn` are
thin scene shells whose scripts construct most runtime content.

## Primary Edit Surfaces

| Area | Owning files | Useful symbols or notes |
| --- | --- | --- |
| Startup routes | `godot/scenes/Startup.tscn`, `godot/scripts/startup.gd` | Authored startup UI, `_select_destination`, `_run_startup_validation` |
| Save and resume | `godot/scripts/game_save.gd`, `godot/scripts/main.gd`, `godot/scripts/startup.gd`, `godot/tests/save_resume.gd` | Versioned/checksummed save envelope, backup recovery, incompatible-version preservation, stable spatial IDs, gameplay snapshot/restore including reserve guard posts and dismissed results, title Resume route, and headless round-trip; failed Quit/ending saves keep the current game open |
| UFO intro timing/text | `godot/scripts/intro_timeline.gd` | Stable scene dictionaries and `time_for_view`; expected lines are also asserted by the renderer's validator |
| UFO intro rendering | `godot/scripts/intro_cutscene.gd` | Camera, bubbles, Earth, fleet, audio events, and duplicated validation expectations |
| UFO geometry | `godot/scripts/ufo_visual_factory.gd` | Bridge interior and opaque exterior factories |
| Family intro timing/text | `godot/scripts/family_intro_timeline.gd`, `godot/scripts/main.gd` | Twenty stable beats/view times; Main owns effect/audio thresholds and duplicated validation expectations |
| Family visuals | `godot/scripts/family_visual_factory.gd` | Gene, Zoe, pill bottles, transfer rings, bark waves |
| Family staging/handoff | `godot/scripts/main.gd` | Search for `_begin_family_intro` and `_run_family_intro_validation` |
| Main gameplay/world | `godot/scripts/main.gd` | Procedural layout, all-building interior roster, pharmacy/grocery/police/clinic services, pack orders, chapter objectives, interactions, AI, UI, and validation |
| Carried supply targeting | `godot/scripts/main.gd`, `godot/tests/supply_targeting.gd` | One shared F/ring target, chapter-2 ally preference, duplicate-protection guards, clinic and grocery priority, cage priority, and no-target feedback |
| Recorded action audio | `godot/scripts/action_audio.gd`, `godot/assets/audio/actions/`, `godot/assets/audio/ATTRIBUTION.md`, `godot/tests/audio_actions.gd` | Exact recorded cue paths and source/license record; lone-imp R defense, nearby storefront emergence, and first-time park drill reward coverage; a missing cue remains silent |
| Render sightlines | `godot/scripts/sightline_cutaway.gd`, `godot/scripts/main.gd` | Temporary render-only occluder visibility, mesh bounds, camera safe framing; collision is unchanged |
| Dogs and animation | `godot/scripts/dog_agent.gd`, `godot/scripts/main.gd` | DogAgent owns visuals/animation; Main owns definitions, spawn, state, and AI |
| Alien character art/lifecycle | `godot/scripts/alien_visual_factory.gd`, `godot/scripts/main.gd` | Factory owns imp mesh/pose; Main owns movement, transfers, and occupation |
| Residential shells/roofs | `godot/scripts/building_factory.gd` | Hollow procedural residential walls, transparent openings, ground/upper-floor separation, materials, roofs, porches, and metrics; Main owns interiors, yards, and alien mutations |
| Dog lodge and preview | `godot/scripts/kennel_factory.gd`, `godot/scripts/kennel_building.gd`, `godot/scripts/main.gd`, `godot/scripts/kennel_concept.gd`, `godot/scenes/KennelConcept.tscn` | Guaranteed near-park lot, minimap marker, wall cleanse, six releasable captives, finite six-spawn budget, save snapshot, and isolated preview/validation |
| Claims and campaign | `godot/scripts/claim_utils.gd`, `godot/scripts/main.gd`, `godot/scenes/CampaignEnding.tscn` | Ownership, scent and building claims, nearby claimed-site weakening bonus, territory visuals, three chapters (8/5/4 highlighted sites), occupation/ally/kennel objectives, generator output/radius guidance, a saved chapter-2 scent relay and final stronghold marker, contextual chapter guidance including the optional park drill, ally protection, pack recovery, and saved H dismissal, story continuation and finale, and optional full-map ownership |
| Minimap | `godot/scripts/minimap.gd`, `godot/scripts/main.gd` | Minimap draws supplied data, M/F/A/C service markers, and a fixed cyan next-site diamond that stays at the map edge when the site is beyond the zoomed view; Main owns state and synchronization |
| Trees | `godot/scripts/tree_factory.gd`, `godot/scripts/main.gd` | Factory owns visual batching; Main owns placement, collision, and claims |
| Runtime assets | `godot/assets/` | Read the local model/audio Markdown before changing assets |
| Regression automation | `scripts/`, `godot/tests/natural_campaign_route.gd`, `godot/tests/performance_stress.gd`, `visual_regressions/` | Headless checks, a separate graphical keyboard route through the three chapters, credits, and Keep Exploring, a live-simulation stress diagnostic, and deterministic screenshot baselines |
| Windows releases | `godot/export_presets.cfg`, `scripts/build_windows_release.sh`, `packaging/windows/`, `.github/workflows/windows-release.yml` | Filtered export, player/legal files, Windows startup smoke, exported campaign route on manual and tag runs, then tag-push GitHub Release publication |

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

After preparing imports, it runs focused validation processes and covers:

1. startup route/focus/selection locking;
2. UFO intro timeline, cast, audio mapping, Earth, and fleet;
3. the placed kennel, cage rescue flow, and finite possessed-dog spawn cap;
4. gameplay smoke checks, targeted gameplay/visual invariants, and the family
   intro timeline/handoff;
5. input-driven route and de-jankification regressions, with explicitly staged
   dog/collision/UI/endgame setups, in `godot/tests/dejank_flow.gd`;
6. generated-layout framing and rendered-mesh occlusion checks in
   `godot/tests/dejank_cameras.gd` across three seeds, all building types, four
   camera orbits, and both zoom extremes. `sightline_cutaway.gd` owns reversible
   render-only cutaways and cached static geometry bounds.
7. a save/resume round trip in `godot/tests/save_resume.gd`, covering the seed,
   campaign chapter and completion, legacy chapter-1 repair, claims, occupation,
   dog state, supplies, meters, kennel, legacy migration, future-version
   preservation, backup recovery, final-site pack recovery, and failed-save
   exit guards;
8. the three-chapter route and story handoff in `godot/tests/campaign_flow.gd`;
9. five generated seeds with chapter entrance, mark, wall, cage, and territory
   connection probes in `godot/tests/campaign_reachability.gd`;
10. claimed-neighbor scent support in `godot/tests/scent_support.gd`;
11. ending layout and navigation in `godot/tests/campaign_ending.gd`;
12. active and reserve pack behavior in `godot/tests/pack_squad.gd`, including
    a seed-20260831 route around a blocking building and nearby reserve guard
    recovery at the cleared final signal;
13. recorded action audio in `godot/tests/audio_actions.gd`, including a
    successful lone-imp R bark, same-beat deduplication, nearby-dog restraint,
    near-only occupied-storefront imp emergence without fallback, and the
    first-time park drill reward;
14. ending Keep Exploring and later save/resume in `godot/tests/ending_resume.gd`;
15. chapter guidance, clean-first target priority, later ally protection and
    final-signal recovery cues, saved dismissal, and
    800×450 guide/goals/pause panel bounds in `godot/tests/chapter_guide.gd`;
16. occupation-margin recovery for Freya and dogs, including old-save restore,
    in `godot/tests/occupation_collision_recovery.gd`;
17. doorway-connected, Freya-width access to the four building services and
    their `F` effects across five seeds in `godot/tests/service_reachability.gd`.
18. carried supply targeting in `godot/tests/supply_targeting.gd`, including
    the matching interaction ring, non-consuming invalid applications, chapter-2
    ally preference, mixed supplies, grocery and cage F priority, and 960×540
    clinic-hint bounds.

Successful output contains `STARTUP_OK`, `INTRO_OK`, `KENNEL_OK`, `SMOKE_OK`,
`TARGET_OK`, `FAMILY_INTRO_OK`, `DEJANK_FLOW_OK`, `DEJANK_CAMERA_OK`,
`SAVE_RESUME_OK`, `CAMPAIGN_FLOW_OK`, `CAMPAIGN_REACHABILITY_OK`,
`OCCUPATION_COLLISION_RECOVERY PASS`, `SERVICE_REACHABILITY_OK`,
`SUPPLY_TARGETING_OK`,
`SCENT_SUPPORT_OK`, `PACK_SQUAD_OK`, `AUDIO_ACTIONS_OK`,
`ENDING_OK`, `ENDING_RESUME_OK`, and `CHAPTER_GUIDE_OK` before the wrapper reports
`Predeploy checks passed.`

Deterministic visual output is a separate form of evidence. See
[visual_regressions/README.md](../visual_regressions/README.md) and inspect the
PNG after regenerating it; successful capture alone does not prove the frame is
visually correct.

The graphical `performance_stress.gd` harness is separate from predeploy. It
stages a full recruited roster, two occupied generators, and kennel production
while Main continues normal updates. Use the command in the
[run guide](../RUN_FRIENDLY_FREYA.md#sustained-graphical-stress-sample).
The separate `natural_campaign_route.gd` route sends keyboard input through
Startup Skip, the meal, a dog cleanse and recruit, surrounding marks, building
claims, lodge rescue, all three chapters, ending page navigation, and Keep
Exploring. A resumed seed-20260831 run passed that route; it reads world
geometry and progress only to choose keys. Its command is in the
[run guide](../RUN_FRIENDLY_FREYA.md#optional-natural-input-route).

## Environment Variables

These are automation interfaces, not player settings.

| Variable | Purpose | Normal entry point |
| --- | --- | --- |
| `FREYA_STARTUP_VALIDATE` | Startup checks | `predeploy_size_checks.sh` |
| `FREYA_INTRO_VALIDATE` | UFO intro checks | `predeploy_size_checks.sh` |
| `FREYA_SMOKE` | Gameplay smoke checks | `predeploy_size_checks.sh` |
| `FREYA_VALIDATE` | Targeted gameplay checks | `predeploy_size_checks.sh` |
| `FREYA_STARTUP_VIEW` | Stage title menu with or without Resume for deterministic captures | `capture_intro_regressions.sh` |
| `FREYA_INTRO_VIEW` | Seek a deterministic UFO-intro beat | `capture_intro_regressions.sh` |
| `FREYA_FAMILY_INTRO_VIEW` | Seek a deterministic live-home family beat | `capture_intro_regressions.sh` |
| `FREYA_VISUAL_VIEW` | Stage a deterministic world/gameplay view | `capture_visual_regressions.sh` |
| `FREYA_ALIEN_VIEW` | Stage a deterministic alien-system view | `capture_visual_regressions.sh` |
| `FREYA_KENNEL_VALIDATE` | Validate the placed kennel contract, cage rescue, and finite spawn behavior | `predeploy_size_checks.sh` |
| `FREYA_KENNEL_VIEW` | Stage the clean, interior, or possessed kennel concept | `capture_visual_regressions.sh` |
| `FREYA_CAPTURE_ONLY` | Limit gameplay/world capture output | `capture_visual_regressions.sh` |
| `FREYA_INTRO_CAPTURE_ONLY` | Limit startup/intro capture output | `capture_intro_regressions.sh` |
| `FREYA_WORLD_SEED` | Reproduce a generated layout using an integer seed | Direct development launch |
| `FREYA_START_AT_HOME` | Development spawn override | Direct development launch |
| `FREYA_INTRO_SHOW_SCENE_ID` | Show stable scene-ID overlays in the UFO or family intro | Direct development launch |
| `FREYA_PERF_BENCHMARK` | Emit aggregate rendering/runtime metrics | Direct benchmark launch |
| `FREYA_PERF_PROFILE_GAMEPLAY` | Include categorized gameplay timing | Use with the performance benchmark |
| `FREYA_PERF_STRESS_WARMUP_SECONDS` | Override the live stress harness's 15-second warm-up for a controlled comparison | Graphical stress launch |
| `FREYA_PERF_STRESS_SAMPLE_SECONDS` | Override the live stress harness's 135-second sample for a controlled comparison | Graphical stress launch |
| `FREYA_PERF_STRESS_HIDE_LANE_DASHES` | Set to `1` to hide center-lane dashes in the staged stress scene for a test-only rendering comparison | Graphical stress launch |
| `FREYA_EXPORTED_CAMPAIGN_QA` | Attach the bundled SceneTree keyboard route to an exported build for Windows campaign QA | Windows Actions manual and tag runs |
| `GODOT_BIN` | Select a direct Godot executable for validation/export automation | CI or local release tooling |
| `FREYA_RELEASE_OUTPUT_DIR` | Override the Windows ZIP output directory | `build_windows_release.sh` |
| `FREYA_EXPORT_GODOT_VERSION` | Override the build script's expected Godot version | Controlled release testing only |

Headless validation and static-view modes use the fixed regression seed; normal
graphical gameplay remains randomized unless `FREYA_WORLD_SEED` is set.

## Change-to-Check Routing

| Changed area | Minimum verification |
| --- | --- |
| Any GDScript, scene, timeline, or gameplay constant | `./scripts/predeploy_size_checks.sh` |
| Startup or UFO intro visuals | Relevant `intro_01`–`intro_05` capture |
| Family intro staging, characters, effects, dialogue UI | Relevant `intro_06`–`intro_13` capture |
| Buildings, home, dogs, aliens, collars, kennel concept, or pause UI | Relevant gameplay/world/concept capture |
| Audio file or mapping | Predeploy checks plus attribution update; missing audio must remain silent |
| Model policy or breed schema | Predeploy checks plus model/breed documentation update |
| Export preset, packaging, or release workflow | Full predeploy checks, local package inspection, and successful Windows Actions startup and campaign runs |

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
