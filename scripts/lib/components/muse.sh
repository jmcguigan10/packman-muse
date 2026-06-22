#!/usr/bin/env bash
# Source-only MUSE/g4PSI build, configure, and install functions.

# shellcheck disable=SC2154

MUSE_SRCDIR="$SRC/muse"
MUSE_BUILDDIR="$BUILD/muse"

prepare_muse_source() {
  checkout_git_source "$MUSE_REPO" "$MUSE_SRCDIR" "$MUSE_REF" "$MUSE_SHA"
}

prepare_muse_cmake_args() {
  local root_dir
  local xqilla_library
  local lzma_library
  local openssl_ssl_library
  local openssl_crypto_library
  local genfit_base_dir
  local genfit_library
  local muse_rpath

  root_dir="${ROOT_DIR:-$(find_cmake_config_dir ROOT "$CONDA_PREFIX" "$CONDA_PREFIX/cmake" "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)}"
  xqilla_library="${XQILLA_LIBRARY:-$(find_library_file xqilla "$XQILLA_PREFIX/lib" "$XQILLA_PREFIX/lib64" 2>/dev/null || true)}"
  lzma_library="${LZMA_LIBRARY:-$(find_library_file lzma "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)}"
  openssl_ssl_library="${OPENSSL_SSL_LIBRARY:-$(find_library_file ssl "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)}"
  openssl_crypto_library="${OPENSSL_CRYPTO_LIBRARY:-$(find_library_file crypto "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)}"
  genfit_base_dir="${GENFIT_BASE_DIR:-$SRC/genfit}"
  genfit_library="${GENFIT_LIBRARIES:-$(find_library_file genfit2 "$GENFIT_PREFIX/lib" "$GENFIT_PREFIX/lib64" "$BUILD/genfit/lib" "$BUILD/genfit/lib64" 2>/dev/null || true)}"
  muse_rpath="$(join_by_semicolon "$XQILLA_PREFIX/lib" "$CLHEP_PREFIX/lib" "$GEANT4_PREFIX/lib" "$GENFIT_PREFIX/lib" "$MUSE_PREFIX/lib")"

  require_nonempty "$root_dir" "could not find ROOT CMake directory under $CONDA_PREFIX"
  require_nonempty "$xqilla_library" "could not find libxqilla under $XQILLA_PREFIX"
  require_nonempty "$lzma_library" "could not find liblzma under $CONDA_PREFIX"
  require_nonempty "$openssl_ssl_library" "could not find libssl under $CONDA_PREFIX"
  require_nonempty "$openssl_crypto_library" "could not find libcrypto under $CONDA_PREFIX"
  require_file "$genfit_base_dir/cmake/genfit.cmake" "could not find GenFit source metadata under $genfit_base_dir"
  require_nonempty "$genfit_library" "could not find libgenfit2 under $GENFIT_PREFIX or $BUILD/genfit"

  MUSE_CMAKE_ARGS=(
    -DCMAKE_INSTALL_PREFIX="$MUSE_PREFIX"
    -DCMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH_CMAKE"
    -DCMAKE_C_COMPILER="$CC"
    -DCMAKE_CXX_COMPILER="$CXX"
    -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"
    -DCMAKE_CXX_STANDARD="$CMAKE_CXX_STANDARD"
    -DCMAKE_CXX_STANDARD_REQUIRED=ON
    "-DCMAKE_INSTALL_RPATH=$muse_rpath"
    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=OFF
    -DCMAKE_FIND_USE_PACKAGE_REGISTRY=FALSE
    -DCMAKE_FIND_USE_SYSTEM_PACKAGE_REGISTRY=FALSE
    -DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=FALSE
    "-DCMAKE_IGNORE_PREFIX_PATH=$MUSE_FORBIDDEN_PREFIXES"
    "-DCMAKE_SYSTEM_IGNORE_PREFIX_PATH=$MUSE_FORBIDDEN_PREFIXES"
    -DCMAKE_SHARED_PREFIX="$SHARED_PREFIX"
    "-DCMAKE_CXX_FLAGS=-I$CLHEP_PREFIX/include -I$CONDA_PREFIX/include"
    -DROOT_CONFIG_EXECUTABLE="$CONDA_PREFIX/bin/root-config"
    -DROOT_INCLUDE_DIR="$CONDA_PREFIX/include"
    -DROOT_LIBRARY_DIR="$CONDA_PREFIX/lib"
    -DROOT_DIR="$root_dir"
    -DCLHEP_CONFIG_EXECUTABLE="$CLHEP_PREFIX/bin/clhep-config"
    -DGSL_CONFIG="$CONDA_PREFIX/bin/gsl-config"
    -DXQILLA_INCLUDE_DIR="$XQILLA_PREFIX/include"
    -DXQILLA_LIBRARY_DIR="$XQILLA_PREFIX/lib"
    -DXQILLA_LIBRARY="$xqilla_library"
    -DXercesC_ROOT="$CONDA_PREFIX"
    -DXERCESC_ROOT_DIR="$CONDA_PREFIX"
    -DLZMA_BASE_DIR="$CONDA_PREFIX"
    -DLZMA_INCLUDE_DIR="$CONDA_PREFIX/include"
    -DLZMA_LIBRARIES="$lzma_library"
    -DOPENSSL_BASE_DIR="$CONDA_PREFIX"
    -DOPENSSL_ROOT_DIR="$CONDA_PREFIX"
    -DOPENSSL_INCLUDE_DIR="$CONDA_PREFIX/include"
    -DOPENSSL_SSL_LIBRARY="$openssl_ssl_library"
    -DOPENSSL_CRYPTO_LIBRARY="$openssl_crypto_library"
    "-DOPENSSL_LIBRARIES=$openssl_ssl_library;$openssl_crypto_library"
    -DGeant4_DIR="$GEANT4_PREFIX/lib/cmake/Geant4"
    -DGENFIT_BASE_DIR="$genfit_base_dir"
    -DGENFIT_LIBRARIES="$genfit_library"
    -DGENFIT_LIBRARY_DIR="$(dirname "$genfit_library")"
    -DDo_G4PSI="$MUSE_DO_G4PSI"
    -DDO_RADGEN="$MUSE_DO_RADGEN"
    -DDO_TIMEWALK="$MUSE_DO_TIMEWALK"
    -DDO_ML="$MUSE_DO_ML"
    -DDo_Tracking="$MUSE_DO_TRACKING"
  )
}

build_muse() {
  local stage="muse"

  if stamp_has "$stage"; then
    echo "$stage already built"
    return 0
  fi

  prepare_muse_source

  rm -rf "$MUSE_BUILDDIR"
  mkdir -p "$MUSE_BUILDDIR"

  prepare_muse_cmake_args

  cmake -S "$MUSE_SRCDIR" -B "$MUSE_BUILDDIR" -G "$CMAKE_GENERATOR" "${MUSE_CMAKE_ARGS[@]}"
  cmake --build "$MUSE_BUILDDIR" --parallel "$JOBS"
  cmake --install "$MUSE_BUILDDIR"

  stamp_done "$stage"
  echo "$stage built into $MUSE_PREFIX"
}

ccmake_muse_main() {
  local fresh=0

  case "${1:-}" in
    "") ;;
    --fresh)
      fresh=1
      ;;
    *)
      echo "usage: bash scripts/ccmake-muse.sh [--fresh]" >&2
      exit 2
      ;;
  esac

  need_cmd ccmake
  prepare_muse_source

  if [ "$fresh" -eq 1 ]; then
    rm -rf "$MUSE_BUILDDIR"
  fi

  mkdir -p "$MUSE_BUILDDIR"

  if [ "$fresh" -eq 1 ] || [ ! -f "$MUSE_BUILDDIR/CMakeCache.txt" ]; then
    prepare_muse_cmake_args
    cmake -S "$MUSE_SRCDIR" -B "$MUSE_BUILDDIR" -G "$CMAKE_GENERATOR" "${MUSE_CMAKE_ARGS[@]}"
  fi

  ccmake "$MUSE_BUILDDIR"
}

install_configured_muse() {
  if [ ! -f "$MUSE_BUILDDIR/CMakeCache.txt" ]; then
    echo "error: no configured MUSE build tree at $MUSE_BUILDDIR" >&2
    echo "hint: run ./scripts/pixi-local run -e batch ccmake-muse first" >&2
    exit 2
  fi

  cmake --build "$MUSE_BUILDDIR" --parallel "$JOBS"
  cmake --install "$MUSE_BUILDDIR"

  stamp_done muse
  echo "muse built into $MUSE_PREFIX"
}
