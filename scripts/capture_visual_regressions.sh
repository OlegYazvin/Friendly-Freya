#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
godot_dir="$project_dir/godot"
output_dir="$project_dir/visual_regressions"
# Host-side X11 tools cannot see the sandbox's /tmp namespace. A temporary
# directory under the shared workspace is visible to both environments.
capture_tmp=$(mktemp -d "$project_dir/.visual_capture.XXXXXX")
trap 'rm -rf "$capture_tmp"' EXIT INT TERM

if host-spawn flatpak ps | grep -q 'org.godotengine.Godot'; then
	echo "Close the running Friendly Freya/Godot session before capturing regressions." >&2
	exit 1
fi

mkdir -p "$output_dir"

for spec in \
	FREYA_VISUAL_VIEW:wide_gable \
	FREYA_VISUAL_VIEW:wide_hip \
	FREYA_VISUAL_VIEW:storefront \
	FREYA_VISUAL_VIEW:home_outside \
	FREYA_VISUAL_VIEW:home_inside \
	FREYA_VISUAL_VIEW:dog_park_friendly \
	FREYA_VISUAL_VIEW:army_collars \
	FREYA_VISUAL_VIEW:pause_menu \
	FREYA_ALIEN_VIEW:alien_model:model \
	FREYA_ALIEN_VIEW:alien_occupied:occupied \
	FREYA_ALIEN_VIEW:alien_store_stronghold:stronghold \
	FREYA_ALIEN_VIEW:ryah_defense:ryah_defense
do
	env_name=${spec%%:*}
	remainder=${spec#*:}
	if [ "$env_name" = "FREYA_ALIEN_VIEW" ]; then
		output_name=${remainder%%:*}
		view=${remainder#*:}
	else
		output_name=$remainder
		view=$remainder
	fi
	if [ -n "${FREYA_CAPTURE_ONLY:-}" ] && [ "$output_name" != "$FREYA_CAPTURE_ONLY" ]; then
		continue
	fi
	log_file="$capture_tmp/$output_name.log"
	host-spawn env "$env_name=$view" flatpak run org.godotengine.Godot --path "$godot_dir" res://scenes/Main.tscn >"$log_file" 2>&1 &
	runner_pid=$!
	window_id=""
	for attempt in $(seq 1 40); do
		window_id=$(host-spawn wmctrl -lx | awk '/Godot_Engine.Friendly Freya/{id=$1} END{print id}')
		if [ -n "$window_id" ]; then
			break
		fi
		sleep 0.25
	done
	if [ -z "$window_id" ]; then
		echo "Could not find the Friendly Freya window for $output_name." >&2
		cat "$log_file" >&2
		exit 1
	fi
	# This project builds the full procedural neighborhood before its first frame.
	# Allow the older target GPU enough time to clear Godot's startup splash.
	sleep 8
	host-spawn wmctrl -ia "$window_id"
	host-spawn xwd -id "$window_id" -silent -out "$capture_tmp/$output_name.xwd"
	ffmpeg -loglevel error -y -i "$capture_tmp/$output_name.xwd" "$output_dir/$output_name.png"
	host-spawn wmctrl -ic "$window_id" || true
	for attempt in $(seq 1 20); do
		if ! host-spawn flatpak ps | grep -q 'org.godotengine.Godot'; then
			break
		fi
		sleep 0.25
	done
	if host-spawn flatpak ps | grep -q 'org.godotengine.Godot'; then
		host-spawn flatpak kill org.godotengine.Godot || true
	fi
	wait "$runner_pid" || true
	echo "Captured $output_name.png"
done

echo "Visual regressions written to $output_dir"
