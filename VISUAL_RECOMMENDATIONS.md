# Friendly Freya Visual Implementation Record

[Documentation hub](README.md) · [Original visual request](New%20changes.md) ·
[Gameplay audit](GAMEPLAY_AUDIT.md) ·
[Regression catalog](visual_regressions/README.md)

> **Status:** Completed implementation record. This document preserves the
> recommendations that guided the neighborhood, storefront, character, and
> Freya-home polish; it is not an active backlog. Runtime code and current
> validation results remain authoritative.

These follow-up improvements were identified during the live neighborhood,
storefront, and Freya-home review.

## Implementation Status

All recommendations below are recorded as implemented. Automated target checks
cover measurable invariants; deterministic, manually reviewed images cover the
visual relationships. Their regeneration workflow is documented in the
[visual regression catalog](visual_regressions/README.md).

## Character Readability

- [x] Replace the floating alien orb with a slightly smaller opaque voxel imp: blocky horns, glowing pixel eyes and chest rune, fangs, articulated arms and legs, grounded feet, and a spade-tipped tail.
- [x] Give the imp a distance-driven alternating gait and a dedicated natural-scale three-quarter reference view beside Freya.
- [x] Make army membership unmistakable at gameplay zoom with a broad, high-contrast camouflage collar, readable top panel, edge bands, and buckle fitted around each breed's neck; retain no overhead indicator.

## Priority 1 — Readability and Architectural Detail

- [x] Add subtle asphalt-shingle courses and two or three roof colors. The corrected roof geometry now reads properly, but the large unbroken roof surfaces can still feel visually flat at close zoom.
- [x] Add window sills, shallow interior reveals, and a small amount of curtain or blind variation. Transparent glass now exposes the interiors, so these details will make the transition between exterior and interior feel finished.
- [x] Replace the remaining blockout-style furniture with simple assembled forms: tapered table legs, chair rails, cabinet doors, sofa cushions, and bed rails. Keep all measurements tied to the existing meter-based scale metrics.
- [x] Add interior ceiling-light pools or baked-looking emissive fixtures near visible windows. This will improve interior legibility without requiring expensive real-time lights.

## Priority 2 — Suburban Neighborhood Character

- [x] Give individual homes small yard identities using hedges, flower beds, porch planters, claimable mailboxes, house numbers, and short front paths. Mailboxes use the same owner-colored claim-ring and minimap feedback as other scent targets. Keep the neighborhood free of ambient crowds and cars; the three temporary dog walkers exist only for the authored first-exit abduction.
- [x] Add restrained driveway or garage-pad variation even when no vehicle is present. This is common visual structure in a Northbrook-style neighborhood and helps break up continuous grass.
- [x] Vary porch shapes between stoops, small covered porches, and low decks while preserving collision clearance.
- [x] Add a few backyard details that do not imply extra people: grills, garden beds, sheds, hose reels, and children’s outdoor toys near Freya’s home.

## Priority 3 — Materials, Lighting, and Camera Polish

- [x] Add modest contact shadows or ambient-occlusion emphasis around foundations, eaves, furniture feet, and storefront awnings. Many shadows are currently disabled for performance, so a lightweight baked or material-based treatment would add depth.
- [x] Reduce façade obstruction by keeping large tree crowns and streetlight poles out of primary entrances and storefront-window sightlines.
- [x] Add small color/value differences between foundations, siding trim, soffits, and fascia so building layers remain readable at the default camera distance.
- [x] Review roof cutaway timing near doorways. Roofs should disappear slightly before Freya crosses an interior boundary when the camera’s view is already blocked.

## Completed Validation Additions

- [x] Screenshot regression views for a wide gable house, a wide hip-roof house, a storefront from outdoors, Freya’s home from outdoors, and Freya’s home from indoors.
- [x] Add a dedicated multi-breed army-collar regression view and validate broad collar dimensions, camouflage color variation, neck mounting, edge bands, top panel, buckle, and the absence of overhead indicators.
- [x] Validate the reduced imp scale against Freya and retain the deterministic mid-stride alien reference view.
- [x] Validate that every residential mailbox remains visible and retained as an accessible target while supporting Freya/enemy claim rings, reclaim state, pee impact placement, and matching minimap markers.
- [x] Continue validating dimensions in meters: door height, wall height, furniture height, aisle width, window sill height, and usable room area relative to Freya.
- [x] Track the number of transparent enterable-building windows and verify that no opaque wall occupies the same opening.
