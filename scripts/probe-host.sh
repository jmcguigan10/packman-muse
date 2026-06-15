#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"

compiler="${CXX:-c++}"

for cmd in bash git curl make tar cmake pkg-config root-config gsl-config "$compiler"; do
  need_cmd "$cmd"
done

tmp="$BUILD/probe-host"
rm -rf "$tmp"
mkdir -p "$tmp"

cat > "$tmp/cxx20.cpp" <<'EOF'
#include <concepts>
#include <span>
#include <ranges>
#include <vector>

template <class T>
concept Number = std::integral<T> || std::floating_point<T>;

int main() {
    std::vector<int> v{1,2,3};
    std::span<int> s(v);
    auto r = s | std::views::filter([](int x){ return x > 1; });
    return *r.begin() == 2 ? 0 : 1;
}
EOF

"$compiler" -std=c++20 "$tmp/cxx20.cpp" -o "$tmp/cxx20"

"$tmp/cxx20"

echo "host probe passed"
