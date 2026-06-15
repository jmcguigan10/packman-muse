#!/usr/bin/env bash
# Source-only Git checkout helper for pinned source builds.

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
      git -C "$srcdir" fetch --tags --depth="${GIT_DEPTH:-1}" origin "${ref:-$sha}" ||
        git -C "$srcdir" fetch --tags origin "${ref:-$sha}"
      git -C "$srcdir" checkout --detach "$sha"
    fi
  fi
}
