#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
MUSE local stack commands

First setup:
  bash scripts/bootstrap-pixi.sh
  ./scripts/pixi-local install
  ./scripts/pixi-local run -e batch build-stack

WSL2 setup note:
  clone under the WSL filesystem, for example ~/code/fpb-edits
  do not build from /mnt/c

Build and probe tasks:
  ./scripts/pixi-local run -e batch probe-host
  ./scripts/pixi-local run -e batch build-xqilla
  ./scripts/pixi-local run -e batch probe-xqilla
  ./scripts/pixi-local run -e batch build-clhep
  ./scripts/pixi-local run -e batch build-geant4
  ./scripts/pixi-local run -e batch build-genfit
  ./scripts/pixi-local run -e batch build-muse
  ./scripts/pixi-local run -e batch build-stack

Manual MUSE configure path:
  ./scripts/pixi-local run -e batch ccmake-muse
  ./scripts/pixi-local run -e batch bash scripts/ccmake-muse.sh --fresh
  ./scripts/pixi-local run -e batch install-configured-muse

Runtime after build:
  ./scripts/pixi-local run -e batch stack-shell
  ./scripts/pixi-local run -e batch bash scripts/stack-shell.sh g4PSI path/to/macro.mac
  ./scripts/pixi-local run -e batch bash scripts/stack-shell.sh g4PSI --rad2 path/to/macro.mac
  ./scripts/pixi-local run -e batch bash scripts/stack-shell.sh g4PSI --rad3 path/to/macro.mac

Rebuild one stage:
  rm -f .install/state/muse.done
  rm -rf .install/build/muse
  ./scripts/pixi-local run -e batch build-muse

Clean local source-built outputs:
  ./scripts/pixi-local run -e batch clean-local

Useful overrides:
  JOBS=4 ./scripts/pixi-local run -e batch build-stack
  PIXI_AUTO_PLATFORM=0 ./scripts/pixi-local install

Dependency inspection:
  otool -L .local/bin/muse/bin/g4PSI
  otool -l .local/bin/muse/bin/g4PSI | grep -A3 LC_RPATH
  ldd .local/bin/muse/bin/g4PSI

Show this help:
  bash scripts/help.sh
  ./scripts/pixi-local run -e batch help
EOF
