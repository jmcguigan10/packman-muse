#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
command_name="${1:-$(basename "$0")}"
[ "$#" -gt 0 ] && shift

# shellcheck source=scripts/env.sh
source "$SCRIPT_DIR/env.sh"

case "$command_name" in
  build-xqilla.sh) build_xqilla ;;
  build-clhep.sh) build_clhep ;;
  build-geant4.sh) build_geant4 ;;
  build-genfit.sh) build_genfit ;;
  build-muse.sh) build_muse ;;
  probe-host.sh) probe_host ;;
  probe-xqilla.sh) probe_xqilla ;;
  ccmake-muse.sh) ccmake_muse_main "$@" ;;
  install-configured-muse.sh) install_configured_muse ;;
  stack-shell.sh)
    if [ "$#" -gt 0 ]; then
      exec "$@"
    fi
    exec "${SHELL:-bash}"
    ;;
  *)
    die "unknown script dispatcher command: $command_name"
    ;;
esac
