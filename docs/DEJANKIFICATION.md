# De-jankification implementation — September 16, 2026

[Documentation hub](../README.md) · [Gameplay intent](../GAMEPLAY_AUDIT.md) ·
[Intro specification](../INTRO_CUTSCENE.md) · [Run guide](../RUN_FRIENDLY_FREYA.md) ·
[Visual catalog](../visual_regressions/README.md)

This pass implements the eleven findings from the September 16 rendered-play
review. It preserves the authored story/dialogue, Freya's three-legged shared
voxel rig, hidden possession, independent army alignment, static alien
architecture, all-building ownership victory, and existing audio mappings.
Planned army combat, re-possession, campaign, kennel placement, and clinic
mechanics remain outside the shipped scope.

## Changes and review surfaces

| Finding | Result | Evidence in the repository |
| --- | --- | --- |
| J01 — cinematic visibility | Framing protects subjects from dialogue; actual rendered bounds clear roofs, overhangs, fixtures and foreground batch instances. Walkers are viewed across their sidewalk; Freya gets a close immunity shot. Labels/ghost overlays clear during playback, scenery restores, and gameplay FOV returns to 40°. | [Family pills](../visual_regressions/intro_14_family_pill_eat.png), [bark](../visual_regressions/intro_12_family_loud_bark.png), [abduction](../visual_regressions/first_exit_abduction.png), [immunity](../visual_regressions/first_exit_freya_immunity.png), [camera checks](../godot/tests/dejank_cameras.gd) |
| J02 — skipped gameplay | Playback history is separate from dog-behavior readiness. Startup/UFO skip starts beside food at 100% Hunger with optional guidance and an open exit. Watching or skipping within the family scene retains the meal/first-exit sequence. | [Route/input checks](../godot/tests/dejank_flow.gd), [intro route contract](../INTRO_CUTSCENE.md) |
| J03 — recruitment | Possessed contact retains Hunger/Vomit costs but awards no recruitment and banks no progress. Cleansing clears pre-cleanse progress; existing army membership stays independent. | [Mixed-group and eligibility checks](../godot/tests/dejank_flow.gd) |
| J04 — gameplay sightlines | Cutaways inspect actual home, shell, interior, neighbor, overhang, and alien-occupation geometry. Wall trim/posters/house numbers follow their supporting geometry. Collision remains intact. Gameplay retains the prop-outline fallback. | [Police interior](../visual_regressions/building_police_inside.png), [pharmacy](../visual_regressions/building_pharmacy_inside.png), [cutaway helper](../godot/scripts/sightline_cutaway.gd) |
| J05 — claim layout | The nine-patch progress texture fits its panel; text wraps and world anchoring/edge clamping remain. | [All six variants and three window sizes](../godot/tests/dejank_flow.gd) |
| J06 — UFO Next | First Next resolves the actual rune and morph phases; the second advances. Exact lines and audio-event history remain. | [Intro implementation/checks](../godot/scripts/intro_cutscene.gd), [input checks](../godot/tests/dejank_flow.gd) |
| J07 — gait | Post-collision displacement drives Freya/NPC locomotion and cadence. Blocked movement idles while preserving facing intent; training keeps its authored poses. | [Dog motion](../godot/scripts/dog_agent.gd), [blocked/cadence checks](../godot/tests/dejank_flow.gd) |
| J08 — feedback | Status text has a compact wrapped background and outcome priority. Objectives lead with ownership, nearby missing mark counts/type/direction, and adjacency requirements. | [Gameplay implementation](../godot/scripts/main.gd), [priority checks](../godot/tests/dejank_flow.gd) |
| J09 — completion | The unchanged ownership predicate opens a centered acknowledgment; Keep exploring resumes the current neighborhood. HUD/objectives retain completion after transient status expires. | [Completion and viewport-bound checks](../godot/tests/dejank_flow.gd) |
| J10 — instructions | Current references agree on R bark, Space claim, X vomit, F interact, and Space cinematic Next. Collision documentation describes Freya/alien substeps and NPC single-step movement. | [Controls](../godot/README_GODOT.md), [gameplay audit](../GAMEPLAY_AUDIT.md), [Windows player reference](../packaging/windows/README.txt) |
| J11 — performance | Spatial indexes eliminate repeated global interior-wall and occupied-footprint scans while retaining exact padded-rectangle tests, radii and simulation timing. Granular profiling separates dog decisions, collision and animation. | [Spatial equivalence and invalidation checks](../godot/tests/dejank_flow.gd), [profiling implementation](../godot/scripts/main.gd) |

The separate design question of Freya barking through the park fence is
unchanged. NPC threats still respect that fence.

## Verification method

The reproducible gate is [predeploy_size_checks.sh](../scripts/predeploy_size_checks.sh).
It imports resources, runs the original four scene validations, then runs the
new input-flow and generated-camera scripts. Camera checks cover seeds
`819267867711688713`, `20260831`, and `20260916`, both home orientations,
full family/first-exit timeline sweeps, all eight live building categories,
services, both entrance sides, four orbits, both normal zoom limits, and
occupied-building exteriors. Mesh-instance sightlines and handoff restoration
are checked alongside framing.

Graphical checks complement these assertions: natural startup-to-UFO-to-family
playback, movement to the bowl, F eating, walking through the first exit,
service pickup/handoff, all four training obstacles in both directions,
R expulsion, C recruitment, timed object reclaim, interrupted building-claim
decay, and the final timed building claim. Distant interaction positions,
calm background dogs, and earlier endgame ownership are explicitly staged;
the full 80-building conquest was not played manually. Completion was reviewed
at 1280×720, 960×540, and 800×450.

Both documented capture commands now wait for rendered-frame readiness through
[capture_ready.gd](../godot/tests/capture_ready.gd), fail on startup errors, and
avoid accidentally accepting the engine splash screen. Static world references
suppress incidental dog-threat tutorial popups. The legacy ad hoc alien close-up
is outside the scripted baseline set.

Environment-specific before/after logs, natural-play captures, staged review
images, and temporary drivers are preserved outside the repository in
`/data/projects/freya-dejank-fixes-20260916/`. The original recommendation audit
remains in `/data/projects/freya-jank-audit-20260916/`.

## Validation results

The complete `./scripts/predeploy_size_checks.sh` run exited successfully,
including resource import, all four original scene validations, input-flow
regressions, and the three-layout camera sweep. Its log contains no errors or
warnings. The audit's import-time `Parameter "singleton" is null` crash did not
recur; no import workaround was needed.

The graphical camera sweep also passed for all three seeds. Full natural watch,
meal, and first-exit input routes passed on seeds `819267867711688713` and
`20260916`. The service/training/exorcism/recruitment/claim input driver and the
staged final-claim/completion driver passed. All 32 world and 19 startup/intro
PNGs were regenerated with the documented capture scripts and visually
inspected, alongside natural-play and noncanonical camera images. First-message
status layout, claim meters, completion bounds, and persistent completion have
regression coverage. Relative documentation links and `git diff --check` passed.

The pre-existing `godot/project.godot` diff is unchanged. Historical packaged
payloads and audio assets/mappings are untouched.

Comparable single-process measurements used Godot 4.7.2 (Flathub), OpenGL
Compatibility, NVIDIA GTX 780M/390.157, the fixed regression seed, and both
`FREYA_PERF_BENCHMARK=1` and `FREYA_PERF_PROFILE_GAMEPLAY=1`. Each run used the
built-in 2.5-second warm-up and five-second sample.

| View | Before FPS | After FPS | Before movement CPU | After movement CPU |
| --- | ---: | ---: | ---: | ---: |
| `home_inside` | 26.1 | 32.8 | 16.389 ms | 9.261 ms |
| `dog_park_friendly` | 19.8 | 26.6 | 26.576 ms | 13.733 ms |

The final samples show movement cost down about 48% in the park and 43% at home.
Granular park profiling before optimization showed 13.784 ms in dog collision
and 8.001 ms in dog decisions; the final run measured 5.530 ms and 2.393 ms.
The new visibility/UI work also has a cost: home visibility measured 2.478 ms
after versus 1.872 ms before. Frame rates varied between runs: an earlier
post-fix sample measured 26.5 FPS at home and 32.2 in the park. These are short
machine-specific samples, not sustained or cross-platform performance guarantees.

## Limits

These are sampled generated layouts and camera sweeps, not exhaustive coverage
of every random neighborhood. Cutaways prioritize action visibility and can
remove a batched wall section or foreground foliage; collision is unaffected.
Performance numbers apply to this Linux/Flatpak machine. This pass does not
include a listening-based audio mix review, Windows runtime testing, packaging,
or publishing. Audio assets and mappings were unchanged; missing sounds still
remain silent.
