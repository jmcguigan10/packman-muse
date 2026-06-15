#!/usr/bin/env bash
# Source-only GenFit build function.

# shellcheck disable=SC2154

build_genfit() {
  local stage="genfit"
  local srcdir="$SRC/genfit"
  local builddir="$BUILD/genfit"
  local root_dir
  local cmake_args

  if stamp_has "$stage"; then
    echo "$stage already built"
    return 0
  fi

  checkout_git_source "$GENFIT_REPO" "$srcdir" "$GENFIT_REF" "$GENFIT_SHA"

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
}
