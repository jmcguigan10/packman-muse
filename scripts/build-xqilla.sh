#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"

stage="xqilla"
stamp_has "$stage" && {
  echo "$stage already built"
  exit 0
}

default_version="2.3.4"
default_url="https://sourceforge.net/projects/xqilla/files/XQilla-${default_version}.tar.gz/download"
default_sha256="292631791631fe2e7eb9727377335063a48f12611d641d0296697e0c075902eb"

version="${XQILLA_VERSION:-$default_version}"
url="${XQILLA_URL:-https://sourceforge.net/projects/xqilla/files/XQilla-${version}.tar.gz/download}"
sha256="${XQILLA_SHA256:-}"
if [ -z "$sha256" ] && [ "$version" = "$default_version" ] && [ "$url" = "$default_url" ]; then
  sha256="$default_sha256"
fi

archive="$SRC/XQilla-${version}.tar.gz"
srcdir="$SRC/XQilla-${version}"

if [ ! -f "$archive" ]; then
  curl -fL "$url" -o "$archive"
fi
verify_sha256 "$archive" "$sha256"

rm -rf "$srcdir"
mkdir -p "$srcdir"
tar -xzf "$archive" -C "$srcdir" --strip-components=1

refresh_gnuconfig_file() {
  local name="$1"
  local replacement=""
  local target
  local candidate

  for candidate in \
    "$CONDA_PREFIX/share/gnuconfig/$name" \
    "$CONDA_PREFIX/share/misc/$name"
  do
    if [ -f "$candidate" ]; then
      replacement="$candidate"
      break
    fi
  done

  if [ -z "$replacement" ]; then
    echo "warning: Pixi gnuconfig file not found: $name" >&2
    return 0
  fi

  while IFS= read -r target; do
    cp "$replacement" "$target"
    chmod +x "$target" 2>/dev/null || true
    echo "refreshed ${target#$ROOT/} from ${replacement#$CONDA_PREFIX/}"
  done < <(find "$srcdir" -name "$name" -type f -print)
}

refresh_gnuconfig_file config.sub
refresh_gnuconfig_file config.guess

configure_dir="$srcdir/${XQILLA_AUTOTOOLS_DIR:-autotools}"
if [ ! -x "$configure_dir/configure" ]; then
  configure_dir="$srcdir"
fi

cd "$configure_dir"

export CPPFLAGS="-I$CONDA_PREFIX/include ${CPPFLAGS:-}"
export CFLAGS="-O2 ${CFLAGS:-}"
export CXXFLAGS="-O2 -std=gnu++14 ${CXXFLAGS:-}"
export LDFLAGS="-L$CONDA_PREFIX/lib -Wl,-rpath,$CONDA_PREFIX/lib ${LDFLAGS:-}"

./configure \
  --prefix="$XQILLA_PREFIX" \
  --with-xerces="$CONDA_PREFIX"

make -j"$JOBS"
make install

stamp_done "$stage"
echo "$stage built into $XQILLA_PREFIX"
