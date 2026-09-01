# Dog Breeds (Strict Definitions)

[Documentation hub](../README.md) · [Godot overview](README_GODOT.md) ·
[Gameplay direction](../GAMEPLAY_AUDIT.md) ·
[Model policy](assets/models/README_MODELS.md)

**Document role:** current subsystem policy. Runtime definitions and schema
validation in [main.gd](scripts/main.gd) are authoritative.

The authoritative breed config is in:

- [scripts/main.gd](scripts/main.gd)
- `const DOG_BREED_DEFINITIONS`
- `const NPC_BREED_SEQUENCE`

Each breed definition controls:

- `breed_profile` (active shared-rig bone reshaping and procedural fallback
  morphology in `DogAgent`)
- `model_candidates` (preferred 3D model files for that breed)
- `coat_palette` (allowed coat colors for that breed)
- `speed_range` (NPC movement range)
- `base_scale` + `scale_jitter` (model scale behavior)
- `target_length_mult` + `target_height_mult` (realistic relative size profile vs Freya baseline)
- strict schema validation in headless smoke checks (`_breed_definition_issues` in `main.gd`)

## Current Runtime Model Policy

- Freya and every NPC breed use the same
  [Portuguese Water Dog voxel asset](assets/models/freya_portuguese_water_dog.glb), rig,
  authored gait, material language, and animation timing.
- Breeds are approximated inside that common art style through deterministic
  body, head, muzzle, leg, and tail proportions; target height/length; and
  breed-appropriate coat palettes.
- This intentionally favors a coherent voxel cast over mixing realistic or
  low-poly models from unrelated sources. If the shared model is unavailable,
  the built-in procedural voxel dog remains the last-resort fallback.

See the [model inventory and provenance status](assets/models/README_MODELS.md)
before adding, replacing, or redistributing model assets.

## Army Alignment Collar Policy

- A recruited dog's ordinary accessory is replaced by a broad camouflage collar
  fitted to that breed's reshaped neck frame.
- High-contrast block-color plates, bright edge bands, a readable top panel, and
  a buckle keep the collar obvious from the normal overhead camera across small
  and large breeds.
- The collar communicates army membership only. Possession remains visually
  secret, and no icon or indicator appears above the dog.

## Current Breed IDs

- `labrador`
- `pitbull`
- `boxer`
- `chihuahua`
- `retriever`
- `shepherd`
- `husky`
- `terrier`
- `hound`
- `bulldog`
- `poodle`
- `mixed`

## Mixes

Mixed dogs are generated with:

- deterministic `primary` + `secondary` breeds from the strict pool
- deterministic `primary_ratio` blend
- explicit metadata passed into each dog:
  - `breed_id`
  - `breed_mix.primary`
  - `breed_mix.secondary`
  - `breed_mix.primary_ratio`

This metadata is already sent in `DogAgent.configure(...)`, so prompt-driven future systems can read/extend it without changing spawn architecture.
