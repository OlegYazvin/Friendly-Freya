#!/usr/bin/env sh
set -eu

PROJECT_PATH="$(CDPATH= cd -- "$(dirname -- "$0")/../godot" && pwd)"

if command -v flatpak >/dev/null 2>&1; then
	set -- flatpak run org.godotengine.Godot
elif command -v host-spawn >/dev/null 2>&1; then
	set -- host-spawn flatpak run org.godotengine.Godot
else
	echo "Error: neither flatpak nor host-spawn is available to launch Godot." >&2
	exit 1
fi

echo "Running Friendly Freya predeploy checks (smoke + targeted validation)..."
FREYA_VALIDATE=1 FREYA_SMOKE=1 "$@" --headless --path "$PROJECT_PATH" --quit
echo "Predeploy checks passed."
