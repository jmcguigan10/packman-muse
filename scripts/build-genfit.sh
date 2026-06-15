#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"

stage="genfit"
stamp_has "$stage" && {
  echo "$stage already built"
  exit 0
}

repo="${GENFIT_REPO:-git@github.com:MUSE-EXP/Genfit.git}"
ref="${GENFIT_REF:-master}"
sha="${GENFIT_SHA:-56e733ff1eacf76b9f2cf046bb424c228ab57129}"

srcdir="$SRC/genfit"
builddir="$BUILD/genfit"

checkout_git_source "$repo" "$srcdir" "$ref" "$sha"

rm -rf "$builddir"
mkdir -p "$builddir"

root_dir="${ROOT_DIR:-$(find_cmake_config_dir ROOT "$CONDA_PREFIX" "$CONDA_PREFIX/cmake" "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)}"

cmake_args=(
  -DCMAKE_INSTALL_PREFIX="$GENFIT_PREFIX"
  -DCMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH_CMAKE"
  -DCMAKE_C_COMPILER="$CC"
  -DCMAKE_CXX_COMPILER="$CXX"
  -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"
  -DCMAKE_CXX_STANDARD="$CMAKE_CXX_STANDARD"
  -DCMAKE_CXX_STANDARD_REQUIRED=ON
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
  -DBUILD_TESTING=OFF
)

if [ -n "$root_dir" ]; then
  cmake_args+=("-DROOT_DIR=$root_dir")
fi

cmake -S "$srcdir" -B "$builddir" -G "$CMAKE_GENERATOR" "${cmake_args[@]}"
cmake --build "$builddir" --parallel "$JOBS"
cmake --install "$builddir"

stamp_done "$stage"
echo "$stage built into $GENFIT_PREFIX"
