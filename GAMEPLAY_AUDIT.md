# Friendly Freya Gameplay Audit and Direction

[Documentation hub](README.md) · [Run and validation](RUN_FRIENDLY_FREYA.md) ·
[Codebase map](docs/CODEBASE_MAP.md) · [Dog breeds](godot/BREEDS.md) ·
[Completed visual record](VISUAL_RECOMMENDATIONS.md) ·
[Capture catalog](visual_regressions/README.md) ·
[Game completion plan](docs/GAME_COMPLETION_PLAN.md)

**Document role:** living design reference and current-build audit. Sections and
bullets marked **implemented** describe the current build; **future** and
**required change** are specifications only. Runtime code and executable
validation remain the authority for exact behavior.

## Canonical Rules

### Dogs Have Two Independent States

There are no angel dogs or devil dogs. Every NPC is always a real dog, and a real dog may additionally be possessed by a demon alien.

- **Possession:** `real` or `possessed`.
- **Army alignment:** `independent` or `Freya's army`.
- Roaming NPC dogs begin a new game possessed. The three staged first-exit
  leashed dogs begin ordinary and become possessed during the visible reveal;
  cleansing creates the unpossessed state the player can then befriend.
- A cleansed dog becomes real; it does not become an angel dog.
- An army dog remains a real dog and may eventually have a lower—but not necessarily zero—risk of re-possession.
- Possession must remain visually secret. Breed, body, coat, animation, and ordinary cosmetics cannot reveal it.

Friendly alignment uses a broad, high-contrast, neck-mounted camouflage-pattern collar that remains obvious at normal gameplay zoom, with no icon or indicator above the dog. Wings, horns, halos, and other angel/devil imagery are removed from dog alignment feedback.

### Aggressive Bark Tests Dogs and Interrupts Visible Imps

Against dogs, aggressive barking tests for and expels possession. A visible
grounded imp can also be intercepted by a sustained bark before it escapes or
finishes a transfer.

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
  convention as Freya and the dogs. Alien and Freya movement substep fast
  travel to prevent tunneling; NPC dogs use one movement step per frame.
  Dog locomotion follows actual post-collision displacement, including Hunger
  speed changes; intent can turn a stopped dog without playing a running gait.
  Characters do not gain a separate physics-only collision system.
- Roaming aliens move briskly at 4.0 world units per second. A fleeing or building-bound alien moves at 5.8: faster than Freya's 4.6 walk, but slower than her 7.13 run.
- Possession is the exception: after reaching a walkable contact point immediately outside a building, the alien may disappear into it and increment that building's occupant count. It never walks through the wall.
- Freya and Ryah Diane's home is excluded from alien targets and from alien walkability. An alien expelled inside its footprint is moved to a valid exterior point and sent toward a different, possessable building.

### Occupied Storefronts Become Alien Strongholds

When an expelled alien occupies a storefront:

- the store immediately becomes non-enterable and unusable by Freya;
- its entrance and services need an unmistakable static locked/contaminated state;
- it strengthens surrounding alien-controlled buildings;
- each occupied storefront adds reinforcement within 22 world units,
  slowing wall weakening; this provisional value still needs balance testing.

The data model should still distinguish a storefront's base function from its current controller so cleansing or reclaiming it can restore its original use.

### Scent Claims Include Mailboxes

- Holding `Space` lets Freya pee on trees, light poles, fire hydrants, and residential mailboxes to fill the same timed claim meter.
- Completed claims store Freya or enemy ownership, display the matching world ring and minimap marker, and allow Freya to reclaim an enemy-owned target.
- An interrupted ordinary-object claim resets its partial progress. Peeing on an alien-controlled building breaks its hold and makes the building enterable/claimable again.
- Freya controls her home by default. Other buildings can be claimed only when every nearby claimable object around them is Freya-marked and the building connects to Freya territory on the same generated block or a direct north/south/east/west neighboring block.
- Claiming a clean eligible building requires holding `Space` inside for 10 seconds. Partial building progress decays by about 10% every 2 seconds while Freya is not peeing inside.
- Claimed building territory receives a subtle yellow ground tint; Ryah Diane places a quick scribbly Freya drawing on a wooden stake near the entrance. The building model itself does not transform.
- The Northbrook chapter ends after its highlighted sites, ally, lodge rescue,
  alien holds, and generators are resolved. Owning every building remains an
  optional mastery victory.

## Current Build Audit

### Already Aligned

- **Implemented:** Roaming NPC dogs begin possessed, independently from
  appearance. The three first-exit leashed dogs begin ordinary until their
  visible possession event.
- **Implemented:** Freya becomes uneasy near possessed dogs without directly identifying them.
- **Implemented:** Close possessed dogs bark aggressively and scare Freya into fleeing unless the player holds `R` to make her bark back and stand ground. On the watch-intro route, aggression stays disabled until the first-exit possession reveal; skipping the intro enables it immediately, and dog-park threats do not project through the fence.
- **Implemented:** A short aggressive bark expels possession and creates a visible alien transfer.
- **Implemented:** Expelled aliens choose among nearby available buildings.
- **Implemented:** Aliens cannot enter or target Freya and Ryah Diane's home; any expelled alien originating inside is placed safely outside and routed elsewhere.
- **Implemented:** Alien buildings have a distinct façade/roof treatment and persistent pee-based integrity damage.
- **Implemented:** All dogs share Freya's voxel mesh, rig, and gait; breeds vary through voxel-rig body-part proportions, sizes, coats, collars, tags, and bandanas independently of possession.
- **Implemented:** Friendly socialization costs Hunger, stops at full Hunger, and recruits dogs into Freya's army with broad, high-contrast neck-mounted camouflage collars and no overhead indicator.
- **Implemented:** Friendly socialization with a possessed dog raises Freya's Vomit meter continuously without stacking the rate for overlapping possessed dogs.
- **Implemented:** Aggressive barking now cleanses a possessed dog or temporarily frightens a real dog; it never creates an enemy dog.
- **Implemented:** Occupied architecture and its minimap outline remain static and use discrete integrity stages.
- **Implemented:** Occupied storefronts lock their entrances and services, reinforce nearby alien buildings, and exclusively generate a map-wide maximum of eight free aliens.
- **Implemented:** Free aliens flee from approaching Freya to the nearest building.
- **Implemented:** A free imp may seek a vulnerable real dog and begin a visible,
  timed transfer. Barking or a nearby guard/assist ally can interrupt it;
  police armor absorbs one completed attempt and pharmacy immunity excludes
  the dog. Successful possession does not change the dog's ordinary appearance
  or army membership. Failed approaches observe a retry cooldown.
- **Implemented:** Barking can intercept a visible imp, and full-meter vomit
  spray interrupts imps in its short path.
- **Implemented:** Visible aliens are slightly smaller grounded voxel imps with articulated gaits, bounded character speed, collision-aware steering, and an exterior-wall possession handoff.
- **Implemented:** Every alien-controlled building stores and displays its current alien occupant count.
- **Implemented:** A new alien occupation moves Freya or a dog only if its
  expanding collision margin would trap that character. Recovery chooses a
  nearby walkable point and retains character height; save/resume also repairs
  older positions trapped against an occupied building.
- **Implemented:** Freya's permanent food bowl inside Ryah Diane's house is reusable and resets Hunger to zero when Freya eats from it.
- **Implemented:** Freya starts fully hungry after the family prologue; first-person text, exact authored barks, and a pulsing bowl pointer guide her to eat, while the home boundary turns her back with a reminder until the meal is complete.
- **Implemented:** Gene drops his pill bottles during abduction; after saving Ryah, Freya eats the spill, performs a comic convulsion, discovers her internal monologue, and only then enters the eat-first tutorial.
- **Implemented:** Freya's first post-meal exit stages three people with initially ordinary leashed city dogs farther down a street-side sidewalk, abducts the people in separate beams, turns those dogs aggressive only when possession energy enters them, then shows the same energy bounce away from Freya. Her exact internal thought identifies the immunity before the leashes clear and dog behavior resumes.
- **Implemented:** The dog park population is six dogs and the park has a complete two-rail perimeter with a visible open gate, weave poles, a jump hurdle, an A-frame, and a crawl tunnel. Each training obstacle now has contextual `F` interaction points at both ends and its own brief, collision-safe Freya animation: slalom weaving, a parabolic hurdle leap, an A-frame climb, or a lowered tunnel crawl.
- **Implemented:** The first completion of each park obstacle gives a lasting
  8% per-dog pack-assist bonus; repeats remain playable without stacking it.
- **Implemented:** Dog audio is separated into conversational, excited-social, and aggressive recorded-bark pools; friendly call-and-response routes by speaker, aggressive socializing stays in its own pool, and per-category shuffle bags exhaust every clip before reuse without immediate cycle-boundary repeats.
- **Implemented:** Residential mailboxes use the same hold-`Space` pee claim, owner/reclaim state, world-ring feedback, and Freya/enemy minimap markers as trees, light poles, and fire hydrants.
- **Implemented:** Freya owns her initial home by default. Eligible clean building interiors can now be claimed through the 10-second hold-`Space` pee action after surrounding objects are marked and the building connects to Freya territory; progress decays when interrupted, and full-map ownership triggers victory.
- **Implemented:** Pause > Controls offers an optional saved "Press once for long actions (Space/C)" setting. Its default is off. When enabled, one Space press continues a selected scent mark, interior claim, or occupied-wall weakening, and one C press continues socializing with a selected dog. Pressing the same key again, moving, changing action or target, pausing, losing window focus, or reaching a chapter result stops the action; completion stops it automatically. The Space claim meter gives a visible stop cue.
- **Implemented:** Three pack orders (`1` follow, `2` guard, `3` assist) direct
  up to three active real dogs, with stuck detours. Additional clean recruits
  hold individual guard posts and defend nearby dogs and sites. Active allies
  speed weakening and claims; Social and park drills increase their effect.
- **Implemented:** The current Northbrook chapter highlights eight connected
  properties and requires two cleared alien holds, one ally, a lodge rescue,
  and no active storefront generator. Full-map ownership remains optional.
  A chapter result panel provides continuation; save/resume preserves progress.
  A saved, H-dismissible first-chapter guide points from the park dog through
  an optional first agility drill, the first clean connected claim, alien hold,
  and lodge rescue. Occupied generators show their 22m influence; Tab goals
  explain their 10–17-second imp output and shared eight-imp cap. Initial
  stronghold seeding does not interrupt the eat-first lesson with an alien
  notice; alien occupations during live play still announce themselves.
- **Implemented:** Every non-possessed building is enterable. Residences are
  scattered across ranch, two-story, and three-story flavors and expose only a
  furnished bottom floor through hollow shells with transparent windows. Each
  residence owns its own wall/foundation render batch so its complete lower
  shell disappears with that house when Freya enters.
- **Implemented:** The pharmacy provides medicine that freed dogs consume for
  permanent possession immunity; the grocery provides an infinite reusable
  dog-food bowl; and the police station provides visible doggy armor.
- **Implemented:** The medical clinic supplies a care kit that immediately
  frees a repossessed ally or calms a frightened dog when used nearby. It is
  distinct from pharmacy immunity and one-use police armor.
- **Implemented:** Carried supplies mark the dog that `F` will affect. Medicine
  is retained if the nearby dog is already immune; armor is retained for dogs
  with intact armor or permanent immunity. Chapter 2 favors an unprotected
  recruited ally, while independent dogs can still be protected and then
  recruited. At the grocery bowl, `F` feeds Freya before using a carried item;
  an unused clinic kit requires a taken ally or frightened dog.
- **Implemented:** Service locations carry `M` medicine, `F` food, `A` armor,
  and `C` care minimap markers. A static cyan diamond identifies the next
  highlighted site named in Tab goals, including at the minimap edge when it
  lies beyond the zoomed view. A static orange `!` identifies the nearest
  active storefront imp generator, including at the map edge while distant;
  it clears when that source is no longer occupied. The pause and objectives
  panels scale for smaller windows.
- **Implemented:** Public-building fixtures leave Freya-radius aisles from the
  entrance to each service. A five-seed doorway flood and F-effect regression
  covers grocery food, pharmacy medicine, police armor, and clinic care.
- **Implemented:** Any occupied building locks its full footprint and service;
  only retail buildings marked `generates_free_aliens` produce free aliens.

### Live Northbrook Dog Lodge

- **Implemented:** The lodge has a guaranteed lot and minimap marker. It starts
  occupied, locks entry until cleansed, and offers six caged shared-rig dogs.
- **Implemented:** While occupied it requests one possessed dog every eight
  seconds with a lifetime cap of six accepted spawns. Cleansing forfeits
  unspawned releases; all dogs still in cages can be cleansed and freed, so
  an early attack cannot block the chapter rescue.
- **Implemented:** Freya can bark at captives, then press `F` to open safe
  cages. Released dogs enter the ordinary real-dog and recruitment loop. The
  one-time clean-entry promise remains `I'll find a way to free you!`

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
3. **Implemented — Respond to building occupation.** Expelled aliens claim nearby buildings; occupied storefronts lose services and reinforce nearby holds. Bark or guarding allies can intercept visible imps.
4. **Implemented — Contain alien generation.** Occupied storefronts generate additional free aliens under a map-wide cap.
5. **Implemented — Deploy the dog army.** Recruited dogs follow, guard, or assist; nearby assistants speed wall weakening and claims and can contain imps. Guard near an independent clean dog to follow and protect that dog, or guard a location when no such dog is nearby. Assist selects the nearby chapter site or alien hold first and names the selected building in its feedback.
6. **Implemented — Resist re-possession.** Free imps attempt a timed transfer to vulnerable real dogs. Bark, pack defense, immunity, armor, and a clinic recovery kit offer different responses.
7. **Implemented — Claim and weaken through scent marking.** Freya marks
   objects and directly weakens occupied buildings; pack assistance improves
   both. Each nearby claimed building adds a visible 14% wall-weakening bonus,
   capped at 42%. A broader defensive scent network remains future work.
8. **Implemented — Protect Freya's friends.** Pharmacy medicine grants permanent immunity, police armor absorbs one attempt, and clinic care recovers a taken ally.
9. **Future — Fortify buildings.** Resource costs and multiple fortification levels are still proposals; current services and territory have tactical value without them.
10. **Implemented — Secure Northbrook and finish the story.** The eight-site
    rescue chapter leads to a five-site ally-protection chapter, a four-site
    pack-assisted final hold, and a Gene/Zoe/Ryah ending with credits. If the
    player owns every eligible site before chapter 3, a marked clean final
    signal still requires a deliberate ally guard instead of silently awarding
    the finale. The guard success plays the recorded objective cue unless the
    chapter-result cue confirms the same final action. Owning every building
    remains an optional victory. First-run
    pacing and the full story route still need human playtesting.
11. **Future — Advance beyond the neighborhood.** Treat the current map as Level 1 and vary later layouts, resources, pressure, and bonuses while preserving the core loop.

## Recommended System Model

Current entries use runtime dictionary keys where one exists. Future entries
are proposed conceptual fields. Each field is labeled by implementation status.

### Dog State

- **Current:** `alien_possessed`: whether a real dog is currently possessed.
- **Current:** `army_aligned`: whether the dog has joined Freya's army.
- **Current:** `flee_timer`: temporary response after a wrong exorcism guess.
- **Current:** `socialization_progress`: post-cleanse recruitment progress, paused by full Hunger. Unrecruited possessed dogs cannot bank progress; cleansing starts recruitment at zero without changing existing army membership.
- **Current:** `possession_immune`: permanent protection granted by pharmacy medicine after cleansing.
- **Current:** `has_dog_armor`: one available police-station armor defense and its visible vest; an absorbed attempt removes it.

Possession and army alignment must remain orthogonal. This avoids recreating angel/devil categories under different names.

### Building State

- **Current:** `building_type`, `is_store`, and `is_freya_home`: the building's base role independently from its controller.
- **Current:** `enterable` and `bottom_floor_only`: clean-entry state and the residential floor limit.
- **Current:** `generates_free_aliens`: explicit retail pressure flag, independent from whether a building has an interior.
- **Current:** `alien_occupied`: whether the building is alien controlled.
- **Current:** `alien_integrity`: persistent weakening from direct pee damage.
- **Current:** `alien_occupant_count`: aliens currently held by that building.
- **Current derived behavior:** nearby occupied storefronts update the cached
  `alien_reinforcement_sources` and `alien_reinforcement_strength` fields.
- **Future proposed field:** `fortification_level`: resource investment after Freya reclaims a building.
- **Current derived behavior:** occupied-building services are disabled; the
  clean building's base service remains available for future restoration.
- **Current:** pharmacy immunity, grocery food, police armor, and clinic care
  are distinct building benefits.

### Level State

- **Current:** owned-building count, eight highlighted Northbrook properties,
  chapter rescue/stronghold requirements, and optional all-building victory;
- **Current:** active and available alien population;
- **Current:** army roster, three orders, immunity, one-use armor, and clinic
  recovery;
- **Current foundation:** claimed scent targets exist, and nearby claimed
  buildings strengthen Freya's weakening of an occupied wall;
- **Future:** resource inventory and fortified-building network;
- **Future:** transition from the current neighborhood into later levels.

## Visualization and Feedback Recommendations

1. **Implemented:** Use Freya's posture and restrained HUD message as the hidden-possession clue. Never alter the possessed dog's appearance or minimap marker.
2. **Implemented foundation:** A wrongly barked-at real dog retreats immediately and remains real; further startle/tucked-posture polish is optional.
3. **Implemented:** A broad camouflage collar communicates army membership at normal zoom; supernatural silhouettes remain reserved for aliens and occupied architecture.
4. **Implemented:** Alien buildings remain static and use fixed details/discrete integrity states rather than pulsing.
5. **Partial:** Occupied storefronts have a static blocked entrance and disabled services. A distinct secondary reinforcement trim remains future polish.
6. **Implemented:** Socialization visibly changes Hunger/Social progress, stops at full Hunger, and presents the blocked reason without permanent state changes.
7. **Implemented foundation:** Occupied walls show a static `FREYA SCENT +%`
   label when nearby claimed buildings strengthen wall weakening. A brief
   action cue remains optional polish; do not add permanent pulsing.

## Implementation Roadmap

### Pass 1 — Correct the Existing Prototype (Complete)

- Remove friendly/enemy wings and enemy-dog conversion.
- Make aggressive barking cleanse possessed dogs or frighten real dogs into temporary flight.
- Charge Hunger for socialization and block it at full Hunger.
- Add the broad, high-contrast camouflage army collar.
- Remove occupied-building and minimap pulsing.
- Lock alien storefront entry, focus, food, and services.
- Add a provisional nearby-building reinforcement field from occupied storefronts.

### Pass 2 — Free Aliens, Re-possession, and Protection Implemented

- **Implemented:** Occupied storefronts exclusively generate free-roaming aliens, capped at eight map-wide.
- **Implemented:** Approaching Freya makes a free alien flee to the nearest building, where it increments the occupant count.
- **Implemented:** Alien roaming, fleeing, and expelled-alien travel use grounded character collision; possession begins only from a reachable exterior wall point, and Ryah's home is forbidden navigation space.
- **Implemented:** Free imps seek vulnerable real dogs, show a 1.65-second
  warning at contact, and possess on success without changing dog cosmetics.
- **Implemented:** Bark and assigned pack defense interrupt; armor absorbs one
  attempt, immunity blocks targeting, and a failed approach has a cooldown.

### Pass 3 — Reclamation, Resources, and Fortification

- **Implemented foundation:** Pee weakening already clears occupation, after which a clean, eligible interior can be claimed. Decide through playtests whether any additional reclaim action would create a useful choice.
- Add resource collection and costs.
- **Implemented foundation:** Grocery, pharmacy, police, clinic, and lodge each
  change a usable action. Further claimed-site bonuses remain future work.
- **Implemented foundation:** Claimed neighboring buildings now help Freya
  weaken an occupied wall. Broader defensive coverage remains future work.

### Pass 4 — Army Combat and Alien Escalation

- **Implemented foundation:** Follow, guard, and assist orders let dogs contain
  imps or shorten wall/claim actions; more varied army tactics remain future.
- **Implemented:** Occupied storefronts generate capped free imps and
  reinforce nearby occupied buildings.
- Balance storefront influence, building strength, and army effectiveness.

### Pass 5 — Level Victory and Campaign Structure

- **Implemented:** Three connected highlighted routes on the Northbrook map
  vary rescue, ally protection, and pack-assistance requirements. Chapter
  results lead to the family ending and credits; complete-map ownership is
  optional.
- **Implemented:** A versioned save stores world seed, buildings, dogs, pack,
  supplies, meters, kennel, and chapter state with startup resume.
- **Future:** Distinct later maps or levels may vary layouts and resources;
  the current campaign uses the existing neighborhood for all three chapters.

## Validation Requirements

### Implemented Invariants

Existing checks for roaming-dog initial possession, the staged first-exit
exception, appearance independence, Freya's unease, exorcism transfer,
Ryah-home exclusion, alien-building visuals, and pee weakening should remain.

The current automated guardrail suite should continue to prove:

- no angel/devil/hostile dog relation state or wing visuals remain;
- roaming NPC dogs record possessed as their origin state without a
  possession-only cosmetic marker; the staged first-exit leashed dogs begin
  ordinary until the visible reveal;
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
- fortification resources and building bonuses;
- distinct later-map transitions, if later maps are added.
