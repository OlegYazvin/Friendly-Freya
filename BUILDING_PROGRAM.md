# Friendly Freya Building Program

[Documentation hub](README.md) · [Godot overview](godot/README_GODOT.md) ·
[Codebase map](docs/CODEBASE_MAP.md) · [Gameplay direction](GAMEPLAY_AUDIT.md)

**Status:** implemented in the generated neighborhood.

## Entry and Occupation Rules

- Every generated building is enterable while it is not alien-occupied.
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
  and the clinic never become free-alien generators merely because they have
  interiors.

## Building Types

| Type | Interior identity | Current gameplay use |
| --- | --- | --- |
| Ranch residence | Warm sitting room, kitchen fixture, and dining furniture | Enterable ground-floor residence |
| Two-story residence | Green-accent family-room variant | Enterable ground floor; upper floor closed |
| Three-story residence | Purple-accent walk-up variant | Enterable ground floor; upper floors closed |
| Northbrook Pharmacy | Prescription counter, medicine shelving, green cross dispenser | Freya picks up one dose and gives it to a freed dog; that dog records permanent possession immunity |
| Northbrook Grocery | Produce/meat stands, refrigerators, and a dog bowl | The permanent bowl can be eaten from repeatedly and always sets Hunger to zero |
| Northbrook Police | Blue desk/lockers and a dog-armor rack | Freya carries one armor set to a freed dog, which receives visible fitted armor |
| Northbrook Medical Clinic | Reception/exam furniture, wall cabinets, and medical cross | Deliberately has no gameplay function yet |

All NPC dogs still begin possessed. Pharmacy medicine and police armor can only
be administered after Freya has de-possessed the dog, preserving the existing
hidden-possession loop.

## Presentation

- Procedural residences now use hollow wall shells instead of solid boxes.
- Residential doors and windows are real openings; glass is transparent and
  the furnished ground floor can be seen from outdoors.
- Named public buildings have distinct palettes, readable façade labels, and
  type-specific furnishings.
- Interior fixtures participate in the same manual blocker/reachability model
  used by Freya, dogs, and aliens.

## Runtime Ownership and Checks

`godot/scripts/main.gd` assigns the building roster, builds interiors and
services, manages entry/focus, and validates the program. 
`godot/scripts/building_factory.gd` owns the hollow residential shell,
transparent glazing, upper-floor slabs, roofs, and porches.
`godot/scripts/dog_agent.gd` owns the fitted dog-armor visual.

Run `./scripts/predeploy_size_checks.sh` for the full executable gate. The
`building_*` images in `visual_regressions/` are the deterministic exterior and
interior review views.
