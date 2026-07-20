#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After update feeds)
#

# Add feeds
git clone https://github.com/kenzok8/small-package.git package/small-package
git clone https://github.com/kenzok8/luci-theme-ifit.git package/luci-theme-ifit

# Update feeds
./scripts/feeds update -a
./scripts/feeds install -a
