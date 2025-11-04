#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TD_DIR="${ROOT_DIR}/td"
BUILDER_DIR="${ROOT_DIR}/builder"

PLATFORM="${1:-macOS}"

log() {
  echo "[$(date '+%H:%M:%S')] $*"
}

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require git
require python3

log "Platform: ${PLATFORM}"

log "Resetting td submodule"
git -C "${TD_DIR}" reset --hard HEAD
git -C "${TD_DIR}" clean -fd

log "Applying patches"
git -C "${TD_DIR}" apply "${BUILDER_DIR}/tdlib-patches/build-openssl.patch"
git -C "${TD_DIR}" apply "${BUILDER_DIR}/tdlib-patches/Python-Apple-Support-patch.patch"
git -C "${TD_DIR}" apply "${BUILDER_DIR}/teamgram-patches/td-teamgram.patch"

log "Building OpenSSL"
(
  cd "${TD_DIR}/example/ios"
  ./build-openssl.sh "${PLATFORM}"
)

log "Preparing TDLib build script"
cp "${BUILDER_DIR}/tdlib-patches/build.sh" "${TD_DIR}/example/ios/build.sh"

log "Building TDLib"
(
  cd "${TD_DIR}/example/ios"
  if [[ "${PLATFORM}" == visionOS* ]]; then
    ./build.sh "${PLATFORM}" ""
  else
    MIN_VERSION=$(python3 ../../../scripts/extract_os_version.py "${PLATFORM}")
    ./build.sh "${PLATFORM}" "${MIN_VERSION}"
  fi
)

log "Patching headers"
(
  cd "${BUILDER_DIR}"
  ./patch-headers.sh
)

if command -v tuist >/dev/null 2>&1; then
  log "Generating Xcode project with Tuist"
  (
    cd "${BUILDER_DIR}"
    TUIST_PLATFORM="${PLATFORM}" tuist generate
  )
else
  log "Tuist not found; skipping project generation (install via 'mise install tuist' if needed)"
fi

log "Building xcframework"
(
  cd "${BUILDER_DIR}"
  ./build-framework.sh "${PLATFORM}"
)

log "Done"
