#!/usr/bin/env bash
# Source-only runtime environment setup for local source-built prefixes.

# shellcheck disable=SC2154

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

configure_dependency_environment() {
  local pkg_config_paths
  local bins
  local libs

  pkg_config_paths="$XQILLA_PREFIX/lib/pkgconfig:$XQILLA_PREFIX/share/pkgconfig:$CLHEP_PREFIX/lib/pkgconfig:$CLHEP_PREFIX/share/pkgconfig:$GEANT4_PREFIX/lib/pkgconfig:$GEANT4_PREFIX/share/pkgconfig:$GENFIT_PREFIX/lib/pkgconfig:$GENFIT_PREFIX/share/pkgconfig:$MUSE_PREFIX/lib/pkgconfig:$MUSE_PREFIX/share/pkgconfig"
  bins="$XQILLA_PREFIX/bin:$CLHEP_PREFIX/bin:$GEANT4_PREFIX/bin:$GENFIT_PREFIX/bin:$MUSE_PREFIX/bin"
  libs="$XQILLA_PREFIX/lib:$XQILLA_PREFIX/lib64:$CLHEP_PREFIX/lib:$CLHEP_PREFIX/lib64:$GEANT4_PREFIX/lib:$GEANT4_PREFIX/lib64:$GENFIT_PREFIX/lib:$GENFIT_PREFIX/lib64:$MUSE_PREFIX/lib:$MUSE_PREFIX/lib64"

  export PKG_CONFIG_PATH="$pkg_config_paths:$CONDA_PREFIX/lib/pkgconfig:$CONDA_PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
  export PATH="$bins:$CONDA_PREFIX/bin:$PATH"

  case "$(uname -s)" in
    Linux)
      export LD_LIBRARY_PATH="$libs:$CONDA_PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      ;;
    Darwin)
      export DYLD_FALLBACK_LIBRARY_PATH="$libs:$CONDA_PREFIX/lib${DYLD_FALLBACK_LIBRARY_PATH:+:$DYLD_FALLBACK_LIBRARY_PATH}"
      ;;
  esac
}

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
