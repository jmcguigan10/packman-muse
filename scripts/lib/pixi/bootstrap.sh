#!/usr/bin/env bash
# Source-only Pixi bootstrap helper.

bootstrap_pixi_main() {
  local root="$1"

  mkdir -p \
    "$root/.local/bin" \
    "$root/.local/pixi-home" \
    "$root/.local/pixi-cache"

  export PIXI_HOME="$root/.local/pixi-home"
  export PIXI_BIN_DIR="$root/.local/bin"
  export PIXI_CACHE_DIR="$root/.local/pixi-cache"
  export PIXI_NO_PATH_UPDATE=1
  export PIXI_NO_CONFIG=1

  curl -fsSL https://pixi.sh/install.sh | bash

  install -m 755 "$root/scripts/pixi-local.in" "$root/scripts/pixi-local"

  echo "Local pixi installed:"
  echo "  $root/.local/bin/pixi"
  echo
  echo "Use:"
  echo "  ./scripts/pixi-local install"
  echo "  ./scripts/pixi-local run -e batch build-stack"
}
