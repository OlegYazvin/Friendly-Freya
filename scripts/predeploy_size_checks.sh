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
	case "$launcher_kind" in
		direct)
			env "$@" "$godot_bin" --headless --path "$PROJECT_PATH" "$scene_path" --quit
			;;
		flatpak)
			env "$@" flatpak run org.godotengine.Godot --headless --path "$PROJECT_PATH" "$scene_path" --quit
			;;
		host_spawn)
			host-spawn env "$@" flatpak run org.godotengine.Godot --headless --path "$PROJECT_PATH" "$scene_path" --quit
			;;
	esac
}

echo "Running Friendly Freya startup-choice validation..."
run_scene_validation res://scenes/Startup.tscn FREYA_STARTUP_VALIDATE=1

echo "Running Friendly Freya intro cut-scene validation..."
run_scene_validation res://scenes/IntroCutscene.tscn FREYA_INTRO_VALIDATE=1

echo "Running Friendly Freya gameplay checks (smoke + targeted validation)..."
run_scene_validation res://scenes/Main.tscn FREYA_VALIDATE=1 FREYA_SMOKE=1
echo "Predeploy checks passed."
