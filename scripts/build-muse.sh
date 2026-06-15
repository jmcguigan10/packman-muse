#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/env.sh"

stage="muse"
stamp_has "$stage" && {
  echo "$stage already built"
  exit 0
}

repo="${MUSE_REPO:-git@github.com:MUSE-EXP/MUSE.git}"
ref="${MUSE_REF:-master}"
sha="${MUSE_SHA:-37a7846d09fb44b7dff533a27ba242241de32504}"

srcdir="$SRC/muse"
builddir="$BUILD/muse"

checkout_git_source "$repo" "$srcdir" "$ref" "$sha"

rm -rf "$builddir"
mkdir -p "$builddir"

root_dir="${ROOT_DIR:-$(find_cmake_config_dir ROOT "$CONDA_PREFIX" "$CONDA_PREFIX/cmake" "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)}"
xqilla_library="${XQILLA_LIBRARY:-$(find_library_file xqilla "$XQILLA_PREFIX/lib" "$XQILLA_PREFIX/lib64" 2>/dev/null || true)}"
lzma_library="${LZMA_LIBRARY:-$(find_library_file lzma "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)}"
openssl_ssl_library="${OPENSSL_SSL_LIBRARY:-$(find_library_file ssl "$CONDA_PREFIX/lib" "$CONDA_PREFIX/lib64" 2>/dev/null || true)}"

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

cmake_args=(
  -DCMAKE_INSTALL_PREFIX="$MUSE_PREFIX"
  -DCMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH"
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
  -DLZMA_BASE_DIR="$CONDA_PREFIX/include"
  -DLZMA_LIBRARIES="$lzma_library"
  -DOPENSSL_BASE_DIR="$CONDA_PREFIX/include"
  -DOPENSSL_LIBRARIES="$openssl_ssl_library"
  -DGeant4_DIR="$GEANT4_PREFIX/lib/cmake/Geant4"
  -DDo_G4PSI=ON
  -DDO_RADGEN=ON
  -DDO_ML=OFF
  -DDo_Tracking=On
)

cmake -S "$srcdir" -B "$builddir" -G "$CMAKE_GENERATOR" "${cmake_args[@]}"
cmake --build "$builddir" --parallel "$JOBS"
cmake --install "$builddir"

stamp_done "$stage"
echo "$stage built into $MUSE_PREFIX"
