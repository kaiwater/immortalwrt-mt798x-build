# 2026-11-27 — 加入 coreutils-sort

```text
defconfig/rax3000m-openclash.config   RAX3000M / 256M / ME / WR30U(stock+ubootmod)
defconfig/wr30u-minimal.config        WR30U minimal
```

两处从 `# CONFIG_PACKAGE_coreutils-sort is not set` 改为：

```text
CONFIG_PACKAGE_coreutils-sort=y
```

单个 applet，体积很小；下次构建生效。360T7 未改。
