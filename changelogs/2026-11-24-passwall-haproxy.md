# 2026-11-24 — PassWall 负载均衡补上 HAProxy

PassWall 的“负载均衡”节点类型（HAPROXY）依赖 `haproxy`，启动时会检查版本
（要求 >= 3.0）。chasey 25.12 这棵树的几个 defconfig 之前是关闭状态。

## 变更

```text
defconfig/rax3000m-openclash.config
defconfig/redmi-ax6000-stock.config
```

两处改为：

```text
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Haproxy=y
CONFIG_PACKAGE_haproxy=y
```

覆盖的设备：

- RAX3000M / RAX3000M-256M / RAX3000Me（`rax3000m-openclash.config`）
- Redmi AX6000 passwall 变体（`redmi-ax6000-stock.config`）

## 未改动的配置

```text
defconfig/rax3000m-360T7.config          INCLUDE_Haproxy / haproxy 本来就是 y
defconfig/redmi-ax6000-stock-openclash.config  没有安装 PassWall（只有 OpenClash）
defconfig/wr30u-minimal.config           minimal，未安装 PassWall
```

## 体积

haproxy 3.x 二进制加配置约 1.2–1.5 MB，压缩后更小；这些机型都是 128 MB
NAND，且已经有了 PassWall + sing-box，增量可以接受。

## 生效方式

下次构建时生效；本次不触发 GitHub Actions，等 Lima 空闲后本地重编。
