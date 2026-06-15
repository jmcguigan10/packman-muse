#!/usr/bin/env bash
# Source-only logging and command-check helpers.

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
