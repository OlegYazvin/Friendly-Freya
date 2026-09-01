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

- OpenGameArt, ["dog barking"](https://opengameart.org/content/dog-barking),
  uploaded by user `qubodup`
- OpenGameArt, ["Dog sounds"](https://opengameart.org/content/dog-sounds),
  uploaded by user `justink`

### License

- CC0 (Public Domain)

### Derived files

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

`barks/bark_01.wav` through `barks/bark_06.wav` were trimmed from
`dog_barking.wav`. `barks/bark_real_01.wav` through `barks/bark_real_08.wav`
and `barks/aggressive_bark_01.wav` through `barks/aggressive_bark_06.wav` were
trimmed and processed from the OpenGameArt `dog.7z` archive.

The current candidate arrays and exact family-intro bark mappings are defined
near the top of [main.gd](../../scripts/main.gd).

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

### License

- [CC0 (Public Domain)](https://creativecommons.org/publicdomain/zero/1.0/)

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

Only `vomit/dog_wheezing_coughing_825417.mp3` is currently listed in
[`VOMIT_SAMPLE_CANDIDATES`](../../scripts/main.gd). The shipped
`vomit/dog_gagging_135415.mp3` file is retained as a source/reference asset; it
is not currently selected by that mapping and must never be used as a fallback.
