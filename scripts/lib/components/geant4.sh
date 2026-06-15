#!/usr/bin/env bash
# Source-only Geant4 build function.

# shellcheck disable=SC2154

build_geant4() {
  local stage="geant4"
  local archive="$SRC/geant4-v${GEANT4_VERSION}.tar.gz"
  local srcdir="$SRC/geant4-v${GEANT4_VERSION}"
  local builddir="$BUILD/geant4"
  local clhep_dir
  local cmake_args

  if stamp_has "$stage"; then
    echo "$stage already built"
    return 0
  fi

  download_if_missing "$GEANT4_URL" "$archive"
  verify_sha256 "$archive" "$GEANT4_SHA256"

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
}
