#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/env.sh"

stage="xqilla"
stamp_has "$stage" && {
  echo "$stage already built"
  exit 0
}

version="${XQILLA_VERSION:-2.3.4}"
url="${XQILLA_URL:-https://sourceforge.net/projects/xqilla/files/XQilla-${version}.tar.gz/download}"

archive="$SRC/XQilla-${version}.tar.gz"
srcdir="$SRC/XQilla-${version}"

if [ ! -f "$archive" ]; then
  curl -fL "$url" -o "$archive"
fi

rm -rf "$srcdir"
mkdir -p "$srcdir"
tar -xzf "$archive" -C "$srcdir" --strip-components=1

refresh_gnuconfig_file() {
  local name="$1"
  local replacement=""
  local target

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
