#!/bin/bash
#
# Organize firmware files for release
#

set -euo pipefail

cd /tmp
rm -rf firmware-basic firmware-gecoosac-v2 release-firmware
mkdir -p release-firmware

# Copy BASIC firmware
cp -r /tmp/firmware-basic/* release-firmware/ 2>/dev/null || true

# Copy GECOSAC-V2 firmware
if [ -d "/tmp/firmware-gecoosac-v2" ]; then
    cp -r /tmp/firmware-gecoosac-v2/* release-firmware/ 2>/dev/null || true
fi

echo "Firmware organized:"
ls -lh release-firmware/ | tail -n +2
