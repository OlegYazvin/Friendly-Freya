# Dog Kennel Building Concept

[Documentation hub](README.md) · [Gameplay direction](GAMEPLAY_AUDIT.md) ·
[Codebase map](docs/CODEBASE_MAP.md) · [Capture catalog](visual_regressions/README.md)

> **Status:** Placement-ready concept, intentionally not instantiated by normal
> map generation. The reusable building, behavior controller, preview scene,
> captures, and automated contract checks exist now; live-map placement and the
> eventual dog-rescue outcome remain future work.

## Identity and Read

The archetype is `dog_kennel`, presented as the **Northbrook Dog Lodge**: a
one-story red-brick neighborhood boarding/daycare building with teal trim, a
large glazed storefront, a central public entrance, paw logos, a reception
desk, wash station, floor drain, and two banks of barred kennels.

The building footprint is `10.8m × 7.6m`. Its three transparent front openings
make the reception area and cages visible from outside. The clean interior has
six cages and six distinct shared-rig dogs. The cages use open bar frames on all
sides so their occupants remain readable from the public aisle and from the
cutaway camera.

All six captive dogs carry the same hidden possessed origin state as the rest
of the game's dog population, without possession-only cosmetics. Freya can
de-possess each one independently through the normal dog-exorcism interaction;
the cage does not make possession permanent. They remain caged afterward,
because physical release is still reserved for the rescue-mechanic pass.

Both captive and kennel-spawned dogs use the same shared Portuguese Water Dog
voxel mesh, rig, authored animation, runtime breed shaping, coat treatment, and
ordinary accessories as every dog on the live map. Possession never swaps in a
placeholder model or adds a visible marker.

## State Contract

| State | Entry | Presentation | Spawn behavior |
| --- | --- | --- | --- |
| Clean | Enterable through the central door | Warm lights, transparent glazing, service/open signage, six initially possessed caged dogs | No possessed-dog generation; Freya may de-possess individual caged dogs |
| Possessed | Locked and non-enterable | Static purple window membranes, crossed door lock, façade veins, roof spires, exterior spawn aperture, and remaining-capacity pods | Requests one possessed dog every `8s` until 6 successful lifetime spawns or until Freya cleanses the building |

Possession does not pulse the building. The infestation is a static
architectural state, consistent with the game's occupied-building rules.

### First Entry

The first time Freya enters the clean kennel in a level, the controller emits
one exact first-person thought:

> I'll find a way to free you!

The line fires once. Repeat entries return no dialogue. A possessed kennel is
not enterable and therefore cannot consume the first-entry event. The promise
establishes a future rescue objective; no cage-opening or dog-release mechanic
has been invented yet.

### Finite Possessed-Dog Generation

- Spawn interval: `8.0s` while possessed.
- Lifetime maximum: exactly `6` successfully created possessed dogs.
- Cleansing the kennel permanently closes that level's production run. Any
  unspawned portion of the six-dog budget is forfeited, so cleansing after two
  confirmed spawns leaves exactly two kennel-spawned dogs and prevents the
  remaining four from appearing—even if the kennel is later re-possessed.
- Only a new-level reset restores the six-spawn budget. This prevents toggling
  possession to farm unlimited dogs.
- Six façade pods represent the remaining lifetime budget and extinguish as
  accepted spawns accumulate.
- The controller emits `possessed_dog_spawn_requested(position, spawn_number)`
  at its exterior aperture. The future map owner must instantiate and register
  a normal dog character with hidden `alien_possessed` state, then call
  `confirm_possessed_dog_spawned(spawn_number)`. If another dog cannot be
  safely placed, it calls `reject_possessed_dog_spawn_request(retry_delay)`.
  Rejected requests do not consume the kennel's lifetime budget.
- Spawned dogs retain the ordinary breed/collar variation used throughout the
  game and use its canonical voxel rig. They enter the normal dog lifecycle
  with hidden possession enabled, so Freya can de-possess them like any other
  map dog. Possession adds no identifying cosmetic and does not consume or
  bypass the separate map-wide free-alien limit.

No sound is attached to the kennel concept. A later sound request must use an
authored file; missing audio remains silent under the project audio policy.

## Placement Contract

`KennelBuilding.placement_contract()` exposes the integration data instead of
coupling the concept to current random map generation:

- archetype and display name;
- `10.8m × 7.6m` footprint;
- local interior rectangle;
- inside and outside entry points;
- exterior possessed-dog spawn point;
- five shell blockers plus cage/reception/wash-station fixture blockers;
- transparent-window and caged-dog counts;
- canonical shared voxel-dog model and caged-dog de-possession hook;
- clean/possessed enterability;
- exact first-entry text;
- spawn interval, lifetime cap, request signal, confirmation method, and retry
  method;
- explicit kennel-cleansing method and the rule that cleansing forfeits every
  unspawned dog.

When placement is requested, Main still needs to select a lot with sufficient
frontage, merge these blockers into its walkability cache, connect the entry
transition to the normal thought UI, connect spawn requests to the normal dog
NPC lifecycle with hidden possession enabled, and register occupation/minimap
state. Main must also route the standard bark/exorcism interaction to caged
dogs in range and call the kennel controller's de-possession hook. None of
those map mutations are made by this concept pass.

## Owning Files

| Concern | File |
| --- | --- |
| Geometry, materials, cage banks, caged dogs, clean/possessed visual layers | `godot/scripts/kennel_factory.gd` |
| Entry-once state, enterability, finite spawn budget, integration contract | `godot/scripts/kennel_building.gd` |
| Deterministic cameras, explanatory UI, sample spawned possessed dogs, validation | `godot/scripts/kennel_concept.gd` |
| Standalone preview shell | `godot/scenes/KennelConcept.tscn` |

## Reviewed References

- [Clean exterior](visual_regressions/kennel_clean.png)
- [Clean interior and exact first-entry thought](visual_regressions/kennel_interior.png)
- [Possessed exterior after three accepted possessed-dog spawns](visual_regressions/kennel_possessed.png)

Regenerate an individual view with:

```sh
FREYA_CAPTURE_ONLY=kennel_clean ./scripts/capture_visual_regressions.sh
FREYA_CAPTURE_ONLY=kennel_interior ./scripts/capture_visual_regressions.sh
FREYA_CAPTURE_ONLY=kennel_possessed ./scripts/capture_visual_regressions.sh
```

The complete predeploy wrapper loads the standalone scene and proves the
placement metadata, shared voxel rig, six initially possessed/de-possessable
caged dogs, exact one-time line, clean entry, possessed lockout, spawn
handshake, partial-cleanse forfeiture, and hard six-possessed-dog lifetime cap.
