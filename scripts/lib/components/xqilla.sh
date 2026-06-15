#!/usr/bin/env bash
# Source-only XQilla build and probe functions.

# shellcheck disable=SC2154

build_xqilla() {
  local stage="xqilla"
  local archive="$SRC/XQilla-${XQILLA_VERSION}.tar.gz"
  local srcdir="$SRC/XQilla-${XQILLA_VERSION}"
  local configure_dir

  if stamp_has "$stage"; then
    echo "$stage already built"
    return 0
  fi

  download_if_missing "$XQILLA_URL" "$archive"
  verify_sha256 "$archive" "$XQILLA_SHA256"

  rm -rf "$srcdir"
  mkdir -p "$srcdir"
  tar -xzf "$archive" -C "$srcdir" --strip-components=1

  refresh_gnuconfig_file "$srcdir" config.sub
  refresh_gnuconfig_file "$srcdir" config.guess

  configure_dir="$srcdir/$XQILLA_AUTOTOOLS_DIR"
  if [ ! -x "$configure_dir/configure" ]; then
    configure_dir="$srcdir"
  fi

  cd "$configure_dir" || return

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
}

probe_xqilla() {
  local tmp="$BUILD/probe-xqilla"

  need_cmd xqilla

  rm -rf "$tmp"
  mkdir -p "$tmp"

  cat >"$tmp/test.xq" <<'EOF'
1 + 1
EOF

  xqilla "$tmp/test.xq" | grep -q "2"

  cat >"$tmp/link.cpp" <<'EOF'
#include <xqilla/xqilla-simple.hpp>

int main() {
  XQilla xqilla;
  return 0;
}
EOF

  "${CXX:-c++}" \
    -std=c++14 \
    "$tmp/link.cpp" \
    -I"$XQILLA_PREFIX/include" \
    -I"$CONDA_PREFIX/include" \
    -L"$XQILLA_PREFIX/lib" \
    -L"$CONDA_PREFIX/lib" \
    -Wl,-rpath,"$XQILLA_PREFIX/lib" \
    -Wl,-rpath,"$CONDA_PREFIX/lib" \
    -lxqilla \
    -lxerces-c \
    -o "$tmp/link-test"

  "$tmp/link-test"

  echo "xqilla probe passed"
}
