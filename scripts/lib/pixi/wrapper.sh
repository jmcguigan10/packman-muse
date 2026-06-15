#!/usr/bin/env bash
# Source-only behavior shared by pixi-local and its template.

maybe_use_current_platform() {
  local root="$1"
  local command="${2:-}"

  case "$command" in
    install | lock | run | shell | add | remove | update | upgrade)
      if [ "${PIXI_AUTO_PLATFORM:-1}" != "0" ]; then
        "$root/scripts/pixi-use-current-platform.sh" "$root/pixi.toml"
      fi
      ;;
  esac
}
