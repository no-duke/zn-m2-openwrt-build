#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part3.sh
# Description: OpenWrt DIY script part 3 (After Install feeds)
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate

#修改版本信息
sed -i "s/DISTRIB_DESCRIPTION='*.*'/DISTRIB_DESCRIPTION='OpenWrt IPQ6000 ZN-M2 (build time: $(date +%Y%m%d))'/g"  package/base-files/files/etc/openwrt_release
# 替换golang版本为1.26
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# ttyd免登陆
sed -i -r 's#/bin/login#/bin/login -f root#g' feeds/packages/utils/ttyd/files/ttyd.config

# design修改proxy链接
sed -i -r "s#navbar_proxy = 'openclash'#navbar_proxy = 'passwall'#g" feeds/luci/themes/luci-theme-design/luasrc/view/themes/design/header.htm

# 增大 rootfs 分区给 OpenClash 腾空间
sed -i '/define Device\/zn_m2/,/^endef$/ {
  /DEVICE_PACKAGES := .*kmod-usb-phy-msm/a\\tROOTFS_PARTSIZE := 20M
}' target/linux/ipq60xx/image/Makefile 2>/dev/null || true

# --- 诊断：确认 rootfs 分区调整是否生效 ---
if [ -f target/linux/ipq60xx/image/Makefile ]; then
    echo "=== ipq60xx Makefile 中的 zn_m2 定义 ==="
    sed -n '/define Device\/zn_m2/,/^endef$/p' target/linux/ipq60xx/image/Makefile
else
    echo "!! target/linux/ipq60xx/image/Makefile 不存在，尝试定位实际路径"
    find target -name 'Makefile' -path '*image*' 2>/dev/null | head -10
fi


# ============================================================================
# 内核配置修复：NEW 选项导致 silentoldconfig abort
# ----------------------------------------------------------------------------
# 报错原文：
#   Qualcomm Atheros IPQ806X AHCI SATA support (AHCI_IPQ) [N/m/?] (NEW) aborted!
#   Console input/output is redirected. Run 'make oldconfig' to update configuration.
#   make[7]: *** [scripts/kconfig/Makefile:38: silentoldconfig] Error 1
#
# 原因：内核 Kconfig 新增了选项，但 target/linux/ipq60xx/config-4.4 未声明，
#       CI 里 stdin 被重定向，silentoldconfig 无法交互应答 → 直接中止编译。
#
# 双保险：
#   保险 A —— 显式声明该选项为 not set（IPQ806X 的 SATA 控制器，IPQ6000 用不到）
#   保险 B —— 把构建系统里的 silentoldconfig 换成 oldconfig，
#             后者遇到 NEW 选项会取默认值而不是 abort
# ============================================================================

echo ""
echo "=== 内核配置修复 ==="

# ---- 保险 A：显式声明缺失的内核选项 ----
KCFG="target/linux/ipq60xx/config-4.4"
if [ -f "$KCFG" ]; then
    for sym in AHCI_IPQ; do
        if grep -q "CONFIG_${sym}\b" "$KCFG"; then
            echo "  [A] 已存在 CONFIG_${sym}"
        else
            echo "# CONFIG_${sym} is not set" >> "$KCFG"
            echo "  [A] 已补充 CONFIG_${sym}=n"
        fi
    done
else
    echo "  [A] !! 未找到 $KCFG"
fi

# ---- 保险 B：silentoldconfig -> oldconfig ----
# oldconfig 在 stdin 为 EOF 时对 NEW 选项取默认值；silentoldconfig 会直接失败
PATCHED=0
for f in $(grep -rl 'silentoldconfig' include/ scripts/ 2>/dev/null || true); do
    sed -i 's/\bsilentoldconfig\b/oldconfig/g' "$f"
    echo "  [B] 已修补 $f"
    PATCHED=$((PATCHED + 1))
done
if [ "$PATCHED" -eq 0 ]; then
    echo "  [B] 未发现 silentoldconfig 调用点，跳过"
fi

# ---- 验证 ----
echo "  --- config-4.4 尾部 ---"
tail -4 "$KCFG" 2>/dev/null || true
echo "  --- 剩余 silentoldconfig 引用 ---"
grep -rn 'silentoldconfig' include/ 2>/dev/null | head -5 || echo "  (无)"
