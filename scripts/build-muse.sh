#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/env.sh
source "$SCRIPT_DIR/env.sh"
# shellcheck source=scripts/muse-cmake-args.sh
source "$SCRIPT_DIR/muse-cmake-args.sh"

stage="muse"
stamp_has "$stage" && {
  echo "$stage already built"
  exit 0
}

prepare_muse_source

rm -rf "$MUSE_BUILDDIR"
mkdir -p "$MUSE_BUILDDIR"

prepare_muse_cmake_args

cmake -S "$MUSE_SRCDIR" -B "$MUSE_BUILDDIR" -G "$CMAKE_GENERATOR" "${MUSE_CMAKE_ARGS[@]}"
cmake --build "$MUSE_BUILDDIR" --parallel "$JOBS"
cmake --install "$MUSE_BUILDDIR"

stamp_done "$stage"
echo "$stage built into $MUSE_PREFIX"
