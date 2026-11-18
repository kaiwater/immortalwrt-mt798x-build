# ImmortalWrt MT798x build support

本仓库只保存 **defconfig、GitHub Actions workflow、脚本和文档**，不包含 OpenWrt 源码树。

所有固件构建都固定 clone：

```
https://github.com/chasey-dev/immortalwrt-mt798x-rebase.git  25.12
```

内核固定为 **6.12.116**（`k616`），避免误用旧 fork 的 6.12.87。

## 支持设备

| 设备 | 变体 | defconfig | workflow |
| --- | --- | --- | --- |
| CMCC RAX3000M | eMMC / NAND（OpenClash） | `defconfig/rax3000m-openclash.config` | `auto_rax3000m.yml` / `rax3000m.yml` |
| CMCC RAX3000M 256M | NAND 256M（注入式） | `scripts/inject-rax3000m-256m.py` | `auto_rax3000m.yml` |
| 360T7 | OpenClash | `defconfig/rax3000m-360T7.config` | `auto_360T7.yml` |
| Redmi AX6000 | stock layout，passwall / openclash | `defconfig/redmi-ax6000-stock.config`<br>`defconfig/redmi-ax6000-stock-openclash.config` | `redmi_ax6000.yml` |
| Xiaomi WR30U | stock / ubootmod，基础镜像（无代理） | `defconfig/wr30u-minimal.config` | `wr30u.yml` |

## 快速构建

```sh
git clone https://github.com/chasey-dev/immortalwrt-mt798x-rebase.git openwrt -b 25.12
cd openwrt
./scripts/feeds update -a
./scripts/feeds install -a

cp ../defconfig/<device>.config .config
make defconfig

# 仅 openclash 变体
sh ../scripts/prepare-openclash.sh

make download -j$(nproc)
make -j$(nproc)
```

详细说明见 [BUILDING.md](BUILDING.md)。

## 文档

- [BUILDING.md](BUILDING.md)：构建步骤、校验、常见错误
- [docs/releases.md](docs/releases.md)：Release 命名与清单
- [docs/geodata-apk.md](docs/geodata-apk.md)：OpenClash / PassWall geodata apk

## 历史

旧的完整 fork（包含 OpenWrt 源码树和 6.12.87 历史）已重命名为
`immortalwrt-mt798x-25.12-legacy`，仅作存档。
