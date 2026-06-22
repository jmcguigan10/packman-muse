#!/usr/bin/env bash
# Source-only MUSE/g4PSI CMake defaults.

: "${MUSE_DO_G4PSI:=ON}"
: "${MUSE_DO_RADGEN:=ON}"
: "${MUSE_DO_TIMEWALK:=ON}"
: "${MUSE_DO_ML:=OFF}"
: "${MUSE_DO_TRACKING:=On}"

: "${MUSE_FORBIDDEN_PREFIXES:=/opt/homebrew;/usr/local;$HOME/.muse}"
