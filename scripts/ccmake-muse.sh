#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"
# shellcheck source=muse-cmake-args.sh
source "$SCRIPT_DIR/muse-cmake-args.sh"

fresh=0
case "${1:-}" in
  "")
    ;;
  --fresh)
    fresh=1
    ;;
  *)
    echo "usage: bash scripts/ccmake-muse.sh [--fresh]" >&2
    exit 2
    ;;
esac

need_cmd ccmake
prepare_muse_source

if [ "$fresh" -eq 1 ]; then
  rm -rf "$MUSE_BUILDDIR"
fi

mkdir -p "$MUSE_BUILDDIR"

if [ "$fresh" -eq 1 ] || [ ! -f "$MUSE_BUILDDIR/CMakeCache.txt" ]; then
  prepare_muse_cmake_args
  cmake -S "$MUSE_SRCDIR" -B "$MUSE_BUILDDIR" -G "$CMAKE_GENERATOR" "${MUSE_CMAKE_ARGS[@]}"
fi

ccmake "$MUSE_BUILDDIR"
