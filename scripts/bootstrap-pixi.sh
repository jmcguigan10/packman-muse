#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

# shellcheck source=scripts/lib/pixi/bootstrap.sh
source "$SCRIPT_DIR/lib/pixi/bootstrap.sh"

bootstrap_pixi_main "$ROOT"
