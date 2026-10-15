#!/usr/bin/env sh
set -eu

PROJECT_PATH="$(CDPATH= cd -- "$(dirname -- "$0")/../godot" && pwd)"

godot_bin=""
if [ -n "${GODOT_BIN:-}" ]; then
	if [ -x "$GODOT_BIN" ]; then
		godot_bin=$GODOT_BIN
	elif command -v "$GODOT_BIN" >/dev/null 2>&1; then
		godot_bin=$(command -v "$GODOT_BIN")
	else
		echo "Error: GODOT_BIN does not name an executable: $GODOT_BIN" >&2
		exit 1
	fi
	launcher_kind=direct
elif command -v godot >/dev/null 2>&1; then
	godot_bin=$(command -v godot)
	launcher_kind=direct
elif command -v flatpak >/dev/null 2>&1; then
	launcher_kind=flatpak
elif command -v host-spawn >/dev/null 2>&1; then
	launcher_kind=host_spawn
else
	echo "Error: set GODOT_BIN or install godot, flatpak, or host-spawn." >&2
	exit 1
fi

run_scene_validation() {
	scene_path=$1
	shift
	entry_flag=""
	quit_flag="--quit"
	case "$scene_path" in
		*.gd) entry_flag="--script"; quit_flag="" ;;
	esac
	case "$launcher_kind" in
		direct)
			env "$@" "$godot_bin" --headless --path "$PROJECT_PATH" $entry_flag "$scene_path" $quit_flag
			;;
		flatpak)
			env "$@" flatpak run org.godotengine.Godot --headless --path "$PROJECT_PATH" $entry_flag "$scene_path" $quit_flag
			;;
		host_spawn)
			host-spawn env "$@" flatpak run org.godotengine.Godot --headless --path "$PROJECT_PATH" $entry_flag "$scene_path" $quit_flag
			;;
	esac
}

prepare_project_imports() {
	case "$launcher_kind" in
		direct)
			"$godot_bin" --headless --path "$PROJECT_PATH" --import
			;;
		flatpak)
			flatpak run org.godotengine.Godot --headless --path "$PROJECT_PATH" --import
			;;
		host_spawn)
			host-spawn flatpak run org.godotengine.Godot --headless --path "$PROJECT_PATH" --import
			;;
	esac
}

echo "Preparing Friendly Freya imported resources..."
prepare_project_imports

echo "Running Friendly Freya startup-choice validation..."
run_scene_validation res://scenes/Startup.tscn FREYA_STARTUP_VALIDATE=1

echo "Running Friendly Freya intro cut-scene validation..."
run_scene_validation res://scenes/IntroCutscene.tscn FREYA_INTRO_VALIDATE=1

echo "Running Friendly Freya kennel validation..."
run_scene_validation res://scenes/KennelConcept.tscn FREYA_KENNEL_VALIDATE=1

echo "Running Friendly Freya gameplay checks (smoke + targeted validation)..."
run_scene_validation res://scenes/Main.tscn FREYA_VALIDATE=1 FREYA_SMOKE=1
echo "Running Friendly Freya active pack and reserve guard checks..."
run_scene_validation res://tests/pack_squad.gd
echo "Running Friendly Freya recorded action audio coverage checks..."
run_scene_validation res://tests/audio_actions.gd
echo "Running Friendly Freya input and de-jankification regressions..."
run_scene_validation res://tests/dejank_flow.gd
echo "Running Friendly Freya generated-layout camera regressions..."
run_scene_validation res://tests/dejank_cameras.gd
echo "Running Friendly Freya save and resume regressions..."
run_scene_validation res://tests/save_resume.gd
echo "Running Friendly Freya three-chapter campaign flow..."
run_scene_validation res://tests/campaign_flow.gd
echo "Running Friendly Freya generated campaign reachability sweep..."
run_scene_validation res://tests/campaign_reachability.gd
echo "Running Friendly Freya service access routes..."
run_scene_validation res://tests/service_reachability.gd
echo "Running Friendly Freya carried-supply target and feedback checks..."
run_scene_validation res://tests/supply_targeting.gd
echo "Running Friendly Freya occupied-building collision recovery regression..."
run_scene_validation res://tests/occupation_collision_recovery.gd FREYA_WORLD_SEED=20260831
echo "Running Friendly Freya first-chapter guidance flow..."
run_scene_validation res://tests/chapter_guide.gd
echo "Running Friendly Freya claimed-territory scent support..."
run_scene_validation res://tests/scent_support.gd
echo "Running Friendly Freya ending navigation regressions..."
run_scene_validation res://tests/campaign_ending.gd
echo "Running Friendly Freya ending-to-neighborhood resume regressions..."
run_scene_validation res://tests/ending_resume.gd
echo "Predeploy checks passed."
