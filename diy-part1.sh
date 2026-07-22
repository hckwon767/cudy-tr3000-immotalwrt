#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

# 临时解决Rust问题
sed -i 's/ci-llvm=true/ci-llvm=false/g' feeds/packages/lang/rust/Makefile

# add date in output file name
sed -i -e '/^IMG_PREFIX:=/i BUILD_DATE := $(shell date +%Y%m%d)' \
       -e '/^IMG_PREFIX:=/ s/\($(SUBTARGET)\)/\1-$(BUILD_DATE)/' include/image.mk

# set ubi to 122M
# sed -i 's/reg = <0x5c0000 0x7000000>;/reg = <0x5c0000 0x7a40000>;/' target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1-ubootmod.dts

# Add zashboard Korean dashboard for OpenClash
# Source: https://github.com/hckwon767/dashboard-ko
# Pinned version: v3.15.0 (change DASHBOARD_KO_VERSION to bump manually)
DASHBOARD_KO_VERSION="v3.15.0"
DASHBOARD_KO_NAME="zashboard-ko"
# [수정] OpenClash LuCI는 대시보드 서브패스가 /ui/zashboard/ 로 하드코딩되어 있어
# 폴더명에 '-ko'가 붙으면 "Zashboard" 옵션으로 인식되지 않음 -> 원래 이름(zashboard)로 설치
# [수정2] luci-app-openclash 는 package/ 밑이 아니라 immortalwrt luci feed
# (feeds/luci/applications/luci-app-openclash) 에서 오므로 실제 경로로 지정
DASHBOARD_KO_UI_DIR="feeds/luci/applications/luci-app-openclash/root/usr/share/openclash/ui/zashboard"
rm -rf /tmp/dashboard-ko "${DASHBOARD_KO_UI_DIR}"
mkdir -p /tmp/dashboard-ko
curl -L --retry 3 --fail \
  "https://github.com/hckwon767/dashboard-ko/releases/download/${DASHBOARD_KO_VERSION}/${DASHBOARD_KO_NAME}.zip" \
  -o /tmp/dashboard-ko/${DASHBOARD_KO_NAME}.zip
unzip -q /tmp/dashboard-ko/${DASHBOARD_KO_NAME}.zip -d /tmp/dashboard-ko/extracted
mkdir -p "${DASHBOARD_KO_UI_DIR}"
# The release zip may contain the files directly at the root, or nested
# inside a single subfolder. Handle both cases so index.html always ends
# up directly under the ui/zashboard-ko/ directory.
if [ -f /tmp/dashboard-ko/extracted/index.html ]; then
  cp -a /tmp/dashboard-ko/extracted/. "${DASHBOARD_KO_UI_DIR}/"
else
  SUBDIR=$(find /tmp/dashboard-ko/extracted -mindepth 1 -maxdepth 1 -type d | head -n 1)
  if [ -n "${SUBDIR}" ] && [ -f "${SUBDIR}/index.html" ]; then
    cp -a "${SUBDIR}/." "${DASHBOARD_KO_UI_DIR}/"
  else
    echo "WARNING: could not locate index.html in ${DASHBOARD_KO_NAME}.zip, please check the archive layout." >&2
  fi
fi
rm -rf /tmp/dashboard-ko

# Pre-install OpenClash core (Smart core, arm64) so the router works
# right after first boot without needing internet access to fetch the core.
# Source: https://github.com/vernesong/OpenClash/tree/core/master/smart
OPENCLASH_CORE_DIR="feeds/luci/applications/luci-app-openclash/root/etc/openclash/core"
mkdir -p "${OPENCLASH_CORE_DIR}"
rm -rf /tmp/openclash-core && mkdir -p /tmp/openclash-core
if curl -L --retry 3 --fail \
     "https://raw.githubusercontent.com/vernesong/OpenClash/core/master/smart/clash-linux-arm64.tar.gz" \
     -o /tmp/openclash-core/clash-arm64.tar.gz; then
  tar -xzf /tmp/openclash-core/clash-arm64.tar.gz -C /tmp/openclash-core
  mv /tmp/openclash-core/clash "${OPENCLASH_CORE_DIR}/clash_meta"
  chmod +x "${OPENCLASH_CORE_DIR}/clash_meta"
else
  echo "WARNING: failed to download OpenClash Smart core, it was not pre-installed." >&2
fi
rm -rf /tmp/openclash-core
