#!/usr/bin/env bash
set -euo pipefail

# Compatibility loader for build entrypoints.
# It wires source-only configs and library modules into the repo-local build env.

: "${PIXI_PROJECT_ROOT:?Run this through pixi: ./scripts/pixi-local run <task>}"
: "${CONDA_PREFIX:?Pixi did not set CONDA_PREFIX}"

_ENV_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
_ENV_ROOT="$(cd "$_ENV_SCRIPT_DIR/.." && pwd -P)"

# shellcheck source=configs/build.sh
source "$_ENV_ROOT/configs/build.sh"
# shellcheck source=configs/paths.sh
source "$_ENV_ROOT/configs/paths.sh"
# shellcheck source=configs/sources.sh
source "$_ENV_ROOT/configs/sources.sh"
# shellcheck source=configs/muse.sh
source "$_ENV_ROOT/configs/muse.sh"

# shellcheck source=scripts/lib/core/logging.sh
source "$_ENV_SCRIPT_DIR/lib/core/logging.sh"
# shellcheck source=scripts/lib/core/paths.sh
source "$_ENV_SCRIPT_DIR/lib/core/paths.sh"
# shellcheck source=scripts/lib/core/stamps.sh
source "$_ENV_SCRIPT_DIR/lib/core/stamps.sh"
# shellcheck source=scripts/lib/core/checksums.sh
source "$_ENV_SCRIPT_DIR/lib/core/checksums.sh"
# shellcheck source=scripts/lib/platform/detect.sh
source "$_ENV_SCRIPT_DIR/lib/platform/detect.sh"
# shellcheck source=scripts/lib/platform/toolchain.sh
source "$_ENV_SCRIPT_DIR/lib/platform/toolchain.sh"
# shellcheck source=scripts/lib/build/discover.sh
source "$_ENV_SCRIPT_DIR/lib/build/discover.sh"
# shellcheck source=scripts/lib/build/git.sh
source "$_ENV_SCRIPT_DIR/lib/build/git.sh"
# shellcheck source=scripts/lib/build/download.sh
source "$_ENV_SCRIPT_DIR/lib/build/download.sh"
# shellcheck source=scripts/lib/build/autotools.sh
source "$_ENV_SCRIPT_DIR/lib/build/autotools.sh"
# shellcheck source=scripts/lib/build/cmake.sh
source "$_ENV_SCRIPT_DIR/lib/build/cmake.sh"
# shellcheck source=scripts/lib/build/runtime.sh
source "$_ENV_SCRIPT_DIR/lib/build/runtime.sh"

init_repo_paths
configure_muse_runtime
configure_cmake_prefix_paths
configure_dependency_environment
configure_git_ssh_command

export CMAKE_BUILD_TYPE CMAKE_GENERATOR CMAKE_CXX_STANDARD CMAKE_CXX_STANDARD_REQUIRED
configure_toolchain
configure_jobs

# shellcheck source=scripts/lib/components/xqilla.sh
source "$_ENV_SCRIPT_DIR/lib/components/xqilla.sh"
# shellcheck source=scripts/lib/components/clhep.sh
source "$_ENV_SCRIPT_DIR/lib/components/clhep.sh"
# shellcheck source=scripts/lib/components/geant4.sh
source "$_ENV_SCRIPT_DIR/lib/components/geant4.sh"
# shellcheck source=scripts/lib/components/genfit.sh
source "$_ENV_SCRIPT_DIR/lib/components/genfit.sh"
# shellcheck source=scripts/lib/components/muse.sh
source "$_ENV_SCRIPT_DIR/lib/components/muse.sh"
# shellcheck source=scripts/lib/components/probes.sh
source "$_ENV_SCRIPT_DIR/lib/components/probes.sh"
