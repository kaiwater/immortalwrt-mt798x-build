# mtwifi MAC 随机化（rmac）

## 背景

mtwifi 驱动不会使用 OpenWrt 自带的 MAC 随机化配置，接口 MAC 直接来自各频段的 `.dat` 文件。
因此需要在每次刷机/升级后，把随机 MAC 写进 `.dat`，再重载 WiFi。

脚本位置：[scripts/utils/rmac.sh](../scripts/utils/rmac.sh)

## 文件与规则

| 文件 | 频段 |
| --- | --- |
| `/etc/wireless/mediatek/mt7981.dbdc.b0.dat` | 2.4 GHz |
| `/etc/wireless/mediatek/mt7981.dbdc.b1.dat` | 5 GHz |

每个频段按自己的 `BssidNum` 处理：

- 生成 `MacAddress`、`MacAddress1` … `MacAddress<BssidNum>`，共 `BssidNum + 1` 条
- 已存在的条目：替换为新 MAC
- 缺失的条目：追加
- 索引超过 `BssidNum` 的条目：删除（不做溢出到 16 的补位）
- 最后执行 `/sbin/wifi` 重载

生成的 MAC 为本地管理单播地址（第一字节 `& 0xFC | 0x02`）。

## 用法

```sh
# 默认处理 MT7981 的 b0/b1
./rmac.sh

# 也可以显式指定 .dat
./rmac.sh /etc/wireless/mediatek/mt7981.dbdc.b0.dat \
          /etc/wireless/mediatek/mt7981.dbdc.b1.dat
```

脚本会打印每个 `[REPLACED]`、`[ADDED]`、`[DROPPED]` 的 key，最后重载 WiFi。

## 验收结果

- 日期：2026-11-18
- 设备：CMCC RAX3000M（MT7981）
- 固件：`chasey-dev/immortalwrt-mt798x-rebase` 25.12
- revision：`r0-458d2f7`
- 内核：`6.12.116`
- 系统：ImmortalWrt 25.12-SNAPSHOT

配置与结果：

| 频段 | BssidNum | 生成条目数 | 结果 |
| --- | --- | --- | --- |
| 2.4 GHz (b0) | 5 | 6（`MacAddress` … `MacAddress5`） | 通过 |
| 5 GHz (b1) | 6 | 7（`MacAddress` … `MacAddress6`） | 通过 |

接口映射（仅列字段来源，不记录实际 MAC）：

| 接口 | 频段 | 来源 | 状态 |
| --- | --- | --- | --- |
| `ra0` | 2.4G | b0 `MacAddress` | UP |
| `ra1` | 2.4G | b0 `MacAddress1` | UP |
| `ra2` | 2.4G | b0 `MacAddress2` | DOWN（`00:00:...`） |
| `ra3` | 2.4G | b0 `MacAddress3` | UP |
| `ra4` | 2.4G | b0 `MacAddress4` | UP |
| `rax0` | 5G | **b0 `MacAddress5`（组内 +1）** | UP |
| `rax1` | 5G | b1 `MacAddress1` | DOWN（`00:00:...`） |
| `rax2` | 5G | b1 `MacAddress2` | UP |
| `rax3` | 5G | b1 `MacAddress3` | DOWN（`00:00:...`） |
| `rax4` | 5G | b1 `MacAddress4` | UP |
| `rax5` | 5G | b1 `MacAddress5` | UP |

结论：

- 所有 UP 接口 MAC 唯一、无空值
- `DOWN` 接口读出 `00:00:00:00:00:00` 属于正常（接口未启用）
- 5G 第一个接口使用 b0 的 +1 位，因此“每个频段自己的组 +1”是必要的
- b1 的 `MacAddress` 是基准位，实际 5G 接口从 `MacAddress1` 起使用；`MacAddress6`（+1）在该拓扑下未被占用
- `wifi` 重载后 SSID 正常起来，WAN 连通性正常

## 验证命令

```sh
# 条目数量（b0=6，b1=7）
grep -c '^MacAddress' /etc/wireless/mediatek/mt7981.dbdc.b0.dat
grep -c '^MacAddress' /etc/wireless/mediatek/mt7981.dbdc.b1.dat

# 实际接口 MAC
for i in 0 1 2 3 4; do printf 'ra%s ' "$i"; cat /sys/class/net/ra$i/address; done
for i in 0 1 2 3 4 5; do printf 'rax%s ' "$i"; cat /sys/class/net/rax$i/address; done

# 接口状态与 WiFi
ip link show ra0
iwinfo
```

## 注意

- 仅适用于 mtwifi / MT7981 的 `.dat` 结构；其他驱动或平台不要直接套用
- 每次运行都会重新生成 MAC，客户端需要重新关联
- 刷机/升级后 `.dat` 可能被覆盖，需要重新执行脚本
- 运行前建议备份 `.dat` 和脚本（例如打包到 `/root/`）
