# Friendly Freya Title Card Theme

[Audio attribution](../../godot/assets/audio/ATTRIBUTION.md) ·
[Stable Audio 3 build script](../../scripts/build_title_card_theme.sh) ·
[ACE-Step cover request](../../scripts/request_ace_step_cover.sh)

## Source

The source performance is the project-owner recording at:

`/data/projects/Audio Recordings/Recording for Freya Title Card.wav`

## Current shipped menu asset

The current `menu/title_card_theme_8bit.wav` is a Stable Audio 3
audio-to-audio render:

1. Use the project-owner WAV directly.
2. Duplicate the original 8.51-second performance once as the full 17.02-second
   reference bed.
3. Run Stable Audio 3 Small-Music through the optimized TFLite CPU path in
   audio-to-audio mode.
4. Prompt for a bright, cheerful NES/chiptune title-screen theme.
5. Save as a Godot-friendly 44.1 kHz, 16-bit PCM WAV.

This deliberately does not use the rejected MIDI-continuation experiment. The
bad Magenta/MusicRNN tail was removed because it drifted from the recorded
theme and sounded like an incoherent add-on. The active asset is not built from
that MIDI path.

## Current render settings

- Model/runtime: Stable Audio 3 optimized TFLite CPU path
- Model id: `small-music`
- Decoder/encoder: `same-s`
- Seed: `20260620`
- Duration: `17.02`
- Init audio: the doubled source recording
- Init noise level: `0.68`
- Steps: `8`
- Prompt:
  `bright cheerful NES 8-bit chiptune title screen theme, cute heroic dog
  adventure in a suburban town, square wave lead melody, triangle bass, simple
  playful arcade drums, lighthearted and sunny, clean instrumental, no vocals,
  no human humming, loopable`

Alternate generated candidates are stored in
[`ai_attempts/`](ai_attempts/):

- `title_card_theme_stable_audio_candidate_02.wav` is the currently shipped
  candidate. It keeps more of the source structure with a lower init-noise
  level.
- `title_card_theme_stable_audio_candidate_03.wav` pushes harder toward
  chiptune and is kept as an alternate.

## Alternate ACE-Step cover pipeline

ACE-Step remains a good alternate cover/source-audio transformation route:

1. Submit the original WAV as `src_audio`, not as a MIDI transcription.
2. Use `task_type=cover` so ACE-Step preserves the source structure.
3. Use a high `audio_cover_strength` such as `0.86` so the result follows the
   recording closely while changing the production style.
4. Prompt for a cheerful, light-hearted 8-bit/chiptune title-screen
   instrumental.
5. Convert the returned audio to the same Godot WAV format.

`request_ace_step_cover.sh` implements that API flow for either a local
ACE-Step API server or an authenticated remote ACE-Step-compatible endpoint.

## ACE-Step access blockers

- `ACE-Step/Ace-Step-v1.5` on Hugging Face exposes the correct cover/source
  audio controls, but this session received `No GPU was available after 60s`
  from ZeroGPU when uploading the recording.
- `acemusic.ai` advertises a free hosted ACE-Step-backed service, but its API
  currently returns `Missing Authorization header` from this environment.
- `JanBabela/Riffusion-Melodiff-v1` advertises audio upload/img2img Riffusion,
  but the live Space did not expose a usable Gradio config to the API client.
- Local ACE-Step remains promising, but Stable Audio 3 produced a local
  CPU-rendered audio-to-audio candidate in this environment first.

## Rebuild

```sh
./scripts/build_title_card_theme.sh
```

The script expects the Stable Audio 3 TFLite runtime at
`/data/projects/freya-ai-runtimes/stable-audio-3/optimized/tflite` by default.
Set `FREYA_STABLE_AUDIO_3_TFLITE_DIR` if the runtime lives elsewhere. The script
fails rather than falling back to a non-AI substitute.

## ACE-Step cover attempt

With a local ACE-Step 1.5 API server:

```sh
FREYA_ACE_STEP_API_BASE=http://127.0.0.1:8001 \
	./scripts/request_ace_step_cover.sh
```

With an authenticated remote endpoint:

```sh
FREYA_ACE_STEP_API_BASE=https://example-ace-step-endpoint \
FREYA_ACE_STEP_API_TOKEN=... \
	./scripts/request_ace_step_cover.sh
```
