#!/usr/bin/env sh
set -eu

REPOSITORY_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SOURCE_AUDIO="${FREYA_TITLE_SOURCE_AUDIO:-/data/projects/Audio Recordings/Recording for Freya Title Card.wav}"
CANDIDATE_DIR="$REPOSITORY_ROOT/docs/audio/ai_attempts"
LIVE_AUDIO="$REPOSITORY_ROOT/godot/assets/audio/menu/title_card_theme_8bit.wav"
LIVE_CANDIDATE="${FREYA_TITLE_LIVE_CANDIDATE:-02}"

if [ ! -s "$SOURCE_AUDIO" ]; then
	echo "Error: source title-card recording is missing: $SOURCE_AUDIO" >&2
	exit 1
fi

mkdir -p "$CANDIDATE_DIR" "$(dirname -- "$LIVE_AUDIO")"

source_duration="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$SOURCE_AUDIO")"
target_duration="$(awk -v d="$source_duration" 'BEGIN { printf "%.2f", d * 2 }')"
fade_start="$(awk -v d="$target_duration" 'BEGIN { printf "%.2f", d - 0.26 }')"

render_candidate() {
	candidate_id="$1"
	filter_graph="$2"
	output_audio="$CANDIDATE_DIR/title_card_theme_source_energy_candidate_${candidate_id}.wav"
	ffmpeg -hide_banner -nostdin -y \
		-stream_loop -1 \
		-i "$SOURCE_AUDIO" \
		-t "$target_duration" \
		-filter_complex "$filter_graph" \
		-map "[out]" \
		-ac 2 \
		-ar 44100 \
		-sample_fmt s16 \
		"$output_audio"
}

render_candidate "01" "[0:a]aformat=channel_layouts=stereo,atempo=1.22,acrusher=level_in=1.25:level_out=0.78:bits=8:mix=0.82:mode=log:aa=0.58:samples=3,aecho=0.24:0.20:70:0.18,volume=26dB,alimiter=limit=0.88,atrim=duration=$target_duration,afade=t=in:st=0:d=0.03,afade=t=out:st=$fade_start:d=0.26[out]"

render_candidate "02" "[0:a]aformat=channel_layouts=stereo,atempo=1.32,asplit=3[base][spark][pulse];[base]acrusher=level_in=1.35:level_out=0.68:bits=7:mix=0.90:mode=log:aa=0.46:samples=4,volume=0.95[baseo];[spark]asetrate=49392,aresample=44100,highpass=f=560,acrusher=level_in=1.10:level_out=0.38:bits=5.5:mix=0.72:mode=log:aa=0.35:samples=5,aecho=0.16:0.22:42:0.20[sparko];[pulse]lowpass=f=420,acrusher=level_in=1.15:level_out=0.25:bits=6:mix=0.75:samples=6,apulsator=hz=5.5:amount=0.36:offset_l=0:offset_r=0.5[pulseo];[baseo][sparko][pulseo]amix=inputs=3:normalize=0,alimiter=limit=0.86,atrim=duration=$target_duration,afade=t=in:st=0:d=0.03,afade=t=out:st=$fade_start:d=0.26[out]"

render_candidate "03" "[0:a]aformat=channel_layouts=stereo,atempo=1.44,acrusher=level_in=1.45:level_out=0.66:bits=6:mix=0.88:mode=log:aa=0.38:samples=5,apulsator=mode=square:hz=7.2:amount=0.18:offset_l=0:offset_r=0.5,aecho=0.18:0.20:34:0.16,volume=27dB,alimiter=limit=0.84,atrim=duration=$target_duration,afade=t=in:st=0:d=0.03,afade=t=out:st=$fade_start:d=0.26[out]"

case "$LIVE_CANDIDATE" in
	01|02|03)
		ffmpeg -hide_banner -nostdin -y \
			-i "$CANDIDATE_DIR/title_card_theme_source_energy_candidate_${LIVE_CANDIDATE}.wav" \
			-ac 2 \
			-ar 44100 \
			-sample_fmt s16 \
			"$LIVE_AUDIO"
		;;
	*)
		echo "Error: FREYA_TITLE_LIVE_CANDIDATE must be 01, 02, or 03." >&2
		exit 1
		;;
esac

ffprobe -hide_banner -v error -show_entries format=duration,size:stream=codec_name,sample_rate,channels -of compact=p=0:nk=1 "$LIVE_AUDIO"
echo "Rendered source-derived energetic title-card candidates from $SOURCE_AUDIO"
echo "Live candidate: $LIVE_CANDIDATE"
