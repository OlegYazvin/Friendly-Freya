#!/usr/bin/env sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
audio_dir="$repository_root/godot/assets/audio/actions"
source_dir=$(mktemp -d)
trap 'rm -rf "$source_dir"' EXIT HUP INT TERM

# These Freesound HQ previews are CC0 recordings. Verify the exact source
# bytes before cropping; a changed or unavailable recording is an error.
curl -fLsS -o "$source_dir/girl_crying_218184.mp3" \
	'https://cdn.freesound.org/previews/218/218184_3298571-hq.mp3'
curl -fLsS -o "$source_dir/plastic_bottle_falling_173597.mp3" \
	'https://cdn.freesound.org/previews/173/173597_2393266-hq.mp3'
(
	cd "$source_dir"
	printf '%s\n' \
		'0f03b4a4fabec4afa8da55595fd007af89d80c2ac2b45d94d8fb738c9b73952e  girl_crying_218184.mp3' \
		'8a8b4dc8e61c25e3658d7d7721e1118d1aff9122bdd43f65cc0d583da4478b21  plastic_bottle_falling_173597.mp3' \
		| sha256sum -c -
)

# Ryah's visual cry lasts about 1.87 seconds. Use one recorded sob, with fixed
# gain and gentle edges, so rapid alien attempts cannot leave a long voice bed.
ffmpeg -hide_banner -loglevel error -nostdin -y \
	-i "$source_dir/girl_crying_218184.mp3" \
	-af 'atrim=start=25.58:duration=1.72,asetpts=PTS-STARTPTS,volume=19dB,afade=t=in:st=0:d=0.025,afade=t=out:st=1.52:d=0.20' \
	-ac 1 -ar 44100 -c:a libvorbis -q:a 5 \
	"$audio_dir/girl_crying_ryah_218184.ogg"

# The first real bottle impact and rebounds fit between the pill landing at
# 46.35 seconds and the parents' vanishing sound at 47.20 seconds.
ffmpeg -hide_banner -loglevel error -nostdin -y \
	-i "$source_dir/plastic_bottle_falling_173597.mp3" \
	-af 'atrim=start=0.03:duration=0.79,asetpts=PTS-STARTPTS,afade=t=in:st=0:d=0.008,afade=t=out:st=0.71:d=0.08' \
	-ac 1 -ar 44100 -c:a libvorbis -q:a 5 \
	"$audio_dir/plastic_bottle_landing_173597.ogg"
