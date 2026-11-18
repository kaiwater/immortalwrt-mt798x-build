# 构建指南（必读）

> [!IMPORTANT]
> 所有固件必须从 **`chasey-dev/immortalwrt-mt798x-rebase` 25.12** 构建。
> 本仓库不保存 OpenWrt 源码树；旧的完整 fork 已改名 `...-legacy`（6.12.87，仅存档）。

## 1. 固定源码与内核

```sh
git clone https://github.com/chasey-dev/immortalwrt-mt798x-rebase.git openwrt -b 25.12
```

校验内核：

```sh
grep '^LINUX_VERSION-6.12' openwrt/target/linux/generic/kernel-6.12   # 必须是 .116
```

## 2. 选择配置

| 设备 | 变体 | defconfig |
| --- | --- | --- |
| RAX3000M | eMMC / NAND | `defconfig/rax3000m-openclash.config` |
| RAX3000M 256M | NAND 256M | 由 `scripts/inject-rax3000m-256m.py` 注入 |
| 360T7 | OpenClash | `defconfig/rax3000m-360T7.config` |
| Redmi AX6000 | passwall | `defconfig/redmi-ax6000-stock.config` |
| Redmi AX6000 | openclash | `defconfig/redmi-ax6000-stock-openclash.config` |
| Xiaomi WR30U | stock + ubootmod | `defconfig/wr30u-minimal.config` |

## 3. 构建步骤

```sh
cd openwrt
./scripts/feeds update -a
./scripts/feeds install -a

cp ../defconfig/<device>.config .config

# 仅本地：ccache + arm64 Go 引导（不要提交）
sed -i 's|^CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT=.*|CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT="/opt/go-bootstrap"|' .config
grep -q '^CONFIG_CCACHE=y' .config || echo 'CONFIG_CCACHE=y' >> .config
sed -i '/^CONFIG_CCACHE_DIR=/d' .config
echo 'CONFIG_CCACHE_DIR="/mnt/qnap/ccache"' >> .config

make defconfig

# openclash 变体额外执行（注入 meta core + gfwlist）
sh ../scripts/prepare-openclash.sh

make download -j"$(nproc)"
make -j"$(nproc)"
```

## 4. 校验

```sh
# AX6000
grep -qx 'CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_xiaomi_redmi-router-ax6000-stock=y' .config

# WR30U（stock + ubootmod）
grep -qx 'CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_xiaomi_mi-router-wr30u-stock=y' .config
grep -qx 'CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_xiaomi_mi-router-wr30u-ubootmod=y' .config

# 通用
grep -qx 'CONFIG_PACKAGE_kmod-mt_wifi=y' .config
```

## 5. 常见错误

| 现象 | 原因 |
| --- | --- |
| 内核 6.12.87 | 用了旧的 `...-legacy` fork，应改用 chasey-dev |
| AX6000 device 被 defconfig 丢弃 | 源码树里没有该 device，或用了旧 fork |
| `go-bootstrap cannot be installed on linux/arm64` | 没设置 `CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT` |
| `rust [host] failed` | Ruby YJIT 或 shadowsocks-rust server 被选中 |

## 6. Release 命名

- `k616` = kernel 6.12.116
- 正式 tag 不带 `k616`，但内容一致
- 6.12.87 的旧构建不再发布

> [!IMPORTANT]
> 发布门禁：固件必须先在真机刷机并成功启动验证，才允许 push 到 GitHub 或创建公开 Release；未验证的只能留本地或 draft。详见 docs/release-process.md。
