# zn-m2-openwrt-build

兆能 M2（ZN M2 / 高通 IPQ6000 / 1GB 扩容版）OpenWrt 云编译仓库。

## 产物

无 WiFi + 有线 NSS 硬件加速 + **OpenClash** + HomeProxy 的 OpenWrt 固件。

| 项 | 值 |
|---|---|
| 源码 | `LiBwrt/LibWrt` 分支 `25.12-nss` |
| 内核 | 6.12（满血 NSS 支持）|
| 平台 | `qualcommax` / `ipq60xx` / `zn_m2` |
| WiFi | 无（ath11k 全部剔除）|
| 默认 IP | `192.168.12.1` |
| 默认账号 | `root` / `password` |

## 怎么用

1. `Actions` → 左侧选 `Build-ZN-M2-OpenClash` → `Run workflow`
2. 等 3–5 小时
3. 去 `Releases` 下载 `*zn_m2*.ubi`

### 首次使用必须先开权限

`Settings` → `Actions` → `General` → 最下面 `Workflow permissions`
→ 选 **Read and write** → Save

不设这一步，编译会成功但**发不了 Release**。

## 文件说明

| 文件 | 作用 |
|---|---|
| `.github/workflows/build-zn-m2.yml` | 工作流 |
| `configs/zn-m2.config` | 编译配置 |
| `diy-zn-m2.sh` | 定制脚本：拉 OpenClash 包体 + 预置 mihomo 内核 + 改默认 IP |

## 关键修正记录

相对上游 `breeze303/openwrt-ci` 的 `IPQ60XX-6.12-NOWIFI`：

- ❌ 上游 `REPO_BRANCH: main-nss` —— **该分支已不存在**，`LiBwrt/LibWrt` 现只有 `25.12-nss`
- ✅ 本仓库已修正
- ➕ 新增 OpenClash 集成（上游没有）
- ➕ 默认 IP 改为 `192.168.12.1`
- ➕ 预置 mihomo arm64 内核与 GeoIP/GeoSite 规则库到固件内
- ➖ 去掉上游的每日定时编译（省额度）

## 刷机

⚠️ **刷前务必备份 CDT**（扩容机命根子）：

```bash
ssh root@192.168.12.1 "dd if=/dev/mtd10 of=/tmp/cdt10.bin; dd if=/dev/mtd11 of=/tmp/cdt11.bin"
```

刷机走暗云 U-Boot 网页 → **只点「固件」入口** → 上传 `*nand-factory.ubi`

⛔ 不要碰 ART 和 U-Boot 两个入口。
