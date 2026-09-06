# Friendly Freya Intro Cut-Scene

[Documentation hub](README.md) · [Run and validation](RUN_FRIENDLY_FREYA.md) ·
[Codebase map](docs/CODEBASE_MAP.md) ·
[Capture catalog](visual_regressions/README.md) ·
[Audio attribution](godot/assets/audio/ATTRIBUTION.md)

**Document role:** current subsystem reference for the intended timeline,
staging, and handoff. The runtime files and executable validators listed below
are authoritative for exact implementation.

This document is the canonical, scene-by-scene edit guide for the full opening
sequence. The five-scene UFO segment runs in `IntroCutscene.tscn`; natural
completion hands a one-shot request to `Main.tscn`, where the family segment
runs inside the actual generated map home before control is released to Freya.
Both halves use absolute-time timelines and deterministic regression views.

## Editable Architecture

| Concern | Primary edit surface |
| --- | --- |
| Startup and in-game replay routes | [Startup.tscn](godot/scenes/Startup.tscn), [startup.gd](godot/scripts/startup.gd), [main.gd](godot/scripts/main.gd) |
| UFO scene order, times, speakers, runes, and English | [intro_timeline.gd](godot/scripts/intro_timeline.gd) |
| UFO camera, bubble morph, Earth, lighting, audio, and validation | [intro_cutscene.gd](godot/scripts/intro_cutscene.gd) |
| Family writing, timeline times, and capture checkpoints | [family_intro_timeline.gd](godot/scripts/family_intro_timeline.gd) |
| Live-home staging, gameplay lock, effect/audio thresholds, validation, and handoff | [main.gd](godot/scripts/main.gd) |
| Gene, Zoe, pill bottles, beams, bark waves, and possession energy | [family_visual_factory.gd](godot/scripts/family_visual_factory.gd) |
| Shared alien geometry and idle/walk pose | [alien_visual_factory.gd](godot/scripts/alien_visual_factory.gd) |
| UFO bridge and opaque fleet geometry | [ufo_visual_factory.gd](godot/scripts/ufo_visual_factory.gd) |
| Runtime cut-scene entry | [IntroCutscene.tscn](godot/scenes/IntroCutscene.tscn) |
| Rune and translation sound files | [audio/intro](godot/assets/audio/intro/) |
| Audio source/license record | [audio attribution](godot/assets/audio/ATTRIBUTION.md) |

Both renderers seek their timelines by absolute time instead of chaining
Tweens, and named capture views can jump to important beats. The timeline files
are not the only edit sites: validators intentionally duplicate expected
dialogue, and `main.gd` owns several family effect and audio thresholds. A line
or timing change must be synchronized with its validator, this guide, affected
Main thresholds, and the relevant reviewed captures.

## Scene 00 — Startup Choice

- Runtime scene: `Startup.tscn`
- Timing: untimed; appears every normal application launch.
- During gameplay, press `Esc` and select `Watch Intro` to replay the cut-scene at any time. The pause state is cleared before routing; finishing or skipping the replay starts a fresh game.
- Visible UI: title, invasion prompt, `Watch Intro`, and `Skip To Game`.
- Default focus: `Watch Intro`.
- `Watch Intro` route: `IntroCutscene.tscn`.
- `Skip To Game` route: `Main.tscn`.
- Selection behavior: both buttons immediately lock after either choice so two
  destination changes cannot race.
- Edit point: presentation lives in `Startup.tscn`; route invariants and startup
  validation live in `startup.gd`.

## Scene 01 — Bridge Establishing

- Stable ID: `scene_01_bridge_establishing`
- Timeline: `0.0–2.8s`
- Regression view: `FREYA_INTRO_VIEW=establishing`
- Purpose: establish three demonic aliens inside the hero UFO while it hovers
  over Earth.
- Visible roots: `InteriorShot`, `InteriorEarth`, `HeroUFOInterior`, and
  `AlienCast`.
- Earth presentation: the globe floats unsupported in space; seven named,
  coastline-shaped land/ice meshes conform to its surface with no box cap or
  pedestal beneath it.
- Cast positions:
  - Alien A: left/front bridge station.
  - Alien B: right/front bridge station.
  - Alien C: center/rear bridge station.
- Camera: slow, subtle cockpit dolly toward the three grounded voxel imps.
- Dialogue: none.
- Audio cue: none.
- Transition: direct continuation into Alien A's first speech bubble.
- Edit points: cast positions in `_create_interior_shot`; bridge geometry in
  `ufo_visual_factory.gd`; scene end in `intro_timeline.gd`.

## Scene 02 — Alien A: The Question

- Stable ID: `scene_02_alien_a_question`
- Timeline: `2.8–8.0s`
- Regression views:
  - `FREYA_INTRO_VIEW=a_question_runes`
  - `FREYA_INTRO_VIEW=a_question_morph`
  - `FREYA_INTRO_VIEW=a_question_english`
- Speaker: Alien A.
- Bubble anchor: projected above Alien A's head through the active 3D camera.
- Initial rune text: `|<[]> /\ <>{} ^|?#`
- Final English: `So this is the place?`
- Progression:
  1. The bubble appears and reveals nonsensical runes for `1.1s`.
  2. Rune cells progressively resolve into English for `1.4s`.
  3. The exact English sentence remains readable for the rest of the scene.
- Sound cues:
  - `rune_reveal.ogg` once when the rune bubble begins.
  - `translation_resolve.ogg` once when translation begins.
- Transition: the A bubble clears before the B bubble takes over.
- Edit points: speaker, text, and durations are all in this scene's timeline
  dictionary.

## Scene 03 — Alien B: The Answer

- Stable ID: `scene_03_alien_b_answer`
- Timeline: `8.0–15.0s`
- Regression views:
  - `FREYA_INTRO_VIEW=b_answer_runes`
  - `FREYA_INTRO_VIEW=b_answer_english`
- Speaker: Alien B.
- Bubble anchor: projected above Alien B's head.
- Initial rune text: `^><, ][|/\ {}[]^ ><\/\'? ##|<>{}|<>{}?`
- Final English: `Yes, the planet that can't get its shit together.`
- Progression:
  1. Nonsensical runes reveal for `1.1s`.
  2. Runes progressively resolve for `1.6s`.
  3. The longer English sentence receives the sequence's longest reading hold.
- Sound cues: one exact rune reveal cue and one exact translation cue.
- Transition: the B bubble clears before Alien A's final command.
- Edit points: speaker, text, and durations are in `intro_timeline.gd`.

## Scene 04 — Alien A: The Command

- Stable ID: `scene_04_alien_a_command`
- Timeline: `15.0–19.4s`
- Regression views:
  - `FREYA_INTRO_VIEW=a_command_runes`
  - `FREYA_INTRO_VIEW=a_command_english`
- Speaker: Alien A.
- Initial rune text: `<|^'[] /\>{}|<`
- Final English: `Let's begin`
- Progression:
  1. Runes reveal for `1.0s`.
  2. Runes resolve into English for `1.3s`.
  3. The command holds through the end of the bridge shot.
- Sound cues: one exact rune reveal cue and one exact translation cue.
- Alien C rule: Alien C never owns a dialogue entry or speech bubble anywhere in
  the timeline.
- Transition: a short black mask hides the switch from the bridge interior to
  the hero UFO exterior.

## Scene 05 — Fleet Reveal

- Stable ID: `scene_05_fleet_reveal`
- Timeline: `19.4–25.5s`
- Regression view: `FREYA_INTRO_VIEW=fleet`
- Purpose: reveal the invasion scale.
- Visible roots: `FleetShot`, `FleetEarth`, `FleetRoot`, and eight named ships
  `UFO_00` through `UFO_07`.
- Fleet count: exactly eight UFOs total, including the hero ship whose bridge was
  shown earlier.
- Exterior rule: all eight ships use the same opaque exterior factory signature.
  No bridge/interior nodes or transparent dome materials are visible.
- Camera: begins close on the hero ship, then continuously dollies backward and
  widens its field of view until Earth and the full eight-ship formation appear.
- Dialogue/bubble: none.
- Speech audio: none.
- End transition: natural completion sets a one-shot family-intro handoff and
  opens `Main.tscn`. Main generates the map and actual home before beginning the
  family sequence. Skipping the UFO segment bypasses that sequence.
- Edit points: ship positions/scales in `_create_fleet_shot`; exterior geometry
  in `ufo_visual_factory.gd`; camera endpoints in `_apply_fleet_camera`.

## Scenes 06–25 — Family Prologue in the Live Map Home

- Runtime scene: `Main.tscn`; this is not a duplicate cutscene house.
- Timeline: `0.0–64.0s` relative to the start of the family segment.
- Stable data: `family_intro_timeline.gd`.
- Set rule: Main first generates its normal randomized map, selects Freya's real
  home, builds the shell/interior/furniture, and creates the persistent Freya
  and Ryah nodes. Only then does the family prologue stage those exact objects.
- Cutaway rule: the camera-facing wall remains open, but the complete wall away
  from the camera and the home's right wall are restored with their windows,
  curtains, and trim. The right wall appears at screen-left in this composition.
- Roof rule: only the roof surface behind the restored back wall is drawn. It
  uses the generated home's real style, pitch, footprint, and shingle material.
- Camera rule: the family sequence retains its original left-side perspective
  through Ryah's rescue; the added pill-eating/reaction beats cut to a lower
  profile angle so the floor spill and Freya's mouth remain visible.
- Freya staging: Freya remains at least `1.4m` from Ryah and faces inward toward
  Ryah, Gene, and Zoe through the abduction. After saving Ryah she turns toward
  the dropped bottles, approaches them, and eats them.
- Gameplay rule: movement, Hunger, dogs, aliens, Ryah wandering, and actions are
  locked during the sequence. Completion or an in-family skip removes the
  temporary cinematic objects and unlocks control without reloading the map.
  Gene drops the nine-bottle bundle during his beam, leaving a scattered floor
  spill. After Ryah is safe, Freya eats the spill, squash-stretches and hops
  through a colorful comic convulsion, and discovers her internal monologue:
  `Oh wow. I have an internal monologue now! This is weird. I'm hungry!` Freya
  then begins the first controllable moment at `100%` Hunger. Two exact authored
  barks introduce her first-person instruction to eat and investigate outside,
  while a pulsing arrow/ring identifies her permanent bowl. Until she eats,
  crossing the home boundary triggers one exact reminder bark, displays `I have
  to eat first,`, and automatically turns her back into the house. Eating resets
  Hunger to zero and removes both the guidance and exit gate. Her first exit
  frames three people walking city dogs on visible leashes. Separate beams
  abduct the people and the leashes disappear. Purple/cyan possession energy
  then descends into the dogs. The same energy targets Freya, strikes her, and
  visibly ricochets up and away while an immunity burst expands from her. Freya
  concludes, `Whatever's happening to those other dogs seems like I'm immune
  from it. Interesting.` Only after that exact thought clears do the dogs resume
  their ordinary autonomous behavior and control return.
- Character references: Gene uses dark hair, a full beard/mustache, rectangular
  glasses, a dark gray shirt, gray pants, and brown shoes. Zoe uses layered
  light-brown curls, a black top, dark pants, and dark shoes. Both are stylized
  to match the native low-poly Ryah/home presentation.

| Stable ID | Time | Speaker/action |
| --- | ---: | --- |
| `family_00_home_establishing` | 0.0–2.0 | Actual map home, Ryah, Freya, Gene, and Zoe establish. |
| `family_01_zoe_last_day` | 2.0–6.5 | Zoe congratulates Gene on his last day. |
| `family_02_gene_new_job` | 6.5–13.0 | Gene explains Elon's licensed-pharmacist job. |
| `family_03_zoe_drug` | 13.0–20.0 | Zoe describes the drug's three effects. |
| `family_04_gene_last_part` | 20.0–23.0 | Gene questions the last effect. |
| `family_05_laugh` | 23.0–25.0 | Gene and Zoe: `Ha, ha, ha`. |
| `family_06_zoe_gift` | 25.0–28.4 | Zoe asks about "celebration materials." |
| `family_07_gene_pills` | 28.4–35.8 | Gene raises both hands and holds up nine pharmacy pill bottles. |
| `family_08_zoe_ryah` | 35.8–39.8 | Zoe asks who will watch Ryah. |
| `family_09_gene_freya` | 39.8–41.7 | Gene: `Freya will!` |
| `family_10_freya_bark` | 41.7–43.0 | Freya barks once. |
| `family_11_zoe_interrupted` | 43.0–45.0 | Zoe begins `Okay, ope---`. |
| `family_12_parents_abducted` | 45.0–48.0 | Two-ring beams surround Gene and Zoe; Gene drops the bottles to the floor and both parents disappear. |
| `family_13_ryah_targeted` | 48.0–50.0 | The same transfer effect begins around Ryah. |
| `family_14_freya_loud_bark` | 50.0–51.2 | Freya's super-loud bark collapses Ryah's effect. |
| `family_15_ryah_saved` | 51.2–52.4 | Ryah remains and her collapsed transfer effect clears. |
| `family_16_freya_approaches_pills` | 52.4–54.0 | Freya turns toward and approaches the dropped bottles. |
| `family_17_freya_eats_pills` | 54.0–55.2 | Freya eats the shrinking bottle-and-capsule spill. |
| `family_18_freya_convulses` | 55.2–59.0 | Freya hops, squashes, wobbles, and spins through colorful comic reaction rings and stars. |
| `family_19_internal_monologue` | 59.0–64.0 | Freya discovers her exact internal-monologue line; the cinematic then clears and fully hungry bowl guidance begins. |

## Speech-Bubble Audio Policy

The UFO half has six deterministic authored sound events: rune reveal and
translation resolve for each alien line. The family half maps the normal and
super-loud Freya beats to two exact existing recorded bark files. The
post-intro eat-first prompt and boundary reminder map only to the same exact
normal Freya recording; a missing file produces silence. Dialogue remains
text-only.

- No sound is synthesized or generated at runtime.
- There is no candidate list and no replacement clip.
- If one mapped file is missing or fails to decode/play, only that event is
  silent. The other mapped file remains independent.
- Skipping either half stops its active audio players before gameplay resumes.
- The loud bark changes playback gain only; it does not synthesize or replace
  the authored recording.

See [the audio attribution record](godot/assets/audio/ATTRIBUTION.md) for source
URLs, original archive names, licenses, and unchanged-file details.

## Validation and Captures

Run all startup, intro, and gameplay checks:

```sh
./scripts/predeploy_size_checks.sh
```

Capture every startup/intro reference frame:

```sh
./scripts/capture_intro_regressions.sh
```

Capture just one frame, for example the final fleet:

```sh
FREYA_INTRO_CAPTURE_ONLY=intro_05_fleet ./scripts/capture_intro_regressions.sh
```

The script overwrites tracked reference PNGs. Review every changed image; the
capture command is an update tool, not an image-diff assertion. See the
[capture catalog](visual_regressions/README.md) for prerequisites and all stable
output names.

The validators check the UFO scene IDs/times, exact alien cast and dialogue,
audio schedules, Earth, fleet, and natural handoff. They also seek the live-home
timeline to check all exact family lines, Gene/Zoe likeness signatures, held
and dropped pill bottles, two rings around each parent, both disappearance
checkpoints, Ryah's interrupted transfer, Freya's pill-eating, convulsion, and
monologue beats, both exact bark schedules, the eat-first handoff, and the
first-exit leashed-owner abduction, dog-possession effects, Freya's rejected
possession effect, exact immunity thought, and delayed dog release.
