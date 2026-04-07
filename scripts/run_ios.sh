#!/usr/bin/env bash
# Build and run the Flutter app on an iOS Simulator (or connected iOS device).
# Usage: ./scripts/run_ios.sh
#        ./scripts/run_ios.sh --release
#        ./scripts/run_ios.sh --dart-define=FOO=bar

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: iOS builds require macOS." >&2
  exit 1
fi

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

# First supported iOS device id from JSON (avoids fragile parsing of human table spacing).
get_ios_device_id() {
  flutter devices --machine 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for d in data:
        if d.get('targetPlatform') == 'ios' and d.get('isSupported', True):
            print(d['id'])
            sys.exit(0)
    sys.exit(1)
except Exception:
    sys.exit(1)
"
}

ensure_ios_device() {
  local id
  id=$(get_ios_device_id) || true
  if [[ -n "${id:-}" ]]; then
    echo "Using iOS device: $id" >&2
    echo "$id"
    return 0
  fi

  echo "No iOS device detected; starting iOS Simulator…" >&2
  if ! flutter emulators --launch apple_ios_simulator 2>/dev/null; then
    echo "error: Could not launch apple_ios_simulator. Install Xcode and run: flutter doctor" >&2
    exit 1
  fi

  local i=0
  while [[ $i -lt 120 ]]; do
    id=$(get_ios_device_id) || true
    if [[ -n "${id:-}" ]]; then
      echo "Simulator ready; building and launching…" >&2
      echo "$id"
      return 0
    fi
    sleep 1
    i=$((i + 1))
  done

  echo "error: No iOS device appeared in flutter devices within 120s." >&2
  echo "Try: open -a Simulator   then run this script again." >&2
  exit 1
}

flutter pub get
IOS_DEVICE="$(ensure_ios_device)"
exec flutter run -d "$IOS_DEVICE" "$@"
