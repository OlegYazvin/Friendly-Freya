#!/usr/bin/env sh
set -eu

PROJECT_PATH="$(CDPATH= cd -- "$(dirname -- "$0")/../godot" && pwd)"

if command -v flatpak >/dev/null 2>&1; then
	launcher_kind=flatpak
elif command -v host-spawn >/dev/null 2>&1; then
	launcher_kind=host_spawn
else
	echo "Error: neither flatpak nor host-spawn is available to launch Godot." >&2
	exit 1
fi

echo "Running Friendly Freya startup-choice validation..."
if [ "$launcher_kind" = flatpak ]; then
	FREYA_STARTUP_VALIDATE=1 flatpak run org.godotengine.Godot --headless --path "$PROJECT_PATH" res://scenes/Startup.tscn --quit
else
	host-spawn env FREYA_STARTUP_VALIDATE=1 flatpak run org.godotengine.Godot --headless --path "$PROJECT_PATH" res://scenes/Startup.tscn --quit
fi

echo "Running Friendly Freya intro cut-scene validation..."
if [ "$launcher_kind" = flatpak ]; then
	FREYA_INTRO_VALIDATE=1 flatpak run org.godotengine.Godot --headless --path "$PROJECT_PATH" res://scenes/IntroCutscene.tscn --quit
else
	host-spawn env FREYA_INTRO_VALIDATE=1 flatpak run org.godotengine.Godot --headless --path "$PROJECT_PATH" res://scenes/IntroCutscene.tscn --quit
fi

echo "Running Friendly Freya gameplay checks (smoke + targeted validation)..."
if [ "$launcher_kind" = flatpak ]; then
	FREYA_VALIDATE=1 FREYA_SMOKE=1 flatpak run org.godotengine.Godot --headless --path "$PROJECT_PATH" res://scenes/Main.tscn --quit
else
	host-spawn env FREYA_VALIDATE=1 FREYA_SMOKE=1 flatpak run org.godotengine.Godot --headless --path "$PROJECT_PATH" res://scenes/Main.tscn --quit
fi
echo "Predeploy checks passed."
