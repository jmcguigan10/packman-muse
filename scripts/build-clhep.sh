#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"

stage="clhep"
stamp_has "$stage" && {
  echo "$stage already built"
  exit 0
}

repo="${CLHEP_REPO:-https://gitlab.cern.ch/CLHEP/CLHEP.git}"
ref="${CLHEP_REF:-CLHEP_2_4_7_2}"
sha="${CLHEP_SHA:-10fdf9b342265174b37db3bcb9a1fc79e585fde7}"

srcdir="$SRC/clhep"
builddir="$BUILD/clhep"

checkout_git_source "$repo" "$srcdir" "$ref" "$sha"

cmake_source="$srcdir"
if [ ! -f "$cmake_source/CMakeLists.txt" ] && [ -f "$srcdir/CLHEP/CMakeLists.txt" ]; then
  cmake_source="$srcdir/CLHEP"
fi

rm -rf "$builddir"
mkdir -p "$builddir"

cmake -S "$cmake_source" -B "$builddir" -G "$CMAKE_GENERATOR" \
  -DCMAKE_INSTALL_PREFIX="$CLHEP_PREFIX" \
  -DCMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH_CMAKE" \
  -DCMAKE_C_COMPILER="$CC" \
  -DCMAKE_CXX_COMPILER="$CXX" \
  -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE" \
  -DCMAKE_CXX_STANDARD="$CMAKE_CXX_STANDARD" \
  -DCMAKE_CXX_STANDARD_REQUIRED=ON \
  "-DCLHEP_BUILD_CXXSTD=-std=c++$CMAKE_CXX_STANDARD" \
  -DCLHEP_BUILD_STATIC_LIBS=OFF

cmake --build "$builddir" --parallel "$JOBS"
cmake --install "$builddir"

stamp_done "$stage"
echo "$stage built into $CLHEP_PREFIX"
