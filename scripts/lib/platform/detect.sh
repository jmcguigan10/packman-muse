#!/usr/bin/env bash
# Source-only platform normalization helpers.

detect_platform() {
  local os arch

  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os:$arch" in
    Linux:x86_64)
      echo "linux-x86_64"
      ;;
    Linux:aarch64 | Linux:arm64)
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
