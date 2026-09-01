# Model Assets and Dog Model Policy

[Documentation hub](../../../README.md) ·
[codebase map](../../../docs/CODEBASE_MAP.md) ·
[Godot project overview](../../README_GODOT.md) ·
[breed system](../../BREEDS.md)

**Status:** Current runtime policy and inventory for model files distributed in
`godot/assets/models/`. Godot-generated `.import` files are omitted below.

## Runtime Policy

Friendly Freya intentionally uses one shared dog art source:

- `freya_portuguese_water_dog.glb`

Freya and every NPC instantiate that voxel mesh and its authored
skeleton/animations. Breed variation is applied at runtime through bone
proportions, target dimensions, coat palettes, and accessories. This keeps
limbs, shading, geometry density, and animation timing stylistically consistent
across the entire cast.

The other dog GLBs retained in this directory are inactive reference assets. Do
not add them to [`NPC_DOG_MODEL_CANDIDATES`](../../scripts/main.gd) unless they
are first rebuilt on the same voxel art specification and animation rig as
Freya.

Buildings currently use the procedural construction path in
[`building_factory.gd`](../../scripts/building_factory.gd). The external
`building_house.glb` candidate is registered there, but
`EXTERNAL_HOUSE_MODEL_CHANCE` is `0.0`, so it is disabled at runtime.

## Distributed Asset Inventory

### Active dog model

- `freya_portuguese_water_dog.glb` — the sole model in both Freya and NPC dog
  candidate lists
- `freya_portuguese_water_dog_Atlas.png` — associated texture atlas

### Inactive dog reference assets

- `dog_golden.glb`
- `dog_golden_Tex_Puppy.png`
- `dog_husky.glb`
- `dog_labrador.glb`
- `dog_labrador_Tex_Beagle.png`
- `dog_neighbor_01.glb`
- `dog_neighbor_02.glb`

### Inactive external building assets

- `buildings/building_house.glb` and
  `buildings/building_house_PUSHILIN_house.png` — registered external candidate,
  currently disabled by the `0.0` selection chance
- `buildings/building_apartment.glb` and
  `buildings/building_apartment_Apartment_BaseColor.png`
- `buildings/building_big.glb`
- `buildings/building_large_01.glb`
- `buildings/building_large_02.glb`
- `buildings/building_roofgarden.glb`

The building assets other than `building_house.glb` are not referenced by the
current runtime scripts.

## Provenance and Release Blocker

The repository does not currently contain source, author, or license records
for the distributed GLBs or their associated texture files. Do not infer those
details from filenames or embedded mesh names.

Before any redistribution or release, recover and record verifiable provenance
and license terms for each retained model bundle, or replace it with an asset
whose provenance and redistribution rights are documented. This requirement
applies to the active Freya model as well as the inactive reference assets.
