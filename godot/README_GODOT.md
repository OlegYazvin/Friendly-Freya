# Friendly Freya Godot Project

[Documentation hub](../README.md) · [Run and validation](../RUN_FRIENDLY_FREYA.md) ·
[Codebase map](../docs/CODEBASE_MAP.md) · [Gameplay direction](../GAMEPLAY_AUDIT.md) ·
[Intro guide](../INTRO_CUTSCENE.md)

This directory is the authoritative Godot source for Friendly Freya. The
project declares its feature target in `project.godot` and uses the OpenGL
compatibility renderer. See the run guide for the editor version last used to validate it.

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
The configured entry scene is `Startup.tscn`: choose `New Game: Watch Intro`,
`New Game: Skip Intro`, `Resume Game` when a valid save exists, or `Settings`. Settings currently contains a master-volume
slider. Its background is generated cinematic key art of the real three-legged
Freya in a Northbrook-inspired brick town-center streetscape.

## Controls

- Startup: choose `New Game: Watch Intro`, `New Game: Skip Intro`, `Resume Game`
  when available, or `Settings`. The first new-game choice has keyboard focus
  on a fresh install; `Resume Game` has focus when a save exists. Starting over
  with a saved campaign opens a confirmation focused on `Keep Progress`.
- Intro: `Space` / Next completes the current line, then advances the beat.
  `Esc` / Skip To Game skips the current cinematic.
- `WASD` or Arrow keys: move Freya; `Shift`: run.
- `Q` / `E`: rotate the camera; mouse wheel: zoom.
- `F`: eat nearby food or bones, use a dog-food bowl, pick up a stick, collect
  pharmacy medicine or police armor, give carried supplies to a freed dog, or
  use a park training obstacle from either end;
  `V`: drop a carried stick.
- Hold `C` near a dog: socialize at a Hunger cost. A possessed dog also raises
  Vomit; only sustained socializing after cleansing recruits a dog into Freya's
  army. Contact before cleansing earns no recruitment progress.
- Hold `R` near a dog: bark aggressively, stand ground against possessed dogs,
  expel an alien, or scare a real dog away. Bark near a visible imp to interrupt
  its attempt.
- `1` / `2` / `3`: order the active pack to follow Freya, guard a nearby clean
  dog (otherwise her current spot), or assist at a nearby building. The first three eligible allies form the
  active squad; later recruits hold their own guard posts and defend nearby dogs.
- Hold `Space`: claim trees, light poles, hydrants, mailboxes, and eligible building
  interiors; weaken an alien building beside its wall; or search a nearby
  dumpster.
- `X`: vomit when the Vomit meter is full; the burst can interrupt nearby imps.
- `H`: show or hide the current chapter's next-step guidance panel.
- Hold `Tab` for temporary objectives, or press `G` to pin and unpin the goals
  while playing. Page Up and Page Down scroll the goals. Pausing clears the pin.
- `Esc` during gameplay: pause or resume. `Resume` receives keyboard focus when
  the menu opens, so Enter also resumes. The Controls and How To Play panels
  scroll with Page Up and Page Down while open. `Save Game` writes current progress,
  and `Quit Game` saves before exiting. `Restart Story` warns before ending the
  current session and starting a new game through the intro; Escape returns to
  the paused session.

The in-game pause menu is the closest player-facing source for controls. Input
bindings are configured in `main.gd` under `_configure_input` and
`_unhandled_input`.

## Save and Resume

Gameplay autosaves every 45 active seconds. The pause menu offers `Save Game`,
and `Quit Game` saves before exiting. A failed quit save keeps the session open
and displays a retry message. `Resume Game` appears on the title menu
when a valid `user://friendly_freya_save.json` or its backup exists. Saves
include the generated seed, campaign chapter, targets and progress, territory and alien
occupation, dogs, active pack orders and reserve guard posts, supplies, meters,
kennel budget and cages,
and story flags. Scent and building records use stable positions rather than
scene nodes. The save format is versioned and checksummed; a damaged primary
file can be recovered from its previous valid backup. If a later build changes
the generated map so substantially that progress cannot be matched safely, the
game starts a fresh neighborhood and leaves the old save untouched. A primary
save from an unsupported game version hides Resume even if an older backup
exists. If either save slot is incompatible, this build blocks new-game and
restart routes, with instructions to use a matching build or archive both
files before starting fresh. A compatible primary paired with an incompatible
backup cannot be resumed in this build because saving would fail.

## Implemented Gameplay at a Glance

- A selectable UFO intro leads into a twenty-beat family prologue staged in the
  actual generated map home. Gene drops his pills during abduction; after
  saving Ryah, Freya eats them, has a comic convulsion, and discovers her
  internal monologue. Freya then starts fully hungry, and an authored-bark
  thought prompt plus a pulsing bowl pointer keeps her inside until she eats.
- Skipping the intro starts Freya at home near her bowl at `100%` Hunger.
  Food guidance is optional, the exit is open, and dog aggression is enabled.
- On Freya's first exit after the family prologue, three temporary dog walkers appear farther down the
  street-side sidewalk with initially ordinary leashed city dogs. Alien beams
  abduct the people, visible possession energy turns the dogs aggressive, and
  the same energy targets Freya but bounces away. Freya recognizes
  her immunity in an internal-monologue panel before the dogs resume their
  normal autonomous behavior.
- An isometric procedural suburban neighborhood surrounds a center-block dog
  park with six dogs, a complete gated fence, and varied agility equipment.
  Every clean building is enterable: scattered ranch, two-story, and three-story
  residences expose their furnished bottom floor, alongside a pharmacy,
  grocery, police station, clinic, and Freya's persistent home.
- Freya is a black, three-legged Portuguese Water Dog rendered with the shared
  voxel dog rig. NPC breeds use that rig with distinct proportions, scale,
  coats, and ordinary accessories.
- Hunger starts at `100%`, rises very slowly at rest after eating, and rises
  faster while walking, running, or taking sustained actions. Home-bowl food
  resets Hunger to zero.
- Every roaming NPC dog begins secretly possessed. The three first-exit dogs
  are held ordinary on their leashes until the visible possession beat.
  Possession never changes dog appearance; the event and Freya's unease supply
  the clues. After that reveal (or immediately on an intro-skip route), possessed dogs bark aggressively and scare
  Freya away unless the player holds `R` to bark back and stand ground.
- Socialization costs Hunger and raises Vomit around a possessed dog. Recruited
  dogs wear a broad camouflage neck collar with no overhead indicator. A
  recruited pack can follow, guard, or assist a building claim; Social and
  first-time park training improve its help.
- Dog exchanges draw from independent recorded conversational, excited-social,
  and aggressive bark pools. Each pool cycles through every clip before reuse
  and prevents the same recording at a cycle boundary.
- Grounded voxel imp aliens use collision-aware movement. Expelled/free aliens
  travel to reachable exterior points before occupying buildings. Free imps
  can also approach vulnerable real dogs, telegraph an interruptible transfer,
  and secretly possess them again. Barking, pack defense, and full-meter Vomit
  can interrupt an imp. Medicine prevents another possession permanently;
  armor absorbs one attempt.
- Any occupied building locks its entrance and interior service. Occupied
  retail storefronts additionally reinforce nearby alien buildings and
  exclusively generate a map-wide maximum of eight free aliens. Their world
  labels identify the 22m reinforcement radius; `Tab` describes the 10–17s
  interval for each active source.
- The grocery has an infinite reusable dog-food bowl; the pharmacy supplies
  possession-immunity medicine for freed dogs; the police station supplies
  visible doggy armor. The clinic provides a care kit that frees a retaken
  ally or calms a frightened dog. `F` selects one eligible dog, marked by the
  interaction ring, and does not spend medicine on an immune dog or armor on
  an armored or immune dog. During chapter 2 it favors an unprotected recruited
  ally; an independent dog can still receive protection and counts after
  recruitment. The grocery bowl takes `F` before a carried supply when Freya
  stands within its service range.
- Buildings track Freya ownership and alien occupant counts. Freya owns her
  home by default. Other clean buildings become claimable only after the nearby
  pee targets are marked and the building connects to Freya territory on the
  same generated block or a cardinal-neighbor block. Holding `Space` inside for 10
  seconds claims the building; partial building progress decays when interrupted.
  Claimed territory gets a subtle yellow ground tint and Ryah Diane's scribbly
  Freya stake near the entrance. Nearby claimed buildings give Freya a visible
  scent bonus while she weakens an alien hold. Chapter 1 asks for eight highlighted
  properties, two cleared occupations, one freed ally, every active generator
  disabled, and all six kennel captives rescued. Chapter 2 follows a five-site
  scent trail and asks Freya to protect two allies with medicine or intact armor.
  Chapter 3 narrows to four sites and a pack-assisted final stronghold before
  Gene and Zoe's ending. The final site remains marked after being cleared, so
  Freya can return with a recruited ally and guard it if she cleared it alone.
  The next-step guide suggests an optional park drill after first recruitment,
  then explains ally protection in chapter 2 and pack help or guard recovery
  at the final signal in chapter 3;
  each first drill adds 8% to a dog's pack assist. The chapter result panel
  continues the story; owning every building remains an optional completion
  challenge.
  Hold `Tab` or press `G` near a building to inspect missing marks and its
  territory connection.
- Alien architecture and minimap states are static, while holding `Space` by an
  occupied wall breaks its hold and makes the building enterable/claimable again.
  The minimap labels the four service types: `M` for pharmacy medicine, `F` for
  grocery food, `A` for police armor, and `C` for clinic care. A fixed cyan
  diamond marks the next site named in the Tab goals; when that site is beyond
  the current zoomed view, the diamond rests at the map edge in its direction.
  At a service building, the diamond sits beside its letter so both stay visible.
- Scent claims cover trees, light poles, hydrants, and residential mailboxes.
  Bones raise Strength; sticks can be carried and increase run speed.
- All mapped action effects use exact sourced recordings. If a mapped file is
  unavailable, its action is silent.

For exact current/future distinctions, use
[GAMEPLAY_AUDIT.md](../GAMEPLAY_AUDIT.md). For breed details, use
[BREEDS.md](BREEDS.md).

## Northbrook Dog Lodge

The [kennel](../KENNEL_CONCEPT.md) occupies a guaranteed lot near the park and
starts alien-occupied, with a teal paw on the minimap. Hold `Space` at its wall
to cleanse it; Freya's first clean entry prompts her promise to find a way to
free the six caged dogs. Hold `R` near a captive to expel its alien, then press
`F` at its cage to release it into the normal dog roster. While occupied, the
lodge can produce at most six possessed dogs, one accepted spawn every eight
seconds. Cleansing forfeits any unspawned portion of that lifetime budget,
without preventing rescue of the six captives.

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
