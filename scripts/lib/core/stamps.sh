#!/usr/bin/env bash
# Source-only build stamp helpers.

# shellcheck disable=SC2154

stamp_done() {
  touch "$STATE/$1.done"
}

stamp_has() {
  test -f "$STATE/$1.done"
}
