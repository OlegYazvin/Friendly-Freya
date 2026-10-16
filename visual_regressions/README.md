# Friendly Freya Visual Regressions

[Documentation hub](../README.md) · [Run and validation guide](../RUN_FRIENDLY_FREYA.md) ·
[Visual implementation record](../VISUAL_RECOMMENDATIONS.md) ·
[Intro specification](../INTRO_CUTSCENE.md)

> **Status:** Current deterministic reference-image catalog. The PNGs are
> review evidence, not replacements for automated checks or manual playtesting.

These deterministic reference views cover the geometry and visibility
relationships called out by the visual audit.

Camera cutaways use cached rendered mesh bounds, including roof overhangs and
neighboring buildings. Removed wall attachments follow their supporting walls;
ceiling fixtures disappear with the interior cutaway. Cinematic subjects are
framed above dialogue, gameplay labels/ghost overlays are cleared, and temporary
visibility is restored at handoff. Normal gameplay retains a prop-occlusion
outline fallback.

## Intro and Startup References

The three translated UFO lines remain on screen until the player presses Next;
the English reference views show their fully readable held state.

- [startup_menu.png](startup_menu.png) — the first-launch choice over generated heroic Freya key art in a Northbrook-inspired urban streetscape, with `New Game: Watch Intro` focused and `New Game: Skip Intro` and `Settings` available in the dark menu panel.
- [startup_resume.png](startup_resume.png) — the same title layout with `Resume Game` focused as it is when a valid save exists; checks that all four choices remain visible and readable.
- [startup_new_game_confirm.png](startup_new_game_confirm.png) — the saved-campaign new-game warning with keyboard focus on `Keep Progress` before an existing save can be replaced.
- [intro_01_establishing.png](intro_01_establishing.png) — Earth through the hero UFO bridge with exactly Aliens A, B, and silent C.
- [intro_02_a_question_runes.png](intro_02_a_question_runes.png) — Alien A's speech bubble during the initial rune reveal.
- [intro_02_a_question_morph.png](intro_02_a_question_morph.png) — the same bubble midway through visible rune-to-English transformation.
- [intro_02_a_question_english.png](intro_02_a_question_english.png) — Alien A's first translated sentence.
- [intro_03_b_answer_english.png](intro_03_b_answer_english.png) — Alien B's translated response, wrapped legibly and anchored to B.
- [intro_04_a_command_english.png](intro_04_a_command_english.png) — Alien A's final translated command.
- [intro_05_fleet.png](intro_05_fleet.png) — Earth and exactly eight similar, opaque-exterior UFOs after the camera pullback.
- [intro_06_family_home.png](intro_06_family_home.png) — the actual generated map home with persistent Freya/Ryah, photo-referenced Gene/Zoe models, clear Freya/Ryah spacing, complete camera-away and physical right walls, and the matching back roof surface.
- [intro_07_family_gene.png](intro_07_family_gene.png) — Gene's longest job line wrapped inside the wide human-dialogue panel.
- [intro_08_family_zoe.png](intro_08_family_zoe.png) — Zoe's long drug-description line and curly-haired native-style character.
- [intro_09_family_pills.png](intro_09_family_pills.png) — Gene raising both hands to hold up nine readable pharmacy pill bottles.
- [intro_10_family_abduction.png](intro_10_family_abduction.png) — separate two-ring transfer columns surrounding Gene and Zoe, with Gene's bottle bundle dropped as a scattered floor spill.
- [intro_11_family_ryah_targeted.png](intro_11_family_ryah_targeted.png) — the parents gone and Ryah surrounded by the same transfer effect.
- [intro_12_family_loud_bark.png](intro_12_family_loud_bark.png) — Freya's super-loud bark wave collapsing Ryah's transfer.
- [intro_13_family_ryah_saved.png](intro_13_family_ryah_saved.png) — Ryah and Freya remain in the live home after the interrupted transfer, with the dropped pills still present.
- [intro_14_family_pill_eat.png](intro_14_family_pill_eat.png) — the lower profile angle shows Freya dipping toward and consuming the shrinking bottle-and-capsule spill.
- [intro_15_family_convulsion.png](intro_15_family_convulsion.png) — Freya's comic squash, hop, wobble, orbiting rings, and colorful star reaction.
- [intro_16_family_monologue.png](intro_16_family_monologue.png) — the exact new internal-monologue line before the eat-first gameplay tutorial begins.

## Campaign Ending References

- [ending_01_signal_breaks.png](ending_01_signal_breaks.png) — the last alien signal fails and the captive transport returns Gene and Zoe alive, with Freya guarding Ryah until the beam fades.
- [ending_02_family_reunion.png](ending_02_family_reunion.png) — Ryah reunites with Gene and Zoe, with Freya's recruited dogs acknowledged in the epilogue.
- [ending_03_freya_rest.png](ending_03_freya_rest.png) — the freed Dog Lodge captives and Freya's care for Ryah pay off before the family rests.
- [ending_04_credits.png](ending_04_credits.png) — the scrollable credits, including the food recording's CC BY 4.0 credit, and focused Keep Exploring and Replay Story choices, with optional campaign summary metadata.
- [ending_05_replay_confirm.png](ending_05_replay_confirm.png) — the ending's saved-campaign replay warning with keyboard focus on `Keep Credits` before a new story can replace completed progress.

## Gameplay and World References

- [pause_menu.png](pause_menu.png) — the in-game pause menu with keyboard focus on Resume and `Restart Story` available alongside the normal gameplay controls.
- [pause_restart.png](pause_restart.png) — the pause-menu restart warning, focused on `Keep Playing` while the current session remains paused.
- [pause_controls.png](pause_controls.png) — the Page Up/Down scrollable control reference, including the keyboard-focused optional press-once Space/C setting, keyboard `-`/`=` zoom, the `G` goals pin, pack orders, and chapter continuation.
- [pause_howto.png](pause_howto.png) — the Page Up/Down scrollable explanation of the three-chapter campaign, orange active-source badge, optional press-once long actions, keyboard camera control, ally defense, services, and lodge rescue.
- [chapter_guide.png](chapter_guide.png) — the enlarged first-chapter guidance panel suggests an optional first park drill before the initial territory action and can be hidden with `H`; the minimap shows `M` medicine, `F` food, `A` armor, and `C` clinic care, plus a cyan diamond for the next highlighted site and an orange `!` for the nearest active source.
- [chapter_guide_2.png](chapter_guide_2.png) — at 960×540, the larger skippable `H` panel persists into chapter 2 and tells Freya where to collect ally protection and which dog can receive it.
- [chapter_guide_3.png](chapter_guide_3.png) — at 960×540, after the final signal is cleared without pack help, the larger panel explains the recoverable clean-ally guard action at the signal site without clipping.
- [wide_gable.png](wide_gable.png) — long-axis gable ridge, shingles, soffit, fascia, and wall support.
- [wide_hip.png](wide_hip.png) — long-axis hip ridge, shingles, soffit, fascia, and wall support.
- [storefront.png](storefront.png) — transparent storefront openings with the furnished store visible outside.
- [building_residence_outside.png](building_residence_outside.png) — hollow suburban residence shell with real entrance and transparent windows.
- [building_residence_inside.png](building_residence_inside.png) — ground-floor-only residential cutaway with that residence's complete batched lower shell removed around Freya.
- [building_pharmacy_inside.png](building_pharmacy_inside.png) — prescription shelving, counter, and immunity-medicine dispenser.
- [building_grocery_inside.png](building_grocery_inside.png) — produce/meat fixtures and permanent dog-food point.
- [building_police_inside.png](building_police_inside.png) — police lockers and dog-armor rack.
- [building_clinic_inside.png](building_clinic_inside.png) — furnished medical interior with a care kit that can free a re-possessed ally or calm a frightened dog.
- [home_outside.png](home_outside.png) — Freya's already-controlled home exterior, transparent windows, subtle Freya-territory tint, yard identity with a claimable mailbox, and roof connection.
- [home_inside.png](home_inside.png) — the scaled, partitioned interior with Freya and Ryah Diane, framed by the two camera-away walls of the gameplay cutaway.
- [kennel_live.png](kennel_live.png) — the guaranteed Northbrook Dog Lodge lot on the generated neighborhood map, showing its initial occupied façade, entry lock, Freya, and the teal paw minimap marker.
- [chapter_goals.png](chapter_goals.png) — the scrollable `Tab`/`G` goals show the first chapter's highlighted-site, ally, lodge, stronghold, and generator tasks; an active storefront's imp output and 22m reinforcement range are spelled out. The cyan diamond shows the named next site, while the orange `!` identifies the nearest active source at the minimap edge.
- [chapter_goals_status.png](chapter_goals_status.png) — at 960×540, the orange source badge and its legend remain visible while a live imp warning stays readable in a reserved strip inside pinned goals and the tasks remain scrollable above it.
- [chapter_relay.png](chapter_relay.png) — the chapter 2 scent relay label above its seeded alien hold, with Freya at the site.
- [chapter_relay_goals.png](chapter_relay_goals.png) — the chapter 2 objectives name the same relay building and give its distance and alien-wall action.
- [chapter_final_recovery.png](chapter_final_recovery.png) — the final signal has been cleared and all four sites claimed; the goals explain the recoverable recruited-ally guard action while the cleared final site remains highlighted on the minimap.
- [chapter_result.png](chapter_result.png) — the first chapter result and Continue Story or Keep Exploring choice.
- [chapter_result_final.png](chapter_result_final.png) — the final chapter result and path to the family ending.
- [post_intro_food_tutorial.png](post_intro_food_tutorial.png) — the first controllable home moment with the corrected two-wall cutaway, Freya fully hungry, her first-person eat-first guidance, and the pulsing arrow/ring identifying her bowl.
- [first_exit_leashed.png](first_exit_leashed.png) — Freya's first post-meal exit frames three temporary people and their still-ordinary city dogs, safely staged farther down the street-side sidewalk and connected by clearly visible leashes.
- [first_exit_abduction.png](first_exit_abduction.png) — separate two-ring beams lift the three people while every dog remains leashed and held out of its normal AI.
- [first_exit_owners_gone.png](first_exit_owners_gone.png) — the people, leashes, and beams are gone while the three dogs remain held for the next cinematic beat.
- [first_exit_dog_possession.png](first_exit_dog_possession.png) — purple, cyan, and magenta energy visibly descends into the three ordinary-looking dogs.
- [first_exit_freya_immunity.png](first_exit_freya_immunity.png) — the matching possession energy ricochets away from Freya while a mint immunity burst expands from her.
- [first_exit_immunity_thought.png](first_exit_immunity_thought.png) — Freya's exact immunity conclusion and Continue button remain visible until the player advances the cinematic.
- [dog_park_friendly.png](dog_park_friendly.png) — the reduced six-dog shared-rig cast inside a complete two-rail gated fence, with weave poles, hurdle, A-frame, crawl tunnel, and readable camouflage collars on recruited dogs.
- [pack_squad.png](pack_squad.png) — three active recruited dogs near Freya, two reserve dogs holding posts, and the follow-order status with the active/reserve counts.
- [pack_assist_context.png](pack_assist_context.png) — Pack Assist chooses the nearby highlighted residence and names it in the order status, with recruited allies beside Freya and the distant active-source badge separate from the next-site diamond.
- [pack_guard_dog.png](pack_guard_dog.png) — the guard order names a nearby clean independent dog while the three active recruited dogs remain available to protect it.
- [supply_target.png](supply_target.png) — Freya carries dog armor near two allies; the nearer ally already wears a vest, so the single interaction ring marks the unarmored ally that `F` will protect.
- [supply_target_960.png](supply_target_960.png) — at 960×540, Freya carries a clinic kit; the short persistent hint names the eligible dog state, and one ring marks the retaken ally that `F` will help.
- [dog_park_training_weave.png](dog_park_training_weave.png) — Freya following the alternating slalom path with a fast gait and side-to-side body lean.
- [dog_park_training_hurdle.png](dog_park_training_hurdle.png) — Freya airborne over the bar at the apex of the contextual hurdle interaction.
- [dog_park_training_aframe.png](dog_park_training_aframe.png) — Freya aligned to the A-frame slope during her climb-over animation.
- [dog_park_training_tunnel.png](dog_park_training_tunnel.png) — Freya's lowered, compressed crawl pose inside the open-ended tunnel.
- [army_collars.png](army_collars.png) — a dedicated multi-breed lineup showing the readable camouflage plates, edge bands, top panels, and buckles at normal presentation scale.
- [alien_model.png](alien_model.png) — the canonical grounded voxel-imp view: a slightly smaller imp in a deterministic mid-stride three-quarter close-up beside Freya for scale.
- [alien_occupied.png](alien_occupied.png) — an occupied house, rooftop crown, façade mutation, minimap state, ordinary-looking possessed dog, and Freya's unease clue.
- [alien_occupied_scent.png](alien_occupied_scent.png) — a neighboring Freya-owned building grants a visible scent support bonus on an occupied house, helping weaken its hold.
- [alien_store_stronghold.png](alien_store_stronghold.png) — an occupied storefront labeled as a 22m imp source, with its capped free-alien pressure and static orange `!` minimap badge in neighborhood context.
- [ryah_defense.png](ryah_defense.png) — Freya's open home interior with Ryah Diane's tears and cry waves; the home remains unoccupied.

## Kennel Close-up References

- [kennel_clean.png](kennel_clean.png) — the standalone clean Northbrook Dog Lodge exterior with complete roof/walls, transparent front glazing, public door, and recognizable kennel signage.
- [kennel_interior.png](kennel_interior.png) — the roofless review cutaway showing six open-bar cages, six distinct shared-rig voxel dogs, reception/wash fixtures, and Freya's exact one-time promise.
- [kennel_possessed.png](kennel_possessed.png) — the locked static infestation after three accepted spawn requests, with three ordinary-looking shared-rig voxel dogs and three of six lifetime capacity pods remaining.

## Legacy and Ad Hoc References

- [alien_demon_model_closeup.png](alien_demon_model_closeup.png) — legacy close-up retained for historical comparison. It is not generated by the current capture scripts; [alien_model.png](alien_model.png) is the canonical tracked alien reference.

## Regenerating Captures

The checked-in scripts target the project's Linux/Flatpak capture environment.
Before running either script:

- Work from the repository root.
- Close every running Friendly Freya or Godot instance; the scripts stop rather
  than capture an ambiguous window.
- Ensure `host-spawn`, Flatpak Godot, `wmctrl`, and `xwd` are available on the
  host, with an X11-visible desktop session, and ensure local `ffmpeg` is
  installed.

Regenerate the gameplay/world set only with:

```sh
./scripts/capture_visual_regressions.sh
```

Regenerate the startup/intro set only with:

```sh
./scripts/capture_intro_regressions.sh
```

Run **both** commands to regenerate every current scripted baseline; neither
script alone produces that complete set. The legacy ad hoc alien close-up is
intentionally left unchanged.

To regenerate one gameplay/world image, set `FREYA_CAPTURE_ONLY` to its output
name without `.png`:

```sh
FREYA_CAPTURE_ONLY=wide_gable ./scripts/capture_visual_regressions.sh
```

If a host desktop popup appears through the captured window, move the capture
window to a clear part of the desktop before its first frame. For a 960×540
view on a 1920×1080 desktop, for example:

```sh
FREYA_CAPTURE_ONLY=chapter_guide_2 FREYA_CAPTURE_WINDOW_POSITION=900,120 \
  ./scripts/capture_visual_regressions.sh
```

To regenerate one startup/intro image, use `FREYA_INTRO_CAPTURE_ONLY`:

```sh
FREYA_INTRO_CAPTURE_ONLY=intro_09_family_pills ./scripts/capture_intro_regressions.sh
```

Capture generation overwrites same-name PNGs. Inspect every changed image after
generation and confirm framing, geometry, visibility, and UI readability before
accepting it. Then run the validation command from the
[run guide](../RUN_FRIENDLY_FREYA.md); a successful screenshot command alone is
not a complete regression check.

Both scripts launch through `godot/tests/capture_ready.gd` and wait for the
requested scene's first rendered frames before taking the X11 screenshot. They
fail on startup errors or a readiness timeout, rather than accepting Godot's
splash screen after a fixed delay. Static world views suppress incidental
possessed-dog tutorial popups; ordinary gameplay routes retain them.

Deterministic headless validation and static-view modes use a fixed city seed;
ordinary graphical play remains randomized. UFO captures seek through
`FREYA_INTRO_VIEW`; live-home family captures seek through
`FREYA_FAMILY_INTRO_VIEW`; the four campaign ending pages seek through
`FREYA_ENDING_VIEW`. Static captures never play audio or auto-advance.
