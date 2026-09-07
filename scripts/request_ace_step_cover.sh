#!/usr/bin/env sh
set -eu

REPOSITORY_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SOURCE_AUDIO="${1:-/data/projects/Audio Recordings/Recording for Freya Title Card.wav}"
OUTPUT_AUDIO="${2:-$REPOSITORY_ROOT/godot/assets/audio/menu/title_card_theme_8bit.wav}"
API_BASE="${FREYA_ACE_STEP_API_BASE:-http://127.0.0.1:8001}"
API_TOKEN="${FREYA_ACE_STEP_API_TOKEN:-}"
POLL_SECONDS="${FREYA_ACE_STEP_POLL_SECONDS:-10}"
MAX_POLLS="${FREYA_ACE_STEP_MAX_POLLS:-60}"
MODEL="${FREYA_ACE_STEP_MODEL:-acestep-v15-turbo}"
INFERENCE_STEPS="${FREYA_ACE_STEP_INFERENCE_STEPS:-8}"
COVER_STRENGTH="${FREYA_ACE_STEP_COVER_STRENGTH:-0.86}"
PROMPT="${FREYA_ACE_STEP_PROMPT:-cheerful upbeat 8-bit chiptune title-screen instrumental, lighthearted dog hero adventure, playful retro videogame synths, bright melody, clean loopable arrangement}"
WORK_DIR="${FREYA_ACE_STEP_WORK_DIR:-$(mktemp -d /tmp/freya-ace-step-cover.XXXXXX)}"

if [ ! -s "$SOURCE_AUDIO" ]; then
	echo "Error: source title-card recording is missing: $SOURCE_AUDIO" >&2
	exit 1
fi

mkdir -p "$(dirname -- "$OUTPUT_AUDIO")"

submit_response="$WORK_DIR/submit.json"
query_response="$WORK_DIR/query.json"
downloaded_audio="$WORK_DIR/ace_step_cover_raw"

submit_task() {
	if [ -n "$API_TOKEN" ]; then
		curl -sS -X POST "$API_BASE/release_task" \
			-H "Authorization: Bearer $API_TOKEN" \
			-F "prompt=$PROMPT" \
			-F "lyrics=[instrumental]" \
			-F "audio_duration=17.02" \
			-F "audio_format=wav" \
			-F "task_type=cover" \
			-F "audio_cover_strength=$COVER_STRENGTH" \
			-F "model=$MODEL" \
			-F "inference_steps=$INFERENCE_STEPS" \
			-F "batch_size=1" \
			-F "thinking=false" \
			-F "src_audio=@$SOURCE_AUDIO"
	else
		curl -sS -X POST "$API_BASE/release_task" \
			-F "prompt=$PROMPT" \
			-F "lyrics=[instrumental]" \
			-F "audio_duration=17.02" \
			-F "audio_format=wav" \
			-F "task_type=cover" \
			-F "audio_cover_strength=$COVER_STRENGTH" \
			-F "model=$MODEL" \
			-F "inference_steps=$INFERENCE_STEPS" \
			-F "batch_size=1" \
			-F "thinking=false" \
			-F "src_audio=@$SOURCE_AUDIO"
	fi
}

query_task() {
	if [ -n "$API_TOKEN" ]; then
		curl -sS -X POST "$API_BASE/query_result" \
			-H "Authorization: Bearer $API_TOKEN" \
			-H "Content-Type: application/json" \
			-d "{\"task_id_list\":[\"$1\"]}"
	else
		curl -sS -X POST "$API_BASE/query_result" \
			-H "Content-Type: application/json" \
			-d "{\"task_id_list\":[\"$1\"]}"
	fi
}

download_result() {
	if [ -n "$API_TOKEN" ]; then
		curl -sSL -H "Authorization: Bearer $API_TOKEN" "$1" -o "$downloaded_audio"
	else
		curl -sSL "$1" -o "$downloaded_audio"
	fi
}

submit_task > "$submit_response"
task_id="$(
	python3 - "$submit_response" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    raw = handle.read()

try:
    payload = json.loads(raw)
except json.JSONDecodeError as exc:
    raise SystemExit("ACE-Step task submission returned non-JSON data. Check FREYA_ACE_STEP_API_BASE and authentication. First bytes: " + raw[:160]) from exc

if payload.get("code") != 200 or not payload.get("data"):
    raise SystemExit("ACE-Step task submission failed: " + json.dumps(payload, ensure_ascii=False))

task_id = payload["data"].get("task_id")
if not task_id:
    raise SystemExit("ACE-Step task submission did not return a task_id: " + json.dumps(payload, ensure_ascii=False))
print(task_id)
PY
)"

poll_index=0
result_path=""
while [ "$poll_index" -lt "$MAX_POLLS" ]; do
	query_task "$task_id" > "$query_response"
	result_path="$(
		python3 - "$query_response" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    raw = handle.read()

try:
    payload = json.loads(raw)
except json.JSONDecodeError as exc:
    raise SystemExit("ACE-Step task query returned non-JSON data. Check FREYA_ACE_STEP_API_BASE and authentication. First bytes: " + raw[:160]) from exc

if payload.get("code") != 200 or not payload.get("data"):
    raise SystemExit("ACE-Step task query failed: " + json.dumps(payload, ensure_ascii=False))

record = payload["data"][0]
status = int(record.get("status", 0))
if status == 0:
    print("")
elif status == 1:
    result = record.get("result")
    if isinstance(result, str):
        result = json.loads(result)
    if not result:
        raise SystemExit("ACE-Step task succeeded without result files.")
    print(result[0].get("file") or result[0].get("audio") or "")
else:
    raise SystemExit("ACE-Step task failed: " + json.dumps(record, ensure_ascii=False))
PY
	)"
	if [ -n "$result_path" ]; then
		break
	fi
	poll_index=$((poll_index + 1))
	sleep "$POLL_SECONDS"
done

if [ -z "$result_path" ]; then
	echo "Error: ACE-Step task did not finish after $MAX_POLLS polls of $POLL_SECONDS seconds." >&2
	exit 1
fi

case "$result_path" in
	http://*|https://*)
		result_url="$result_path"
		;;
	/*)
		result_url="${API_BASE%/}$result_path"
		;;
	*)
		result_url="${API_BASE%/}/$result_path"
		;;
esac

download_result "$result_url"

ffmpeg -hide_banner -y \
	-i "$downloaded_audio" \
	-af "highpass=f=60,lowpass=f=9000,alimiter=limit=0.92,afade=t=in:st=0:d=0.03" \
	-ac 2 \
	-ar 22050 \
	-sample_fmt s16 \
	"$OUTPUT_AUDIO"

ffprobe -hide_banner -show_entries format=duration,size,bit_rate -show_streams "$OUTPUT_AUDIO"
echo "ACE-Step cover generated from $SOURCE_AUDIO"
echo "ACE-Step task id: $task_id"
echo "Temporary work directory: $WORK_DIR"
