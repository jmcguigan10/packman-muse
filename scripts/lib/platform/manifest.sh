#!/usr/bin/env bash
# Source-only helpers for the Pixi current-platform manifest rewrite.

detect_pixi_platform() {
  local os arch

  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os:$arch" in
    Linux:x86_64)
      echo "linux-64"
      ;;
    Linux:aarch64 | Linux:arm64)
      echo "linux-aarch64"
      ;;
    Darwin:x86_64)
      echo "osx-64"
      ;;
    Darwin:arm64)
      echo "osx-arm64"
      ;;
    *)
      echo "Unsupported platform: $os:$arch" >&2
      return 1
      ;;
  esac
}

rewrite_pixi_manifest_for_platform() {
  local manifest="$1"
  local platform="$2"
  local tmp status

  tmp="$(mktemp "${TMPDIR:-/tmp}/pixi-platform.XXXXXX")"

  if ! awk -v platform="$platform" '
    BEGIN {
      in_workspace = 0
      replaced = 0
      inserted_target = 0
      skip_target = 0
    }

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
      if (skip_target) {
        skip_target = 0
      }

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

    skip_target {
      next
    }

    in_workspace && /^[[:space:]]*platforms[[:space:]]*=/ {
      print "platforms = [\"" platform "\"]"
      replaced = 1
      next
    }

    {
      print
    }

    END {
      if (!replaced) {
        exit 42
      }
      emit_current_compiler_target()
    }
  ' "$manifest" >"$tmp"; then
    status=$?
    rm -f "$tmp"
    if [ "$status" -eq 42 ]; then
      echo "error: could not find [workspace] platforms line in $manifest" >&2
    fi
    exit "$status"
  fi

  if cmp -s "$manifest" "$tmp"; then
    rm -f "$tmp"
  else
    mv "$tmp" "$manifest"
    echo "Set Pixi workspace platform to $platform"
  fi
}
