#!/usr/bin/env bash
# Source-only source metadata defaults. Hashes are pinned for tar downloads.

: "${XQILLA_DEFAULT_VERSION:=2.3.4}"
: "${XQILLA_DEFAULT_URL:=https://sourceforge.net/projects/xqilla/files/XQilla-${XQILLA_DEFAULT_VERSION}.tar.gz/download}"
: "${XQILLA_DEFAULT_SHA256:=292631791631fe2e7eb9727377335063a48f12611d641d0296697e0c075902eb}"
: "${XQILLA_VERSION:=$XQILLA_DEFAULT_VERSION}"
: "${XQILLA_URL:=https://sourceforge.net/projects/xqilla/files/XQilla-${XQILLA_VERSION}.tar.gz/download}"
: "${XQILLA_SHA256:=}"
: "${XQILLA_AUTOTOOLS_DIR:=autotools}"

if [ -z "$XQILLA_SHA256" ] && [ "$XQILLA_VERSION" = "$XQILLA_DEFAULT_VERSION" ] && [ "$XQILLA_URL" = "$XQILLA_DEFAULT_URL" ]; then
  XQILLA_SHA256="$XQILLA_DEFAULT_SHA256"
fi

: "${CLHEP_REPO:=https://gitlab.cern.ch/CLHEP/CLHEP.git}"
: "${CLHEP_REF:=CLHEP_2_4_7_2}"
: "${CLHEP_SHA:=10fdf9b342265174b37db3bcb9a1fc79e585fde7}"

: "${GEANT4_DEFAULT_VERSION:=11.4.1}"
: "${GEANT4_DEFAULT_URL:=https://gitlab.cern.ch/geant4/geant4/-/archive/v${GEANT4_DEFAULT_VERSION}/geant4-v${GEANT4_DEFAULT_VERSION}.tar.gz}"
: "${GEANT4_DEFAULT_SHA256:=99dcf5f9d4f806fb8c4fde85cb2674a42e4ca19833143464ff7efa55c1852140}"
: "${GEANT4_VERSION:=$GEANT4_DEFAULT_VERSION}"
: "${GEANT4_URL:=https://gitlab.cern.ch/geant4/geant4/-/archive/v${GEANT4_VERSION}/geant4-v${GEANT4_VERSION}.tar.gz}"
: "${GEANT4_SHA256:=}"

if [ -z "$GEANT4_SHA256" ] && [ "$GEANT4_VERSION" = "$GEANT4_DEFAULT_VERSION" ] && [ "$GEANT4_URL" = "$GEANT4_DEFAULT_URL" ]; then
  GEANT4_SHA256="$GEANT4_DEFAULT_SHA256"
fi

: "${GENFIT_REPO:=git@github.com:MUSE-EXP/Genfit.git}"
: "${GENFIT_REF:=master}"
: "${GENFIT_SHA:=56e733ff1eacf76b9f2cf046bb424c228ab57129}"

: "${MUSE_REPO:=git@github.com:jmcguigan10/muse.git}"
: "${MUSE_REF:=impl/event-level-scatter}"
: "${MUSE_SHA:=d85c5aa6164b76565e3b40e94426f7ca89316edd}"
