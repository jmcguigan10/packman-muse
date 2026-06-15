#!/usr/bin/env bash
# Shared host platform, Pixi manifest, and compiler-selection helpers.

# shellcheck disable=SC2154

detect_platform() {
  case "$(uname -s):$(uname -m)" in
    Linux:x86_64) echo "linux-x86_64" ;;
    Linux:aarch64 | Linux:arm64) echo "linux-aarch64" ;;
    Darwin:x86_64) echo "darwin-x86_64" ;;
    Darwin:arm64) echo "darwin-arm64" ;;
    *)
      echo "Unsupported platform: $(uname -s):$(uname -m)" >&2
      return 1
      ;;
  esac
}

pixi_platform_for() {
  case "$1" in
    linux-x86_64) echo "linux-64" ;;
    linux-aarch64) echo "linux-aarch64" ;;
    darwin-x86_64) echo "osx-64" ;;
    darwin-arm64) echo "osx-arm64" ;;
    *)
      echo "Unsupported build platform: $1" >&2
      return 1
      ;;
  esac
}

detect_pixi_platform() {
  pixi_platform_for "$(detect_platform)"
}

rewrite_pixi_manifest_for_platform() {
  local manifest="$1"
  local platform="$2"
  local tmp status

  tmp="$(mktemp "${TMPDIR:-/tmp}/pixi-platform.XXXXXX")"

  if ! awk -v platform="$platform" '
    BEGIN { in_workspace = replaced = inserted_target = skip_target = 0 }
    function is_managed_compiler_target(line) {
      return line ~ /^\[target\.(linux-64|linux-aarch64|osx-64|osx-arm64)\.dependencies\]$/
    }
    function emit_current_compiler_target() {
      if (!inserted_target) {
        print "[target." platform ".dependencies]"
        print "c-compiler = \"*\""
        print "cxx-compiler = \"*\""
        print ""
        inserted_target = 1
      }
    }
    /^\[[^]]+\]$/ {
      if (skip_target) skip_target = 0
      if (is_managed_compiler_target($0)) {
        skip_target = 1
        in_workspace = 0
        next
      }
      if (!inserted_target && ($0 ~ /^\[feature\./ || $0 == "[environments]" || $0 == "[tasks]")) {
        emit_current_compiler_target()
      }
      in_workspace = ($0 == "[workspace]")
    }
    skip_target { next }
    in_workspace && /^[[:space:]]*platforms[[:space:]]*=/ {
      print "platforms = [\"" platform "\"]"
      replaced = 1
      next
    }
    { print }
    END {
      if (!replaced) exit 42
      emit_current_compiler_target()
    }
  ' "$manifest" >"$tmp"; then
    status=$?
    rm -f "$tmp"
    [ "$status" -ne 42 ] || echo "error: could not find [workspace] platforms line in $manifest" >&2
    exit "$status"
  fi

  if cmp -s "$manifest" "$tmp"; then
    rm -f "$tmp"
  else
    mv "$tmp" "$manifest"
    echo "Set Pixi workspace platform to $platform"
  fi
}

first_executable() {
  local candidate
  for candidate in "$@"; do
    [ -n "$candidate" ] || continue
    [ ! -x "$candidate" ] || {
      printf '%s\n' "$candidate"
      return 0
    }
    command -v "$candidate" >/dev/null 2>&1 || continue
    command -v "$candidate"
    return 0
  done
  return 1
}

first_matching_executable() {
  find "$CONDA_PREFIX/bin" -maxdepth 1 \( -type f -o -type l \) -name "$1" -perm -111 -print -quit 2>/dev/null
}

select_platform_tool() {
  local mode="path"
  local pattern

  case "$1:$2" in
    cc:linux-x86_64) pattern="$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-cc" ;;
    cxx:linux-x86_64) pattern="$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-c++" ;;
    fc:linux-x86_64) pattern="$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-gfortran" ;;
    cc:linux-aarch64) pattern="$CONDA_PREFIX/bin/aarch64-conda-linux-gnu-cc" ;;
    cxx:linux-aarch64) pattern="$CONDA_PREFIX/bin/aarch64-conda-linux-gnu-c++" ;;
    fc:linux-aarch64) pattern="$CONDA_PREFIX/bin/aarch64-conda-linux-gnu-gfortran" ;;
    cc:darwin-x86_64)
      mode="glob"
      pattern="x86_64-apple-darwin*-clang"
      ;;
    cxx:darwin-x86_64)
      mode="glob"
      pattern="x86_64-apple-darwin*-clang++"
      ;;
    fc:darwin-x86_64)
      mode="glob"
      pattern="x86_64-apple-darwin*-gfortran"
      ;;
    cc:darwin-arm64)
      mode="glob"
      pattern="arm64-apple-darwin*-clang"
      ;;
    cxx:darwin-arm64)
      mode="glob"
      pattern="arm64-apple-darwin*-clang++"
      ;;
    fc:darwin-arm64)
      mode="glob"
      pattern="arm64-apple-darwin*-gfortran"
      ;;
    *) return 1 ;;
  esac

  if [ "$mode" = glob ]; then
    first_matching_executable "$pattern"
  else
    first_executable "$pattern"
  fi
}

configure_toolchain() {
  BUILD_PLATFORM="$(detect_platform)"
  PIXI_TARGET_PLATFORM="$(pixi_platform_for "$BUILD_PLATFORM")"
  export BUILD_PLATFORM PIXI_TARGET_PLATFORM

  [ -n "${CC:-}" ] || CC="$(select_platform_tool cc "$BUILD_PLATFORM" || true)"
  [ -n "${CXX:-}" ] || CXX="$(select_platform_tool cxx "$BUILD_PLATFORM" || true)"
  [ -n "${FC:-}" ] || FC="$(select_platform_tool fc "$BUILD_PLATFORM" 2>/dev/null || true)"

  require_nonempty "$CC" "could not find Pixi C compiler for $BUILD_PLATFORM ($PIXI_TARGET_PLATFORM)"
  require_nonempty "$CXX" "could not find Pixi C++ compiler for $BUILD_PLATFORM ($PIXI_TARGET_PLATFORM)"

  export CC CXX
  [ -n "${FC:-}" ] && export FC
  export CMAKE_C_COMPILER="${CMAKE_C_COMPILER:-$CC}"
  export CMAKE_CXX_COMPILER="${CMAKE_CXX_COMPILER:-$CXX}"
  [ -n "${FC:-}" ] && export CMAKE_Fortran_COMPILER="${CMAKE_Fortran_COMPILER:-$FC}"
}

configure_jobs() {
  if [ "$JOBS" = "auto" ]; then
    local detected_jobs

    if command -v getconf >/dev/null 2>&1; then
      detected_jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"
    elif command -v sysctl >/dev/null 2>&1; then
      detected_jobs="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
    else
      detected_jobs=4
    fi

    JOBS="$((detected_jobs > 1 ? detected_jobs - 1 : 1))"
  fi

  export JOBS
  export CMAKE_BUILD_PARALLEL_LEVEL="$JOBS"
}
