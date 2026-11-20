#!/bin/sh
# Stamp the image version with the chasey source commit and build date.
#
# OpenWrt builds DISTRIB_DESCRIPTION from "%D %V %C" where %C is
# VERSION_CODE.  By default that is the source tree revision (r0-xxxxxxx),
# which does not tell different releases apart when the upstream commit
# has not changed.  Set CONFIG_VERSION_CODE to
#
#     r0-<chasey-short>-<YYYYMMDD>
#
# so the LuCI/ubus "firmware version" string identifies both the chasey
# node and the release date.
#
# Usage: scripts/stamp-version.sh <source-tree> [config-file]
set -eu

SRC=${1:?usage: stamp-version.sh <source-tree> [config-file]}
CFG=${2:-$SRC/.config}

if [ ! -d "$SRC/.git" ]; then
	echo "ERROR: $SRC is not a git tree" >&2
	exit 1
fi

SHORT=$(git -C "$SRC" rev-parse --short=7 HEAD)
DATE=${VERSION_DATE:-$(date +%Y%m%d)}
CODE="r0-${SHORT}-${DATE}"

if grep -q '^CONFIG_VERSION_CODE=' "$CFG" 2>/dev/null; then
	tmp=$(mktemp)
	sed "s|^CONFIG_VERSION_CODE=.*|CONFIG_VERSION_CODE=\"${CODE}\"|" "$CFG" > "$tmp"
	mv "$tmp" "$CFG"
else
	printf 'CONFIG_VERSION_CODE="%s"\n' "$CODE" >> "$CFG"
fi

echo "VERSION_CODE=${CODE}"
