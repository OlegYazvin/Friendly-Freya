#!/usr/bin/env sh
set -eu

# Build authored bark clips by trimming fixed ranges from the project's real
# recorded source WAVs. This script never synthesizes, pitch-shifts, normalizes,
# or substitutes audio. A missing or changed source is a hard failure.

REPOSITORY_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
AUDIO_ROOT="$REPOSITORY_ROOT/godot/assets/audio"
BARK_ROOT="$AUDIO_ROOT/barks"
MONO_SOURCE="$AUDIO_ROOT/dog_barking_mono.wav"
FIELD_SOURCE="$AUDIO_ROOT/dog_barking.wav"
MONO_SHA256="bbd0f908b3514dd3bd7d2bc04dcf64f8d360a161e7f43cac5d6761e7add79451"
FIELD_SHA256="94b9180914ce6142599562e47a58b224c4ac81575056752df5fd48fb0e570701"

if ! command -v ffmpeg >/dev/null 2>&1; then
	echo "Error: ffmpeg is required to trim the recorded bark sources." >&2
	exit 1
fi

verify_source() {
	source_path=$1
	expected_hash=$2
	if [ ! -f "$source_path" ]; then
		echo "Error: recorded bark source is missing: $source_path" >&2
		exit 1
	fi
	actual_hash=$(sha256sum "$source_path" | awk '{print $1}')
	if [ "$actual_hash" != "$expected_hash" ]; then
		echo "Error: recorded bark source hash changed: $source_path" >&2
		exit 1
	fi
}

verify_source "$MONO_SOURCE" "$MONO_SHA256"
verify_source "$FIELD_SOURCE" "$FIELD_SHA256"

temporary_root=$(mktemp -d)
trap 'rm -rf "$temporary_root"' EXIT HUP INT TERM

build_clip() {
	source_path=$1
	start_time=$2
	duration=$3
	output_name=$4
	temporary_path="$temporary_root/$output_name"
	ffmpeg -hide_banner -loglevel error -nostdin -y \
		-ss "$start_time" -t "$duration" -i "$source_path" \
		-map_metadata -1 -fflags +bitexact -flags:a +bitexact \
		-c:a pcm_s16le -ar 44100 "$temporary_path"
	mv -f "$temporary_path" "$BARK_ROOT/$output_name"
}

# Four naturally separated single barks suited to low-key call-and-response.
build_clip "$MONO_SOURCE" 0.000 0.285 conversational_bark_01.wav
build_clip "$MONO_SOURCE" 0.485 0.300 conversational_bark_02.wav
build_clip "$MONO_SOURCE" 1.075 0.350 conversational_bark_03.wav
build_clip "$MONO_SOURCE" 1.645 0.394 conversational_bark_04.wav

# Six energetic field-recording moments suited to active friendly socializing.
build_clip "$FIELD_SOURCE" 1.020 0.340 excited_social_bark_01.wav
build_clip "$FIELD_SOURCE" 1.380 0.440 excited_social_bark_02.wav
build_clip "$FIELD_SOURCE" 1.820 0.320 excited_social_bark_03.wav
build_clip "$FIELD_SOURCE" 2.700 0.310 excited_social_bark_04.wav
build_clip "$FIELD_SOURCE" 4.150 0.780 excited_social_bark_05.wav
build_clip "$FIELD_SOURCE" 6.200 0.310 excited_social_bark_06.wav

active_count=0
for clip_path in \
	"$BARK_ROOT"/conversational_bark_*.wav \
	"$BARK_ROOT"/excited_social_bark_*.wav \
	"$BARK_ROOT"/bark_real_*.wav \
	"$BARK_ROOT"/aggressive_bark_*.wav
do
	if [ ! -f "$clip_path" ]; then
		echo "Error: active bark clip is missing: $clip_path" >&2
		exit 1
	fi
	max_volume=$(ffmpeg -hide_banner -nostdin -i "$clip_path" -af volumedetect -f null - 2>&1 | sed -n 's/.*max_volume: \([-0-9.]*\) dB.*/\1/p' | tail -1)
	if [ -z "$max_volume" ] || ! awk -v level="$max_volume" 'BEGIN { exit !(level >= -35.0) }'; then
		echo "Error: active bark clip is silent or below the -35 dB peak floor: $clip_path" >&2
		exit 1
	fi
	active_count=$((active_count + 1))
done

if [ "$active_count" -ne 24 ]; then
	echo "Error: expected 24 active bark recordings, found $active_count." >&2
	exit 1
fi

unique_hash_count=$(
	sha256sum \
		"$BARK_ROOT"/conversational_bark_*.wav \
		"$BARK_ROOT"/excited_social_bark_*.wav \
		"$BARK_ROOT"/bark_real_*.wav \
		"$BARK_ROOT"/aggressive_bark_*.wav |
	awk '{print $1}' | sort -u | wc -l | tr -d ' '
)
if [ "$unique_hash_count" -ne 24 ]; then
	echo "Error: active bark library contains duplicate recordings." >&2
	exit 1
fi

echo "Built 4 conversational and 6 excited-social clips; verified 24 unique active recorded barks."
