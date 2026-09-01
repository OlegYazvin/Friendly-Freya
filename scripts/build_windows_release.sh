#!/usr/bin/env sh
set -eu

REPOSITORY_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
PROJECT_PATH="$REPOSITORY_ROOT/godot"
OUTPUT_ROOT="${FREYA_RELEASE_OUTPUT_DIR:-$REPOSITORY_ROOT/dist}"
EXPECTED_GODOT_VERSION="${FREYA_EXPORT_GODOT_VERSION:-4.7.2}"
RELEASE_LABEL="${1:-dev}"

case "$RELEASE_LABEL" in
	*[!A-Za-z0-9._-]*|'')
		echo "Error: release label may contain only letters, digits, dots, underscores, and hyphens." >&2
		exit 1
		;;
esac

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

godot_version() {
	case "$launcher_kind" in
		direct) "$godot_bin" --version ;;
		flatpak) flatpak run org.godotengine.Godot --version ;;
		host_spawn) host-spawn flatpak run org.godotengine.Godot --version ;;
	esac
}

actual_version=$(godot_version)
case "$actual_version" in
	"$EXPECTED_GODOT_VERSION".*) ;;
	*)
		echo "Error: Windows releases require Godot $EXPECTED_GODOT_VERSION.x; found $actual_version." >&2
		exit 1
		;;
esac

mkdir -p "$OUTPUT_ROOT"
OUTPUT_ROOT=$(CDPATH= cd -- "$OUTPUT_ROOT" && pwd)
stage_root=$(mktemp -d "$OUTPUT_ROOT/.friendly-freya-windows.XXXXXX")
trap 'rm -rf "$stage_root"' EXIT INT TERM
package_dir="$stage_root/FriendlyFreya"
mkdir -p "$package_dir"

export_project() {
	case "$launcher_kind" in
		direct)
			"$godot_bin" --headless --path "$PROJECT_PATH" --export-release "Windows Desktop" "$package_dir/FriendlyFreya.exe"
			;;
		flatpak)
			flatpak run org.godotengine.Godot --headless --path "$PROJECT_PATH" --export-release "Windows Desktop" "$package_dir/FriendlyFreya.exe"
			;;
		host_spawn)
			host-spawn flatpak run org.godotengine.Godot --headless --path "$PROJECT_PATH" --export-release "Windows Desktop" "$package_dir/FriendlyFreya.exe"
			;;
	esac
}

export_project

for required_file in FriendlyFreya.exe FriendlyFreya.pck; do
	if [ ! -s "$package_dir/$required_file" ]; then
		echo "Error: export did not create a non-empty $required_file." >&2
		exit 1
	fi
done

validate_exported_pack() {
	case "$launcher_kind" in
		direct)
			(
				cd "$stage_root"
				env FREYA_RELEASE_CONTENT_VALIDATE=1 "$godot_bin" --headless --main-pack "$package_dir/FriendlyFreya.pck"
			)
			;;
		flatpak)
			env FREYA_RELEASE_CONTENT_VALIDATE=1 flatpak run org.godotengine.Godot --headless --main-pack "$package_dir/FriendlyFreya.pck"
			;;
		host_spawn)
			host-spawn env FREYA_RELEASE_CONTENT_VALIDATE=1 flatpak run org.godotengine.Godot --headless --main-pack "$package_dir/FriendlyFreya.pck"
			;;
	esac
}

# Load the exported PCK itself, not the source project. The embedded startup
# validator requires the active CC0 dog and rejects every inactive model with
# unresolved provenance.
content_validation_log="$stage_root/release-content-validation.log"
if ! validate_exported_pack >"$content_validation_log" 2>&1; then
	cat "$content_validation_log" >&2
	echo "Error: exported PCK content validation failed." >&2
	exit 1
fi
cat "$content_validation_log"
if ! grep -Fq "RELEASE_CONTENT_OK" "$content_validation_log"; then
	echo "Error: exported PCK did not report RELEASE_CONTENT_OK." >&2
	exit 1
fi

cp "$REPOSITORY_ROOT/packaging/windows/README.txt" "$package_dir/README.txt"
cp "$REPOSITORY_ROOT/packaging/windows/GODOT_ENGINE_LICENSE.txt" "$package_dir/GODOT_ENGINE_LICENSE.txt"
cp "$REPOSITORY_ROOT/godot/assets/audio/ATTRIBUTION.md" "$package_dir/AUDIO_ATTRIBUTION.md"
cp "$REPOSITORY_ROOT/packaging/windows/MODEL_ATTRIBUTION.md" "$package_dir/MODEL_ATTRIBUTION.md"

archive_name="Friendly-Freya-${RELEASE_LABEL}-Windows-x86_64.zip"
archive_path="$OUTPUT_ROOT/$archive_name"
checksum_path="$archive_path.sha256"
if [ -e "$archive_path" ] || [ -e "$checksum_path" ]; then
	echo "Error: release output already exists: $archive_path" >&2
	exit 1
fi

temporary_archive="$stage_root/$archive_name"
temporary_checksum="$stage_root/$archive_name.sha256"
(
	cd "$stage_root"
	zip -X -q -r "$temporary_archive" FriendlyFreya
)
(
	cd "$stage_root"
	sha256sum "$archive_name" >"$temporary_checksum"
)
mv "$temporary_archive" "$archive_path"
mv "$temporary_checksum" "$checksum_path"

echo "Windows release archive: $archive_path"
echo "SHA-256 manifest: $checksum_path"
