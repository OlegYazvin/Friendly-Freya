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
