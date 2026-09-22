#!/bin/bash
#
# Free disk space on GitHub Actions runner
#

set -euo pipefail

# Remove unnecessary packages
sudo rm -rf /usr/share/dotnet
sudo rm -rf /opt/ghc
sudo rm -rf /usr/local/lib/android
sudo rm -rf /usr/local/share/powershell
sudo rm -rf /usr/share/swift

# Remove Docker images
docker system prune -af || true

# Free space from apt cache
sudo apt-get clean

# Remove old kernels
sudo apt-get autoremove -y

# Remove swap file
sudo swapoff -a
sudo rm -f /mnt/swapfile
fallocate -l 4G /mnt/swapfile
sudo chmod 600 /mnt/swapfile
sudo mkswap /mnt/swapfile
sudo swapon /mnt/swapfile

echo "Free disk space: $(df -h / | awk 'NR==2{print $4}')"
