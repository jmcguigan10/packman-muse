#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/env.sh"

need_cmd xqilla

tmp="$BUILD/probe-xqilla"
rm -rf "$tmp"
mkdir -p "$tmp"

cat > "$tmp/test.xq" <<'EOF'
1 + 1
EOF

xqilla "$tmp/test.xq" | grep -q "2"

cat > "$tmp/link.cpp" <<'EOF'
#include <xercesc/util/PlatformUtils.hpp>

int main() {
    xercesc::XMLPlatformUtils::Initialize();
    xercesc::XMLPlatformUtils::Terminate();
    return 0;
}
EOF

"${CXX:-c++}" \
  -std=c++20 \
  "$tmp/link.cpp" \
  -I"$CONDA_PREFIX/include" \
  -I"$XQILLA_PREFIX/include" \
  -L"$CONDA_PREFIX/lib" \
  -L"$XQILLA_PREFIX/lib" \
  -lxqilla \
  -lxerces-c \
  -o "$tmp/link"

"$tmp/link"

echo "xqilla probe passed"
