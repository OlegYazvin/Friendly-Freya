#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
godot_dir="$project_dir/godot"
output_dir="$project_dir/visual_regressions"
capture_tmp=$(mktemp -d "$project_dir/.intro_capture.XXXXXX")
trap 'rm -rf "$capture_tmp"' EXIT INT TERM

if host-spawn flatpak ps | grep -q 'org.godotengine.Godot'; then
	echo "Close the running Friendly Freya/Godot session before capturing the intro." >&2
	exit 1
fi

mkdir -p "$output_dir"

for spec in \
	startup_menu:Startup.tscn:none \
	intro_01_establishing:IntroCutscene.tscn:establishing \
	intro_02_a_question_runes:IntroCutscene.tscn:a_question_runes \
	intro_02_a_question_morph:IntroCutscene.tscn:a_question_morph \
	intro_02_a_question_english:IntroCutscene.tscn:a_question_english \
	intro_03_b_answer_english:IntroCutscene.tscn:b_answer_english \
	intro_04_a_command_english:IntroCutscene.tscn:a_command_english \
	intro_05_fleet:IntroCutscene.tscn:fleet \
	intro_06_family_home:Main.tscn:family_home \
	intro_07_family_gene:Main.tscn:family_gene \
	intro_08_family_zoe:Main.tscn:family_zoe \
	intro_09_family_pills:Main.tscn:family_pills \
	intro_10_family_abduction:Main.tscn:family_abduction \
	intro_11_family_ryah_targeted:Main.tscn:family_ryah_targeted \
	intro_12_family_loud_bark:Main.tscn:family_loud_bark \
	intro_13_family_ryah_saved:Main.tscn:family_ryah_saved
do
	output_name=${spec%%:*}
	remainder=${spec#*:}
	scene_name=${remainder%%:*}
	view=${remainder#*:}
	if [ -n "${FREYA_INTRO_CAPTURE_ONLY:-}" ] && [ "$output_name" != "$FREYA_INTRO_CAPTURE_ONLY" ]; then
		continue
	fi
	log_file="$capture_tmp/$output_name.log"
	if [ "$view" = "none" ]; then
		host-spawn flatpak run org.godotengine.Godot --path "$godot_dir" "res://scenes/$scene_name" >"$log_file" 2>&1 &
	elif [ "$scene_name" = "Main.tscn" ]; then
		host-spawn env FREYA_FAMILY_INTRO_VIEW="$view" flatpak run org.godotengine.Godot --path "$godot_dir" "res://scenes/$scene_name" >"$log_file" 2>&1 &
	else
		host-spawn env FREYA_INTRO_VIEW="$view" flatpak run org.godotengine.Godot --path "$godot_dir" "res://scenes/$scene_name" >"$log_file" 2>&1 &
	fi
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
	if [ "$scene_name" = "Main.tscn" ]; then
		# Main builds the real procedural neighborhood and selected home before the
		# family cutscene can seek to its deterministic checkpoint.
		sleep 8
	else
		sleep 2
	fi
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
	if grep -qE 'SCRIPT ERROR|Parse Error|ERROR:' "$log_file"; then
		echo "Godot reported an error while capturing $output_name:" >&2
		cat "$log_file" >&2
		exit 1
	fi
	echo "Captured $output_name.png"
done

echo "Intro visual regressions written to $output_dir"
