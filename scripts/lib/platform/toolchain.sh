#!/usr/bin/env bash
# Source-only Pixi toolchain selection helpers.

# shellcheck disable=SC2154

first_executable() {
  local candidate
  for candidate in "$@"; do
    [ -n "$candidate" ] || continue
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
    if command -v "$candidate" >/dev/null 2>&1; then
      command -v "$candidate"
      return 0
    fi
  done

  return 1
}

first_matching_executable() {
  local pattern="$1"
  local match

  match="$(find "$CONDA_PREFIX/bin" -maxdepth 1 \( -type f -o -type l \) -name "$pattern" -perm -111 -print -quit 2>/dev/null || true)"
  if [ -n "$match" ]; then
    printf '%s\n' "$match"
    return 0
  fi

  return 1
}

select_platform_tool() {
  local tool_kind="$1"
  local platform="$2"

  case "$tool_kind:$platform" in
    cc:linux-x86_64)
      first_executable "$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-cc"
      ;;
    cxx:linux-x86_64)
      first_executable "$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-c++"
      ;;
    cc:linux-aarch64)
      first_executable "$CONDA_PREFIX/bin/aarch64-conda-linux-gnu-cc"
      ;;
    cxx:linux-aarch64)
      first_executable "$CONDA_PREFIX/bin/aarch64-conda-linux-gnu-c++"
      ;;
    cc:darwin-x86_64)
      first_matching_executable "x86_64-apple-darwin*-clang"
      ;;
    cxx:darwin-x86_64)
      first_matching_executable "x86_64-apple-darwin*-clang++"
      ;;
    cc:darwin-arm64)
      first_matching_executable "arm64-apple-darwin*-clang"
      ;;
    cxx:darwin-arm64)
      first_matching_executable "arm64-apple-darwin*-clang++"
      ;;
    fc:linux-x86_64)
      first_executable "$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-gfortran"
      ;;
    fc:linux-aarch64)
      first_executable "$CONDA_PREFIX/bin/aarch64-conda-linux-gnu-gfortran"
      ;;
    fc:darwin-x86_64)
      first_matching_executable "x86_64-apple-darwin*-gfortran"
      ;;
    fc:darwin-arm64)
      first_matching_executable "arm64-apple-darwin*-gfortran"
      ;;
    *)
      return 1
      ;;
  esac
}

configure_toolchain() {
  BUILD_PLATFORM="$(detect_platform)"
  PIXI_TARGET_PLATFORM="$(pixi_platform_for "$BUILD_PLATFORM")"
  export BUILD_PLATFORM PIXI_TARGET_PLATFORM

  if [ -z "${CC:-}" ]; then
    CC="$(select_platform_tool cc "$BUILD_PLATFORM" || true)"
  fi
  if [ -z "${CXX:-}" ]; then
    CXX="$(select_platform_tool cxx "$BUILD_PLATFORM" || true)"
  fi
  if [ -z "${FC:-}" ]; then
    FC="$(select_platform_tool fc "$BUILD_PLATFORM" 2>/dev/null || true)"
  fi

  if [ -z "$CC" ]; then
    die "could not find Pixi C compiler for $BUILD_PLATFORM ($PIXI_TARGET_PLATFORM)"
  fi

  if [ -z "$CXX" ]; then
    die "could not find Pixi C++ compiler for $BUILD_PLATFORM ($PIXI_TARGET_PLATFORM)"
  fi

  export CC CXX
  [ -n "${FC:-}" ] && export FC
  export CMAKE_C_COMPILER="${CMAKE_C_COMPILER:-$CC}"
  export CMAKE_CXX_COMPILER="${CMAKE_CXX_COMPILER:-$CXX}"
  [ -n "${FC:-}" ] && export CMAKE_Fortran_COMPILER="${CMAKE_Fortran_COMPILER:-$FC}"
}

configure_jobs() {
  if [ "$JOBS" = "auto" ]; then
    if command -v getconf >/dev/null 2>&1; then
      JOBS="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"
    elif command -v sysctl >/dev/null 2>&1; then
      JOBS="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
    else
      JOBS=4
    fi
  fi

  export JOBS
  export CMAKE_BUILD_PARALLEL_LEVEL="$JOBS"
}
