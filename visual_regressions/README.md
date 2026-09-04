# Friendly Freya Visual Regressions

[Documentation hub](../README.md) · [Run and validation guide](../RUN_FRIENDLY_FREYA.md) ·
[Visual implementation record](../VISUAL_RECOMMENDATIONS.md) ·
[Intro specification](../INTRO_CUTSCENE.md)

> **Status:** Current deterministic reference-image catalog. The PNGs are
> review evidence, not replacements for automated checks or manual playtesting.

These deterministic reference views cover the geometry and visibility
relationships called out by the visual audit.

## Intro and Startup References

- [startup_menu.png](startup_menu.png) — the first-launch choice over generated heroic Freya key art in a Northbrook-inspired urban streetscape, now under a brighter, welcoming early-evening sky; `Watch Intro` remains focused and `Skip To Game` remains available in the dark menu panel.
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

## Gameplay and World References

- [pause_menu.png](pause_menu.png) — the in-game pause menu with `Watch Intro` available alongside the normal gameplay controls.
- [wide_gable.png](wide_gable.png) — long-axis gable ridge, shingles, soffit, fascia, and wall support.
- [wide_hip.png](wide_hip.png) — long-axis hip ridge, shingles, soffit, fascia, and wall support.
- [storefront.png](storefront.png) — transparent storefront openings with the furnished store visible outside.
- [home_outside.png](home_outside.png) — Freya's home exterior, transparent windows, yard identity with a claimable mailbox, and roof connection.
- [home_inside.png](home_inside.png) — the scaled, partitioned interior with Freya and Ryah Diane.
- [post_intro_food_tutorial.png](post_intro_food_tutorial.png) — the first controllable home moment with Freya fully hungry, her first-person eat-first guidance, and the pulsing arrow/ring identifying her bowl.
- [first_exit_leashed.png](first_exit_leashed.png) — Freya's first post-meal exit frames three temporary people and their city dogs connected by clearly visible leashes on the street-side sidewalk.
- [first_exit_abduction.png](first_exit_abduction.png) — separate two-ring beams lift the three people while every dog remains leashed and held out of its normal AI.
- [first_exit_owners_gone.png](first_exit_owners_gone.png) — the people and leashes are gone, leaving the three dogs at the release beat immediately before their default behavior resumes.
- [dog_park_friendly.png](dog_park_friendly.png) — the reduced six-dog shared-rig cast inside a complete two-rail gated fence, with weave poles, hurdle, A-frame, crawl tunnel, and readable camouflage collars on recruited dogs.
- [army_collars.png](army_collars.png) — a dedicated multi-breed lineup showing the readable camouflage plates, edge bands, top panels, and buckles at normal presentation scale.
- [alien_model.png](alien_model.png) — the canonical grounded voxel-imp view: a slightly smaller imp in a deterministic mid-stride three-quarter close-up beside Freya for scale.
- [alien_occupied.png](alien_occupied.png) — an occupied house, rooftop crown, façade mutation, minimap state, ordinary-looking possessed dog, and Freya's unease clue.
- [alien_store_stronghold.png](alien_store_stronghold.png) — an occupied storefront and its capped free-alien pressure in neighborhood context.
- [ryah_defense.png](ryah_defense.png) — Freya's open home interior with Ryah Diane's tears and cry waves; the home remains unoccupied.

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

To regenerate one startup/intro image, use `FREYA_INTRO_CAPTURE_ONLY`:

```sh
FREYA_INTRO_CAPTURE_ONLY=intro_09_family_pills ./scripts/capture_intro_regressions.sh
```

Capture generation overwrites same-name PNGs. Inspect every changed image after
generation and confirm framing, geometry, visibility, and UI readability before
accepting it. Then run the validation command from the
[run guide](../RUN_FRIENDLY_FREYA.md); a successful screenshot command alone is
not a complete regression check.

Deterministic headless validation and static-view modes use a fixed city seed;
ordinary graphical play remains randomized. UFO captures seek through
`FREYA_INTRO_VIEW`; live-home family captures seek through
`FREYA_FAMILY_INTRO_VIEW`. Static captures never play audio or auto-advance.
