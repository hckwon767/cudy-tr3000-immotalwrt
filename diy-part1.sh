#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
#echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
#echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

# Copy custom local packages into OpenWrt tree so they are available during build
if [ -d "$GITHUB_WORKSPACE/package/luci-compat-keep" ]; then
  mkdir -p package
  cp -r "$GITHUB_WORKSPACE/package/luci-compat-keep" package/
fi

# Copy custom rootfs overlay (uci-defaults, first-boot settings, etc.) into
# the OpenWrt tree so it gets baked into the firmware image.
if [ -d "$GITHUB_WORKSPACE/files" ]; then
  mkdir -p files
  cp -r "$GITHUB_WORKSPACE/files/." files/
  # Safety net: uci-defaults scripts must be executable to run on first boot.
  # If the file lost its +x bit (e.g. uploaded via the GitHub web UI, which
  # always commits files as non-executable), force it back on here.
  if [ -d files/etc/uci-defaults ]; then
    chmod +x files/etc/uci-defaults/* 2>/dev/null || true
  fi
fi

git clone https://github.com/eamonxg/luci-theme-aurora package/luci-theme-aurora
git clone https://github.com/eamonxg/luci-app-aurora-config package/luci-app-aurora-config
git clone https://github.com/timsaya/luci-app-bandix package/luci-app-bandix
git clone https://github.com/timsaya/openwrt-bandix package/openwrt-bandix
