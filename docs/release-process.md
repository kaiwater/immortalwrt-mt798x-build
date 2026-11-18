# 发布流程（硬性门禁）

> [!IMPORTANT]
> **固件必须先在真机刷机并成功启动验证，才能 push 到 GitHub / 创建公开 Release。**
> 未验证的构建只能留在本地，或先保存为 **draft release**，不得公开。

## 1. 本地构建

- 使用 chasey-dev 25.12（kernel 6.12.116）
- 产物在 `<tree>/bin/targets/mediatek/filogic/`
- 归档到 `/mnt/qnap/out/<variant>/`，生成 `SHA256SUMS`、`RELEASE.txt`

## 2. 镜像布局校验（刷机前）

| 变体 | 必须使用的镜像 | 禁止 |
| --- | --- | --- |
| stock | `*-stock-squashfs-sysupgrade.bin`、`*-stock-initramfs-factory.ubi` | 任何 `*-ubootmod-*` |
| ubootmod | `*-ubootmod-squashfs-sysupgrade.itb`、`*-ubootmod-initramfs-recovery.itb`、`preloader.bin`、`bl31-uboot.fip` | 任何 `*-stock-*` |

再核对：

```sh
tar xOf *-stock-squashfs-sysupgrade.bin sysupgrade-*/CONTROL   # BOARD 必须匹配
file *-stock-squashfs-sysupgrade.bin                            # POSIX tar
file *-ubootmod-squashfs-sysupgrade.itb                         # FIT/ITB
```

## 3. 真机刷机

- stock：原厂固件 → `initramfs-factory.ubi` → `sysupgrade -n *-stock-squashfs-sysupgrade.bin`
- ubootmod：先确保已刷 OpenWrt U-Boot → `sysupgrade -n *-ubootmod-squashfs-sysupgrade.itb`

## 4. 启动验证（全部通过才发布）

- 串口日志 / 系统正常启动，无 kernel panic、无反复重启
- `ubus call system board` 的 `board_name` 与变体一致
- `uname -r` 为预期内核（当前要求 6.12.116）
- LAN / WAN 正常，能 ping 外网
- WiFi 正常起来（mtwifi）
- overlay 正常挂载，剩余空间合理
- 关键包存在（`coreutils`、`dnsmasq-full`；WR30U 不应有代理）
- 重启一次，仍能正常启动

## 5. 发布

全部通过后：

```sh
git push
gh release create <tag> ...        # 非 draft
```

未通过：修改配置 / 源码，重新构建和验证，**不要上传**。

## 6. 状态标记

| 状态 | 处理 |
| --- | --- |
| 未刷机 / 未验证 | 仅本地保存，或 draft release |
| 已验证启动，基本功能正常 | 可公开 release |
| 已验证但仍有已知问题 | release 标记 pre-release，并在 notes 说明 |
