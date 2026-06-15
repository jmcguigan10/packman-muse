#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/env.sh
source "$SCRIPT_DIR/env.sh"
# shellcheck source=scripts/muse-cmake-args.sh
source "$SCRIPT_DIR/muse-cmake-args.sh"

if [ ! -f "$MUSE_BUILDDIR/CMakeCache.txt" ]; then
  echo "error: no configured MUSE build tree at $MUSE_BUILDDIR" >&2
  echo "hint: run ./scripts/pixi-local run -e batch ccmake-muse first" >&2
  exit 2
fi

cmake --build "$MUSE_BUILDDIR" --parallel "$JOBS"
cmake --install "$MUSE_BUILDDIR"

stamp_done muse
echo "muse built into $MUSE_PREFIX"
