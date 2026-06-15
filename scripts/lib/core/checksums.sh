#!/usr/bin/env bash
# Source-only checksum helpers. Missing hashes are hard errors by design.

verify_sha256() {
  local file="$1"
  local expected="$2"

  if [ -z "$expected" ]; then
    die "missing SHA256 for $file"
  fi

  printf '%s  %s\n' "$expected" "$file" | shasum -a 256 -c -
}
