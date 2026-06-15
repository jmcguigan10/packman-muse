#!/usr/bin/env bash
# Source-only CMake helpers.

# CMake accepts semicolon lists for -D CMAKE_PREFIX_PATH, while the environment
# variable uses the host path separator. Keep both forms available.
configure_cmake_prefix_paths() {
  local preexisting="${CMAKE_PREFIX_PATH:-}"

  LOCAL_PREFIXES=(
    "$XQILLA_PREFIX"
    "$CLHEP_PREFIX"
    "$GEANT4_PREFIX"
    "$GENFIT_PREFIX"
    "$MUSE_PREFIX"
    "$CONDA_PREFIX"
  )

  LOCAL_CMAKE_PREFIXES_ENV="$(join_by_colon "${LOCAL_PREFIXES[@]}")"
  LOCAL_CMAKE_PREFIXES_CMAKE="$(join_by_semicolon "${LOCAL_PREFIXES[@]}")"

  export CMAKE_PREFIX_PATH="$LOCAL_CMAKE_PREFIXES_ENV${preexisting:+:$preexisting}"
  CMAKE_PREFIX_PATH_CMAKE="$LOCAL_CMAKE_PREFIXES_CMAKE"
  if [ -n "$preexisting" ]; then
    CMAKE_PREFIX_PATH_CMAKE="$CMAKE_PREFIX_PATH_CMAKE;$(printf '%s' "$preexisting" | tr ':' ';')"
  fi
  export CMAKE_PREFIX_PATH_CMAKE
}
