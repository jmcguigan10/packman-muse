#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/env.sh"

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

exec "${SHELL:-bash}"
