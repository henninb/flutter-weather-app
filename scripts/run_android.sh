#!/usr/bin/env bash
# Build and run the Flutter app on an Android emulator (or connected device).
# Usage: ./scripts/run_android.sh
#        ./scripts/run_android.sh --release
#        ./scripts/run_android.sh --dart-define=FOO=bar

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "error: flutter is not on PATH." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required (for flutter devices --machine)." >&2
  exit 1
fi

get_android_device_id() {
  flutter devices --machine 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for d in data:
        tp = d.get('targetPlatform', '')
        if 'android' in tp and d.get('isSupported', True):
            print(d['id'])
            sys.exit(0)
    sys.exit(1)
except Exception:
    sys.exit(1)
"
}

ensure_android_device() {
  local id
  id=$(get_android_device_id) || true
  if [[ -n "${id:-}" ]]; then
    echo "Using Android device: $id" >&2
    echo "$id"
    return 0
  fi

  echo "No Android device detected; attempting to launch an emulator…" >&2

  local avd
  avd=$(flutter emulators 2>/dev/null \
    | grep -i android \
    | head -n1 \
    | sed 's/^[[:space:]]*//' \
    | awk '{print $1}') || true

  if [[ -z "${avd:-}" ]]; then
    echo "error: No Android emulator found. Create one with: flutter emulators --create [--name my_emulator]" >&2
    exit 1
  fi

  echo "Launching emulator: $avd" >&2
  flutter emulators --launch "$avd" 2>/dev/null || true

  local i=0
  while [[ $i -lt 120 ]]; do
    id=$(get_android_device_id) || true
    if [[ -n "${id:-}" ]]; then
      echo "Emulator ready; building and launching…" >&2
      echo "$id"
      return 0
    fi
    sleep 1
    i=$((i + 1))
  done

  echo "error: No Android device appeared in flutter devices within 120s." >&2
  echo "Try starting an emulator manually, then run this script again." >&2
  exit 1
}

flutter pub get
ANDROID_DEVICE="$(ensure_android_device)"
exec flutter run -d "$ANDROID_DEVICE" "$@"
