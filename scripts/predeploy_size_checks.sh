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

echo "Running Friendly Freya placement-ready kennel validation..."
run_scene_validation res://scenes/KennelConcept.tscn FREYA_KENNEL_VALIDATE=1

echo "Running Friendly Freya gameplay checks (smoke + targeted validation)..."
run_scene_validation res://scenes/Main.tscn FREYA_VALIDATE=1 FREYA_SMOKE=1
echo "Running Friendly Freya input and de-jankification regressions..."
run_scene_validation res://tests/dejank_flow.gd
echo "Running Friendly Freya generated-layout camera regressions..."
run_scene_validation res://tests/dejank_cameras.gd
echo "Predeploy checks passed."
