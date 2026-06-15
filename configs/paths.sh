#!/usr/bin/env bash
# Source-only path defaults. Values are repo-relative unless noted otherwise.

: "${SOURCE_DIR:=.install/src}"
: "${BUILD_DIR:=.install/build}"
: "${STATE_DIR:=.install/state}"
: "${LOG_DIR:=.install/logs}"
: "${INSTALL_DIR_REL:=.local/bin}"

: "${XQILLA_PREFIX_REL:=$INSTALL_DIR_REL/xqilla}"
: "${CLHEP_PREFIX_REL:=$INSTALL_DIR_REL/clhep}"
: "${GEANT4_PREFIX_REL:=$INSTALL_DIR_REL/geant4}"
: "${GENFIT_PREFIX_REL:=$INSTALL_DIR_REL/genfit}"
: "${MUSE_PREFIX_REL:=$INSTALL_DIR_REL/muse}"
: "${SHARED_PREFIX_REL:=$INSTALL_DIR_REL/shared}"
