# 2026-11-25 — 版本号追加构建时间与分支

## 格式

固件版本尾部追加：

```text
<YYYYMMDD HHMMSS> - <分支> <commit>
```

示例：

```text
ImmortalWrt 25.12-SNAPSHOT r0-458d2f7 20261125 001500 - chasey 458d2f7
```

## 实现

`scripts/stamp-version.sh` 原来只设置 `CONFIG_VERSION_CODE=r0-<short>-<date>`，
现在改为：

1. `VERSION_CODE=r0-<short>`（保持短 revision）
2. 生成 `files/etc/wrt_release`：

```text
BUILD_STAMP='20261125 001500'
BUILD_BRANCH='chasey'
SOURCE_REV='458d2f7'
```

3. 生成 `files/etc/uci-defaults/98-wrt-release`，首次启动时把后缀追加到
   `DISTRIB_DESCRIPTION`（幂等，重复执行不会重复追加）

分支名按 `origin` 识别：`chasey-dev` → `chasey`，`LiBwrt` → `LibWrt`，
`VIKINGYFY` → `VIKINGYFY`。

## 注意

`files/` 是 OpenWrt 会在打包时并入 rootfs 的本地覆盖目录；脚本每次运行都会
重写这两个文件。GitHub Actions 里调用 `stamp-version.sh` 的 workflow
（360T7 / WR30U）也会自动带上。

## 生效方式

下次构建生效；11-24 已产出的固件保持原样。
