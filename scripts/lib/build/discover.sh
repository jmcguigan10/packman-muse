#!/usr/bin/env bash
# Source-only discovery helpers for CMake package dirs and libraries.

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
