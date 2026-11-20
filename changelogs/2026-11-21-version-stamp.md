# 2026-11-21 — 固件版本加入 chasey commit 与构建日期

## 背景

release 的 tag、正文和资产里只能看到 `chasey-dev 25.12`，没有记录
实际使用的 chasey commit。换算出上游基线需要下载镜像、解出
`/etc/openwrt_release` 才能看到 `r0-xxxxxxx`，不方便核对。

## 变更

新增 `scripts/stamp-version.sh`：

- 读取源码树当前 HEAD 的 7 位 short commit
- 取构建日期（workflow 传入 `VERSION_DATE`，本地默认当天）
- 写入 `CONFIG_VERSION_CODE="r0-<short>-<YYYYMMDD>"`

`/etc/openwrt_release` 的模板是：

```text
DISTRIB_DESCRIPTION='%D %V %C'
```

所以系统信息和 LuCI 的“固件版本”会变成：

```text
ImmortalWrt 25.12-SNAPSHOT r0-458d2f7-20261118
```

## 覆盖范围

- `.github/workflows/auto_rax3000m.yml`
- `.github/workflows/auto_360T7.yml`
- `.github/workflows/wr30u.yml`
- `.github/workflows/redmi_ax6000.yml`
- `scripts/build-ax6000.sh`

以上都在 `make defconfig`（或复制 `.config`）之后执行版本标记，再开始
`make download` / `make -j`。

release notes 同时增加：

```text
- 源码 commit：<完整 40 位 chasey commit>
```

## 注意

- `CONFIG_VERSION_CODE` 在 `make defconfig` 之后写入，避免被 defconfig 丢弃
- 版本标记不影响 `DISTRIB_REVISION` 的 `r0-<short>`
- 旧的 `rax3000m.yml`（从本仓库 6.12.87 树构建）未纳入，后续以 chasey 树为准
