#!/bin/bash
# ============================================================================
# diy-zn-m2.sh —— 在 feeds install 之后、make 之前执行
# 工作目录：openwrt/
#
# 干三件事：
#   1. 从 OpenClash 官方仓库克隆包体（上游 feeds 里没有，必须自己加）
#   2. 把 mihomo 完整内核 + GeoIP/GeoSite 预置进 files/，刷完即用
#   3. 把默认 IP 改成 192.168.12.1（对齐现有网段）
# ============================================================================
set -e

echo "==================== DIY: ZN-M2 开始 ===================="
echo "当前目录: $(pwd)"

# ----------------------------------------------------------------------------
# 1. OpenClash 包体
# ----------------------------------------------------------------------------
echo ""
echo "[1/4] 拉取 OpenClash 包体..."

# 先清掉可能由 feeds 带入的同名包，避免重名冲突
rm -rf package/luci-app-openclash
rm -rf package/feeds/*/luci-app-openclash 2>/dev/null || true

if git clone --depth=1 https://github.com/vernesong/OpenClash.git /tmp/OpenClash; then
    if [ -d /tmp/OpenClash/luci-app-openclash ]; then
        cp -r /tmp/OpenClash/luci-app-openclash package/luci-app-openclash
        echo "    ✓ luci-app-openclash 已就位"
        ls package/luci-app-openclash | head -20
    else
        echo "    ✗ 仓库结构异常，未找到 luci-app-openclash 目录"
        exit 1
    fi
else
    echo "    ✗ 克隆 OpenClash 失败"
    exit 1
fi

# 确认 Makefile 存在 —— 没有 Makefile 编译系统不会识别该包，
# config 里的 CONFIG_PACKAGE_luci-app-openclash=y 会在 defconfig 时被丢弃
if [ ! -f package/luci-app-openclash/Makefile ]; then
    echo "    ✗ 缺少 Makefile，包不会被编译"
    exit 1
fi
echo "    ✓ Makefile 校验通过"

# ----------------------------------------------------------------------------
# 2. mihomo 内核 + GeoIP/GeoSite 预置
#    这些文件不进 RootFS 的包，而是放进 files/ 目录，
#    打包时被复制进固件根文件系统，刷完直接可用，不用联网下载。
# ----------------------------------------------------------------------------
echo ""
echo "[2/4] 预置 mihomo 内核（arm64）与规则库..."

META_DIR="files/etc/openclash/core"
GEO_DIR="files/etc/openclash"
mkdir -p "$META_DIR" "$GEO_DIR"

# --- Meta 内核（mihomo），M2 是 aarch64，取 arm64 版 ---
META_OK=0
for url in \
    "https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz" \
    "https://ghfast.top/https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz" \
    "https://gh-proxy.com/https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz"
do
    echo "    尝试: ${url:0:80}..."
    if wget -q --timeout=90 --tries=2 -O /tmp/meta.tar.gz "$url" 2>/dev/null; then
        if tar -xzf /tmp/meta.tar.gz -O > "$META_DIR/clash_meta" 2>/dev/null; then
            SZ=$(stat -c%s "$META_DIR/clash_meta" 2>/dev/null || echo 0)
            # 正常 mihomo 内核 > 5MB，小于则是错误页
            if [ "$SZ" -gt 5000000 ]; then
                chmod +x "$META_DIR/clash_meta"
                echo "    ✓ clash_meta  $(( SZ / 1024 / 1024 )) MB"
                META_OK=1
                break
            else
                echo "    ✗ 文件过小 ($SZ B)，判定失败"
                rm -f "$META_DIR/clash_meta"
            fi
        fi
    fi
done

if [ "$META_OK" -eq 0 ]; then
    echo "    ⚠ Meta 内核预置失败 —— 编译继续，但刷完需在 OpenClash 界面手动更新内核"
fi

# --- GeoIP / GeoSite 规则库 ---
for item in "geoip.dat:GeoIP.dat" "geosite.dat:GeoSite.dat"; do
    SRC="${item%%:*}"
    DST="${item##*:}"
    for url in \
        "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/$SRC" \
        "https://ghfast.top/https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/$SRC"
    do
        if wget -q --timeout=90 --tries=2 -O "$GEO_DIR/$DST" "$url" 2>/dev/null; then
            SZ=$(stat -c%s "$GEO_DIR/$DST" 2>/dev/null || echo 0)
            if [ "$SZ" -gt 100000 ]; then
                echo "    ✓ $DST  $(( SZ / 1024 )) KB"
                break
            else
                rm -f "$GEO_DIR/$DST"
            fi
        fi
    done
done

echo "    --- files 目录 ---"
find files -type f 2>/dev/null | while read -r f; do
    echo "        $(stat -c%s "$f")  $f"
done

# ----------------------------------------------------------------------------
# 3. 改默认 IP 为 192.168.12.1
# ----------------------------------------------------------------------------
echo ""
echo "[3/4] 设置默认 LAN IP = 192.168.12.1 ..."

# config_generate 是生成默认网络配置的脚本，改这里最彻底
CG=$(find package/base-files -name 'config_generate' -type f 2>/dev/null | head -1)
if [ -n "$CG" ]; then
    echo "    目标文件: $CG"
    sed -i 's/192\.168\.1\.1/192.168.12.1/g' "$CG"
    sed -i 's/192\.168\.6\.1/192.168.12.1/g' "$CG"
    grep -n '192\.168\.12\.1' "$CG" | head -5 || echo "    ⚠ 未匹配到，将由 uci-defaults 兜底"
else
    echo "    ⚠ 未找到 config_generate，将由 uci-defaults 兜底"
fi

# 双保险：首次启动时再设一次（防止源码默认值路径变化）
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-zn-m2-init <<'UCIEOF'
#!/bin/sh
# 兆能 M2 首次启动初始化

# --- LAN IP ---
uci -q set network.lan.ipaddr='192.168.12.1'
uci -q set network.lan.netmask='255.255.255.0'
uci -q commit network

# --- 主机名与时区 ---
uci -q set system.@system[0].hostname='ZN-M2'
uci -q set system.@system[0].timezone='CST-8'
uci -q set system.@system[0].zonename='Asia/Shanghai'
uci -q commit system

# --- NSS 硬件加速：开启软件 + 硬件流量卸载 ---
# IPQ6000 的 NSS 协处理器负责 NAT/PPPoE 卸载，不开则千兆跑满时 CPU 打满
uci -q set firewall.@defaults[0].flow_offloading='1'
uci -q set firewall.@defaults[0].flow_offloading_hw='1'
uci -q commit firewall

# --- OpenClash 基础配置 ---
# 注意：core_type 与 enable_meta_core 必须匹配，否则内核启动失败
uci -q set openclash.config.enable='0'
uci -q set openclash.config.core_type='Meta'
uci -q set openclash.config.enable_meta_core='1'
uci -q set openclash.config.en_mode='redir-host'
uci -q set openclash.config.enable_redirect_dns='1'
uci -q set openclash.config.dns_port='7874'
uci -q set openclash.config.proxy_port='7890'
uci -q set openclash.config.socks_port='7891'
uci -q set openclash.config.mixed_port='7893'
uci -q set openclash.config.redirect_port='7892'
uci -q commit openclash

exit 0
UCIEOF
chmod +x files/etc/uci-defaults/99-zn-m2-init
echo "    ✓ uci-defaults 已写入"

# ----------------------------------------------------------------------------
# 4. 自检
# ----------------------------------------------------------------------------
echo ""
echo "[4/4] 自检..."
echo "    package/luci-app-openclash : $([ -d package/luci-app-openclash ] && echo 存在 || echo 缺失)"
echo "    files/etc/openclash/core   : $([ -d files/etc/openclash/core ] && echo 存在 || echo 缺失)"
echo "    uci-defaults               : $(ls files/etc/uci-defaults 2>/dev/null | tr '\n' ' ')"

echo ""
echo "==================== DIY: ZN-M2 完成 ===================="
