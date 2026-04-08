#!/usr/bin/env bash
# Download HUMAN Doctor App assets (HUMAN.bundle) for iOS Simulator / iOS 13 and below.
# Docs: https://docs.humansecurity.com/applications/how-to-verify-the-sdk-integration-in-your-app
#
# Usage:
#   ./scripts/download_human_doctor_bundle.sh
#   ./scripts/download_human_doctor_bundle.sh 2.1
#
# After running, add HUMAN.bundle to the Xcode Runner target if Xcode does not pick it up automatically.
# Remove HUMAN.bundle before production builds.

set -euo pipefail

VERSION="${1:-2.1}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${ROOT}/ios/Runner"
BASE_URL="https://jfrog.humansecurity.com/artifactory/files/doctor-app-assets/ios"
ZIP_NAME="HUMAN.bundle.zip"
URL="${BASE_URL}/${VERSION}/${ZIP_NAME}"

if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl is required but was not found on PATH." >&2
  exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
  echo "error: unzip is required to extract HUMAN.bundle.zip but was not found on PATH." >&2
  echo "  Install it, then run this script again." >&2
  echo "  macOS: unzip is usually provided with the system or Xcode Command Line Tools (xcode-select --install)." >&2
  echo "  Linux: e.g. sudo apt install unzip   or   sudo dnf install unzip" >&2
  exit 1
fi

TMP="$(mktemp -d)"
cleanup() { rm -rf "${TMP}"; }
trap cleanup EXIT

echo "Downloading ${URL}"
curl -fsSL -o "${TMP}/${ZIP_NAME}" "${URL}"

echo "Extracting to ${DEST}"
mkdir -p "${DEST}"
unzip -o "${TMP}/${ZIP_NAME}" -d "${TMP}"

if [[ -d "${TMP}/HUMAN.bundle" ]]; then
  BUNDLE_SRC="${TMP}/HUMAN.bundle"
elif [[ -d "${TMP}/ios/HUMAN.bundle" ]]; then
  BUNDLE_SRC="${TMP}/ios/HUMAN.bundle"
else
  echo "error: HUMAN.bundle not found inside the zip. Contents:" >&2
  find "${TMP}" -maxdepth 3 -type d 2>/dev/null || ls -la "${TMP}"
  exit 1
fi

rm -rf "${DEST}/HUMAN.bundle"
mv "${BUNDLE_SRC}" "${DEST}/"

echo "Done: ${DEST}/HUMAN.bundle"
echo "Reminder: enable Doctor only in development; remove this bundle before App Store builds if required by your process."
