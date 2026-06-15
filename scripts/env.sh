#!/usr/bin/env bash
set -euo pipefail

: "${PIXI_PROJECT_ROOT:?Run this through pixi: ./scripts/pixi-local run <task>}"
: "${CONDA_PREFIX:?Pixi did not set CONDA_PREFIX}"

detect_platform() {
  local os arch

  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os:$arch" in
    Linux:x86_64)
      echo "linux-x86_64"
      ;;
    Linux:aarch64|Linux:arm64)
      echo "linux-aarch64"
      ;;
    Darwin:x86_64)
      echo "darwin-x86_64"
      ;;
    Darwin:arm64)
      echo "darwin-arm64"
      ;;
    *)
      echo "Unsupported platform: $os:$arch" >&2
      return 1
      ;;
  esac
}

pixi_platform_for() {
  local platform="$1"

  case "$platform" in
    linux-x86_64)
      echo "linux-64"
      ;;
    linux-aarch64)
      echo "linux-aarch64"
      ;;
    darwin-x86_64)
      echo "osx-64"
      ;;
    darwin-arm64)
      echo "osx-arm64"
      ;;
    *)
      echo "Unsupported build platform: $platform" >&2
      return 1
      ;;
  esac
}

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

ROOT="$PIXI_PROJECT_ROOT"
SRC="$ROOT/.install/src"
BUILD="$ROOT/.install/build"
STATE="$ROOT/.install/state"
LOGS="$ROOT/.install/logs"
INSTALL_DIR="$ROOT/.local/bin"

XQILLA_PREFIX="$ROOT/.local/bin/xqilla"
CLHEP_PREFIX="$ROOT/.local/bin/clhep"
GEANT4_PREFIX="$ROOT/.local/bin/geant4"
GENFIT_PREFIX="$ROOT/.local/bin/genfit"
MUSE_PREFIX="$ROOT/.local/bin/muse"
SHARED_PREFIX="$INSTALL_DIR/shared"

mkdir -p \
  "$SRC" "$BUILD" "$STATE" "$LOGS" "$INSTALL_DIR" \
  "$XQILLA_PREFIX" "$CLHEP_PREFIX" "$GEANT4_PREFIX" "$GENFIT_PREFIX" "$MUSE_PREFIX"

export ROOT SRC BUILD STATE LOGS INSTALL_DIR
export XQILLA_PREFIX CLHEP_PREFIX GEANT4_PREFIX GENFIT_PREFIX MUSE_PREFIX SHARED_PREFIX

configure_muse_runtime() {
  local muse_home="$INSTALL_DIR/.muse"
  local shared_link="$muse_home/shared"

  mkdir -p "$muse_home"

  if [ -e "$shared_link" ] && [ ! -L "$shared_link" ]; then
    echo "error: $shared_link exists and is not a symlink" >&2
    echo "hint: g4PSI expects shared data at \$COOKERHOME/.muse/shared" >&2
    exit 2
  fi

  ln -sfn "../shared" "$shared_link"
  export COOKERHOME="$INSTALL_DIR"
}

configure_muse_runtime

join_by_colon() {
  local IFS=:
  printf '%s' "$*"
}

join_by_semicolon() {
  local IFS=';'
  printf '%s' "$*"
}

LOCAL_PREFIXES=(
  "$XQILLA_PREFIX"
  "$CLHEP_PREFIX"
  "$GEANT4_PREFIX"
  "$GENFIT_PREFIX"
  "$MUSE_PREFIX"
  "$CONDA_PREFIX"
)

PREEXISTING_CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH:-}"
LOCAL_CMAKE_PREFIXES_ENV="$(join_by_colon "${LOCAL_PREFIXES[@]}")"
LOCAL_CMAKE_PREFIXES_CMAKE="$(join_by_semicolon "${LOCAL_PREFIXES[@]}")"
LOCAL_PKG_CONFIG_PATHS="$XQILLA_PREFIX/lib/pkgconfig:$XQILLA_PREFIX/share/pkgconfig:$CLHEP_PREFIX/lib/pkgconfig:$CLHEP_PREFIX/share/pkgconfig:$GEANT4_PREFIX/lib/pkgconfig:$GEANT4_PREFIX/share/pkgconfig:$GENFIT_PREFIX/lib/pkgconfig:$GENFIT_PREFIX/share/pkgconfig:$MUSE_PREFIX/lib/pkgconfig:$MUSE_PREFIX/share/pkgconfig"
LOCAL_BINS="$XQILLA_PREFIX/bin:$CLHEP_PREFIX/bin:$GEANT4_PREFIX/bin:$GENFIT_PREFIX/bin:$MUSE_PREFIX/bin"
LOCAL_LIBS="$XQILLA_PREFIX/lib:$XQILLA_PREFIX/lib64:$CLHEP_PREFIX/lib:$CLHEP_PREFIX/lib64:$GEANT4_PREFIX/lib:$GEANT4_PREFIX/lib64:$GENFIT_PREFIX/lib:$GENFIT_PREFIX/lib64:$MUSE_PREFIX/lib:$MUSE_PREFIX/lib64"

export CMAKE_PREFIX_PATH="$LOCAL_CMAKE_PREFIXES_ENV${PREEXISTING_CMAKE_PREFIX_PATH:+:$PREEXISTING_CMAKE_PREFIX_PATH}"
CMAKE_PREFIX_PATH_CMAKE="$LOCAL_CMAKE_PREFIXES_CMAKE"
if [ -n "$PREEXISTING_CMAKE_PREFIX_PATH" ]; then
  CMAKE_PREFIX_PATH_CMAKE="$CMAKE_PREFIX_PATH_CMAKE;$(printf '%s' "$PREEXISTING_CMAKE_PREFIX_PATH" | tr ':' ';')"
fi
export CMAKE_PREFIX_PATH_CMAKE
export PKG_CONFIG_PATH="$LOCAL_PKG_CONFIG_PATHS:$CONDA_PREFIX/lib/pkgconfig:$CONDA_PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export PATH="$LOCAL_BINS:$CONDA_PREFIX/bin:$PATH"

case "$(uname -s)" in
  Linux)
    export LD_LIBRARY_PATH="$LOCAL_LIBS:$CONDA_PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    ;;
  Darwin)
    export DYLD_FALLBACK_LIBRARY_PATH="$LOCAL_LIBS:$CONDA_PREFIX/lib${DYLD_FALLBACK_LIBRARY_PATH:+:$DYLD_FALLBACK_LIBRARY_PATH}"
    ;;
esac

configure_git_ssh_command() {
  if [ -n "${GIT_SSH_COMMAND:-}" ]; then
    return 0
  fi

  case "$(uname -s)" in
    Darwin)
      if [ -x /usr/bin/ssh ]; then
        export GIT_SSH_COMMAND="/usr/bin/ssh"
      else
        export GIT_SSH_COMMAND="ssh -o IgnoreUnknown=UseKeychain"
      fi
      ;;
    *)
      export GIT_SSH_COMMAND="ssh -o IgnoreUnknown=UseKeychain"
      ;;
  esac
}

configure_git_ssh_command

export CMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Release}"
export CMAKE_GENERATOR="${CMAKE_GENERATOR:-Ninja}"
export CMAKE_CXX_STANDARD="${CMAKE_CXX_STANDARD:-20}"
export CMAKE_CXX_STANDARD_REQUIRED=ON

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
  echo "error: could not find Pixi C compiler for $BUILD_PLATFORM ($PIXI_TARGET_PLATFORM)" >&2
  echo "hint: run ./scripts/pixi-local install, or set CC explicitly to override" >&2
  exit 2
fi

if [ -z "$CXX" ]; then
  echo "error: could not find Pixi C++ compiler for $BUILD_PLATFORM ($PIXI_TARGET_PLATFORM)" >&2
  echo "hint: run ./scripts/pixi-local install, or set CXX explicitly to override" >&2
  exit 2
fi

export CC CXX
[ -n "${FC:-}" ] && export FC
export CMAKE_C_COMPILER="${CMAKE_C_COMPILER:-$CC}"
export CMAKE_CXX_COMPILER="${CMAKE_CXX_COMPILER:-$CXX}"
[ -n "${FC:-}" ] && export CMAKE_Fortran_COMPILER="${CMAKE_Fortran_COMPILER:-$FC}"

if command -v getconf >/dev/null 2>&1; then
  JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"
elif command -v sysctl >/dev/null 2>&1; then
  JOBS="${JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || echo 4)}"
else
  JOBS="${JOBS:-4}"
fi

export JOBS
export CMAKE_BUILD_PARALLEL_LEVEL="$JOBS"

stamp_done() {
  touch "$STATE/$1.done"
}

stamp_has() {
  test -f "$STATE/$1.done"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: missing command: $1" >&2
    exit 1
  }
}

verify_sha256() {
  local file="$1"
  local expected="$2"

  if [ -z "$expected" ]; then
    echo "error: missing SHA256 for $file" >&2
    exit 2
  fi

  printf '%s  %s\n' "$expected" "$file" | shasum -a 256 -c -
}

checkout_git_source() {
  local repo="$1"
  local srcdir="$2"
  local ref="${3:-}"
  local sha="${4:-}"
  local current_url

  if [ ! -d "$srcdir/.git" ]; then
    if [ -n "$ref" ]; then
      git clone --branch "$ref" --depth="${GIT_DEPTH:-1}" "$repo" "$srcdir"
    else
      git clone --depth="${GIT_DEPTH:-1}" "$repo" "$srcdir"
    fi
  fi

  current_url="$(git -C "$srcdir" remote get-url origin 2>/dev/null || true)"
  if [ "$current_url" != "$repo" ]; then
    echo "error: $srcdir origin is '$current_url', expected '$repo'" >&2
    echo "hint: remove '$srcdir' or run:" >&2
    echo "  git -C '$srcdir' remote set-url origin '$repo'" >&2
    exit 2
  fi

  if [ -n "$sha" ]; then
    local current
    current="$(git -C "$srcdir" rev-parse HEAD)"
    if [ "$current" != "$sha" ]; then
      git -C "$srcdir" fetch --tags --depth="${GIT_DEPTH:-1}" origin "${ref:-$sha}" \
        || git -C "$srcdir" fetch --tags origin "${ref:-$sha}"
      git -C "$srcdir" checkout --detach "$sha"
    fi
  fi
}

find_cmake_package_dir() {
  local pattern="$1"
  shift

  local base
  local result
  for base in "$@"; do
    [ -d "$base" ] || continue
    result="$(find "$base" -path "$pattern" -type d -print -quit 2>/dev/null || true)"
    if [ -n "$result" ]; then
      printf '%s\n' "$result"
      return 0
    fi
  done

  return 1
}

find_cmake_config_dir() {
  local package="$1"
  shift

  local base
  local result
  for base in "$@"; do
    [ -d "$base" ] || continue
    result="$(
      find "$base" \
        \( -name "${package}Config.cmake" -o -name "${package}-config.cmake" \) \
        -type f -print -quit 2>/dev/null || true
    )"
    if [ -n "$result" ]; then
      dirname "$result"
      return 0
    fi
  done

  return 1
}

find_library_file() {
  local stem="$1"
  shift

  local base
  local result
  for base in "$@"; do
    [ -d "$base" ] || continue
    result="$(
      find "$base" \
        \( -type f -o -type l \) \
        \( \
          -name "lib${stem}.dylib" -o \
          -name "lib${stem}.*.dylib" -o \
          -name "lib${stem}.so" -o \
          -name "lib${stem}.so.*" -o \
          -name "lib${stem}.a" \
        \) \
        -print -quit 2>/dev/null || true
    )"
    if [ -n "$result" ]; then
      printf '%s\n' "$result"
      return 0
    fi
  done

  return 1
}
