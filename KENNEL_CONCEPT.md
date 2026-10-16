# Northbrook Dog Lodge

[Documentation hub](README.md) · [Gameplay direction](GAMEPLAY_AUDIT.md) ·
[Codebase map](docs/CODEBASE_MAP.md) · [Capture catalog](visual_regressions/README.md)

> **Status:** Playable in the generated neighborhood. Main places the lodge on
> a reserved lot near the dog park, and the standalone concept scene remains a
> deterministic close-up for visual review and contract checks.

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

All six captive dogs begin secretly possessed, without possession-only
cosmetics. Once the lodge is cleansed, Freya can hold `R` near each cage to
expel that dog's alien. Pressing `F` beside a cleansed dog opens its cage. The
released dog joins the normal roaming and recruitment systems. Releasing all
six completes the lodge rescue objective, regardless of when the building was
cleansed.

Both captive and kennel-spawned dogs use the same shared Portuguese Water Dog
voxel mesh, rig, authored animation, runtime breed shaping, coat treatment, and
ordinary accessories as every dog on the live map. Possession never swaps in a
placeholder model or adds a visible marker.

## State Contract

| State | Entry | Presentation | Spawn behavior |
| --- | --- | --- | --- |
| Clean | Enterable through the central door | Warm lights, transparent glazing, service/open signage, six initially possessed caged dogs | No further generation; Freya may expel each captive's alien and open its cage |
| Possessed | Locked and non-enterable | Static purple window membranes, crossed door lock, façade veins, roof spires, exterior spawn aperture, and remaining-capacity pods | Requests one possessed dog every `8s` until 6 successful lifetime spawns or until Freya cleanses the building |

The lodge begins in the possessed state. Freya can hold `Space` beside its wall
to weaken and cleanse it through the normal building interaction. The
infestation is a static architectural state, consistent with other occupied
buildings.

### First Entry

The first time Freya enters the clean kennel in a level, the controller emits
one exact first-person thought:

> I'll find a way to free you!

The line fires once. Repeat entries return no dialogue. A possessed lodge is
not enterable and therefore cannot consume the first-entry event. The six
captives remain available for rescue after any early cleanse.

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
  at its exterior aperture. Main places and registers a normal dog with hidden
  `alien_possessed` state, then confirms the accepted spawn. If another dog
  cannot be safely placed, Main rejects the request and retries later.
  Rejected requests do not consume the lodge's lifetime budget.
- Spawned dogs retain the ordinary breed/collar variation used throughout the
  game and use its canonical voxel rig. They enter the normal dog lifecycle
  with hidden possession enabled, so Freya can de-possess them like any other
  map dog. Possession adds no identifying cosmetic and does not consume or
  bypass the separate map-wide free-alien limit.

Opening a cage plays a [recorded CC0 metal-gate cue](godot/assets/audio/ATTRIBUTION.md)
when its mapped asset loads. Missing audio remains silent under the project
audio policy.
Each confirmed live possessed-dog spawn within 14 world units of Freya plays
one exact [recorded CC0 bark](godot/assets/audio/ATTRIBUTION.md#dog-barks).
Distant spawns, failed requests, and save restoration stay silent.

## Placement Contract

`KennelBuilding.placement_contract()` supplies Main's live-map integration:

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
  unspawned dog;
- individual captive de-possession, cage-release hooks, and rescue count.

Main reserves a frontage-compatible lot near the dog park and adds the lodge
to its building roster. It merges the shell and fixture blockers into
walkability, uses the normal entrance and roof cutaway, reports alien
occupation, and marks the lodge with a teal paw on the minimap. The controller
owns its finite spawn budget and six cage flags; Main owns the interaction,
normal dog roster, and save reconstruction. Saves preserve the spawn budget,
timer, first-entry flag, each dog's cage state, and the stable IDs of spawned
and rescued dogs.

## Owning Files

| Concern | File |
| --- | --- |
| Geometry, materials, cage banks, caged dogs, clean/possessed visual layers | `godot/scripts/kennel_factory.gd` |
| Entry-once state, enterability, finite spawn budget, cage release, save state | `godot/scripts/kennel_building.gd` |
| Guaranteed placement, occupied-building state, interactions, dog lifecycle, minimap | `godot/scripts/main.gd` |
| Static lodge marker | `godot/scripts/minimap.gd` |
| Deterministic cameras, explanatory UI, sample spawned possessed dogs, validation | `godot/scripts/kennel_concept.gd` |
| Standalone preview shell | `godot/scenes/KennelConcept.tscn` |

## Reviewed References

- [Live occupied lodge in the neighborhood](visual_regressions/kennel_live.png)
- [Clean exterior](visual_regressions/kennel_clean.png)
- [Clean interior and exact first-entry thought](visual_regressions/kennel_interior.png)
- [Possessed exterior after three accepted possessed-dog spawns](visual_regressions/kennel_possessed.png)

Regenerate an individual view with:

```sh
FREYA_CAPTURE_ONLY=kennel_live ./scripts/capture_visual_regressions.sh
FREYA_CAPTURE_ONLY=kennel_clean ./scripts/capture_visual_regressions.sh
FREYA_CAPTURE_ONLY=kennel_interior ./scripts/capture_visual_regressions.sh
FREYA_CAPTURE_ONLY=kennel_possessed ./scripts/capture_visual_regressions.sh
```

The complete predeploy wrapper checks the standalone contract and the live
placement: shared voxel rigs, six initially possessed captives, one-time line,
occupied lockout, finite spawn handshake, early-cleanse forfeiture, reachable
cages, per-dog bark and release, rescue completion, and snapshot restoration.
