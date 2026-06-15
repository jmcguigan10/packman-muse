#!/usr/bin/env bash
exec "$(dirname "$0")/dispatch.sh" "${0##*/}" "$@"
