#!/bin/sh
#
# rmac.sh - mtwifi MAC randomization helper (MT7981 dbdc)
#
# OpenWrt's built-in MAC randomization does not take effect with mtwifi.
# This script writes random locally-administered MACs directly into the
# per-band .dat files, then reloads WiFi.
#
# Per band: BssidNum + 1 MacAddress entries
#   MacAddress, MacAddress1, ... MacAddress<BssidNum>
# - existing entries are replaced
# - missing entries are appended
# - entries beyond BssidNum are dropped
#
# Usage:
#   rmac.sh [dat-file ...]
#
# Default when no argument is given:
#   /etc/wireless/mediatek/mt7981.dbdc.b0.dat   (2.4 GHz)
#   /etc/wireless/mediatek/mt7981.dbdc.b1.dat   (5 GHz)

if [ "$#" -gt 0 ]; then
    CONFIG_FILES="$*"
else
    CONFIG_FILES="
/etc/wireless/mediatek/mt7981.dbdc.b0.dat
/etc/wireless/mediatek/mt7981.dbdc.b1.dat
"
fi

# 生成随机本地管理 MAC
gen_mac() {
    b1=$(( (RANDOM % 256) & 0xFC | 0x02 ))
    b2=$(( RANDOM % 256 ))
    b3=$(( RANDOM % 256 ))
    b4=$(( RANDOM % 256 ))
    b5=$(( RANDOM % 256 ))
    b6=$(( RANDOM % 256 ))
    printf "%02x:%02x:%02x:%02x:%02x:%02x" \
        "$b1" "$b2" "$b3" "$b4" "$b5" "$b6"
}

for CONFIG_FILE in $CONFIG_FILES; do
    [ ! -f "$CONFIG_FILE" ] && {
        echo "ERROR: $CONFIG_FILE not found!" >&2
        exit 1
    }

    # BssidNum = 该频段 interface 数量；每个频段补 BssidNum + 1 个 MAC
    BSSID_NUM=$(grep '^BssidNum=' "$CONFIG_FILE" | head -1 | cut -d= -f2 | tr -d '\r')
    case "$BSSID_NUM" in
        ''|*[!0-9]*) BSSID_NUM=1 ;;
    esac

    MAC_MAX=$BSSID_NUM
    [ "$MAC_MAX" -lt 0 ] && MAC_MAX=0

    TEMP_FILE=$(mktemp)
    echo "== [$CONFIG_FILE] MAC randomization (BssidNum=$BSSID_NUM, MacAddress..MacAddress$MAC_MAX) ==" >&2

    # 使用 cat + while：保证 echo 到 console 的内容不会写进文件
    cat "$CONFIG_FILE" | while IFS= read -r line
    do
        if echo "$line" | grep -qE "^MacAddress[0-9]*="; then
            KEY=$(echo "$line" | cut -d= -f1)
            case "$KEY" in
                MacAddress) IDX=0 ;;
                MacAddress*) IDX=${KEY#MacAddress} ;;
                *) IDX=0 ;;
            esac
            case "$IDX" in
                ''|*[!0-9]*) IDX=0 ;;
            esac

            if [ "$IDX" -le "$MAC_MAX" ]; then
                NEW=$(gen_mac)
                echo "${KEY}=${NEW}"
                echo "[REPLACED] $KEY -> $NEW" >&2
            else
                echo "[DROPPED] $KEY (interface count=$BSSID_NUM)" >&2
            fi
        else
            echo "$line"
        fi
    done > "$TEMP_FILE"

    # 确保每个 interface 都有 MAC（0..MAC_MAX）
    i=0
    while [ "$i" -le "$MAC_MAX" ]; do
        if [ "$i" -eq 0 ]; then
            KEY="MacAddress"
        else
            KEY="MacAddress${i}"
        fi
        if ! grep -q "^${KEY}=" "$TEMP_FILE"; then
            NEW=$(gen_mac)
            echo "${KEY}=${NEW}" >> "$TEMP_FILE"
            echo "[ADDED] $KEY -> $NEW" >&2
        fi
        i=$((i + 1))
    done

    mv "$TEMP_FILE" "$CONFIG_FILE"
    echo "== [$CONFIG_FILE] MAC addresses ready ==" >&2
done

echo "Reload WiFi..." >&2
/sbin/wifi

echo "Done." >&2
exit 0
