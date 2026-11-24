#!/bin/sh
# Stamp the image version with the source commit, build date and branch name.
#
# Two things are written:
#
# 1. CONFIG_VERSION_CODE = r0-<short>
#    Keeps the LuCI revision short; the date/branch suffix is appended below.
#
# 2. files/etc/wrt_release + files/etc/uci-defaults/98-wrt-release
#    At first boot the uci-defaults script appends
#
#        <YYYYMMDD HHMMSS> - <branch> <commit>
#
#    to DISTRIB_DESCRIPTION, e.g.
#
#        ImmortalWrt 25.12-SNAPSHOT r0-458d2f7 20261124 231528 - chasey 458d2f7
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
STAMP=${VERSION_STAMP:-$(date '+%Y%m%d %H%M%S')}
CODE="r0-${SHORT}"

case "$(git -C "$SRC" remote get-url origin 2>/dev/null || true)" in
	*chasey-dev*) BRANCH=chasey ;;
	*LiBwrt*) BRANCH=LibWrt ;;
	*VIKINGYFY*) BRANCH=VIKINGYFY ;;
	*) BRANCH=$(git -C "$SRC" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown) ;;
esac

if grep -q '^CONFIG_VERSION_CODE=' "$CFG" 2>/dev/null; then
	tmp=$(mktemp)
	sed "s|^CONFIG_VERSION_CODE=.*|CONFIG_VERSION_CODE=\"${CODE}\"|" "$CFG" > "$tmp"
	mv "$tmp" "$CFG"
else
	printf 'CONFIG_VERSION_CODE="%s"\n' "$CODE" >> "$CFG"
fi

FILES="$SRC/files"
mkdir -p "$FILES/etc/uci-defaults"
cat > "$FILES/etc/wrt_release" <<EOF
BUILD_STAMP='$STAMP'
BUILD_BRANCH='$BRANCH'
SOURCE_REV='$SHORT'
EOF

cat > "$FILES/etc/uci-defaults/98-wrt-release" <<'EOS'
#!/bin/sh
# 版本号尾部追加：<YYYYMMDD HHMMSS> - <分支> <commit>
[ -f /etc/wrt_release ] || exit 0
. /etc/wrt_release

[ -f /etc/openwrt_release ] || : > /etc/openwrt_release

stamp="${BUILD_STAMP} - ${BUILD_BRANCH} ${SOURCE_REV}"
desc=$(sed -n "s/^DISTRIB_DESCRIPTION='\(.*\)'$/\1/p" /etc/openwrt_release)
[ -n "$desc" ] || desc="$DISTRIB_DESCRIPTION"

case "$desc" in
	*"$stamp"*) ;;
	*) desc="$desc $stamp" ;;
esac

if grep -q '^DISTRIB_DESCRIPTION=' /etc/openwrt_release; then
	sed -i "s|^DISTRIB_DESCRIPTION=.*|DISTRIB_DESCRIPTION='$desc'|" /etc/openwrt_release
else
	printf "DISTRIB_DESCRIPTION='%s'\n" "$desc" >> /etc/openwrt_release
fi

exit 0
EOS
chmod 0755 "$FILES/etc/uci-defaults/98-wrt-release"

echo "VERSION_CODE=${CODE} STAMP=${STAMP} BRANCH=${BRANCH} (${DATE})"
