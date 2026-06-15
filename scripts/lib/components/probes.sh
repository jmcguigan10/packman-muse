#!/usr/bin/env bash
# Source-only host/runtime probe functions.

# shellcheck disable=SC2154

probe_host() {
  local compiler="${CXX:-c++}"
  local tmp="$BUILD/probe-host"

  for cmd in bash git curl make tar cmake pkg-config root-config gsl-config "$compiler"; do
    need_cmd "$cmd"
  done

  rm -rf "$tmp"
  mkdir -p "$tmp"

  cat >"$tmp/cxx20.cpp" <<'EOF'
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
}
