#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/env.sh"

stage="geant4"
stamp_has "$stage" && {
  echo "$stage already built"
  exit 0
}

version="${GEANT4_VERSION:-11.4.1}"
url="${GEANT4_URL:-https://gitlab.cern.ch/geant4/geant4/-/archive/v${version}/geant4-v${version}.tar.gz}"

archive="$SRC/geant4-v${version}.tar.gz"
srcdir="$SRC/geant4-v${version}"
builddir="$BUILD/geant4"

if [ ! -f "$archive" ]; then
  curl -fL "$url" -o "$archive"
fi

rm -rf "$srcdir" "$builddir"
mkdir -p "$srcdir" "$builddir"

tar -xzf "$archive" -C "$srcdir" --strip-components=1

clhep_dir="${CLHEP_DIR:-$(find_cmake_package_dir '*/CLHEP*cmake*' "$CLHEP_PREFIX" "$CLHEP_PREFIX/lib" "$CLHEP_PREFIX/lib64" 2>/dev/null || true)}"

cmake_args=(
  -DCMAKE_INSTALL_PREFIX="$GEANT4_PREFIX"
  -DCMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH"
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
)

if [ -n "$clhep_dir" ]; then
  cmake_args+=("-DCLHEP_DIR=$clhep_dir")
fi

cmake -S "$srcdir" -B "$builddir" -G "$CMAKE_GENERATOR" "${cmake_args[@]}"
cmake --build "$builddir" --parallel "$JOBS"
cmake --install "$builddir"

stamp_done "$stage"
echo "$stage built into $GEANT4_PREFIX"
