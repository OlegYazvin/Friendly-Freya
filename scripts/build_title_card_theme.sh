#!/usr/bin/env sh
set -eu

REPOSITORY_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SOURCE_AUDIO="${1:-/data/projects/Audio Recordings/Recording for Freya Title Card.wav}"
OUTPUT_AUDIO="$REPOSITORY_ROOT/godot/assets/audio/menu/title_card_theme_8bit.wav"
STABLE_AUDIO_DIR="${FREYA_STABLE_AUDIO_3_TFLITE_DIR:-/data/projects/freya-ai-runtimes/stable-audio-3/optimized/tflite}"
STABLE_AUDIO_CLI="$STABLE_AUDIO_DIR/sa3"
UV_BIN_DIR="${FREYA_UV_BIN_DIR:-/data/projects/freya-ai-runtimes/hf-client/bin}"
WORK_DIR="${FREYA_TITLE_THEME_WORK_DIR:-$(mktemp -d /tmp/freya-title-theme.XXXXXX)}"
REFERENCE_AUDIO="$WORK_DIR/title_card_reference_twice.wav"
CANDIDATE_AUDIO="$WORK_DIR/title_card_stable_audio_candidate.wav"
PROMPT="${FREYA_TITLE_THEME_PROMPT:-bright cheerful NES 8-bit chiptune title screen theme, cute heroic dog adventure in a suburban town, square wave lead melody, triangle bass, simple playful arcade drums, lighthearted and sunny, clean instrumental, no vocals, no human humming, loopable}"
SEED="${FREYA_TITLE_THEME_SEED:-20260620}"
INIT_NOISE_LEVEL="${FREYA_TITLE_THEME_INIT_NOISE_LEVEL:-0.68}"
STEPS="${FREYA_TITLE_THEME_STEPS:-8}"
THREADS="${FREYA_TITLE_THEME_THREADS:-8}"

if [ ! -s "$SOURCE_AUDIO" ]; then
	echo "Error: source title-card recording is missing: $SOURCE_AUDIO" >&2
	exit 1
fi

if [ ! -x "$STABLE_AUDIO_CLI" ]; then
	echo "Error: Stable Audio 3 TFLite CLI is missing: $STABLE_AUDIO_CLI" >&2
	echo "Install it first, or set FREYA_STABLE_AUDIO_3_TFLITE_DIR to its optimized/tflite directory." >&2
	exit 1
fi

mkdir -p "$(dirname -- "$OUTPUT_AUDIO")"
mkdir -p "$REPOSITORY_ROOT/docs/audio"

source_duration="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$SOURCE_AUDIO")"
target_duration="$(awk -v d="$source_duration" 'BEGIN { printf "%.2f", d * 2 }')"

ffmpeg -hide_banner -y \
	-i "$SOURCE_AUDIO" \
	-filter_complex "[0:a]aformat=channel_layouts=stereo,asplit=2[first][second];[first][second]concat=n=2:v=0:a=1[out]" \
	-map "[out]" \
	-ac 2 \
	-ar 44100 \
	-sample_fmt s16 \
	"$REFERENCE_AUDIO"

PATH="$UV_BIN_DIR:$PATH" "$STABLE_AUDIO_CLI" \
	--prompt "$PROMPT" \
	--dit sm-music \
	--decoder same-s \
	--seconds "$target_duration" \
	--steps "$STEPS" \
	--seed "$SEED" \
	--threads "$THREADS" \
	--init-audio "$REFERENCE_AUDIO" \
	--init-noise-level "$INIT_NOISE_LEVEL" \
	--out "$CANDIDATE_AUDIO"

ffmpeg -hide_banner -y \
	-i "$CANDIDATE_AUDIO" \
	-af "aformat=channel_layouts=stereo,alimiter=limit=0.95" \
	-ac 2 \
	-ar 44100 \
	-sample_fmt s16 \
	"$OUTPUT_AUDIO"

ffprobe -hide_banner -show_entries format=duration,size,bit_rate -show_streams "$OUTPUT_AUDIO"
echo "Rendered Stable Audio 3 source-audio title theme from $SOURCE_AUDIO"
echo "Temporary work directory: $WORK_DIR"
