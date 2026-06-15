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

cat > "$ROOT/scripts/pixi-local" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

export PIXI_HOME="$ROOT/.local/pixi-home"
export PIXI_CACHE_DIR="$ROOT/.local/pixi-cache"
export PIXI_NO_CONFIG=1

maybe_use_current_platform() {
  case "${1:-}" in
    install|lock|run|shell|add|remove|update|upgrade)
      if [ "${PIXI_AUTO_PLATFORM:-1}" != "0" ]; then
        "$ROOT/scripts/pixi-use-current-platform.sh" "$ROOT/pixi.toml"
      fi
      ;;
  esac
}

if [ ! -x "$ROOT/.local/bin/pixi" ]; then
  echo "error: local pixi is missing: $ROOT/.local/bin/pixi" >&2
  echo "run: bash scripts/bootstrap-pixi.sh" >&2
  exit 127
fi

maybe_use_current_platform "${1:-}"

exec "$ROOT/.local/bin/pixi" "$@"
EOF

chmod +x "$ROOT/scripts/pixi-local"

echo "Local pixi installed:"
echo "  $ROOT/.local/bin/pixi"
echo
echo "Use:"
echo "  ./scripts/pixi-local install"
echo "  ./scripts/pixi-local run -e batch build-stack"
