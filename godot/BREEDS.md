# Dog Breeds (Strict Definitions)

The authoritative breed config is in:

- `res://scripts/main.gd`
- `const DOG_BREED_DEFINITIONS`
- `const NPC_BREED_SEQUENCE`

Each breed definition controls:

- `breed_profile` (procedural morphology fallback in `DogAgent`)
- `model_candidates` (preferred 3D model files for that breed)
- `coat_palette` (allowed coat colors for that breed)
- `speed_range` (NPC movement range)
- `base_scale` + `scale_jitter` (model scale behavior)
- `target_length_mult` + `target_height_mult` (realistic relative size profile vs Freya baseline)

## Current Runtime Model Policy

- NPC spawn uses animated models only.
- If a breed's model candidates do not contain walk/run animations, spawn falls back to the animated Freya Portuguese water dog rig.
- This keeps visual style + walk animation consistency across all dogs.

## Current Breed IDs

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
