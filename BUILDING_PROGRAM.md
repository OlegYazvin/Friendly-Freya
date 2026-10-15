# Friendly Freya Building Program

[Documentation hub](README.md) · [Godot overview](godot/README_GODOT.md) ·
[Codebase map](docs/CODEBASE_MAP.md) · [Gameplay direction](GAMEPLAY_AUDIT.md)

**Status:** implemented in the generated neighborhood.

## Entry and Occupation Rules

- Every generated building is enterable while it is not alien-occupied. The
  placed Northbrook Dog Lodge starts occupied and opens after cleansing.
- Freya and Ryah Diane's home keeps its bespoke interior and tutorial rules.
- Every other building uses the shared collision-safe interior system and a
  centered street-facing entrance.
- Multi-story residences expose only the furnished ground floor. Exterior upper
  stories and floor slabs remain visible, but there is no stair access.
- Alien occupation sets the building non-enterable, blocks its complete
  footprint, disables its service, ejects Freya if necessary, and adds static
  contamination bars plus the existing occupant-count display.
- Retail alien generation remains separate from entry: only the pharmacy and
  grocery have `generates_free_aliens = true`. Residences, the police station,
  clinic, and lodge never become free-alien generators merely because they
  have interiors. The occupied lodge separately has a finite six-dog output.

## Building Types

| Type | Interior identity | Current gameplay use |
| --- | --- | --- |
| Ranch residence | Warm sitting room, kitchen fixture, and dining furniture | Enterable ground-floor residence |
| Two-story residence | Green-accent family-room variant | Enterable ground floor; upper floor closed |
| Three-story residence | Purple-accent walk-up variant | Enterable ground floor; upper floors closed |
| Northbrook Pharmacy | Prescription counter, medicine shelving, green cross dispenser | Freya picks up one dose and gives it to a freed dog; that dog records permanent possession immunity |
| Northbrook Grocery | Produce/meat stands, refrigerators, and a dog bowl | The permanent bowl can be eaten from repeatedly and always sets Hunger to zero |
| Northbrook Police | Blue desk/lockers and a dog-armor rack | Freya carries one armor set to a freed dog; the visible vest absorbs one imp possession attempt |
| Northbrook Medical Clinic | Reception/exam furniture, wall cabinets, and care cabinet | Freya carries one care kit to free a repossessed ally or calm a frightened dog |
| Northbrook Dog Lodge | Six transparent cages and shared-rig captive dogs | Cleansing opens the occupied lodge; bark at captives and press `F` to release each clean dog |

All ordinary NPC dogs still begin possessed. Pharmacy medicine and police armor
can only be given to a freed dog, preserving the hidden-possession loop. Clinic
care can recover a recruited dog after a new imp takes it, or end a real dog's
temporary fright after a wrong bark. The lodge's six caged dogs can always be
rescued after cleansing, even when its remaining spawn budget is forfeited.

## Presentation

- Procedural residences now use hollow wall shells instead of solid boxes.
- Residential doors and windows are real openings; glass is transparent and
  the furnished ground floor can be seen from outdoors.
- Named public buildings have distinct palettes, readable façade labels, and
  type-specific furnishings.
- Interior fixture selection uses Freya's store-wall clearance and checks
  doorway-connected aisle segments. Service props sit at walkable interior
  points, so Freya can reach them and use `F` from the entrance.

## Runtime Ownership and Checks

`godot/scripts/main.gd` assigns the building roster, builds interiors and
services, manages entry/focus, and validates the program. 
`godot/scripts/building_factory.gd` owns the hollow residential shell,
transparent glazing, upper-floor slabs, roofs, and porches.
`godot/scripts/dog_agent.gd` owns the fitted dog-armor visual.

Run `./scripts/predeploy_size_checks.sh` for the full executable gate. The
`building_*` images in `visual_regressions/` are the deterministic exterior and
interior review views. `godot/tests/service_reachability.gd` checks all four
services from their doorways across five generated seeds using Freya's live
collision rules and then verifies each service effect.
