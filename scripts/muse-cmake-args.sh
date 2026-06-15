#!/usr/bin/env bash
set -euo pipefail

# This helper is source-only; env.sh provides the shared build globals.
# shellcheck disable=SC2034,SC2154

MUSE_REPO="${MUSE_REPO:-git@github.com:MUSE-EXP/MUSE.git}"
MUSE_REF="${MUSE_REF:-master}"
MUSE_SHA="${MUSE_SHA:-37a7846d09fb44b7dff533a27ba242241de32504}"

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
  local openssl_libraries
  local genfit_base_dir
  local genfit_library

  root_dir="${ROOT_DIR:-$(find_cmake_config_dir ROOT "$CONDA_PREFIX" "$CONDA_PREFIX/cmake" "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)}"
  xqilla_library="${XQILLA_LIBRARY:-$(find_library_file xqilla "$XQILLA_PREFIX/lib" "$XQILLA_PREFIX/lib64" 2>/dev/null || true)}"
  lzma_library="${LZMA_LIBRARY:-$(find_library_file lzma "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)}"
  openssl_ssl_library="${OPENSSL_SSL_LIBRARY:-$(find_library_file ssl "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)}"
  openssl_crypto_library="${OPENSSL_CRYPTO_LIBRARY:-$(find_library_file crypto "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)}"
  openssl_libraries="$openssl_ssl_library;$openssl_crypto_library"
  genfit_base_dir="${GENFIT_BASE_DIR:-$SRC/genfit}"
  genfit_library="${GENFIT_LIBRARIES:-$(find_library_file genfit2 "$GENFIT_PREFIX/lib" "$GENFIT_PREFIX/lib64" "$BUILD/genfit/lib" "$BUILD/genfit/lib64" 2>/dev/null || true)}"

  if [ -z "$root_dir" ]; then
    echo "error: could not find ROOT CMake directory under $CONDA_PREFIX" >&2
    exit 2
  fi

  if [ -z "$xqilla_library" ]; then
    echo "error: could not find libxqilla under $XQILLA_PREFIX" >&2
    exit 2
  fi

  if [ -z "$lzma_library" ]; then
    echo "error: could not find liblzma under $CONDA_PREFIX" >&2
    exit 2
  fi

  if [ -z "$openssl_ssl_library" ]; then
    echo "error: could not find libssl under $CONDA_PREFIX" >&2
    exit 2
  fi

  if [ -z "$openssl_crypto_library" ]; then
    echo "error: could not find libcrypto under $CONDA_PREFIX" >&2
    exit 2
  fi

  if [ ! -f "$genfit_base_dir/cmake/genfit.cmake" ]; then
    echo "error: could not find GenFit source metadata under $genfit_base_dir" >&2
    exit 2
  fi

  if [ -z "$genfit_library" ]; then
    echo "error: could not find libgenfit2 under $GENFIT_PREFIX or $BUILD/genfit" >&2
    exit 2
  fi

  MUSE_CMAKE_ARGS=(
    -DCMAKE_INSTALL_PREFIX="$MUSE_PREFIX"
    -DCMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH_CMAKE"
    -DCMAKE_C_COMPILER="$CC"
    -DCMAKE_CXX_COMPILER="$CXX"
    -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"
    -DCMAKE_CXX_STANDARD="$CMAKE_CXX_STANDARD"
    -DCMAKE_CXX_STANDARD_REQUIRED=ON
    "-DCMAKE_INSTALL_RPATH=$XQILLA_PREFIX/lib;$CLHEP_PREFIX/lib;$GEANT4_PREFIX/lib;$GENFIT_PREFIX/lib;$MUSE_PREFIX/lib"
    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=OFF
    -DCMAKE_FIND_USE_PACKAGE_REGISTRY=FALSE
    -DCMAKE_FIND_USE_SYSTEM_PACKAGE_REGISTRY=FALSE
    -DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=FALSE
    "-DCMAKE_IGNORE_PREFIX_PATH=/opt/homebrew;/usr/local;$HOME/.muse"
    "-DCMAKE_SYSTEM_IGNORE_PREFIX_PATH=/opt/homebrew;/usr/local;$HOME/.muse"
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
    -DOPENSSL_LIBRARIES="$openssl_libraries"
    -DGeant4_DIR="$GEANT4_PREFIX/lib/cmake/Geant4"
    -DGENFIT_BASE_DIR="$genfit_base_dir"
    -DGENFIT_LIBRARIES="$genfit_library"
    -DGENFIT_LIBRARY_DIR="$(dirname "$genfit_library")"
    -DDo_G4PSI=ON
    -DDO_RADGEN=ON
    -DDO_ML=OFF
    -DDo_Tracking=On
  )
}
