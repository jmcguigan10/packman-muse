#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"

stage="geant4"
stamp_has "$stage" && {
  echo "$stage already built"
  exit 0
}

default_version="11.4.1"
default_url="https://gitlab.cern.ch/geant4/geant4/-/archive/v${default_version}/geant4-v${default_version}.tar.gz"
default_sha256="99dcf5f9d4f806fb8c4fde85cb2674a42e4ca19833143464ff7efa55c1852140"

version="${GEANT4_VERSION:-$default_version}"
url="${GEANT4_URL:-https://gitlab.cern.ch/geant4/geant4/-/archive/v${version}/geant4-v${version}.tar.gz}"
sha256="${GEANT4_SHA256:-}"
if [ -z "$sha256" ] && [ "$version" = "$default_version" ] && [ "$url" = "$default_url" ]; then
  sha256="$default_sha256"
fi

archive="$SRC/geant4-v${version}.tar.gz"
srcdir="$SRC/geant4-v${version}"
builddir="$BUILD/geant4"

if [ ! -f "$archive" ]; then
  curl -fL "$url" -o "$archive"
fi
verify_sha256 "$archive" "$sha256"

rm -rf "$srcdir" "$builddir"
mkdir -p "$srcdir" "$builddir"

tar -xzf "$archive" -C "$srcdir" --strip-components=1

clhep_dir="${CLHEP_DIR:-$(find_cmake_config_dir CLHEP \
  "$CLHEP_PREFIX" \
  "$CLHEP_PREFIX/lib" \
  "$CLHEP_PREFIX/lib64" \
  2>/dev/null || true)}"

if [ -z "$clhep_dir" ]; then
  echo "error: could not find CLHEPConfig.cmake under $CLHEP_PREFIX" >&2
  echo "hint: run build-clhep first, or set CLHEP_DIR explicitly" >&2
  exit 2
fi

cmake_args=(
  -DCMAKE_INSTALL_PREFIX="$GEANT4_PREFIX"
  -DCMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH_CMAKE"
  -DCMAKE_C_COMPILER="$CC"
  -DCMAKE_CXX_COMPILER="$CXX"
  -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"
  -DCMAKE_CXX_STANDARD="$CMAKE_CXX_STANDARD"
  -DCMAKE_CXX_STANDARD_REQUIRED=ON
  -DGEANT4_BUILD_MULTITHREADED=ON
  -DGEANT4_INSTALL_DATA=ON
  -DGEANT4_USE_GDML=ON
  -DGEANT4_USE_SYSTEM_CLHEP=ON
  -DGEANT4_USE_SYSTEM_EXPAT=ON
  -DGEANT4_USE_SYSTEM_ZLIB=ON
  -DGEANT4_USE_QT=OFF
  -DGEANT4_USE_OPENGL_X11=OFF
  -DGEANT4_USE_RAYTRACER_X11=OFF
  -DGEANT4_USE_XM=OFF
  -DGEANT4_INSTALL_DATADIR="$GEANT4_PREFIX/share/Geant4/data"
  -DCLHEP_ROOT_DIR="$CLHEP_PREFIX"
  -DXercesC_ROOT="$CONDA_PREFIX"
  -DXERCESC_ROOT_DIR="$CONDA_PREFIX"
  -DCLHEP_DIR="$clhep_dir"
)

cmake -S "$srcdir" -B "$builddir" -G "$CMAKE_GENERATOR" "${cmake_args[@]}"
cmake --build "$builddir" --parallel "$JOBS"
cmake --install "$builddir"

stamp_done "$stage"
echo "$stage built into $GEANT4_PREFIX"
