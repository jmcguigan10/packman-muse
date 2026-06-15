#!/usr/bin/env bash
# Source-only helpers for old autotools source packages.

# shellcheck disable=SC2154

refresh_gnuconfig_file() {
  local srcdir="$1"
  local name="$2"
  local replacement=""
  local target
  local candidate

  for candidate in \
    "$CONDA_PREFIX/share/gnuconfig/$name" \
    "$CONDA_PREFIX/share/misc/$name"; do
    if [ -f "$candidate" ]; then
      replacement="$candidate"
      break
    fi
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
