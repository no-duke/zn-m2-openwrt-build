#!/bin/bash
#
# Free disk space on GitHub Actions runner + prepare build directory
#
# 修复记录（2026-09-22）：
#   1. fallocate 缺 sudo 导致 /mnt 写入被拒，配合 set -e 使整个 job 直接失败
#   2. workflow 将源码 clone 到 /workdir，但本脚本从未创建该目录，下一步必然失败
#      → 现将构建目录建到 /mnt（runner 上的大容量临时盘），再软链为 /workdir
#

set -euo pipefail

# ---------- 1. 删除体积大且用不到的预装组件 ----------
sudo rm -rf /usr/share/dotnet || true
sudo rm -rf /opt/ghc || true
sudo rm -rf /usr/local/lib/android || true
sudo rm -rf /usr/local/share/powershell || true
sudo rm -rf /usr/share/swift || true

# ---------- 2. 清理 Docker 镜像与 apt 缓存 ----------
docker system prune -af || true
sudo apt-get clean
sudo apt-get autoremove -y || true

# ---------- 3. 准备构建目录 ----------
# runner 的 /mnt 挂载在大容量临时盘上，把编译目录放这里避免根分区写满
sudo mkdir -p /mnt/workdir
sudo chown -R "$USER":"$USER" /mnt/workdir
sudo ln -sfn /mnt/workdir /workdir

# ---------- 4. swap ----------
# 原脚本在此重建 swap，但 fallocate 缺 sudo 会直接让 job 挂掉。
# 编译主要吃 CPU 与磁盘 IO，swap 非必需，故只做清理并全部容错。
sudo swapoff -a 2>/dev/null || true
sudo rm -f /mnt/swapfile 2>/dev/null || true

# ---------- 5. 状态输出 ----------
echo "=== 磁盘状态 ==="
df -hT / /mnt 2>/dev/null || df -hT
echo "=== /workdir 指向 ==="
ls -ld /workdir
echo "=== 可用空间 ==="
echo "根分区可用: $(df -h / | awk 'NR==2{print $4}')"
echo "/mnt 可用:  $(df -h /mnt 2>/dev/null | awk 'NR==2{print $4}')"
