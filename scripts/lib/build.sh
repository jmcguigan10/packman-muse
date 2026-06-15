#!/usr/bin/env bash
# Shared source download, checkout, discovery, and runtime helpers.

# shellcheck disable=SC2154

download_if_missing() {
  [ -f "$2" ] || curl -fL "$1" -o "$2"
}

refresh_gnuconfig_file() {
  local srcdir="$1"
  local name="$2"
  local replacement=""
  local target
  local candidate

  for candidate in "$CONDA_PREFIX/share/gnuconfig/$name" "$CONDA_PREFIX/share/misc/$name"; do
    [ ! -f "$candidate" ] || {
      replacement="$candidate"
      break
    }
  done

  if [ -z "$replacement" ]; then
    warn "Pixi gnuconfig file not found: $name"
    return 0
  fi

  while IFS= read -r target; do
    cp "$replacement" "$target"
    chmod +x "$target" 2>/dev/null || true
    echo "refreshed ${target#"$ROOT"/} from ${replacement#"$CONDA_PREFIX"/}"
  done < <(find "$srcdir" -name "$name" -type f -print)
}

checkout_git_source() {
  local repo="$1"
  local srcdir="$2"
  local ref="${3:-}"
  local sha="${4:-}"
  local clone_args
  local current_url
  local fetch_target

  if [ ! -d "$srcdir/.git" ]; then
    clone_args=(clone --depth="${GIT_DEPTH:-1}")
    [ -z "$ref" ] || clone_args+=(--branch "$ref")
    git "${clone_args[@]}" "$repo" "$srcdir"
  fi

  current_url="$(git -C "$srcdir" remote get-url origin 2>/dev/null || true)"
  if [ "$current_url" != "$repo" ]; then
    echo "error: $srcdir origin is '$current_url', expected '$repo'" >&2
    echo "hint: remove '$srcdir' or run:" >&2
    echo "  git -C '$srcdir' remote set-url origin '$repo'" >&2
    exit 2
  fi

  if [ -n "$sha" ] && [ "$(git -C "$srcdir" rev-parse HEAD)" != "$sha" ]; then
    fetch_target="$sha"
    git -C "$srcdir" fetch --tags --depth="${GIT_DEPTH:-1}" origin "$fetch_target" ||
      git -C "$srcdir" fetch --tags origin "$fetch_target" ||
      {
        fetch_target="${ref:-HEAD}"
        git -C "$srcdir" fetch --tags --depth="${GIT_DEPTH:-1}" origin "$fetch_target" ||
          git -C "$srcdir" fetch --tags origin "$fetch_target"
      }
    git -C "$srcdir" checkout --detach "$sha"
  fi
}

find_cmake_config_dir() {
  local package="$1"
  local base
  local result
  shift

  for base in "$@"; do
    [ -d "$base" ] || continue
    result="$(find "$base" \( -name "${package}Config.cmake" -o -name "${package}-config.cmake" \) -type f -print -quit 2>/dev/null || true)"
    [ -z "$result" ] || {
      dirname "$result"
      return 0
    }
  done
  return 1
}

find_library_file() {
  local stem="$1"
  local base
  local result
  shift

  for base in "$@"; do
    [ -d "$base" ] || continue
    result="$(
      find "$base" \
        \( -type f -o -type l \) \
        \( -name "lib${stem}.dylib" -o -name "lib${stem}.*.dylib" -o \
        -name "lib${stem}.so" -o -name "lib${stem}.so.*" -o -name "lib${stem}.a" \) \
        -print -quit 2>/dev/null || true
    )"
    [ -z "$result" ] || {
      printf '%s\n' "$result"
      return 0
    }
  done
  return 1
}

configure_cmake_prefix_paths() {
  local preexisting="${CMAKE_PREFIX_PATH:-}"

  LOCAL_PREFIXES=("$XQILLA_PREFIX" "$CLHEP_PREFIX" "$GEANT4_PREFIX" "$GENFIT_PREFIX" "$MUSE_PREFIX" "$CONDA_PREFIX")
  LOCAL_CMAKE_PREFIXES_ENV="$(join_by_colon "${LOCAL_PREFIXES[@]}")"
  LOCAL_CMAKE_PREFIXES_CMAKE="$(join_by_semicolon "${LOCAL_PREFIXES[@]}")"

  export CMAKE_PREFIX_PATH="$LOCAL_CMAKE_PREFIXES_ENV${preexisting:+:$preexisting}"
  CMAKE_PREFIX_PATH_CMAKE="$LOCAL_CMAKE_PREFIXES_CMAKE"
  [ -z "$preexisting" ] || CMAKE_PREFIX_PATH_CMAKE="$CMAKE_PREFIX_PATH_CMAKE;$(printf '%s' "$preexisting" | tr ':' ';')"
  export CMAKE_PREFIX_PATH_CMAKE
}

configure_muse_runtime() {
  local muse_home="$INSTALL_DIR/.muse"
  local shared_link="$muse_home/shared"

  mkdir -p "$muse_home"
  if [ -e "$shared_link" ] && [ ! -L "$shared_link" ]; then
    die "$shared_link exists and is not a symlink; g4PSI expects shared data at \$COOKERHOME/.muse/shared"
  fi

  ln -sfn "../shared" "$shared_link"
  export COOKERHOME="$INSTALL_DIR"
}

configure_dependency_environment() {
  local prefixes=("$XQILLA_PREFIX" "$CLHEP_PREFIX" "$GEANT4_PREFIX" "$GENFIT_PREFIX" "$MUSE_PREFIX")
  local pkg_config_paths=()
  local bins=()
  local libs=()
  local prefix

  for prefix in "${prefixes[@]}"; do
    pkg_config_paths+=("$prefix/lib/pkgconfig" "$prefix/share/pkgconfig")
    bins+=("$prefix/bin")
    libs+=("$prefix/lib" "$prefix/lib64")
  done

  PKG_CONFIG_PATH="$(join_by_colon "${pkg_config_paths[@]}"):$CONDA_PREFIX/lib/pkgconfig:$CONDA_PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
  PATH="$(join_by_colon "${bins[@]}"):$CONDA_PREFIX/bin:$PATH"
  export PKG_CONFIG_PATH PATH

  case "$(uname -s)" in
    Linux)
      LD_LIBRARY_PATH="$(join_by_colon "${libs[@]}"):$CONDA_PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      export LD_LIBRARY_PATH
      ;;
    Darwin)
      DYLD_FALLBACK_LIBRARY_PATH="$(join_by_colon "${libs[@]}"):$CONDA_PREFIX/lib${DYLD_FALLBACK_LIBRARY_PATH:+:$DYLD_FALLBACK_LIBRARY_PATH}"
      export DYLD_FALLBACK_LIBRARY_PATH
      ;;
  esac
}

configure_git_ssh_command() {
  [ -z "${GIT_SSH_COMMAND:-}" ] || return 0

  if [ "$(uname -s)" = Darwin ] && [ -x /usr/bin/ssh ]; then
    export GIT_SSH_COMMAND="/usr/bin/ssh"
  else
    export GIT_SSH_COMMAND="ssh -o IgnoreUnknown=UseKeychain"
  fi
}
