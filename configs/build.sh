#!/usr/bin/env bash
# Source-only build defaults. Callers may override any value before sourcing.

: "${CMAKE_BUILD_TYPE:=Release}"
: "${CMAKE_GENERATOR:=Ninja}"
: "${CMAKE_CXX_STANDARD:=20}"
: "${CMAKE_CXX_STANDARD_REQUIRED:=ON}"
: "${JOBS:=auto}"
