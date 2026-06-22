#!/usr/bin/env bash

# Shared MUSE CMake cache seeds. This file is sourced after env.sh.

prepare_muse_source() {
  local repo="${MUSE_REPO:-git@github.com:jmcguigan10/muse.git}"
  local ref="${MUSE_REF:-impl/event-level-scatter}"
  local sha="${MUSE_SHA:-5d702e544980cc308a8f21fe15b4f3d6557d4bd9}"

  MUSE_SRCDIR="$SRC/muse"
  MUSE_BUILDDIR="$BUILD/muse"

  checkout_git_source "$repo" "$MUSE_SRCDIR" "$ref" "$sha"

  export MUSE_SRCDIR MUSE_BUILDDIR
}

prepare_muse_cmake_args() {
  local root_dir
  local xqilla_library
  local lzma_library
  local openssl_ssl_library
  local openssl_crypto_library
  local expat_library
  local zlib_library
  local genfit_base_dir
  local genfit_library
  local genfit_library_dir
  local geant4_dir
  local clhep_dir
  local ptl_dir
  local cmake_prefix_path_list

  root_dir="$(find_cmake_config_dir ROOT "$CONDA_PREFIX" "$CONDA_PREFIX/cmake" "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)"
  xqilla_library="$(find_library_file xqilla "$XQILLA_PREFIX/lib" "$XQILLA_PREFIX/lib64" 2>/dev/null || true)"
  lzma_library="$(find_library_file lzma "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)"
  openssl_ssl_library="$(find_library_file ssl "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)"
  openssl_crypto_library="$(find_library_file crypto "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)"
  expat_library="$(find_library_file expat "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)"
  zlib_library="$(find_library_file z "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)"
  genfit_base_dir="$SRC/genfit"
  genfit_library="$(find_library_file genfit2 "$GENFIT_PREFIX/lib" "$GENFIT_PREFIX/lib64" "$BUILD/genfit/lib" "$BUILD/genfit/lib64" 2>/dev/null || true)"
  geant4_dir="$(find_cmake_config_dir Geant4 "$GEANT4_PREFIX" "$GEANT4_PREFIX/lib" "$GEANT4_PREFIX/lib64" 2>/dev/null || true)"
  clhep_dir="$(find_cmake_config_dir CLHEP "$CLHEP_PREFIX" "$CLHEP_PREFIX/lib" "$CLHEP_PREFIX/lib64" 2>/dev/null || true)"
  ptl_dir="$(find_cmake_config_dir PTL "$GEANT4_PREFIX/lib/cmake/Geant4" "$GEANT4_PREFIX/lib64/cmake/Geant4" 2>/dev/null || true)"

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

  if [ -z "$expat_library" ]; then
    echo "error: could not find libexpat under $CONDA_PREFIX" >&2
    exit 2
  fi

  if [ -z "$zlib_library" ]; then
    echo "error: could not find libz under $CONDA_PREFIX" >&2
    exit 2
  fi

  if [ ! -x "$CLHEP_PREFIX/bin/clhep-config" ]; then
    echo "error: could not find clhep-config under $CLHEP_PREFIX" >&2
    exit 2
  fi

  if [ -z "$geant4_dir" ]; then
    echo "error: could not find Geant4Config.cmake under $GEANT4_PREFIX" >&2
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

  genfit_library_dir="$(dirname "$genfit_library")"
  cmake_prefix_path_list="$XQILLA_PREFIX;$CLHEP_PREFIX;$GEANT4_PREFIX;$GENFIT_PREFIX;$MUSE_PREFIX;$CONDA_PREFIX"

  MUSE_CMAKE_ARGS=(
    -DCMAKE_INSTALL_PREFIX="$MUSE_PREFIX"
    -DCMAKE_PREFIX_PATH="$cmake_prefix_path_list"
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
    "-DCMAKE_IGNORE_PREFIX_PATH=/opt/homebrew;/usr/local;$HOME/.muse;$HOME/Packages;$HOME/packages"
    "-DCMAKE_SYSTEM_IGNORE_PREFIX_PATH=/opt/homebrew;/usr/local;$HOME/.muse;$HOME/Packages;$HOME/packages"
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
    -DLZMA_BASE_DIR="$CONDA_PREFIX/include"
    -DLZMA_LIBRARIES="$lzma_library"
    -DOPENSSL_BASE_DIR="$CONDA_PREFIX/include"
    -DOPENSSL_LIBRARIES="$openssl_ssl_library"
    -DOPENSSL_SSL_LIBRARY="$openssl_ssl_library"
    -DOPENSSL_CRYPTO_LIBRARY="$openssl_crypto_library"
    -DEXPAT_INCLUDE_DIR="$CONDA_PREFIX/include"
    -DEXPAT_LIBRARY="$expat_library"
    -DEXPAT_LIBRARY_RELEASE="$expat_library"
    -DZLIB_INCLUDE_DIR="$CONDA_PREFIX/include"
    -DZLIB_LIBRARY="$zlib_library"
    -DGeant4_DIR="$geant4_dir"
    -DGENFIT_BASE_DIR="$genfit_base_dir"
    -DGENFIT_LIBRARIES="$genfit_library"
    -DGENFIT_LIBRARY_DIR="$genfit_library_dir"
    -DDo_G4PSI=ON
    -DDO_RADGEN=ON
    -DDO_ML=OFF
    -DDo_Tracking=ON
    -DWITH_GEANT4_UIVIS=OFF
  )

  if [ -n "$clhep_dir" ]; then
    MUSE_CMAKE_ARGS+=(-DCLHEP_DIR="$clhep_dir")
  fi

  if [ -n "$ptl_dir" ]; then
    MUSE_CMAKE_ARGS+=(-DPTL_DIR="$ptl_dir")
  fi
}
