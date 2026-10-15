# Friendly Freya: Plan for a Complete Game

[Documentation hub](../README.md) · [Current gameplay audit](../GAMEPLAY_AUDIT.md) ·
[Building program](../BUILDING_PROGRAM.md) · [Kennel concept](../KENNEL_CONCEPT.md) ·
[Codebase map](CODEBASE_MAP.md) · [Run and validation guide](../RUN_FRIENDLY_FREYA.md) ·
[Playtest note guide](PLAYTEST_RUN_SHEET.md)

**Status:** The three-chapter campaign and ending are implemented, October 15,
2026. The "What exists today" table records the baseline at planning time.
The implementation log below states what this pass added. The automated
exported-Windows route passes; graphical Windows, minimum-PC performance,
accessibility, and unfamiliar-player gates remain open. Runtime code and
executable checks remain authoritative.

## Next release steps

The [review-o Windows run](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38794653756)
passed source validation, export, EXE startup, the short performance entry,
the keyboard Watch Intro opening, credits, and Keep Exploring. The source
suite, inspected captures, ZIP checksums, and local exported checks also
passed. Release publication remains gated by the checks below.

1. On the actual HP Victus 16-r0073cl, confirm the installed hardware and
   active GPU. Run the packaged no-save graphical stress test at 1280×720 and
   1920×1080. Require every five-second window to reach 30 FPS, and check
   text, input response, audio, and memory in natural play. Optimize and repeat
   only if measured results miss the target.
2. Complete an ordinary graphical Windows start-to-credits run. Exercise
   mid-chapter Resume, a lodge rescue, chapter-2 ally protection, the final
   signal, credits, Keep Exploring, and Replay Story cancellation. Verify a
   future-version save is preserved rather than overwritten. Run the focused
   keyboard-only accessibility pass in the [note guide](PLAYTEST_RUN_SHEET.md),
   including the default holds and optional press-once Space/C controls.
3. Observe five players who have not seen the project, without control
   coaching. Record where they lose the route, why they choose pack and
   protection tactics, time to each chapter, and what feels rewarding or
   repetitive. Players can give informal feedback; the [note guide](PLAYTEST_RUN_SHEET.md)
   has optional prompts for whoever observes or receives their comments.
4. Fix the three most common or severe problems, then repeat affected
   automated, visual, Windows, and player checks. Set the supported window
   sizes and release metadata from observed results before a public release.

The proposed 30–45 minute first chapter is a hypothesis. A passing automated
route and a powerful Victus result do not establish enjoyment or a lower
hardware floor.

## Implementation log

- The Northbrook map now selects eight connected highlighted properties and
  starts with two chapter strongholds, including an active storefront
  generator. The lodge is placed on a reserved lot and rescuing its six
  captives is a chapter requirement. Full-map ownership is optional.
- Real recruited dogs have follow, guard, and assist orders. Three active dogs
  can follow or assist; additional clean recruits guard their own posts. Assist
  speeds contested claims; bark and guarding allies can intercept imps. Free imps
  can try a warned, timed dog transfer; immunity, one-use armor, and clinic
  recovery provide distinct responses. Park drills permanently improve pack
  assist, vomit spray interrupts nearby imps, and claimed neighboring buildings
  now give a visible bonus when Freya weakens an alien hold.
- Versioned save/resume preserves the generated world, chapter state, and
  whether the player dismissed a chapter result. Keep Exploring after the
  ending returns to the completed neighborhood with the result panel closed;
  saving there keeps it closed on the next resume. New gameplay cues use
  sourced recordings with exact file mappings and silence for missing files;
  the active dog-food cue is CC BY 4.0, while the other mapped action excerpts
  are CC0. See [audio attribution](../godot/assets/audio/ATTRIBUTION.md).
- Save loading checks the six-cage lodge state before choosing a slot. An
  incomplete but checksummed primary can fall back to a valid backup, while
  pre-lodge saves receive a fresh, playable lodge state.
- New Game from the title, Restart Story from pause, and Replay Story from the
  ending now show a focused cancelable warning before replacing an existing
  save. A primary or backup save from a newer game version blocks any route
  that would overwrite it and explains where to archive the files.
- The extracted Windows package includes `RunPerformanceQA.cmd`. It stages
  the live full-pack scenario without touching the campaign save, samples
  windowed 1280×720 and fullscreen 1920×1080 separately, verifies the actual
  display sizes, and writes frame-time, five-second FPS, memory, and hardware
  logs. The stress sampler finishes its last complete five-second window and
  reports the count; the Windows runner rejects an early or incomplete sample.
  The HP result is still pending.
- Chapter 2 follows five connected highlighted sites, asks the player to
  protect two real allies with medicine or armor, and adds a warned imp threat.
  Its seeded alien hold carries a visible scent-relay marker; the objectives
  name that building, give its distance, and tell the player how to break it.
  Chapter 3 follows four connected sites, requires pack help at a final hold,
  and leads to Gene and Zoe's return, Ryah's reunion, credits, replay, or
  continued exploration. The finale is checked by a staged start-to-credits
  headless flow and separate ending-navigation and ending-resume tests.
- The final hold remains marked after a solo clear so a recruited ally can return
  and secure it; the chapter cannot be stranded by claiming every site first.
  Goals point to any occupied generator that still blocks progress. Failed
  Quit or ending saves keep the current game open with retry guidance.
- Pack Assist now selects a nearby route site or occupied building before a
  distant hold and names its target. Guard can follow an independent clean dog
  selected near Freya, with that dog's stable identity saved. When earlier
  exploration leaves no legal chapter-3 occupation target, a claimed final
  signal remains marked and must be secured by a real ally with an explicit
  guard order; ownership is preserved and the finale is not auto-awarded.
- A skippable first-chapter guide now advances from park dog to recruitment,
  an optional first park drill, the first clean connected claim, occupied hold,
  and lodge rescue. `H` hides it and the choice survives a save. Occupied
  storefronts identify their 22m influence in the world; Tab/G goals describe
  their 10–17-second imp output and shared eight-imp cap. Service buildings
  have distinct lettered minimap markers. The named next chapter site has a
  static cyan diamond, held at the minimap edge when outside the zoomed view;
  the goals and pause panels fit
  smaller windows. Initial stronghold seeding stays quiet during Freya's
  eat-first lesson, while live alien occupations still announce themselves.
- The optional `H` next-step guide now continues through chapters 2 and 3.
  It names the medicine/armor protection loop, follows the next connected
  site after two allies are protected, and explains both pack-assisted final
  wall clearing and the clean-ally guard recovery after a solo clear. The
  detailed `Tab`/`G` goals and first-chapter teaching sequence remain available.
- A 960×540 graphical route using keyboard input reached Startup Skip, the
  bowl, the home exit, an `R` cleanse, a `C` recruit, all seven marks around
  the first connected residence, its 10-second interior claim at 73.1 seconds,
  and an occupied wall clear at 93.8 seconds on seed 20260831. It used read-only
  world geometry for navigation and gameplay keys for every action. The route
  exposed a near-cleared wall threshold that stopped further weakening; the
  target-selection fix now has a focused regression and passed this live route.
  The same 960×540 live-keyboard sequence also passed on seeds 1 and 42:
  startup, meal, home exit, dog cleanse and recruitment, first connected
  interior claim, and occupied-wall clear. These three runs verify control
  paths across generated layouts, not how easily a new player discovers them
  or the rest of the campaign. Separate rendered 800×450
  startup, home, goals, and pause views showed no clipping, though scaled text
  is small and still needs an accessibility review with players.
- The staged three-chapter campaign flow also passed on generated seeds 1, 42,
  and 20260916. Those checks exercise target selection, chapter transitions,
  protected allies, and ending handoff, but directly assign some claims; the
  natural input route above remains the stronger evidence for the first claim.
- A longer input route exposed a live occupation trap at seed 20260831: an imp
  could occupy a building while Freya stood just outside its wall, expanding
  the collision margin across her position. Occupation now moves affected
  Freya and dogs to nearby walkable ground; compatible saves restore trapped
  positions safely. A focused regression covers the exact exterior point,
  unaffected dogs, movement after recovery, old-save restore, and interior
  ejection. A subsequent keyboard-only route claimed the first site, disabled
  its active generator, entered the lodge, and rescued all six dogs at about
  154 seconds. A free imp did reoccupy the lodge between cages; the route
  cleared it again with normal `R` and Space input before finishing the rescue.
  A subsequent 960×540 keyboard-only run completed chapter 1 on seed 20260831:
  eight of eight connected sites claimed, three hold clears (two required),
  no active generators, six of six lodge dogs rescued, and the chapter-result
  panel open at 629.1 seconds. Its controller recovered from live occupation
  changes; a too-narrow 0.2m A* endpoint tolerance in the controller was
  corrected to 0.4m after a focused probe, with no game-collision change.
  A separate headless sweep of five generated seeds checks all 8/5/4 chapter
  sites, walkable entrances and required mark approaches, alien wall approaches,
  all six lodge cages, and claim-order territory connections.
- Continuing that input route into chapter 2 exposed a genuine service-access
  defect on seed 20260831: grocery shelves left no Freya-width route from the
  entrance to an interior point within reach of the food bowl. The layout
  planner had used 0.09m fixture clearance while Freya needs about 0.245m
  around those fixtures. Service placement and aisle checks now use her actual
  clearance and an entrance-connected position. A regression walks the real
  collision grid to an interior `F` point and checks the effect for grocery,
  pharmacy, police, and clinic services on five seeds. The affected four
  interior captures were regenerated and inspected.
- A resumed seed-20260831 graphical run then completed the campaign with
  keyboard input: chapter 1 secured 8/8 sites, chapter 2 secured 5/5 sites
  with two protected allies, and chapter 3 secured 4/4 sites with an ally
  guarding the cleared final signal. Right reached page 4 of the ending and
  its credits; Escape chose Keep Exploring and restored the completed
  neighborhood. The controller read geometry and progress to choose keys but
  did not set gameplay progress. This verifies one generated route, not
  unfamiliar-player pacing or enjoyment.
- A later fresh seed-20260831 keyboard run reached 8/8 chapter-1 claims,
  cleared three alien holds, disabled the generator, and rescued all six lodge
  dogs. Its only ally was re-possessed during the long route, so the chapter
  result correctly waited for a clean ally. Resume restored the preceding
  7/8 autosave; normal defensive barking cleansed that ally during the last
  claim and opened the result. Continuing through ordinary input passed
  chapter 2 at 5/5 sites with two protected allies, chapter 3 at 4/4 sites
  with pack assistance, page-4 credits, and Keep Exploring. The fresh segment
  and resumed segment are separate processes, so this is not evidence of one
  uninterrupted startup-to-credits session.
- Another fresh seed-20260831 run at 960×540 opened the chapter-1 result at
  578.2 seconds with 8/8 connected sites, three cleared holds, no generator,
  one clean ally, and six rescued lodge dogs. It advanced to chapter 2, then
  the test controller timed out on a progressing cross-map grocery trip. A
  retained-save Resume passed that long trip; its overly strict pharmacy grid
  endpoint stopped the controller even though Freya was inside the store and
  within the `F` interaction range. After those two controller limits were
  corrected, a second Resume protected two allies through pharmacy `F` input,
  secured chapter 2 at 5/5 and chapter 3 at 4/4 with pack assistance, reached
  page-4 credits, and returned through Keep Exploring. This is additional
  playable-route evidence across processes, before the uninterrupted run below.
- A fresh seed-20260831 graphical route at 960×540 then used keyboard gameplay
  actions in one uninterrupted process from Startup Skip through credits and
  Keep Exploring. Chapter 1 reached 8/8 connected sites, three cleared holds,
  no active generator, one clean ally, and six lodge rescues at 620.2 seconds.
  Chapter 2 reached 5/5 sites with two protected allies and no active generator
  at 1147.3 seconds. Chapter 3 reached 4/4 sites with the pack-assist objective
  satisfied at 1366.7 seconds; page-4 credits appeared at 1367.3 seconds and
  Keep Exploring restored the completed neighborhood at 1373.9 seconds. The
  geometry-aware test controller selected normal keys and did not assign
  gameplay progress or use Resume.
- A second fresh, uninterrupted 960×540 graphical input route passed on seed 1.
  Chapter 1 reached 8/8 sites, four cleared holds, no generator, one clean ally,
  and six lodge rescues at 680.3 seconds. Chapter 2 reached 5/5 sites with two
  protected allies and four clean allies at 1116.6 seconds. Chapter 3 reached
  4/4 sites with pack assistance at 1310.8 seconds; page-4 credits appeared at
  1311.3 seconds and Keep Exploring restored the completed neighborhood at
  1317.7 seconds. The controller used normal keyboard actions without Resume
  or direct gameplay-state assignment. Its travel deadline now accounts for
  the actual navigation path; carried medicine approaches allow 1.1m of
  navigation tolerance, then verify the live dog is within 1.45m and is the
  selected `F` target inside the game's 1.55m interaction range. These are
  controller-only changes. Fixed seeds reproduce layouts, while live dog and
  occupation behavior can change which site is claimed first. Together the two
  runs demonstrate technically playable start-to-credits routes on two layouts;
  they do not measure new-player discovery, pacing, enjoyment, or graphical
  Windows QA.
- An earlier chapter-3 attempt found two immune active allies stuck about 23m
  from site 33 after a solo wall clear. Active dogs now compute a local A* path
  lazily when collision blocks direct movement. A nearby clean recruited
  reserve can satisfy the cleared-site guard objective. A focused `pack_squad`
  regression covered that seed and reached the guard range in 17.8 simulated
  seconds; the resumed keyboard route also completed the guard objective.
- Gameplay audio now uses fixed playback pitch and gain with one exact
  recorded urination cue. An isolated `R` defense against an imp plays a
  recorded bark, each first-time park drill has a recorded success cue, and
  occupied storefronts use the recorded imp-emergence cue only when Freya is
  nearby. These events use exact mappings without a replacement when an asset
  is unavailable; sources and licenses are in the
  [audio attribution](../godot/assets/audio/ATTRIBUTION.md).
- Carried medicine, armor, and clinic care now share one visible dog target
  with the `F` action. A dose or vest cannot be consumed on a dog that already
  has that protection, and immunity also makes another armor vest unnecessary.
  Chapter 2 favors an unprotected recruited ally; a protected independent dog
  can still be recruited to satisfy the objective. A grocery bowl takes `F`
  while Freya is at it, a nearby lodge cage keeps its `F` priority, and a
  retaken ally takes clinic priority over routine supplies. Focused regression
  and inspected 1280×720 and 960×540 captures cover target feedback.
- **Five unfamiliar-player playtests, minimum-hardware performance measurement,
  accessibility review, and a natural graphical Windows start-to-credits QA
  run remain open.** The first chapter's 30–45 minute pacing is still a
  playtest hypothesis. Automated checks prove route and state transitions, not
  fun. The user-selected minimum Windows test PC is the HP Victus 16-r0073cl
  (7N4X6UA#ABA): factory Windows 11 Home, Core i7-13700HX, GeForce RTX 4060
  Laptop GPU with 8 GB video memory, and 32 GB RAM, per the
  [HP model listing](https://support.hp.com/us-en/product/details/victus-by-hp-16.1-inch-gaming-laptop-pc-16-r0000/model/2101566991?sku=7N4X6UA)
  and [HP-authored specification sheet](https://cdn.cs.1worldsync.com/syndication/mediaserverredirect/57144c439c7c79835145a69032b43a53/original.pdf).
  Verify the actual PC configuration before testing. Its factory screen is
  1920×1080; 1280×720 is the candidate smallest supported game window,
  pending a readability check. A passing RTX 4060 result cannot establish a
  lower hardware floor. The 800×450 panel-bound check establishes containment
  only.
- A short 2.5-second warm-up plus five-second graphical sample on this Linux
  machine (Godot 4.7.2 Compatibility, Mesa Intel HD Graphics 4600) measured
  37.9 FPS at home, 37.8 FPS at the park, and 35.0 FPS near an occupied
  storefront with three imps. These are useful local baselines, not a sustained
  full-pack run or a Windows minimum-hardware guarantee.
- A staged five-recruit `pack_squad` view averaged 55.9 FPS in
  the same five-second graphical benchmark on that Linux GPU. This benchmark
  freezes gameplay updates while measuring the rendered scene. A separate
  135-second live worst-case scene on the same GPU, with 22 recruited dogs,
  two occupied generator storefronts, a producing kennel, and eight free
  imps, averaged 27.1 FPS; its worst five-second window was 24.0 FPS. This
  older local GPU misses the 30 FPS target for that scene. Engine static memory
  rose from 141.3 to 143.0 MiB, and sampled process RSS from about 418 to
  420 MiB, over that run.
- A matched 10-second warm-up and 35-second live A/B sample on seed 20260831
  measured 30.9 FPS before an unchanged-state alien-visual update guard and
  29.8 FPS with it. Direct scene-update timing was 15.27 versus 15.49 ms per
  frame; the remaining frame time includes rendering and other engine work.
  The guard did not show a benefit and was removed. The minimum-PC release gate
  remains open until the actual target hardware and longer sessions are checked.
- A later matched 10-second warm-up and 35-second live worst-case sample on the
  same Intel HD 4600 measured 27.4 FPS at both 1280×720 and 960×540; the worst
  five-second windows were 27.0 and 26.3 FPS. Main updates averaged 16.90 and
  17.17 ms, respectively, with about 1,065 draw calls late in both runs.
  Reducing resolution alone did not improve this scene, so it is not a measured
  performance fix. The actual minimum Windows machine still needs its own run.
- A temporary outside-store test hid all 76 non-kennel interiors and reduced
  draw calls by about 60–70. It averaged 29.6 FPS versus the 27.4 FPS baseline,
  but its worst five-second window was still 27.6 FPS, and hiding nearby
  interiors would remove furniture visible through windows. No production
  visibility change was made. If minimum-hardware testing requires more speed,
  measure distance-aware interior culling or batching of individual sidewalk
  and lane-marking meshes before changing their visuals.
- A later matched 35-second live sample on the same GPU at 960×540 compared
  the current scene with 192 center-lane-dash nodes present and hidden. The
  visible baseline averaged 31.4 FPS; hiding every dash averaged 31.2 FPS
  and removed only about seven draw calls near Freya. That sample does not
  support batching lane dashes as a useful optimization. Its higher FPS than
  the earlier 27.4-FPS sample is run-to-run variation, not evidence that the
  minimum-hardware target is met.
- A fresh 35-second live baseline on the same Linux GPU averaged 27.5 FPS
  (worst five-second window 26.8 FPS) and 17.04 ms of main updates per frame.
  Skipping nonmoving guard-post collision probes and pack-dog road scans raised
  a same-scenario sample to 29.6 FPS (worst window 28.3 FPS) with 15.08 ms of
  main updates. Caching dog collar placement avoids rescanning the model tree
  each frame; a profiled 35-second sample averaged 31.8 FPS (worst window 29.5 FPS)
  and 12.17 ms of main updates. Profiling has overhead, and these short runs
  vary, so they are diagnostic comparisons rather than a performance guarantee.
  An unprofiled 135-second run with the optimizations averaged 28.6 FPS; its
  worst five-second window was 22.1 FPS with 28 dogs after six kennel births.
  Engine static memory stayed near 142 MiB and process RSS near 422 MiB.
  The minimum Windows hardware and 30 FPS release floor remain unverified.
- Cached whole-building rendered bounds now skip detailed camera checks for
  buildings that cannot intersect the camera ray; intersecting buildings
  retain the exact per-mesh cutaway. An earlier matched 35-second profile
  suggested an improvement, but its category totals included the warm-up;
  the harness now resets categories at the sample boundary. The full
  camera-layout sweep passed. An unprofiled 135-second run with 28 dogs after
  six kennel births averaged 31.6 FPS, but its worst five-second window was
  27.2 FPS. Static memory stayed near 142 MiB and RSS near 420 MiB. This is a
  local improvement, while the 30 FPS floor on minimum Windows hardware is
  still unverified and the local worst window remains below it.
- The corrected 10-second warm-up and 35-second matched profiles measured
  `_nonbuilding_blocks_view` at 1.131 ms per sample frame. A conservative
  camera-segment bounding check now rejects distant trees, poles, hydrants,
  and dumpsters before their exact circle intersection tests; the matched
  profile measured 0.473 ms. Main update time fell from 11.83 to 11.02 ms,
  and the graphical sample averaged 34.3 versus 33.3 FPS on Linux Intel HD
  4600. The unprofiled 135-second run with 28 dogs after all six kennel births
  averaged 34.0 FPS and 11.11 ms of main updates; its worst five-second window
  was 28.8 FPS. Static memory peaked at 142.9 MiB and process RSS at 422.9 MiB.
  These are local results, not a Windows minimum-PC pass, and the local worst
  window remains below the proposed 30 FPS floor.
- Keyboard pause navigation now focuses Resume on opening. Escape resumes,
  and Enter on the focused button resumes. Page Up and Page Down scroll the
  Controls and How To Play panels while they are open; the focused regression
  exercises these inputs. `G` now pins and unpins the goals, Page Up/Down
  scrolls them, `Tab` remains a temporary hold, and pausing clears the pin.
  The chapter guide panel and its type are larger at 960×540. Long family
  dialogue and Freya's first-exit thought now wait for player advancement once
  complete. Repeated action holds and a master-only volume setting remain
  items for unfamiliar-player review, along with readability at supported
  window sizes.
- A focused normal-input Watch Intro route now selects the title's Watch Intro
  choice, waits for a complete UFO English line and a family line to remain
  until Space, then uses keyboard Next through both scenes. Freya uses F for
  her required meal, walks out of the live home, advances the complete immunity
  thought with Space, and returns to ordinary play. A fixed-seed headless
  local run passed with `WATCH_INTRO_ROUTE_OK`. The route is in predeploy and
  the exported Windows startup smoke; review-n passed the exported Windows
  route, while graphical player review still needs to be recorded.
- Accepted camera, goals, help scrolling, and volume controls now have a quiet
  click from the existing recorded CC0 button file. Repeated zoom and scroll
  inputs are throttled; a successful Quit finishes that exact recording after
  saving. A missing recording stays silent. These control cues still need a
  listening pass on the Windows review build.
- When goals are open, action and threat status now appears in a reserved strip
  inside that panel. Its scrollable task list makes room for the message at
  small window sizes, so warnings do not silently expire behind pinned goals.
  The 800×450 keyboard regression checks legibility, containment, and scrolling;
  a 960×540 reference view shows the same live warning.
- The full gameplay/world deterministic PNG set was regenerated after the
  prop-occlusion and guide changes. Inspected residence/pharmacy interiors,
  home, pause controls, occupied buildings, goals, and both 960×540 later
  chapter guides show no missing roofs, new occlusion, or clipped text. The
  larger guide fits that window size. The required full
  `./scripts/predeploy_size_checks.sh` suite passed twice after the final
  gameplay code; the second run also included the final smaller-window input
  regression.
- A Windows Actions route is prepared to verify the SHA-256 ZIP, run
  the extracted EXE/PCK through the bundled normal-input campaign controller,
  assert credits and Keep Exploring, and retain its log. Both manual review
  runs and tag publication require it; the release job depends on its success.
  [Review run 38747554956](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38747554956)
  passed export validation, Windows EXE startup, and the exported Windows
  start-to-credits route on seed 20260831; the publication job was skipped.
  The uploaded Windows log contains `NATURAL_ROUTE_CREDITS_OK`,
  `NATURAL_ROUTE_KEEP_EXPLORING_OK`, and `NATURAL_ROUTE_CAMPAIGN_OK`. The route
  is headless and automated; it does not replace a graphical player run.
- The current local Windows review ZIP,
  `dist/Friendly-Freya-review-20261015m-Windows-x86_64.zip`, was exported with
  Godot 4.7.2 and verified against SHA-256
  `d797428bea62c9098b174a641910d54a508ba2e46e96173ba3a46c6526e4094a`.
  Exported-PCK validation reported `RELEASE_CONTENT_OK` for the ending scene,
  active dog model, 24 recorded barks, all 32 exact cue mappings, and the bundled
  normal-input campaign QA and performance routes. The extracted review-m PCK
  passed a short headless performance-entry smoke with two complete five-second
  reporting windows. The earlier review-k PCK passed, after a five-second
  warm-up, a 20-second graphical 1280×720 sample on the local Intel HD 4600.
  The graphical sample held the requested client size, moved Freya, and spawned
  kennel dogs, but averaged 22.4 FPS on that older GPU. A six-second cold-start
  sample on the same machine tripped the progress guard after a slow first
  frame; these checks do not measure sustained FPS on the selected HP.
  A local live-input route at commit `be0398d` reached the chapter-2 checkpoint
  with all six lodge dogs rescued, 8/8 chapter-1 sites, 5/5 chapter-2 sites,
  and two separately recruited and protected clean allies. The post-refinement
  `./scripts/predeploy_size_checks.sh` suite passed. The later
  [Windows review-m run](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38781287337)
  at commit `06bf6a9` passed export, EXE startup/performance-entry smoke, and
  the full headless campaign route. Its log records three chapters, six lodge
  rescues, 18 claimed sites, three allies, `NATURAL_ROUTE_CREDITS_OK`,
  `NATURAL_ROUTE_KEEP_EXPLORING_OK`, and `NATURAL_ROUTE_CAMPAIGN_OK`.
  A local Linux headless run of the earlier
  review-f extracted PCK secured chapter 1 at 8/8 sites and six lodge
  rescues, recovered from an ally's re-possession to protect two in chapter 2
  at 5/5 sites, then completed chapter 3 at 4/4 with pack assistance. It logged
  `NATURAL_ROUTE_CREDITS_OK`, `NATURAL_ROUTE_KEEP_EXPLORING_OK`, and
  `NATURAL_ROUTE_CAMPAIGN_OK` before exiting successfully. A separate Windows
  export from that earlier review commit completed
  the exported-EXE
  controller route in 1187 simulated seconds, securing all three chapters with
  18 claimed sites, six lodge rescues, and four allies. Graphical Windows
  playtesting on the HP Victus remains open.
- The local `review-20261015n` Windows ZIP was exported from commit `0f66c22`
  and verified against SHA-256
  `77ad53e9ea5345df3223c18c66fd758f11d4f9cfca8dfb810d42b469d85b24bd`.
  Its extracted PCK passed the bundled Watch Intro keyboard route through the
  held UFO and family dialogue, meal, first-exit thought, and ordinary play.
  The same route also passed in rendered 960×540 Linux windows from source and
  the extracted PCK. These checks do not establish graphical Windows quality
  or the HP performance floor.
- The [review-n Windows Actions run](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38786630905)
  passed all three jobs at commit `0f66c22`: export validation, Windows EXE
  startup and packaged stress entry, the keyboard Watch Intro route, and the
  exported start-to-credits campaign. Its [campaign log](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38786630905/artifacts/11999436575)
  records three secured chapters, six rescued lodge dogs, three allied dogs,
  18 claimed sites, credits, and Keep Exploring with no game error or warning.
  The [Windows download artifact](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38786630905/artifacts/11997189030)
  contains `Friendly-Freya-manual-14-Windows-x86_64.zip` with verified SHA-256
  `8724dafe102dc98eb489af1edd6c844e7fb22f1b1ea28a51ba1074e5d6be1ea9`.
  The short CI stress entry is not a graphical HP performance result.
- An optional saved "Press once for long actions (Space/C)" setting in Pause >
  Controls now lets a player continue a scent mark, interior claim, alien-wall
  weakening, or selected-dog socialization after releasing the key. A second
  press, movement, another action, target loss, tutorial/training, pause, loss
  of window focus, or a chapter result stops it; completion stops it
  automatically. The default remains a physical
  hold. A focused keyboard check passed a complete ten-second interior claim,
  dog recruitment, target and action cancellation, dumpster and bark priority,
  settings persistence, and 800×450/960×540 UI bounds. The full
  `./scripts/predeploy_size_checks.sh` suite passed after the final focus-loss
  and chapter-result guards; the affected pause captures were regenerated and
  inspected. A player accessibility pass remains open.
- The generated campaign reachability guard now tests ten fixed seeds with a
  Freya-radius, 0.5m connected grid from the home entrance. Its focused run
  passed 170 sequential chapter sites, 742 required mark approaches, 50
  occupied walls, 170 entrances, and 60 lodge cages in about 153 seconds.
  This strengthens procedural coverage; it is not proof that every random
  layout is enjoyable or free of every route problem.
- A final source audit found exact recorded cues for successful direct player
  actions. All 32 mapped action cues and 33 other directly referenced audio
  assets are present and decode; the runtime keeps a missing selected cue
  silent. Headless checks skip playback, so the Windows review still needs a
  listening pass on the Victus for audible output and mix.
- The local `review-20261015o` Windows ZIP was exported from the updated source
  with Godot 4.7.2 and verified against SHA-256
  `225d39a0aba03362b8436a03ab15e3742b708eabb411a799f73c1197685e1fd4`.
  Its PCK content check passed with the active model, 24 barks, 32 exact cue
  mappings, and ending; the extracted PCK passed the press-once keyboard test.
  The complete source predeploy suite passed after the final focus and chapter
  guards. Updated Controls and How To Play PNGs were regenerated and inspected.
  The [review-o Windows run](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38794653756)
  passed source validation, export, EXE startup, the packaged short stress
  entry, and the keyboard Watch Intro route at commit `0d088f3`. Its
  [download artifact](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38794653756/artifacts/12001498322)
  contains `Friendly-Freya-manual-15-Windows-x86_64.zip`; its SHA-256 manifest
  passed verification against
  `2e6d1f4d9402694f1b82635a4be392a54a8905c782b0bd1f077fd1b12f79a5c0`.
  Its [campaign log](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38794653756/artifacts/12003200905)
  records three completed chapters, six lodge rescues, two allied dogs, 18
  claimed sites, credits, and Keep Exploring. The game logged no error or
  warning. This was a headless automated route; graphical HP performance and
  player enjoyment still need direct observation.

## The game to finish

Freya is an unusually brave three-legged dog protecting Ryah Diane while
searching for Gene and Zoe. Her dog senses expose clues, barking drives aliens
out of dogs, friendship builds a pack, and scent marking pushes the invaders
out of Northbrook. The best version of this game lets the player **notice a
threat, make a choice, see a dog or place change because of it, and use that
gain in the next encounter**. Its humor and domestic stakes should remain as
important as the invasion.

The original scope decision was to ship a complete, replayable neighborhood
chapter first, with roughly **30–45 minutes for a first successful run** as a
playtest hypothesis. It would end with Ryah safe, key alien generators shut
down, a kennel rescue, and a lead toward Gene and Zoe. Two shorter chapters
would vary the same core loop and resolve the parents' abduction. All three
chapters are now implemented; their pacing and clarity still need observation.
The 80-building map supports optional total ownership without making it the
story ending. This staged scope kept the first complete loop central to the
design before expanding its content.

## Planning baseline: what existed and what was missing

This table records the build when this plan was drafted. See the implementation
log above for the current campaign and remaining gates.

| Area | Build at planning time | Work identified for the proposed release |
| --- | --- | --- |
| Opening and world | Startup choice, UFO intro, live-home family prologue, eat-first lesson, first-exit possession reveal, procedural 5×5-block neighborhood | Shorter route into play for returning players; story scenes that pay off the rescue premise |
| Dog encounters | Roaming NPC dogs begin secretly possessed (the staged first-exit dogs start ordinary until the reveal); Freya senses unease; `R` expels an alien or scares a real dog; `C` recruits a cleansed dog at a Hunger cost | A protected-dog threat and useful pack actions, with readable counterplay |
| Buildings and territory | All clean buildings are enterable; occupied ones lock; pee breaks alien occupation; surrounding scent marks plus a 10-second interior claim grant ownership | Reduce mandatory repetition, make claimed sites change the player's options, and give strategic landmarks distinct purposes |
| Alien pressure | Occupied pharmacy/grocery can generate up to eight free aliens; free aliens flee toward buildings; storefronts reinforce nearby occupied buildings | Give aliens a bounded, understandable plan that players can interrupt and eventually defeat |
| Supplies and side activities | Home/grocery food, pharmacy immunity medicine, visible police armor, bones/Strength, stick speed boost, dog park agility, Social and Vomit meters | Make armor, park training, Social, and Vomit affect decisions, or simplify their UI; give the clinic a specific role |
| Kennel | Complete standalone Northbrook Dog Lodge concept with six caged dogs and finite possessed-dog spawning | Place it in the map, connect occupation and dog state, and implement cage release and rescue payoff |
| Completion | HUD victory and acknowledgment when all 80 buildings are owned | A chapter objective, ending, save/resume, and campaign completion; retain full ownership as an optional challenge |
| Delivery | Windows export workflow, automated checks, deterministic captures | Full-route playtests, sustained performance review, settings/accessibility pass, save migration, and release QA |

Evidence: [Godot overview](../godot/README_GODOT.md), [gameplay
audit](../GAMEPLAY_AUDIT.md), [building program](../BUILDING_PROGRAM.md),
[kennel contract](../KENNEL_CONCEPT.md), and the implementation in
[`main.gd`](../godot/scripts/main.gd). The [de-jankification
record](DEJANKIFICATION.md) documents a broad graphical pass, but explicitly
does not represent a manual 80-building conquest. The planning-time gameplay
capture's HUD showed `1/80` buildings in the fixed seed.

### Why the original objective needed revision

The map contains 80 claimable buildings in the reviewed seed. Seventy-nine
post-home interior claims alone require at least **13 minutes of stationary
holding** at 10 seconds each; that excludes travel, surrounding 2.75-second
object claims, alien weakening, food, dogs, and finding entrances. This is a
lower bound, not a playtime estimate. The original main quest rewarded
performing the same action everywhere rather than mastering the game's most
distinctive mechanics. The implemented campaign uses a smaller set of
meaningful targets; full-map ownership remains optional.

## Release design decisions

These choices guided the campaign implementation. The implementation log
records what shipped in this review build; their pacing and clarity still need
observation with new players.

Keep the [canonical rules](../GAMEPLAY_AUDIT.md#canonical-rules) throughout:
all NPCs remain real dogs regardless of possession, possession is visually
secret after an event, a wrong bark causes temporary flight, occupied
architecture stays static rather than pulsing, alien imps move on the ground,
and Ryah's home is excluded from alien occupation.

1. **Main objective:** chapters 1, 2, and 3 have eight, five, and four
   highlighted strategic properties, respectively, with two, one, and one
   seeded alien strongholds. Secure the objectives, disable every active
   generator, and complete the chapter's story requirement. Optional full-map
   ownership remains available after the ending. A property may require nearby
   marks, but the quest does not require every mailbox and tree on the map.
2. **The dog loop:** locate a suspicious dog through Freya's unease and behavior;
   bark to test it; after a successful cleanse, socialize and recruit it;
   decide whether to protect it with medicine or armor; assign it a useful
   pack job. A wrong bark costs a temporary social opportunity and positioning,
   as it does now. Possession never gets a permanent visual tell on a dog.
3. **The pack matters:** start with three simple orders—follow Freya, guard a
   chosen site or dog, and assist at a stronghold. Nearby allies can warn about
   incoming imps, interrupt a possession attempt, or shorten a contested claim.
   Cap the active squad for clarity and performance; the rest of the recruited
   roster can guard locations. Keep all recruited dogs real dogs with
   possession and army alignment as independent states.
4. **Re-possession has counterplay:** an imp must reach a real, non-immune dog,
   show a short, interruptible transfer event, and observe a cooldown after a
   failed attempt. Barking or a guarding ally can interrupt it. After a
   successful transfer the dog again looks ordinary; the visible event, not a
   lasting cosmetic, explains the change. Medicine grants permanent immunity.
   Give armor a different, limited defensive use—for example, absorbing one
   attempt before needing repair—so both services matter.
5. **Territory and services create advantages:** cleansing an occupied pharmacy,
   grocery, police station, clinic, or kennel opens its existing service to the
   player; ownership is not required to use it. Claimed neighboring properties
   give a visible scent-control bonus while weakening a nearby alien hold.
   Keep the two-step building resolution clear: pee at the occupied wall to
   break the hold, then meet territory requirements and claim the clean
   interior. Do not add a third reclaim action unless playtests reveal a
   distinct decision it would create.
6. **Pressure is finite and fair:** strongholds announce their output and
   radius. Disabling one stops its generation and reinforcement. Enemy
   movement contests unclaimed sites and vulnerable dogs. If a later design
   allows enemies to retake owned sites, telegraph it and never silently erase
   a long chain of completed claims. Ryah's home stays safe from alien
   occupation. A visible imp should be interceptable: Freya's bark can briefly
   stagger it, while an assigned ally can contain it; an uncontained imp can
   still escape into a building. Set an explicit maximum on simultaneous
   attacks and allow recovery from a lost site rather than forcing a restart.
7. **Every meter earns its place:** Hunger already regulates travel and
   socializing; Strength already speeds wall weakening. Make a full Vomit meter
   a short-range emergency interruption or area denial with a clear cost, while
   preserving its comic presentation. Give Social a visible tactical effect
   such as faster pack assistance, or remove the meter from the main HUD.
   Current vomit-on-dog and count-the-objects tasks belong in optional
   achievements, not the central quest.
8. **The clinic and park pay off:** use the clinic for healing or restoring a
   vulnerable ally after an attack, separate from pharmacy immunity and police
   armor. Let the first completion of each agility obstacle teach or improve a
   small pack ability; subsequent runs remain optional play. These benefits
   need to be immediately noticeable, not another hidden percentage grind.

## A concrete first chapter

| Beat | Player action | New decision or payoff |
| --- | --- | --- |
| Home | Watch or skip the intro, eat, exit, witness the dog-walker abduction | Understand Ryah, Freya's immunity, Hunger, and `R` |
| Park | Sense one possessed dog, cleanse it, recruit it, try one agility obstacle | Gain the first useful ally and see a small immediate assist |
| First block | Mark a few nearby objects and claim one connected property | See territory expand and get a practical safe point |
| Services | Choose grocery food, pharmacy immunity, or police armor as a near-term route | Protect an ally or sustain a push; the occupied version of a service becomes a clear target |
| Stronghold | Interrupt an imp, defend an ally, weaken an occupied wall, claim the property | Resolve the full alien/building loop once before it repeats with more pressure |
| Kennel | Find the six captives, decide when to cleanse a producing kennel, then open the cages | Make the finite six-spawn rule and Freya's promise meaningful; rescue remaining dogs without punishing an early cleanse with a softlock |
| Finale | Disable the chapter's last generator and secure Ryah's local network | Show a chapter result, dog roster, optional unfinished claims, and a lead on the missing parents |

The kennel's existing `8s` interval, six accepted-spawn lifetime cap, and
forfeiture on cleansing should remain intact. The new rescue mechanic must
explain what happens to the unspawned portion and to dogs still caged when
cleansing occurs. The player must be able to finish the rescue objective
regardless of when they attack the kennel. See the [kennel placement
contract](../KENNEL_CONCEPT.md).

## Production order and gates

### 0. Measure the current game before changing scope

- Record a natural first-time route from startup through first cleanse,
  recruitment, first claim, and first occupied building on at least three map
  seeds. Track elapsed time, missed prompts, wrong inputs, and where players
  stop. Use the existing seed override and graphical capture tools.
- Fix misleading current instructions: the pause help says allies may mark
  surrounding objects, while current marking is Freya's action. Review the
  objective text and service prompts in the same pass.
- Establish a performance baseline in the park, home, and an occupied retail
  block. The September review measured about 26.6 FPS in the park and 32.8 FPS
  at home on its older test GPU, with variation between samples; measure again
  on the intended release hardware before choosing budgets.

**Gate:** a written playtest report identifies the top three friction points
and a reproducible seed for each technical issue.

### 1. Ship the first chapter's short, complete loop

- Introduce chapter objectives and a map route to 6–10 strategic properties;
  make full-map ownership an optional completion badge. Ensure the selected
  objectives, their required scent targets, and the route between them are
  reachable on every generated seed.
- Convert the early park, first claim, and first stronghold into progressive,
  skippable teaching moments. Show one current action, one result, and the
  next nearby objective. Keep `Tab` as the detailed reference.
- Add save/resume for seed, chapter/objectives, claims, occupation, dogs,
  carried supplies, meters, kennel lifetime budget, and story flags. Use
  stable IDs rather than scene-node references in the save. Add versioning and
  a safe recovery path for old saves.
- Add the chapter result and clear continuation path. A player who chooses
  `New Game: Skip Intro` must still reach and understand it.

**Gate:** new players can complete the first cleanse and meaningful claim
without consulting documentation; the whole chapter can be finished and
resumed mid-run. Initial target: 30–45 minutes, adjusted by observed play.

### 2. Add one meaningful tactical layer at a time

- Implement imp-to-dog re-possession with the warning, interruption, success,
  immunity, armor, and cooldown states above. Test both recruited and
  independent real dogs.
- Let the player interrupt a visible imp's route to a building, using bark
  timing and a pack assist. Preserve a credible escape route so exorcism can
  still create a stronghold problem.
- Add the three pack orders and make one ally visibly useful in the first
  stronghold. Test pathing, stuck recovery, separation, occupation transitions,
  and the independent possession/alignment state.
- Make services and claimed landmarks affect tactics. Prototype the clinic,
  defensive territory, and a small supply cost before creating a broad
  resource economy or many fortification levels.
- Balance spawn intervals, reinforcement, Hunger, and claim duration through
  observed decisions. Record why a player chooses one route over another.

**Gate:** two different routes through the same stronghold are viable; losing
an ally or site has a readable cause and recoverable response; recruited dogs
do more than wear collars.

The mechanics support a quick pack-assisted wall break and a prepared
approach that claims a neighboring property for scent support and guards an
ally near the hold. The `tactical_routes.gd` probe tested both on seed 20260831
from the same staged checkpoint: one clean ally, five ready marks, and the same
full-strength occupied wall. It moved Freya and issued orders and claims with
keyboard events after setup. Pack Assist broke the hold in 6.45 seconds total
(4.42 seconds at the wall); claiming the prepared neighbor and ordering Guard
broke it in 17.54 seconds total (4.86 seconds at the wall) and left that
neighbor owned with a 14% scent bonus. Both routes are technically viable, but
the prepared route takes longer to reach this wall clear. Both properties are
highlighted chapter sites on this seed, so the prepared claim also advances a
required objective; the comparison does not measure total chapter time. The
probe has no live dog threat and does not establish the value of ownership for
later holds, which route players choose, or whether the tradeoff feels
worthwhile. Record those decisions in unfamiliar-player sessions before
claiming this balance gate is satisfied.

### 3. Integrate content and resolve the story

- Place the Northbrook Dog Lodge on a guaranteed suitable lot; register it in
  walkability, minimap, occupation, save state, dog AI, and the chapter route.
  Implement the cage-release interaction and rescue feedback.
- Give later chapters new combinations of existing systems, not just larger
  maps: one can stress protection and kennel timing; the last can stress
  coordinated pack defense and removal of the final alien source. Use
  authored landmark positions inside procedural neighborhoods so required
  story beats never depend on luck.
- Write and stage an ending that resolves Gene and Zoe's abduction and Freya's
  protection of Ryah. Preserve the game's humorous voice while giving the
  family a clear outcome. Add credits and a replay/continue choice.

**Gate:** start-to-credits play is possible without dev controls, missing
mechanics, or an objective that depends on an unreachable spawn.

Fresh graphical input runs on seeds 20260831 and 1 each reached credits and
Keep Exploring in a single process, without Resume or direct gameplay-state
assignment. They demonstrate the technical route for this gate on two layouts.
Fixed seeds reproduce layouts, while live dog and occupation behavior can alter
the first claimed site. The geometry-aware controller does not establish that
an unfamiliar player can discover or enjoy the route; graphical Windows QA,
minimum-PC performance, and player observation remain open under Gate 4.

### 4. Polish, test, and release

- Review camera, signage, minimap symbols, target selection, building entry,
  and feedback at 1280×720 and smaller supported windows. Provide a readable
  objective marker and a way to distinguish critical from optional sites.
- Add remappable controls or an alternate input scheme, subtitle/text speed
  choices, contrast/readability options, and separate music/effects volume if
  playtests call for them. Keep the skip route and pause behavior reliable.
- Complete a focused keyboard-only accessibility pass. Check whether sustained
  scent holds and repeated actions are manageable, subtitles and prompts remain
  long enough to read, markers retain contrast at the supported window sizes,
  and every progress-critical sound has a visible or textual cue. Record barriers,
  adjust the controls or presentation, and repeat the affected route.
- Run long-session performance and memory checks with a full pack, occupied
  storefronts, and kennel production. Optimize measured bottlenecks; use a
  release target of at least 30 FPS on the stated HP Victus minimum test
  machine at 1280×720 and native 1920×1080, with predictable input response.
  Confirm the actual hardware configuration and window readability before
  treating those results as a release gate.
- Run every required automated check after gameplay changes, regenerate and
  inspect affected deterministic PNGs after visual changes, and perform
  natural keyboard/controller-if-supported playthroughs on several seeds.
  Test save/load around occupation, kennel cleansing, rescue, and chapter
  completion. Smoke-test the exported Windows package on its target OS.
- Preserve the [audio policy](../AGENTS.md#audio-policy-non-negotiable): use
  only sourced recorded files for gameplay sounds; a missing file means
  silence. Keep [attribution](../godot/assets/audio/ATTRIBUTION.md) and model
  release provenance current.

**Gate:** a clean start-to-credits Windows playthrough, a passing
`./scripts/predeploy_size_checks.sh`, inspected visual captures, no known
softlocks, a completed accessibility pass, and a documented performance floor
on minimum hardware. Five unfamiliar-player sessions must identify severe and
common friction, with fixes and repeat observations showing that players can
finish the route, understand their choices, and want to continue.

## How to tell whether it is fun

The automated suite proves contracts; it cannot prove pacing. Hear from about
five players unfamiliar with the project before freezing the first chapter.
They can relay informal comments through the owner; no player form is needed.
If someone observes, let a comfortable player think aloud without teaching
controls. Optional notes include time to the first independent dog decision,
recruited ally, property claim, stronghold clear, and chapter finish. Look for
repeated stationary holds, backtracking for food, missed possession tells,
pack commands that fail to help, and points where the player cannot name a
useful next action.

Use these findings to tune the number of required claims, claim duration,
distance between landmarks, alien warning time, food availability, and
objective wording. The exact 30–45-minute target and chapter count are
design hypotheses; keep or change them based on completed playthroughs.
