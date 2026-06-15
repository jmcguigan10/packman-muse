#!/usr/bin/env bash
# Source-only download helper for source tarballs.

download_if_missing() {
  local url="$1"
  local destination="$2"

  if [ ! -f "$destination" ]; then
    curl -fL "$url" -o "$destination"
  fi
}
