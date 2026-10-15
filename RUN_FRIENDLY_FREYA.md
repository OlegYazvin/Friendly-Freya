# Run Friendly Freya

[Documentation hub](README.md) · [Codebase map](docs/CODEBASE_MAP.md) ·
[Godot overview and controls](godot/README_GODOT.md)

Last verified: October 15, 2026 with Godot `4.7.2.stable.flathub`.
The project declares its feature target in
[project.godot](godot/project.godot).

Run commands from the repository root unless a section says otherwise.

## Launch in This Codex Environment

Use host Flatpak (not sandbox `flatpak`):

```sh
host-spawn flatpak run org.godotengine.Godot --path "$PWD/godot"
```

The first screen should offer `New Game: Watch Intro` and `New Game: Skip Intro`.
If a valid save exists, `Resume Game` is focused by default. Either new-game
choice asks for confirmation before that save can be replaced.

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
3. the placed kennel's six cages/dogs, exact first-entry promise, canonical
   voxel dogs, caged-dog de-possession, clean/possessed states,
   partial-cleanse forfeiture, and six-possessed-dog cap;
4. gameplay smoke and targeted validation, including the enterable building
   roster and pharmacy/grocery/police services, all four bidirectional dog-park
   training interactions and Freya poses, the three bark pools and their
   no-repeat shuffle behavior, plus family-intro staging, dialogue, effects,
   exact audio mapping, and handoff checks;
5. the active-three pack cap, reserve guard posts, local imp defense, saved
   guard positions, collision-triggered pack routing around the seed-20260831
   site-33 blocker, and a nearby reserve's cleared-site guard recovery in
   `godot/tests/pack_squad.gd`;
6. isolated R and pack-dog bark defense of an imp with duplicate-bark
   restraint, the caged-dog whine on approach, Ryah's brief cry, the real
   pill-bottle landing, near-only occupied-storefront imp emergence without
   fallback, and the first-time park drill's recorded reward cue in
   `godot/tests/audio_actions.gd`;
7. input-driven skip/replay, food, rune/morph Next, recruitment, blocked gait,
   spatial collision equivalence, claim bounds, feedback priority, and persistent
   completion regressions in `godot/tests/dejank_flow.gd`;
8. three generated layouts, cinematic transitions, all live building types,
   both entrance sides, four camera orbits, and both zoom extremes in
   `godot/tests/dejank_cameras.gd`, including actual rendered-mesh sightlines.
9. a save/resume round trip in `godot/tests/save_resume.gd`, including backup
   recovery from an incomplete lodge payload, legacy migration,
   future-version preservation, all campaign
   state, old chapter-1 stronghold repair, dogs, claims, occupation, and kennel
   state;
10. New Game, Restart Story, and Replay Story confirmation/cancel behavior,
    keyboard focus, and future-version primary/backup save protection in
    `godot/tests/new_game_safety.gd`;
11. chapter guidance, clean-first target priority, chapter-2 ally protection,
    chapter-3 pack and final-signal recovery cues, the named next-site
    minimap diamond and legend, the active-source badge and clearing state,
    saved dismissal, and 800×450 guide/goals/pause
    panel bounds in `godot/tests/chapter_guide.gd`;
12. the three connected chapter routes, mandatory holds, ally protection, pack
   assistance, and credits handoff in `godot/tests/campaign_flow.gd`;
13. ten generated seeds with home-connected Freya-radius routes to all chapter
    entrances, required scent marks, occupied wall approaches, and lodge cages,
    plus sequential territory connections in
    `godot/tests/campaign_reachability.gd`;
14. occupied-building margin recovery for Freya and dogs, plus old-save and
    interior-exit checks, in `godot/tests/occupation_collision_recovery.gd`;
15. five-seed doorway-connected routes to grocery, pharmacy, police, and clinic
    services using Freya-radius collision, with each F effect verified in
    `godot/tests/service_reachability.gd`;
16. claimed-neighbor scent support in `godot/tests/scent_support.gd`;
17. ending layout and navigation in `godot/tests/campaign_ending.gd`;
18. the ending's return to the saved neighborhood and persistent exploration
    state in `godot/tests/ending_resume.gd`;
19. carried supply targeting, duplicate-use protection, clinic and grocery
    priority, and matching dog highlights in `godot/tests/supply_targeting.gd`.
20. `-` / `=` keyboard camera zoom through actual input dispatch, both zoom
    limits, pause behavior, and in-game help text in
    `godot/tests/camera_keyboard_zoom.gd`.
21. `New Game: Watch Intro` through the UFO English dialogue hold, family
    dialogue hold, required meal, first-exit thought, and return to play using
    keyboard events in `godot/tests/watch_intro_route.gd`.
22. optional press-once Space and C controls, persisted keyboard setting,
    target lock, focus loss and other interruptions, recruitment completion,
    and UI bounds at 800×450 and 960×540 in
    `godot/tests/claim_input_toggle.gd`.
23. a live Main-process route in `godot/tests/claim_input_live.gd` that taps
    and releases Space for a full ten-second interior claim and C for dog
    recruitment, without calling the gameplay update methods directly.

Successful output includes `STARTUP_OK`, `INTRO_OK`, `WATCH_INTRO_ROUTE_OK`, `CLAIM_INPUT_TOGGLE_OK`, `CLAIM_INPUT_LIVE_OK`, `KENNEL_OK`, `SMOKE_OK`,
`TARGET_OK`, `FAMILY_INTRO_OK`, `PACK_SQUAD_OK`, `AUDIO_ACTIONS_OK`, `DEJANK_FLOW_OK`, `CAMERA_KEYBOARD_ZOOM_OK`,
`DEJANK_CAMERA_OK`, `SAVE_RESUME_OK`, `NEW_GAME_SAFETY_OK`, `CHAPTER_GUIDE_OK`, `CAMPAIGN_FLOW_OK`,
`CAMPAIGN_REACHABILITY_OK`, `SERVICE_REACHABILITY_OK`,
`OCCUPATION_COLLISION_RECOVERY PASS`, `SCENT_SUPPORT_OK`,
`ENDING_OK`, `ENDING_RESUME_OK`, and `SUPPLY_TARGETING_OK`, followed by
`Predeploy checks passed.`

A passing command is required evidence, but visual changes also require an
inspected deterministic capture.

For additional staged camera evidence, run the camera script graphically with
`FREYA_REVIEW_DIR` pointing to an existing directory. It saves the cinematic
checkpoints and interior rotations while retaining the same assertions.

The focused Watch Intro route sends Enter, Space, movement, and F through the
ordinary input path on fixed seed 20260831. It verifies that the first complete
English UFO and family lines remain visible until Space, then completes the
meal and first-exit thought before normal play resumes:

```sh
host-spawn env FREYA_WORLD_SEED=20260831 flatpak run org.godotengine.Godot \
  --headless --path "$PWD/godot" --script res://tests/watch_intro_route.gd
```

The route is in predeploy and the exported Windows smoke step. Its headless
result checks interaction and state transitions; graphical Windows review of
the opening remains part of release QA.

For a 960×540 rendered check of the held English UFO and family dialogue,
close other Godot sessions and run the same route with captures enabled:

```sh
host-spawn env FREYA_WORLD_SEED=20260831 \
  FREYA_NATURAL_CAPTURE_DIR="$PWD/.watch_intro_960" \
  flatpak run org.godotengine.Godot --path "$PWD/godot" \
  --windowed --resolution 960x540 --script res://tests/watch_intro_route.gd
```

The route checks that both dialogue labels and their Next/Skip buttons fit
inside the viewport. Its `watch_intro_ufo_hold_960.png` and
`watch_intro_family_hold_960.png` captures were inspected at 960×540 on
October 15, 2026; both full lines and both buttons were visible. This is
source Linux rendering, so the Windows graphical check remains open.

## Optional Natural Input Route

Close other Godot sessions, then run the fixed-seed graphical route:

```sh
host-spawn env FREYA_WORLD_SEED=20260831 FREYA_NATURAL_DEEP=1 \
  flatpak run org.godotengine.Godot --path "$PWD/godot" \
  --windowed --resolution 960x540 --script res://tests/natural_campaign_route.gd
```

To save 960×540 startup, home, exit, goals, and pause screenshots, add
`FREYA_NATURAL_CAPTURE_DIR="$PWD/.natural_review_960"` alongside the two `env`
assignments. The directory is created automatically.

This separate test sends live key input through Skip To Game, the meal, home
exit, one dog cleanse and recruit, surrounding marks, and the first connected
building claim. It reads walkability to choose movement keys and uses a test
save path. Add `FREYA_NATURAL_STRONGHOLD=1` beside the seed to continue to the
first occupied chapter wall and clear it by holding Space. The stronger route
passed on seed 20260831 at 960×540, claiming its first building at 73.1 seconds
and clearing the occupied wall at 93.8 seconds. This optional graphical test is
not part of the complete headless validation wrapper above.
The same startup-to-first-hold live-input route passed on seeds 1 and 42 at
960×540: first claims at 50.5 and 68.0 seconds, with occupied walls cleared
at 59.4 and 78.6 seconds. These are geometry-aware controller runs, not
unfamiliar-player usability observations.

The campaign route uses the same keyboard-only controller for
connected site claims, lodge rescue, pharmacy protection, pack assistance,
chapter continuation, and credits. It reads live geometry and progress to pick
keys; it does not set gameplay progress. Start with a shorter checkpoint:

```sh
host-spawn env FREYA_WORLD_SEED=20260831 FREYA_NATURAL_CAMPAIGN=1 \
  FREYA_NATURAL_STOP_AFTER_STAGE=lodge flatpak run org.godotengine.Godot \
  --path "$PWD/godot" --windowed --resolution 960x540 \
  --script res://tests/natural_campaign_route.gd
```

To resume from a retained harness checkpoint, set `FREYA_NATURAL_KEEP_SAVE=1`
on the checkpoint run, then select Startup Resume through the same controller:

```sh
host-spawn env FREYA_WORLD_SEED=20260831 FREYA_NATURAL_CAMPAIGN=1 \
  FREYA_NATURAL_RESUME=1 flatpak run org.godotengine.Godot \
  --path "$PWD/godot" --windowed --resolution 960x540 \
  --script res://tests/natural_campaign_route.gd
```

Remove `FREYA_NATURAL_STOP_AFTER_STAGE` and add
`FREYA_NATURAL_STOP_AFTER_CHAPTER=1` or `2` to stop at a chapter result. Remove
both stop variables to run all three chapters and the ending. Expect a long
live run. A staged campaign check does not replace this normal-control route.
The seed-20260831 lodge checkpoint passed at 960×540: it disabled the active
generator, cleansed the lodge wall twice after an imp reoccupied it, and
released all six caged dogs through live R/F input in 154.1 seconds. A longer
seed-20260831 graphical run reached the chapter-1 result panel through live
input in 629.1 seconds: eight of eight connected sites claimed, three occupied
holds cleared, the active generator disabled, one ally recruited, and all six
lodge captives released. A resumed seed-20260831 keyboard run subsequently
passed chapter 1 with 8/8 sites, chapter 2 with 5/5 sites and two protected
allies, and chapter 3 with 4/4 sites and an ally guarding the final signal.
Right advanced to page 4 credits; Escape chose Keep Exploring and restored the
completed neighborhood. The route uses one generated seed and a geometry-aware
controller; unfamiliar-player playtests, graphical Windows QA, and
minimum-hardware measurement remain open.

An October 15 fresh keyboard run on that seed reached chapter 1 at 8/8
claims, three cleared holds, zero generators, and six rescued lodge dogs.
Its sole ally was re-possessed during the route, so the chapter result
correctly waited for a clean ally. Resuming the preceding 7/8 autosave,
normal defensive barking cleansed an aligned dog while finishing the last
claim. The continued keyboard route passed chapters 2 and 3, reached the
actual credits page, and returned through Keep Exploring. This evidence spans
a fresh process and a Resume process; it is not one uninterrupted
startup-to-credits run.

A later fresh seed-20260831 run at 960×540 opened the chapter-1 result in
578.2 seconds with 8/8 sites, three cleared holds, no active generator, one
clean ally, and six rescued lodge dogs. N advanced to chapter 2. The route
controller's fixed 80-second walking limit then expired during a progressing
trip to the grocery. A retained-save Startup Resume passed that cross-map
trip; at the pharmacy, an exact-grid endpoint check stopped despite Freya
being inside and within the 1.55 m `F` range. With distance-based walking
time and a service approach tolerance that still checks live interior and
range, another Startup Resume protected two allies by pharmacy input, secured
chapter 2 at 5/5 sites (319.5 seconds) and chapter 3 at 4/4 with pack
assistance (591.0 seconds), reached page-4 credits at 591.6 seconds, and
returned to a completed unpaused neighborhood through Keep Exploring at
597.6 seconds. Those times start at the second Resume, which exited normally.
These earlier runs spanned separate processes and did not, by themselves,
establish an uninterrupted fresh Startup-to-credits route. The fresh run below
did exercise that route.

A fresh seed-20260831 graphical run at 960×540 then completed the route in one
uninterrupted process without Resume or direct gameplay-state assignment. It
reached the chapter-1 result at 620.2 seconds (8/8 connected sites, three
cleared holds, no generator, one real ally, six rescued lodge dogs), chapter 2
at 1147.3 seconds (5/5 sites, two protected allies, no generator), and chapter
3 at 1366.7 seconds (4/4 sites and pack assistance). The controller reached
page-4 credits at 1367.3 seconds and returned through Keep Exploring at 1373.9
seconds, reporting `NATURAL_ROUTE_CAMPAIGN_OK` and exiting successfully. It
read live geometry and progress to choose ordinary keyboard actions.

A second fresh, uninterrupted 960×540 route passed on seed 1 without Resume or
direct gameplay-state assignment. Chapter 1 reached 8/8 sites at 680.3 seconds
with four cleared holds, no generator, one clean ally, and six rescued lodge
dogs. Chapter 2 reached 5/5 sites at 1116.6 seconds with two protected allies
and four clean allies. Chapter 3 reached 4/4 sites with pack assistance at
1310.8 seconds; page-4 credits followed at 1311.3 seconds and Keep Exploring
at 1317.7 seconds. It reported `NATURAL_ROUTE_CAMPAIGN_OK` and exited
successfully. The controller's walking deadline now uses actual navigation
path length. Its medicine approach permits a 1.1m navigation tolerance, then
checks the live dog is within 1.45m and is the selected `F` target inside the
game's 1.55m interaction range. These controller changes do not alter gameplay.
The fixed seed determines the map layout, but live dog and occupation changes
can alter the first claim. Together these runs verify technical
start-to-credits paths on two generated layouts; unfamiliar-player discovery
and enjoyment, graphical Windows QA, and minimum-hardware performance remain
unverified.

## Sustained Graphical Stress Sample

Close other Godot sessions, then run this on a graphical desktop:

```sh
host-spawn env FREYA_WORLD_SEED=20260831 flatpak run org.godotengine.Godot \
  --path "$PWD/godot" --script res://tests/performance_stress.gd
```

The harness stages a late-game roster of 22 recruited dogs (three active), two
occupied storefront generators, and the still-possessed kennel. It drives
movement beside one storefront while normal gameplay updates run. After a
15-second warm-up, it samples at least 135 seconds, finishing a complete final
five-second window, and prints five-second FPS, scene
population, node and draw-call counts, engine memory, Linux process RSS, and
frame-time percentiles. The stress controller disables game saving. This is a
reproducible local stress diagnostic, not a release gate by itself; measure the natural
playthrough on the stated minimum Windows machine as well. The proposed test
machine is the HP Victus 16-r0073cl (factory Windows 11 Home, i7-13700HX,
RTX 4060 Laptop GPU, 32 GB RAM, 1920×1080 display). Confirm its actual
configuration before testing. On that PC, run the unprofiled stress sample
plugged in with the dedicated GPU at 1280×720 and native 1920×1080, then
observe the exported EXE during a natural full-pack route. Record average and
worst five-second FPS, frame-time percentiles, memory, and graphics settings
in the [playtest note guide](docs/PLAYTEST_RUN_SHEET.md). The target is a floor of
30 FPS in every five-second window on this machine; 960×540 remains a
readability candidate pending manual review.

For the release measurement on Windows, extract the matching review ZIP and
double-click `RunPerformanceQA.cmd` beside `FriendlyFreya.exe`. The bundled
runner launches the exported game graphically at 1280×720 windowed and
1920×1080 fullscreen without a Godot installation, verifies the actual client
size during sampling, saves full logs and a summary in a dated `performance-qa`
folder, and samples Windows process memory. Use its worst five-second FPS result for
the 30 FPS floor. Check the active GPU and observe a separate natural
start-to-credits playthrough; the scripted stress case alone cannot establish
playability or enjoyment. The runner never writes the campaign save.

For a developer diagnostic from source, use a checkout of the exact review
commit and the Godot 4.7.2 editor, with no other Godot instance running. In
PowerShell from the repository root, set `$godotExe` to the editor's actual path
and run both sizes without `--headless` or `FREYA_PERF_PROFILE_GAMEPLAY`:

```powershell
$godotExe = 'C:\path\to\Godot_v4.7.2-stable_win64.exe'
$projectPath = Join-Path (Get-Location).Path 'godot'
$env:FREYA_WORLD_SEED = '20260831'
& $godotExe --path $projectPath --resolution 1280x720 --script res://tests/performance_stress.gd
& $godotExe --path $projectPath --resolution 1920x1080 --script res://tests/performance_stress.gd
Remove-Item Env:FREYA_WORLD_SEED
```

Set `FREYA_PERF_PROFILE_GAMEPLAY=1` on the same command to print per-frame dog
decision, collision, animation, and interaction costs, plus roof occlusion and
sightline visibility timing. That diagnostic adds timing overhead, so use an
unprofiled run for the FPS comparison.

## Save Version Compatibility

An older game build preserves save files created by a newer version. The title
screen and pause-menu restart block fresh starts when either the primary or
backup save uses an incompatible version. Resume is blocked too if an otherwise
compatible primary is paired with an incompatible backup, because further
saves would fail. The on-screen notice names the save folder: use the newer
build, or close the game and copy both `friendly_freya_save.json` and its
`.bak` out of that folder before removing the originals and starting fresh.
Ordinary new-game choices and pause-menu `Restart Story` require a keyboard
accessible confirm/cancel step when progress could be replaced or abandoned.

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
./scripts/build_windows_release.sh review-local-next
```

The build script verifies the executable and PCK, confirms the active CC0 dog,
all 24 runtime bark recordings, every exact mapped action cue and its recorded
source file, and the campaign ending
are present, proves inactive model references are absent, adds the player
instructions and legal notices, creates a ZIP, and writes its SHA-256 manifest
under `dist/`.

To run the bundled keyboard campaign QA route against an extracted PCK with a
local Godot 4.7.2 executable, launch it from outside the source project:

```sh
FREYA_EXPORTED_CAMPAIGN_QA=1 FREYA_NATURAL_CAMPAIGN=1 \
  FREYA_WORLD_SEED=20260831 godot --headless \
  --main-pack /absolute/path/to/FriendlyFreya.pck --resolution 960x540
```

The route should log `NATURAL_ROUTE_CREDITS_OK`,
`NATURAL_ROUTE_KEEP_EXPLORING_OK`, and `NATURAL_ROUTE_CAMPAIGN_OK`. It drives
normal gameplay input and may take a full campaign's play time. The earlier
review-f PCK passed this local Linux route on seed 20260831. The local
`review-20261015q` PCK passed exact-content export and its ZIP passed SHA-256
verification against
`8f7cc850f41de195a958193377dcf4b1c0ffd392dcc48810c15a5b562d8fcb8f`.
The preceding review-p ZIP passed SHA-256 verification against
`bf254080089e41261577255d753a76027f73da9f7d574ff155a9e3f6d24bc5a9`;
review-o's PCK passed the packaged press-once keyboard test. The
prior review-k PCK passed a warmed graphical 1280×720 sample on Linux. The
[review-o Windows Actions run](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38794653756)
passed export, EXE startup, packaged performance entry, Watch Intro, and the
full headless campaign route with credits and Keep Exploring. Its
[campaign log](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38794653756/artifacts/12003200905)
records three chapters, six lodge rescues, two allies, and 18 claimed sites
without a game error or warning. The
[Windows review-o artifact](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38794653756/artifacts/12001498322)
contains `Friendly-Freya-manual-15-Windows-x86_64.zip` with SHA-256
`2e6d1f4d9402694f1b82635a4be392a54a8905c782b0bd1f077fd1b12f79a5c0`.
The updated [review-p Windows run](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38806374748)
passed the same export, Windows startup, packaged stress entry, Watch Intro,
and exported three-chapter campaign checks at commit `e6ba0c4`. Its
[download artifact](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38806374748/artifacts/12006173466)
contains `Friendly-Freya-manual-16-Windows-x86_64.zip`, independently verified
against SHA-256
`48d3c8a2bd49a6028f921e4e11348bc65ea006207f244f6d64b5b04e70910db1`.
The [campaign log](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38806374748/artifacts/12008431229)
records all three chapters, six lodge rescues, three allies, 18 claimed sites,
credits, and Keep Exploring without game errors or warnings.
The [review-q Windows run](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38811647736)
passed source validation, export, EXE startup, packaged stress entry, Watch
Intro, and the exported start-to-credits campaign at commit `84ac29e`. Its
[download artifact](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38811647736/artifacts/12008369653)
contains `Friendly-Freya-manual-17-Windows-x86_64.zip`, independently verified
against SHA-256
`c372b3dea33b2774a7a15cf1af439ec8a34037b1e61cf35532f7725547f0a902`.
The [campaign log](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38811647736/artifacts/12010605810)
records three secured chapters, six lodge rescues, four allies, 18 claimed
sites, credits, and Keep Exploring without game errors or warnings.
Graphical playtesting and sustained performance measurement on the HP Victus
remain open.

Use a new review label for each changed build; the script will not overwrite
an existing ZIP. Before a new public release, choose its version and update
the export metadata and release notes to match the new `vMAJOR.MINOR.PATCH`
tag. Review the notes' highlights and install filename against that build.
The current `v0.1.2` metadata and notes describe the earlier published build.

Any pushed `vMAJOR.MINOR.PATCH` tag runs
`.github/workflows/windows-release.yml` for release publication. The workflow
first verifies that the Windows EXE versions, release notes heading, and install
ZIP filename match that tag. It then downloads checksum-pinned official Godot
files, repeats the full project
validation and export, launches the package on `windows-latest`, and publishes
the ZIP and checksum only after the Windows startup smoke and exported
start-to-credits campaign route pass. Other `v*` tags trigger the workflow but
fail the version/metadata guard. A manual `workflow_dispatch` run from a
pushed review branch builds
an Actions artifact, smoke-tests the exported EXE, its bundled performance
entry, and the Watch Intro opening on `windows-latest`, then
runs the bundled keyboard campaign controller through credits and Keep
Exploring in the extracted EXE/PCK. Tag pushes require the same route before
publication. That Windows route is headless and checks
`NATURAL_ROUTE_CREDITS_OK`, `NATURAL_ROUTE_KEEP_EXPLORING_OK`, and
`NATURAL_ROUTE_CAMPAIGN_OK`; the opening smoke checks `WATCH_INTRO_ROUTE_OK`.
The campaign log is uploaded even if the route fails. Manual
runs do not publish a GitHub Release, including when dispatched from a tag.
A passing route verifies exported Windows input and campaign logic, while visual
Windows review, unfamiliar-player playtests, and minimum-PC performance still
require their own checks. GitHub reports this repository as public, so treat
published Release assets as public too.

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
