# ZN-M2 OpenWrt Build with OpenClash Support (No WiFi)

## 概述
基于 sdf8057-ipq6000 的 OpenWrt 构建，针对兆能 M2 (IPQ6018) 路由器优化，预装 OpenClash，已移除 WiFi 驱动。

## 特性
- IPQ6018 NSS 硬件加速
- 20MB rootfs 分区（支持 OpenClash）
- OpenClash + Metacubexd 面板
- 中文界面支持
- 默认开启 ttyd 免登录
- 无 WiFi 驱动（仅有线）

## 文件说明
```
config/
├── zn-m2.config          # 编译配置（含 OpenClash）
├── feeds.conf.default    # feeds 源配置
├── board/
│   ├── 02_network        # 网络接口配置
│   └── 01_leds           # LED 配置
├── dts/
│   └── qcom/
│       └── ipq6018-zn-m2.dts  # M2 设备树（无WiFi）
├── image/
│   └── ipq60xx.mk        # M2 镜像定义
├── target/
│   └── ipq60xx/
│       └── target.mk     # 目标定义
└── scripts/
    └── zn-m2/
        ├── diy-part1.sh
        ├── diy-part2.sh
        └── diy-part3.sh
scripts/
└── zn-m2/
    ├── diy-part1.sh
    ├── diy-part2.sh
    └── diy-part3.sh
```

## 编译步骤
1. 将 config/ 下的文件放入 zn-m2-openwrt-build 根目录
2. 运行 GitHub Actions 或本地编译
3. 使用 `make defconfig` 加载配置
4. 编译完成后刷入固件

## GitHub Actions
使用 zn-m2-openwrt-build/.github/workflows/zn-m2.yml 进行自动编译

## 注意事项
- 确保 M2 的 flash 分区足够（建议 20MB+ rootfs）
- OpenClash 需要足够的存储空间
- 首次刷入建议使用 factory 镜像
