#!/usr/bin/env bash
# Shared logging, path, stamp, and checksum helpers.

# shellcheck disable=SC2034,SC2154

die() {
  echo "error: $*" >&2
  exit 2
}

warn() {
  echo "warning: $*" >&2
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

require_nonempty() {
  local value="$1"
  local message="$2"
  [ -n "$value" ] || die "$message"
}

require_file() {
  [ -f "$1" ] || die "$2"
}

join_by_colon() {
  local IFS=:
  printf '%s' "$*"
}

join_by_semicolon() {
  local IFS=';'
  printf '%s' "$*"
}

init_repo_paths() {
  ROOT="$PIXI_PROJECT_ROOT"
  SRC="$ROOT/$SOURCE_DIR"
  BUILD="$ROOT/$BUILD_DIR"
  STATE="$ROOT/$STATE_DIR"
  LOGS="$ROOT/$LOG_DIR"
  INSTALL_DIR="$ROOT/$INSTALL_DIR_REL"

  XQILLA_PREFIX="$ROOT/$XQILLA_PREFIX_REL"
  CLHEP_PREFIX="$ROOT/$CLHEP_PREFIX_REL"
  GEANT4_PREFIX="$ROOT/$GEANT4_PREFIX_REL"
  GENFIT_PREFIX="$ROOT/$GENFIT_PREFIX_REL"
  MUSE_PREFIX="$ROOT/$MUSE_PREFIX_REL"
  SHARED_PREFIX="$ROOT/$SHARED_PREFIX_REL"

  mkdir -p \
    "$SRC" "$BUILD" "$STATE" "$LOGS" "$INSTALL_DIR" \
    "$XQILLA_PREFIX" "$CLHEP_PREFIX" "$GEANT4_PREFIX" "$GENFIT_PREFIX" "$MUSE_PREFIX"

  export ROOT SRC BUILD STATE LOGS INSTALL_DIR
  export XQILLA_PREFIX CLHEP_PREFIX GEANT4_PREFIX GENFIT_PREFIX MUSE_PREFIX SHARED_PREFIX
}

stamp_done() {
  touch "$STATE/$1.done"
}

stamp_has() {
  test -f "$STATE/$1.done"
}

verify_sha256() {
  local file="$1"
  local expected="$2"

  require_nonempty "$expected" "missing SHA256 for $file"
  printf '%s  %s\n' "$expected" "$file" | shasum -a 256 -c -
}
