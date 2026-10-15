#!/usr/bin/env sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
audio_dir="$repository_root/godot/assets/audio/eat"

# Verify the exact licensed recordings named in godot/assets/audio/ATTRIBUTION.md.
# Missing or changed input is an error; never substitute a different sound.
(
	cd "$audio_dir"
	printf '%s\n' \
		'52e2fed560af321de816a881cc688554accbbdd3cbde50d169371a2cbf888306  dog_chewing_crunchy_456376.mp3' \
		'ab02b24a0e180643c03ee9a45673da260bbd9f5fb94c235e158fb5541c413fe3  dog_eating_dinner_760336.mp3' \
		'e34ae9265796718e39135a7e467bc67556a710092c2ad1dcd403cc29b7dbbe94  wet_sloppy_eating_382671.mp3' \
		'19145b7ff2a73010f0b63cb0b706d7170774fa8de5691be4dd926d788d0e5a7a  wet_sloppy_eating_alt_382673.mp3' \
		| sha256sum -c -
)

make_excerpt() {
	source=$1
	destination=$2
	start=$3
	duration=$4
	fade_start=$5
	fade_duration=$6
	gain=$7
	ffmpeg -hide_banner -loglevel error -nostdin -y \
		-i "$audio_dir/$source" \
		-af "atrim=start=$start:duration=$duration,asetpts=PTS-STARTPTS,volume=${gain}dB,afade=t=in:st=0:d=0.012,afade=t=out:st=$fade_start:d=$fade_duration" \
		-ac 1 -ar 44100 -c:a libvorbis -q:a 5 \
		"$audio_dir/$destination"
}

# One natural bite/lick at the start of an action. These lengths fit Freya's
# 0.34–0.56-second eating poses, so the file can end without being chopped.
make_excerpt dog_eating_dinner_760336.mp3 dog_eating_dinner_bite_760336.ogg 0.10 0.36 0.31 0.05 0
make_excerpt dog_chewing_crunchy_456376.mp3 dog_chewing_crunchy_bite_456376.ogg 8.40 0.28 0.23 0.05 0
make_excerpt wet_sloppy_eating_382671.mp3 wet_sloppy_eating_bite_382671.ogg 27.05 0.48 0.41 0.07 -14
make_excerpt wet_sloppy_eating_alt_382673.mp3 wet_sloppy_eating_alt_bite_382673.ogg 4.42 0.48 0.41 0.07 -9

# The 1.2-second family pill-eating beat needs a longer uninterrupted chew.
make_excerpt dog_chewing_crunchy_456376.mp3 dog_chewing_crunchy_pills_456376.ogg 8.35 1.12 1.03 0.09 0
