#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

mkdir -p \
  "$ROOT/.local/bin" \
  "$ROOT/.local/pixi-home" \
  "$ROOT/.local/pixi-cache"

export PIXI_HOME="$ROOT/.local/pixi-home"
export PIXI_BIN_DIR="$ROOT/.local/bin"
export PIXI_CACHE_DIR="$ROOT/.local/pixi-cache"
export PIXI_NO_PATH_UPDATE=1
export PIXI_NO_CONFIG=1

curl -fsSL https://pixi.sh/install.sh | bash

install -m 755 "$ROOT/scripts/pixi-local.in" "$ROOT/scripts/pixi-local"

echo "Local pixi installed:"
echo "  $ROOT/.local/bin/pixi"
echo
echo "Use:"
echo "  ./scripts/pixi-local install"
echo "  ./scripts/pixi-local run -e batch build-stack"
