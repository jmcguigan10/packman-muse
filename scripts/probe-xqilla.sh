#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/env.sh
source "$SCRIPT_DIR/env.sh"

need_cmd xqilla

tmp="$BUILD/probe-xqilla"
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
