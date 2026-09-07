# Friendly Freya Gameplay Audit and Direction

[Documentation hub](README.md) · [Run and validation](RUN_FRIENDLY_FREYA.md) ·
[Codebase map](docs/CODEBASE_MAP.md) · [Dog breeds](godot/BREEDS.md) ·
[Completed visual record](VISUAL_RECOMMENDATIONS.md) ·
[Capture catalog](visual_regressions/README.md)

**Document role:** living design reference and current-build audit. Sections and
bullets marked **implemented** describe the current build; **future** and
**required change** are specifications only. Runtime code and executable
validation remain the authority for exact behavior.

## Canonical Rules

### Dogs Have Two Independent States

There are no angel dogs or devil dogs. Every NPC is always a real dog, and a real dog may additionally be possessed by a demon alien.

- **Possession:** `real` or `possessed`.
- **Army alignment:** `independent` or `Freya's army`.
- Every NPC dog begins a new game possessed; cleansing creates the real-dog
  state the player can then befriend.
- A cleansed dog becomes real; it does not become an angel dog.
- An army dog remains a real dog and may eventually have a lower—but not necessarily zero—risk of re-possession.
- Possession must remain visually secret. Breed, body, coat, animation, and ordinary cosmetics cannot reveal it.

Friendly alignment uses a broad, high-contrast, neck-mounted camouflage-pattern collar that remains obvious at normal gameplay zoom, with no icon or indicator above the dog. Wings, horns, halos, and other angel/devil imagery are removed from dog alignment feedback.

### Aggressive Bark Is an Exorcism Test

Aggressive barking has one purpose: testing for and expelling possession.

- Barking at a possessed dog expels its alien.
- Barking at a real dog scares the dog away. Its flee response is the player's feedback that the guess was wrong.
- Aggressive barking must not turn a real or cleansed dog into a hostile/devil alignment.
- A wrong guess should cost positioning and social opportunity through the dog's temporary flight, without permanently converting it into an enemy.

### Socialization Has a Hunger Cost

- Freya's passive Hunger increase is extremely slow while idle; walking, running, and sustained actions create the meaningful metabolic cost.
- Socializing makes Freya hungrier while the interaction is active.
- Socializing with a possessed dog also raises Freya's Vomit meter while the interaction remains active.
- At full Hunger, Freya cannot begin or continue socializing.
- The blocked interaction needs clear feedback, such as “Freya is too hungry to socialize.”
- This creates a resource decision between recruiting dogs, exploring for food, and pursuing alien objectives.

### Alien Buildings Are Static, Not Pulsing

Alien occupation should produce a stable architectural transformation. Neither the building geometry nor its minimap outline should rhythmically grow, shrink, or pulse.

- Use fixed membranes, veins, roof growth, altered color, blocked openings, or discrete integrity stages.
- Pee damage may move the building between a few stable visual states, but it should not create constant throbbing or breathing motion.
- Expelled aliens run quickly as grounded characters; the no-pulse rule applies to occupied buildings and their persistent map indicator.

### Aliens Are Grounded Imp Characters

- A visible alien is a slightly smaller opaque voxel imp with a readable head, eyes, horns, fangs, arms, legs, feet, and tail—not a floating orb or transfer effect.
- Roaming, fleeing, and expelled aliens use an articulated walk/run cycle and stay rooted at ground height.
- Aliens use the same manual walkability, collision-radius, and axis-sliding
  convention as Freya and the dogs. Alien movement additionally substeps fast
  travel to prevent tunneling; Freya and dogs use one movement step per frame.
  Characters do not gain a separate physics-only collision system.
- Roaming aliens move briskly at 4.0 world units per second. A fleeing or building-bound alien moves at 5.8: faster than Freya's 4.6 walk, but slower than her 7.13 run.
- Possession is the exception: after reaching a walkable contact point immediately outside a building, the alien may disappear into it and increment that building's occupant count. It never walks through the wall.
- Ryah Diane rejects an alien at the outside wall of Freya's home; the rejected imp runs away along the ground before choosing another building.

### Occupied Storefronts Become Alien Strongholds

When an expelled alien occupies a storefront:

- the store immediately becomes non-enterable and unusable by Freya;
- its entrance and services need an unmistakable static locked/contaminated state;
- it strengthens surrounding alien-controlled buildings;
- the exact radius, stacking curve, and meaning of “stronger” remain intentionally undefined for a future balance pass.

The data model should still distinguish a storefront's base function from its current controller so cleansing or reclaiming it can restore its original use.

### Scent Claims Include Mailboxes

- Holding `R` lets Freya pee on trees, light poles, fire hydrants, and residential mailboxes to fill the same timed claim meter.
- Completed claims store Freya or enemy ownership, display the matching world ring and minimap marker, and allow Freya to reclaim an enemy-owned target.
- An interrupted ordinary-object claim resets its partial progress. Peeing on an alien-controlled building breaks its hold and makes the building enterable/claimable again.
- Freya controls her home by default. Other buildings can be claimed only when every nearby claimable object around them is Freya-marked and the building connects to Freya territory on the same generated block or a direct north/south/east/west neighboring block.
- Claiming a clean eligible building requires holding `R` inside for 10 seconds. Partial building progress decays by about 10% every 2 seconds while Freya is not peeing inside.
- Claimed building territory receives a subtle yellow ground tint; Ryah Diane places a quick scribbly Freya drawing on a wooden stake near the entrance. The building model itself does not transform.
- Freya wins when she owns every building on the map.

## Current Build Audit

### Already Aligned

- **Implemented:** Every NPC dog begins possessed, independently from appearance.
- **Implemented:** Freya becomes uneasy near possessed dogs without directly identifying them.
- **Implemented:** Close possessed dogs bark aggressively and scare Freya into fleeing unless the player holds `X` to make her bark back and stand ground.
- **Implemented:** A short aggressive bark expels possession and creates a visible alien transfer.
- **Implemented:** Expelled aliens choose among nearby available buildings.
- **Implemented:** Ryah Diane's crying rejects an alien from Freya's home and forces it to select another building.
- **Implemented:** Alien buildings have a distinct façade/roof treatment and persistent pee-based integrity damage.
- **Implemented:** All dogs share Freya's voxel mesh, rig, and gait; breeds vary through voxel-rig body-part proportions, sizes, coats, collars, tags, and bandanas independently of possession.
- **Implemented:** Friendly socialization costs Hunger, stops at full Hunger, and recruits dogs into Freya's army with broad, high-contrast neck-mounted camouflage collars and no overhead indicator.
- **Implemented:** Friendly socialization with a possessed dog raises Freya's Vomit meter continuously without stacking the rate for overlapping possessed dogs.
- **Implemented:** Aggressive barking now cleanses a possessed dog or temporarily frightens a real dog; it never creates an enemy dog.
- **Implemented:** Occupied architecture and its minimap outline remain static and use discrete integrity stages.
- **Implemented:** Occupied storefronts lock their entrances and services, reinforce nearby alien buildings, and exclusively generate a map-wide maximum of eight free aliens.
- **Implemented:** Free aliens flee from approaching Freya to the nearest building.
- **Implemented:** Visible aliens are slightly smaller grounded voxel imps with articulated gaits, bounded character speed, collision-aware steering, and an exterior-wall possession handoff.
- **Implemented:** Every alien-controlled building stores and displays its current alien occupant count.
- **Implemented:** Freya's permanent food bowl inside Ryah Diane's house is reusable and resets Hunger to zero when Freya eats from it.
- **Implemented:** Freya starts fully hungry after the family prologue; first-person text, exact authored barks, and a pulsing bowl pointer guide her to eat, while the home boundary turns her back with a reminder until the meal is complete.
- **Implemented:** Gene drops his pill bottles during abduction; after saving Ryah, Freya eats the spill, performs a comic convulsion, discovers her internal monologue, and only then enters the eat-first tutorial.
- **Implemented:** Freya's first post-meal exit stages three people with leashed city dogs, abducts the people in separate beams, shows possession energy enter the dogs, then shows the same energy bounce away from Freya. Her exact internal thought identifies the immunity before the leashes clear and dog behavior resumes.
- **Implemented:** The dog park population is six dogs and the park has a complete two-rail perimeter with a visible open gate, weave poles, a jump hurdle, an A-frame, and a crawl tunnel. Each training obstacle now has contextual `F` interaction points at both ends and its own brief, collision-safe Freya animation: slalom weaving, a parabolic hurdle leap, an A-frame climb, or a lowered tunnel crawl.
- **Implemented:** Dog audio is separated into conversational, excited-social, and aggressive recorded-bark pools; friendly call-and-response routes by speaker, aggressive socializing stays in its own pool, and per-category shuffle bags exhaust every clip before reuse without immediate cycle-boundary repeats.
- **Implemented:** Residential mailboxes use the same hold-`R` pee claim, owner/reclaim state, world-ring feedback, and Freya/enemy minimap markers as trees, light poles, and fire hydrants.
- **Implemented:** Freya owns her initial home by default. Eligible clean building interiors can now be claimed through the 10-second hold-`R` pee action after surrounding objects are marked and the building connects to Freya territory; progress decays when interrupted, and full-map ownership triggers victory.
- **Implemented:** Every non-possessed building is enterable. Residences are
  scattered across ranch, two-story, and three-story flavors and expose only a
  furnished bottom floor through hollow shells with transparent windows.
- **Implemented:** The pharmacy provides medicine that freed dogs consume for
  permanent possession immunity; the grocery provides an infinite reusable
  dog-food bowl; and the police station provides visible doggy armor.
- **Implemented:** The medical clinic is furnished and enterable, while its
  gameplay function remains intentionally undefined.
- **Implemented:** Any occupied building locks its full footprint and service;
  only retail buildings marked `generates_free_aliens` produce free aliens.

### Placement-Ready, Not Yet on the Map

- **Prepared, not live:** The Northbrook Dog Lodge archetype has a complete
  clean exterior/interior, six caged shared-rig dogs, transparent glazing,
  entry and collision metadata, and deterministic references.
- **Prepared, not live:** All six caged dogs begin secretly possessed and expose
  the same de-possession outcome as other dogs; cage release remains future.
- **Prepared, not live:** Its first clean entry emits Freya's exact one-time
  thought, `I'll find a way to free you!`
- **Prepared, not live:** Possession locks entry and requests one possessed dog
  every eight seconds, with a hard lifetime maximum of six successfully
  accepted spawns and explicit confirmation/retry hooks for safe NPC placement.
  Cleansing the building permanently forfeits all unspawned dogs for that
  level, so early cleansing produces a correspondingly smaller dog population.
- **Prepared, not live:** Caged and spawned kennel dogs use the canonical shared
  voxel rig and hidden possession state; spawned dogs join the normal dog
  lifecycle and can be de-possessed normally.
- Map placement, minimap registration, occupation routing, and the mechanics
  that eventually fulfill Freya's rescue promise remain future integration.

### Pass 1 Implemented

| Previous prototype | Canonical behavior | Completed implementation |
| --- | --- | --- |
| Dogs used `neutral`, `friendly`, and `enemy` relations with angelic or demonic wings. | Dogs are real or possessed; real dogs may separately join Freya's army. | Removed relation/enemy state and all wing creation; army alignment is independent and uses a broad, high-contrast camouflage collar. |
| Sustained aggressive barking advanced an enemy timer. | Aggressive bark only performs the exorcism test. | Possessed dogs are cleansed; real dogs enter a temporary flee state without changing alignment. |
| Socialization restored Social without an interaction-specific Hunger cost. | Socialization increases Hunger and is unavailable at full Hunger. | Active socializing raises Hunger, pauses at full Hunger, and displays the blocked reason. |
| Alien building roots and map outlines pulsed. | Occupied structures remain visually static. | Persistent architecture and minimap outlines are static; integrity selects a stable visual stage. |
| Alien-occupied storefronts remained enterable and usable. | Occupied storefronts are locked strongholds. | Entry, focus, food, and services are unavailable while occupied; static contamination bars and labels mark the lockout. |
| Occupied storefronts did not affect neighboring alien buildings. | A storefront stronghold reinforces surrounding alien-controlled buildings. | Each occupied storefront contributes a provisional reinforcement field within 22 world units, slowing pee weakening. |

## Core Gameplay Loop Status

1. **Implemented — Find possessed dogs.** Freya uses automatic unease while every dog continues to look ordinary.
2. **Implemented — Cleanse them.** Aggressive bark performs the exorcism test; a fleeing real dog communicates an incorrect guess.
3. **Implemented foundation — Respond to building occupation.** Expelled aliens claim nearby buildings, and occupied storefronts lose their services. Broader route/control consequences remain future work.
4. **Implemented — Contain alien generation.** Occupied storefronts generate additional free aliens under a map-wide cap.
5. **Partial — Deploy the dog army.** Socialized real dogs can join Freya's army; army combat and building-assault support are future work.
6. **Future — Resist re-possession.** Aliens will attempt to possess real dogs, including insufficiently protected army members.
7. **Implemented foundation — Claim and weaken through scent marking.** Freya claims trees, poles, hydrants, and mailboxes, and directly weakens occupied buildings. Strategic territory influence remains future work.
8. **Future — Protect Freya's friends.** Add one or more actions that reduce an allied dog's susceptibility to re-possession.
9. **Future — Collect resources and fortify buildings.** Reclaimed buildings will consume resources, join Freya's network, and grant bonuses.
10. **Future — Liberate the entire map.** Define full control, a functioning fortified network, and removal of the alien menace as the level goal.
11. **Future — Advance beyond the neighborhood.** Treat the current map as Level 1 and vary later layouts, resources, pressure, and bonuses while preserving the core loop.

## Recommended System Model

Current entries use runtime dictionary keys where one exists. Future entries
are proposed conceptual fields. Each field is labeled by implementation status.

### Dog State

- **Current:** `alien_possessed`: whether a real dog is currently possessed.
- **Current:** `army_aligned`: whether the dog has joined Freya's army.
- **Current:** `flee_timer`: temporary response after a wrong exorcism guess.
- **Future:** `repossess_resistance`: protection gained from Freya's support actions.
- **Current:** `socialization_progress`: recruitment progress, paused or blocked by full Hunger.
- **Current:** `possession_immune`: permanent protection granted by pharmacy medicine after cleansing.
- **Current:** `has_dog_armor`: whether the dog wears the police-station armor visual.

Possession and army alignment must remain orthogonal. This avoids recreating angel/devil categories under different names.

### Building State

- **Current:** `building_type`, `is_store`, and `is_freya_home`: the building's base role independently from its controller.
- **Current:** `enterable` and `bottom_floor_only`: clean-entry state and the residential floor limit.
- **Current:** `generates_free_aliens`: explicit retail pressure flag, independent from whether a building has an interior.
- **Current:** `alien_occupied`: whether the building is alien controlled.
- **Current:** `alien_integrity`: persistent weakening from direct pee damage.
- **Current:** `alien_occupant_count`: aliens currently held by that building.
- **Current derived behavior:** nearby occupied storefronts contribute the provisional reinforcement effect; there is no persistent `reinforcement_strength` field.
- **Future proposed field:** `fortification_level`: resource investment after Freya reclaims a building.
- **Current derived behavior:** occupied-building services are disabled; the
  clean building's base service remains available for future restoration.
- **Current:** pharmacy immunity, grocery food, and police armor are distinct
  building benefits; clinic behavior is intentionally unassigned.

### Level State

- **Future:** ownership percentage and liberation requirements;
- **Current:** active and available alien population;
- **Partial:** army roster exists; protection levels are future work;
- **Current foundation:** claimed scent targets exist; strategic network effects are future work;
- **Future:** resource inventory and fortified-building network;
- **Future:** transition from the current neighborhood into later levels.

## Visualization and Feedback Recommendations

1. **Implemented:** Use Freya's posture and restrained HUD message as the hidden-possession clue. Never alter the possessed dog's appearance or minimap marker.
2. **Implemented foundation:** A wrongly barked-at real dog retreats immediately and remains real; further startle/tucked-posture polish is optional.
3. **Implemented:** A broad camouflage collar communicates army membership at normal zoom; supernatural silhouettes remain reserved for aliens and occupied architecture.
4. **Implemented:** Alien buildings remain static and use fixed details/discrete integrity states rather than pulsing.
5. **Partial:** Occupied storefronts have a static blocked entrance and disabled services. A distinct secondary reinforcement trim remains future polish.
6. **Implemented:** Socialization visibly changes Hunger/Social progress, stops at full Hunger, and presents the blocked reason without permanent state changes.
7. **Future polish:** Add a brief claimed-territory influence cue when the strategic scent-network effect is implemented; do not add permanent pulsing.

## Implementation Roadmap

### Pass 1 — Correct the Existing Prototype (Complete)

- Remove friendly/enemy wings and enemy-dog conversion.
- Make aggressive barking cleanse possessed dogs or frighten real dogs into temporary flight.
- Charge Hunger for socialization and block it at full Hunger.
- Add the broad, high-contrast camouflage army collar.
- Remove occupied-building and minimap pulsing.
- Lock alien storefront entry, focus, food, and services.
- Add a provisional nearby-building reinforcement field from occupied storefronts.

### Pass 2 — Free Aliens Implemented; Re-possession and Protection Remain

- **Implemented:** Occupied storefronts exclusively generate free-roaming aliens, capped at eight map-wide.
- **Implemented:** Approaching Freya makes a free alien flee to the nearest building, where it increments the occupant count.
- **Implemented:** Alien roaming, fleeing, Ryah rejection, and expelled-alien travel use grounded character collision; possession begins only from a reachable exterior wall point.
- Let aliens attempt possession against real dogs.
- Add resistance and Freya support actions for army dogs.
- Define success, failure, cooldown, and readable feedback for possession attempts.

### Pass 3 — Reclamation, Resources, and Fortification

- Add the final reclaim action after alien integrity is weakened.
- Add resource collection and costs.
- Give reclaimed building types distinct bonuses.
- Connect claimed scent territory to alien weakening and defensive coverage.

### Pass 4 — Army Combat and Alien Escalation

- Give army dogs roles in intercepting aliens and assaulting strongholds.
- Add controlled alien generation and reinforcement behavior.
- Balance storefront influence, building strength, and army effectiveness.

### Pass 5 — Level Victory and Campaign Structure

- Define complete-map ownership and alien-removal victory conditions.
- Persist army, resources, or upgrades according to the campaign design.
- Treat the current neighborhood as Level 1 and author later levels around variations of the same strategic loop.

## Validation Requirements

### Implemented Invariants

Existing checks for all-dog initial possession, appearance independence, Freya's unease, exorcism transfer, Ryah's defense, alien-building visuals, and pee weakening should remain.

The current automated guardrail suite should continue to prove:

- no angel/devil/hostile dog relation state or wing visuals remain;
- every NPC dog records possessed as its origin state without a possession-only cosmetic marker;
- the first-exit cinematic visibly possesses the staged dogs, rejects the same effect from Freya, and presents her exact immunity thought before control resumes;
- barking at a possessed dog cleanses it without creating an enemy state;
- barking at a real dog starts a flee response without altering possession or army alignment;
- socialization increases Hunger and cannot progress at full Hunger;
- army membership uses a broad, high-contrast camouflage collar that stays readable across breed scales and is independent from possession;
- occupied buildings and their minimap indicators do not pulse;
- an occupied storefront cannot be entered and exposes no usable food or service;
- an occupied storefront contributes reinforcement only to nearby alien-controlled buildings;
- every visible alien has the imp anatomy, an alternating limb gait, an opaque voxel body, and no legacy orbit/tendril effect;
- alien movement stays grounded, respects walkability under substepping, cannot tunnel through buildings, and remains below Freya's run speed;
- a transfer can walk to an exterior wall, possess the building, and increment its occupant count without entering collision geometry;
- every residential mailbox remains a retained, accessible claim target with timed pee progress, owner-colored world-ring/minimap feedback, and enemy-to-Freya reclaim behavior.

Run the complete current suite with:

```sh
./scripts/predeploy_size_checks.sh
```

Visual changes also require regenerating and manually inspecting the affected
PNG listed in the [capture catalog](visual_regressions/README.md).

### Future Validation Gates

Add checks alongside—not ahead of—the corresponding implementation for:

- reclaiming a storefront and restoring its entry and services;
- alien attempts to re-possess real and army dogs;
- resistance and Freya support actions for army dogs;
- fortification resources and building bonuses;
- level ownership, liberation requirements, and victory state.
