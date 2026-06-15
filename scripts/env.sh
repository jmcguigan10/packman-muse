#!/usr/bin/env bash
set -euo pipefail

# Compatibility loader for build entrypoints.
# It wires source-only configs and library modules into the repo-local build env.

: "${PIXI_PROJECT_ROOT:?Run this through pixi: ./scripts/pixi-local run <task>}"
: "${CONDA_PREFIX:?Pixi did not set CONDA_PREFIX}"

_ENV_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
_ENV_ROOT="$(cd "$_ENV_SCRIPT_DIR/.." && pwd -P)"

source_many() {
  local file
  for file in "$@"; do
    # shellcheck source=/dev/null
    source "$file"
  done
}

source_many \
  "$_ENV_ROOT/configs/build.sh" \
  "$_ENV_ROOT/configs/paths.sh" \
  "$_ENV_ROOT/configs/sources.sh" \
  "$_ENV_ROOT/configs/muse.sh" \
  "$_ENV_SCRIPT_DIR/lib/core.sh" \
  "$_ENV_SCRIPT_DIR/lib/platform.sh" \
  "$_ENV_SCRIPT_DIR/lib/build.sh"

init_repo_paths
configure_muse_runtime
configure_cmake_prefix_paths
configure_dependency_environment
configure_git_ssh_command

export CMAKE_BUILD_TYPE CMAKE_GENERATOR CMAKE_CXX_STANDARD CMAKE_CXX_STANDARD_REQUIRED
configure_toolchain
configure_jobs

source_many \
  "$_ENV_SCRIPT_DIR/lib/components/xqilla.sh" \
  "$_ENV_SCRIPT_DIR/lib/components/clhep.sh" \
  "$_ENV_SCRIPT_DIR/lib/components/geant4.sh" \
  "$_ENV_SCRIPT_DIR/lib/components/genfit.sh" \
  "$_ENV_SCRIPT_DIR/lib/components/muse.sh" \
  "$_ENV_SCRIPT_DIR/lib/components/probes.sh"
