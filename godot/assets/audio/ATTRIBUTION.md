# Audio Sources and Attribution

[Documentation hub](../../../README.md) ·
[repository instructions](../../../AGENTS.md) ·
[intro reference](../../../INTRO_CUTSCENE.md) ·
[run and validation guide](../../../RUN_FRIENDLY_FREYA.md)

**Status:** Current inventory of the source, license, derivation, and runtime
mapping details for audio distributed with the Godot project.

## Playback Policy

Every sound event must load and play only its explicitly mapped asset. If that
file is missing or fails to load or play, the event is silent. Never synthesize,
procedurally generate, substitute, or select another sound as a fallback.

## Title Card Theme

### Distributed source file

- `menu/title_card_theme_8bit.wav`

### Source

- User-recorded file outside the repository:
  `/data/projects/Audio Recordings/Recording for Freya Title Card.wav`

### License

- Original recording supplied by the project owner for Friendly Freya.

### Derived file

`menu/title_card_theme_8bit.wav` is the source-derived energetic candidate 02
from the project-owner recording. The build repeats the original 8.51-second
performance to make a 17.02-second menu bed, speeds it up, applies fixed
bit/sample reduction, filtering, echo/pulse processing, and limiting, then
saves a Godot-friendly 44.1 kHz, 16-bit PCM WAV. It does not contain a
Stable Audio 3 render or a MIDI continuation. The live WAV has SHA-256
`ced60668f4e72d65cd4d89b6c4624921186e430b2c6669064699feea6f27f5a6`,
matching `title_card_theme_source_energy_candidate_02.wav` exactly. The source
recording, conversion command, and historical AI experiments are documented in
[`docs/audio/TITLE_CARD_THEME.md`](../../../docs/audio/TITLE_CARD_THEME.md).

## Dog Barks

### Distributed source files

- `dog_barking.wav`
- `dog_barking_mono.wav`

### Original archive paths

The following paths identify inputs inside the original `dog.7z` source
archive. They are provenance records, not files distributed in this repository:

- `tmp_dog_extract/Dog/Dog 1.wav` (source archive: `dog.7z`)
- `tmp_dog_extract/Dog/Dog 2.wav` (source archive: `dog.7z`)
- `tmp_dog_extract/Dog/Dog.wav` (source archive: `dog.7z`)
- `tmp_dog_extract/Dog/Raw/Dog Bark.wav` (source archive: `dog.7z`)
- `tmp_dog_extract/Dog/Dog Bark 1.wav` (source archive: `dog.7z`)
- `tmp_dog_extract/Dog/Dog Bark.wav` (source archive: `dog.7z`)

### Sources

- OpenGameArt,
  ["Dog barking mono"](https://opengameart.org/content/dog-barking-mono),
  authored by Brandon Morris and submitted by `HaelDB`
- OpenGameArt, ["Dog sounds"](https://opengameart.org/content/dog-sounds),
  authored by `pauliuw`

### License

- CC0 (Public Domain)

### Derived files

- `barks/conversational_bark_01.wav` through
  `barks/conversational_bark_04.wav`
- `barks/excited_social_bark_01.wav` through
  `barks/excited_social_bark_06.wav`
- `barks/bark_01.wav`
- `barks/bark_02.wav`
- `barks/bark_03.wav`
- `barks/bark_04.wav`
- `barks/bark_05.wav`
- `barks/bark_06.wav`
- `barks/bark_real_01.wav`
- `barks/bark_real_02.wav`
- `barks/bark_real_03.wav`
- `barks/bark_real_04.wav`
- `barks/bark_real_05.wav`
- `barks/bark_real_06.wav`
- `barks/bark_real_07.wav`
- `barks/bark_real_08.wav`
- `barks/aggressive_bark_01.wav`
- `barks/aggressive_bark_02.wav`
- `barks/aggressive_bark_03.wav`
- `barks/aggressive_bark_04.wav`
- `barks/aggressive_bark_05.wav`
- `barks/aggressive_bark_06.wav`

The four `conversational_bark` clips are fixed, unmodified-timebase trims of
the four naturally separated barks in `dog_barking_mono.wav`. Their source
ranges are `0.000–0.285`, `0.485–0.785`, `1.075–1.425`, and
`1.645–2.039` seconds.

The six `excited_social_bark` clips are fixed trims of energetic moments in
`dog_barking.wav`. Their source ranges are `1.020–1.360`, `1.380–1.820`,
`1.820–2.140`, `2.700–3.010`, `4.150–4.930`, and `6.200–6.510` seconds.
The reproducible extraction is [build_bark_library.sh](../../../scripts/build_bark_library.sh),
which verifies both source hashes and never synthesizes, pitch-shifts,
normalizes, or substitutes sound.

The legacy `barks/bark_01.wav` through `barks/bark_06.wav` were also trimmed
from `dog_barking.wav`, but are no longer in an active runtime pool.
`barks/bark_real_01.wav` through `barks/bark_real_08.wav` and
`barks/aggressive_bark_01.wav` through `barks/aggressive_bark_06.wav` were
trimmed and processed from the OpenGameArt `dog.7z` archive.

Runtime uses four conversational clips for ordinary NPC replies, fourteen
excited-social clips (the six new field trims plus eight `bark_real` clips),
and six aggressive clips. Each category has an independent shuffle bag: all
recordings in that category play before any is reused, and cycle boundaries
cannot repeat the immediately previous recording. Every source keeps its own
shuffle slot even when its file fails to load; drawing that slot stays silent
and does not substitute another clip. Another category is never used as a
fallback. Exact family-intro and
post-intro tutorial mappings remain separate and are defined with the pools
near the top of [main.gd](../../scripts/main.gd).

Active bark recordings play at their original pitch. Gain is fixed for each
bark category and for Freya versus another dog; nearby pack size changes the
number and timing of barks, not the recording's pitch or gain.
When `R` stops an imp with no dog or possessed lodge captive nearby, Freya
plays one recorded aggressive bark from that same pool. A short fixed gap
prevents several nearby imps from stacking duplicate barks; dog and captive
interactions keep their existing recorded bark sequences.
The `kennel_spawn_bark` ID maps only to `barks/aggressive_bark_01.wav`, a
recorded CC0 bark from `pauliuw`'s [Dog sounds](https://opengameart.org/content/dog-sounds)
archive above. One confirmed live possessed-dog spawn at the lodge plays it
when Freya is within 14 world units of the spawned dog. Distant spawns, failed
registration or confirmation, and save restoration stay silent. The fixed
mapping has no substitute if this recording is unavailable.

## Urination

### Source files

- `pee/dog_urination_stream_330024.mp3`
- `pee/urinating_bathroom_17120.mp3`

### Sources

- Freesound, ["Urination"](https://freesound.org/people/Mafon2/sounds/330024/),
  uploaded by `Mafon2`
  - Direct preview URL used in project:
    `https://cdn.freesound.org/previews/330/330024_1196472-hq.mp3`
- Freesound,
  ["urinating bathroom urinal fan.aif"](https://freesound.org/people/dcaudio/sounds/17120/),
  uploaded by user `dcaudio`
  - Direct preview URL used in project:
    `https://cdn.freesound.org/previews/17/17120_137-hq.mp3`

### Licenses

- `dog_urination_stream_330024.mp3`: [CC0 (Public Domain)](https://creativecommons.org/publicdomain/zero/1.0/)
- `urinating_bathroom_17120.mp3`: [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/)

### Runtime mapping

Each valid claim target starts `pee/dog_urination_stream_330024.mp3` once,
from a fixed 0.02-second offset, at original pitch and a fixed −12.6 dB gain.
Playback stops when the claim ends or the target changes. It is not chopped
into randomized bursts or mixed with another recording. The distributed
`pee/urinating_bathroom_17120.mp3` remains attributed as a reference source
but is not loaded for gameplay or used as a fallback.

## Eating

### Source files

- `eat/dog_eating_dinner_760336.mp3`
- `eat/wet_sloppy_eating_382671.mp3`
- `eat/wet_sloppy_eating_alt_382673.mp3`
- `eat/dog_chewing_crunchy_456376.mp3`

### Sources

- Freesound,
  ["Hungry Dog Eating Dinner 1"](https://freesound.org/people/Geoff-Bremner-Audio/sounds/760336/),
  uploaded by `Geoff-Bremner-Audio`
  - Direct preview URL used in project:
    `https://cdn.freesound.org/previews/760/760336_10643461-hq.mp3`
- Freesound,
  ["Wet Sloppy Eating 2.wav"](https://freesound.org/people/bbrocer/sounds/382671/),
  uploaded by `bbrocer`
  - Direct preview URL used in project:
    `https://cdn.freesound.org/previews/382/382671_4297074-hq.mp3`
- Freesound,
  ["Wet Sloppy Eating.wav"](https://freesound.org/people/bbrocer/sounds/382673/),
  uploaded by `bbrocer`
  - Direct preview URL used in project:
    `https://cdn.freesound.org/previews/382/382673_4297074-hq.mp3`
- Freesound,
  ["Chewing Dog Eats Crunchy Crackers"](https://freesound.org/people/Bon_Vivant_Pictures/sounds/456376/),
  uploaded by `Bon_Vivant_Pictures`
  - Direct preview URL used in project:
    `https://cdn.freesound.org/previews/456/456376_8812224-hq.mp3`

### Licenses

- `dog_eating_dinner_760336.mp3` and its `dog_eating_dinner_bite_760336.ogg`
  derivative: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
  Credit: Geoff Bremner / `Geoff-Bremner-Audio`,
  [“Hungry Dog Eating Dinner 1”](https://freesound.org/people/Geoff-Bremner-Audio/sounds/760336/).
  The preview MP3 was cropped to 0.10–0.46 seconds, faded at both ends,
  converted to mono Ogg Vorbis, and used at a fixed −10.4 dB playback gain.
- The two `bbrocer` wet-eating recordings and the
  `Bon_Vivant_Pictures` crunchy-dog recording, including their derivatives:
  [CC0 (Public Domain)](https://creativecommons.org/publicdomain/zero/1.0/).

### Runtime mapping

Food, bone, and poop each select only their matching recorded pool. The chosen
recording plays at original pitch and a fixed −10.4 dB gain. Active gameplay
files are short, source-derived excerpts, so each bite can end during Freya's
0.34–0.56-second eating pose without an abrupt cut. The original full-length
MP3s remain as attributed source/reference files; they are not alternative
playback choices. The cinematic pill-eating beat uses its own longer excerpt.
All excerpt ranges below are from the exact source files named above; fixed
fade-in/fade-out and the stated gain are the only edits. No new audio was
synthesized or layered. Rebuild with
[build_eat_action_excerpts.sh](../../../scripts/build_eat_action_excerpts.sh),
which verifies the source-file hashes first.

| Active derived file under `eat/` | Source | Excerpt (seconds) | Fixed source gain | Runtime event |
| --- | --- | --- | --- | --- |
| `dog_eating_dinner_bite_760336.ogg` | `dog_eating_dinner_760336.mp3` | 0.10–0.46 | unchanged | Food or bowl, 0.36 s |
| `dog_chewing_crunchy_bite_456376.ogg` | `dog_chewing_crunchy_456376.mp3` | 8.40–8.68 | unchanged | Bone, 0.28 s |
| `wet_sloppy_eating_bite_382671.ogg` | `wet_sloppy_eating_382671.mp3` | 27.05–27.53 | −14 dB | Poop, 0.48 s |
| `wet_sloppy_eating_alt_bite_382673.ogg` | `wet_sloppy_eating_alt_382673.mp3` | 4.42–4.90 | −9 dB | Poop, 0.48 s |
| `dog_chewing_crunchy_pills_456376.ogg` | `dog_chewing_crunchy_456376.mp3` | 8.35–9.47 | unchanged | Family pill-eating beat, 1.12 s |

A missing selected recording leaves that eat event silent; an unknown kind
selects no recording.

## Intro Speech Bubbles

### Source files

- `intro/rune_reveal.ogg` (original archive file: `Audio/glitch_002.ogg`)
- `intro/translation_resolve.ogg` (original archive file:
  `Audio/confirmation_002.ogg`)

### Source

- Kenney, ["Interface Sounds (1.0)"](https://kenney.nl/assets/interface-sounds)
- Creator and distributor: [Kenney](https://kenney.nl/)
- Direct archive URL:
  `https://kenney.nl/media/pages/assets/interface-sounds/fa43c1dd4d-1677589452/kenney_interface-sounds.zip`

### License

- [CC0 (Public Domain)](https://creativecommons.org/publicdomain/zero/1.0/)

### Semantic mapping

- `intro/rune_reveal.ogg` plays once when each intro dialogue bubble first
  reveals its nonsensical alien runes.
- `intro/translation_resolve.ogg` plays once when each intro dialogue bubble
  begins transforming those runes into English.
- The two source files were extracted and renamed without conversion, trimming,
  pitch changes, or other audio edits.
- Each sound event loads its exact mapped file independently. If that file is
  missing or fails to load or play, that event is silent; no other sound may be
  used as a fallback.

## Vomit

### Distributed source files

- `vomit/dog_wheezing_coughing_825417.mp3`
- `vomit/dog_gagging_135415.mp3`

### Sources

- Freesound,
  ["Small Dog wheezing & coughing"](https://freesound.org/people/Filmscore/sounds/825417/),
  uploaded by `Filmscore`
  - Direct preview URL used in project:
    `https://cdn.freesound.org/previews/825/825417_843915-hq.mp3`
- Freesound,
  ["Gagging 1.wav"](https://freesound.org/people/Turroe22/sounds/135415/),
  uploaded by `Turroe22`

### License

- Both files: [CC0 (Public Domain)](https://creativecommons.org/publicdomain/zero/1.0/)

### Runtime mapping

Only `vomit/dog_gagging_135415.mp3` is currently listed in
[`VOMIT_SAMPLE_CANDIDATES`](../../scripts/main.gd). Its 1.28-second real
gagging sound replaces the much longer wheezing/coughing source as the exact
vomit cue. The shipped `vomit/dog_wheezing_coughing_825417.mp3` remains an
attributed reference file; it is never selected as a fallback. The active
recording plays at original pitch with a fixed −10.2 dB gain and no start
offset. Freya's 1.05-second vomit pose stops the player if any tail remains.

## Recorded Action Cues

The clips below are **real recordings or physical Foley**, edited only by
cutting an excerpt, converting the linked source audio to mono Ogg Vorbis,
applying short edge fades where stated, and applying the stated fixed gain. No tone, oscillator, generated layer,
replacement, or fallback was added. All source pages state
[CC0](https://creativecommons.org/publicdomain/zero/1.0/). These files are
available for specific runtime events; a source file's presence alone does not
mean that the event is already wired to playback.

| Distributed file under `actions/` | Intended event | Source recording (author) | Source audio used | Excerpt (seconds), gain |
| --- | --- | --- | --- | --- |
| `dog_paws_skitter_208654.ogg` | Quick dog run or agility movement | [Dog skitter on concrete](https://freesound.org/people/luckylittleraven/sounds/208654/) (`luckylittleraven`) | [HQ MP3](https://cdn.freesound.org/previews/208/208654_2112203-hq.mp3) | 0.00–3.78, unchanged |
| `dog_sniff_pant_784915.ogg` | Freya sensing or dog breathing | [Dog panting and sniffing](https://freesound.org/people/Primitv094/sounds/784915/) (`Primitv094`) | [HQ MP3](https://cdn.freesound.org/previews/784/784915_9616274-hq.mp3) | 16.40–19.70, +13 dB |
| `dog_whine_462660.ogg` | Kennel captive or vulnerable dog | [Whining Dog](https://freesound.org/people/Breviceps/sounds/462660/) (`Breviceps`) | [HQ MP3](https://cdn.freesound.org/previews/462/462660_9159316-hq.mp3) | 0.45–2.90, unchanged |
| `girl_crying_ryah_218184.ogg` | Ryah's alien-repelling cry | [Girl Crying](https://freesound.org/people/mvVoiceActing/sounds/218184/) (`mvVoiceActing`; a recorded voice performance) | [HQ MP3](https://cdn.freesound.org/previews/218/218184_3298571-hq.mp3) | 25.58–27.30, +19 dB and short edge fades |
| `collar_jingle_611827.ogg` | Recruit or pack order acknowledgment | [Dog Collar Jingling](https://freesound.org/people/AKFeniks/sounds/611827/) (`AKFeniks`) | [HQ MP3](https://cdn.freesound.org/previews/611/611827_7493314-hq.mp3) | 5.85–8.40, +18 dB |
| `home_door_683434.ogg` | Opening a hinged wooden door, if such an action is added | [door open](https://freesound.org/people/saha213131/sounds/683434/) (`saha213131`) | [HQ MP3](https://cdn.freesound.org/previews/683/683434_14040168-hq.mp3) | 0.00–0.90, +10 dB |
| `metal_gate_411884.ogg` | Open a kennel cage or heavy gate | [Metal Door](https://freesound.org/people/Yin_Yang_Jake007/sounds/411884/) (`Yin_Yang_Jake007`) | [HQ MP3](https://cdn.freesound.org/previews/411/411884_7919598-hq.mp3) | 0.48–2.08, unchanged |
| `medicine_bottle_460153.ogg` | Collect or apply immunity medicine | [Pill Bottle, Shaking](https://freesound.org/people/AudioWay/sounds/460153/) (`AudioWay`) | [HQ MP3](https://cdn.freesound.org/previews/460/460153_9565159-hq.mp3) | 0.00–0.94, +9 dB |
| `plastic_bottle_landing_173597.ogg` | Pill bottles landing on the home floor | [Plastic Bottle falling](https://freesound.org/people/WarcakeStudios/sounds/173597/) (`WarcakeStudios`; an empty plastic bottle dropped onto the ground) | [HQ MP3](https://cdn.freesound.org/previews/173/173597_2393266-hq.mp3) | 0.03–0.82, unchanged gain and short edge fades |
| `clinic_fabric_rustle.ogg` | Clinic care kit or bandage handling | [Fabric Rustling](https://opengameart.org/content/fabric-rustling) (`Iochi Glaucus`; a real leg warmer recorded with an AT2020) | [`rustling.ogg`](https://opengameart.org/sites/default/files/rustling.ogg) | 2.00–3.50, unchanged |
| `armor_velcro_267713.ogg` | Attach or repair dog armor | [Velcro](https://freesound.org/people/WeeJee_vdH/sounds/267713/) (`WeeJee_vdH`) | [HQ MP3](https://cdn.freesound.org/previews/267/267713_3666787-hq.mp3) | 1.07–2.28, +7 dB |
| `stick_pickup_qubodup_wobble2.ogg` | Pick up a loose wooden stick | [Wood Wobbling & Rattling](https://opengameart.org/content/wood-wobbling-rattling) (`qubodup`; a thin piece of real wood moved and stopped) | [`qubodup-wobble2.wav` in the CC0 archive](https://opengameart.org/sites/default/files/qubodup-wobble.7z) | Full 0.89, unchanged |
| `stick_drop_593178.ogg` | Drop a carried stick | [dropping wooden stick](https://freesound.org/people/Stefan21100190/sounds/593178/) (`Stefan21100190`) | [HQ MP3](https://cdn.freesound.org/previews/593/593178_12589965-hq.mp3) | 1.93–2.48, +16 dB |
| `dumpster_lid_254982.ogg` | Search a dumpster | [Trash Can Lid](https://freesound.org/people/deleted_user_958643/sounds/254982/) (`deleted_user_958643`) | [HQ MP3](https://cdn.freesound.org/previews/254/254982_958643-hq.mp3) | 2.69–3.55, unchanged |
| `suction_pop_386885.ogg` | Imp transfer interruption | [Suction Cup](https://freesound.org/people/michorvath/sounds/386885/) (`michorvath`) | [HQ MP3](https://cdn.freesound.org/previews/386/386885_3094998-hq.mp3) | 0.00–0.68, unchanged |
| `slime_squelch_433839.ogg` | Visible imp emerges or is expelled | [Slime 28](https://freesound.org/people/Archos/sounds/433839/) (`Archos`; squished rubber ball) | [HQ MP3](https://cdn.freesound.org/previews/433/433839_652422-hq.mp3) | 0.00–0.61, +8 dB |
| `electric_arc_367456.ogg` | Stronghold or alien transfer warning | [Jacob's ladder](https://freesound.org/people/jensfelger/sounds/367456/) (`jensfelger`; recorded 50 kV arc) | [HQ MP3](https://cdn.freesound.org/previews/367/367456_6750383-hq.mp3) | 4.95–6.50, +8 dB |
| `button_click_622060.ogg` | Menu, intro advance/skip, or order selection | [button click](https://freesound.org/people/rydra_wong/sounds/622060/) (`rydra_wong`; mechanical keyboard) | [HQ MP3](https://cdn.freesound.org/previews/622/622060_13685159-hq.mp3) | 0.00–0.66, −3 dB |
| `bubble_pop_669918.ogg` | Territory or objective feedback | [The Best Bubble Pop Sound For Game and UI](https://freesound.org/people/el_boss/sounds/669918/) (`el_boss`; recorded bubble) | [HQ MP3](https://cdn.freesound.org/previews/669/669918_9129912-hq.mp3) | 0.00–0.32, unchanged |
| `family_group_giggling.ogg` | Gene and Zoe laugh during the family prologue | [Group giggling](https://opengameart.org/content/group-giggling) (`Nocturnal_Vanguard` / AuraVoice; recorded human voice) | [`group_giggling.ogg`](https://opengameart.org/sites/default/files/group_giggling.ogg) | 0.00–1.95, unchanged gain |

The action cue IDs in [action_audio.gd](../../scripts/action_audio.gd) map to
these exact files, except `family_pills_eaten`, which maps directly to the
already-attributed `eat/dog_chewing_crunchy_pills_456376.ogg`, and
`kennel_spawn_bark`, which maps to the attributed bark above. The group-giggling
source is already mono Ogg; the distributed excerpt was cropped to 1.95 seconds
and re-encoded as mono Vorbis without pitch change, synthesis, or layering.
Its downloaded source SHA-256 was
`2155db34a3d62290d3dfcb6429cfda2af4e3ff736d3b86bdebb78100598b95fe`.
The Ryah-cry and plastic-bottle excerpts rebuild with
[build_story_action_excerpts.sh](../../../scripts/build_story_action_excerpts.sh).
That script verifies the two CC0 Freesound HQ preview SHA-256 values before
editing: `0f03b4a4fabec4afa8da55595fd007af89d80c2ac2b45d94d8fb738c9b73952e`
for the cry and `8a8b4dc8e61c25e3658d7d7721e1118d1aff9122bdd43f65cc0d583da4478b21`
for the bottle. The cry excerpt ends in 1.72 seconds, within Ryah's brief
visual crying beat. The 0.79-second bottle impact ends before the next
cinematic sound. Both preserve their natural pitch and contain only their
single recorded sources.
Every listed cue except `door` has a live event hook; `door` is reserved for a
future visibly opening door. If an exact file is unavailable, its event stays
silent.
The `claim` cue also confirms the first completion of each dog-park drill;
the drill itself begins with the recorded `dog_run` cue. Repeating an already
learned drill does not replay the first-time reward cue.
The same recorded `claim` cue confirms an ally securing the cleared final
signal when other chapter goals remain. If that guard action completes the
chapter, the chapter-result cue plays once instead.
When a final building claim also completes a chapter, all-map ownership, or
both, one `claim` cue confirms the combined result. The ordinary mark cue does
not restart the same recording in that frame.
The `alien_emerge` cue also plays once when an occupied storefront generates a
free imp within 14 world units of Freya. Distant storefront spawns stay silent;
the event never selects another recording if its exact cue is unavailable.
Approaching an unpossessed caged dog plays the existing recorded `dog_whine`
once per approach and captive, with a 2.6-second minimum gap between whines.
Possessed captives and repeated frames in the same interaction do not retrigger
it. Ryah's home defense plays the exact recorded `ryah_cry` when she starts
crying; a 1.95-second gap prevents simultaneous alien attempts from restarting
the voice. A pack-only imp interception plays one aggressive recorded dog bark
from the existing pool, at the non-Freya gain. Freya's held-bark interception
keeps her own bark, and a 0.85-second gap prevents multiple imps from stacking
pack barks. The pop still marks the imp itself being interrupted.

### Intro story event mappings

These IDs intentionally reuse real recordings where the same physical Foley
fits another visible event. Each ID still has one fixed path. Reuse never
serves as a fallback when a different recording fails to load. The three
staggered first-exit dog possession hits use separate players of the same
exact stream so one hit cannot cut another short.

| Story event / cue ID | Exact source path | Trigger |
| --- | --- | --- |
| `family_laugh` | `actions/family_group_giggling.ogg` | Gene and Zoe laugh at 23.0 s |
| `family_pills_revealed` | `actions/medicine_bottle_460153.ogg` | Gene reveals the bottles at 28.4 s |
| `family_abduction_beam` | `actions/electric_arc_367456.ogg` | The parents' beams appear at 45.0 s |
| `family_pills_landed` | `actions/plastic_bottle_landing_173597.ogg` | The pill bottles land at 46.35 s |
| `family_parents_vanish` | `actions/suction_pop_386885.ogg` | Gene and Zoe disappear at 47.2 s |
| `family_ryah_beam` | `actions/electric_arc_367456.ogg` | Ryah's beam appears at 48.0 s |
| `family_ryah_beam_break` | `actions/suction_pop_386885.ogg` | Her beam collapses at 51.2 s |
| `family_pills_eaten` | `eat/dog_chewing_crunchy_pills_456376.ogg` | Freya eats the spill at 54.0 s |
| `family_convulsion` | `actions/collar_jingle_611827.ogg` | Freya shakes and hops at 55.2 s |
| `first_exit_abduction_beam` | `actions/electric_arc_367456.ogg` | Dog-walker beams appear at 0.9 s |
| `first_exit_walkers_vanish` | `actions/suction_pop_386885.ogg` | The walkers vanish at 3.35 s |
| `first_exit_dog_possession` | `actions/slime_squelch_433839.ogg` | Three possession hits at 4.81, 5.11, and 5.41 s |
| `first_exit_freya_target` | `actions/electric_arc_367456.ogg` | Possession energy aims for Freya at 5.95 s |
| `first_exit_immunity_bounce` | `actions/suction_pop_386885.ogg` | The energy ricochets at 6.85 s |

### Action coverage notes

- Freya's walking, running, and dog-park obstacle motion use the same real
  dog-paws recording, at different gains and a sparse replay interval. The
  same exact recorded stream is used for both movement speeds; no alternate
  file is substituted if it is unavailable.
- The `door` cue is reserved for a door that visibly opens. Home and store
  doorways are already open, so crossing them is silent.
- Successful Q/E camera rotation, changed keyboard or wheel zoom, opening
  unpinned goals with Tab, and Page Up/Down scrolling that moves a panel use
  the exact recorded mechanical `button` cue at a lower gain. Held rotation
  clicks once on key press; rapid zoom or scrolling shares a short click gap
  instead of restarting the recording for every intermediate step. Zoom at a
  limit, scrolling at an edge, Tab while goals are already pinned, and keys
  that complete no action are silent. G/H toggles, menu selections, and
  accepted pack orders also use the recorded mechanical button cue.
- Player-requested Next and Skip in the UFO, family, and first-exit story
  sequences use that exact recorded button cue. Timed, automatic scene
  progression stays silent.
- A changed master-volume slider plays the exact recorded `button` cue after
  adjustment settles, avoiding a click for every intermediate slider value.
  A master volume of zero remains silent as requested by the player's mute.
  Successful Quit saves first, plays the exact recorded button cue, and waits
  for that recording to finish before closing. If it cannot load, Quit closes
  in silence without using a replacement sound.
- The eight-ship fleet reveal is silent. It occurs in space, where recorded
  aircraft or wind movement would imply air around the ships; its automatic
  camera move has no physical source for an audible Foley event.
