#!/bin/bash

# 修改默认IP
# sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 更改默认 Shell 为 zsh
# sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd

# TTYD 免登录
# sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config



# rm -rf feeds/luci/themes/luci-theme-argon
# rm -rf feeds/luci/themes/luci-theme-design


# 拉取仓库文件夹
merge_package() {
	# 参数1是分支名,参数2是库地址,参数3是所有文件下载到指定路径。
	# 同一个仓库下载多个文件夹直接在后面跟文件名或路径，空格分开。
	# 示例:
	# merge_package master https://github.com/WYC-2020/openwrt-packages package/openwrt-packages luci-app-eqos luci-app-openclash luci-app-ddnsto ddnsto 
	# merge_package master https://github.com/lisaac/luci-app-dockerman package/lean applications/luci-app-dockerman
	if [[ $# -lt 3 ]]; then
		echo "Syntax error: [$#] [$*]" >&2
		return 1
	fi
	trap 'rm -rf "$tmpdir"' EXIT
	branch="$1" curl="$2" target_dir="$3" && shift 3
	rootdir="$PWD"
	localdir="$target_dir"
	[ -d "$localdir" ] || mkdir -p "$localdir"
	tmpdir="$(mktemp -d)" || exit 1
        echo "开始下载：$(echo $curl | awk -F '/' '{print $(NF)}')"
	git clone -b "$branch" --depth 1 --filter=blob:none --sparse "$curl" "$tmpdir"
	cd "$tmpdir"
	git sparse-checkout init --cone
	git sparse-checkout set "$@"
	# 使用循环逐个移动文件夹
	for folder in "$@"; do
		mv -f "$folder" "$rootdir/$localdir"
	done
	cd "$rootdir"
}

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}


# sed -i 's/github.com\/coolsnowwolf\/luci.git;openwrt-23.05/github.com\/xiaomeng9597\/luci.git;openwrt-23.05/g' feeds.conf.default
# git clone --depth=1 https://github.com/xiaomeng9597/luci-theme-design package/luci-theme-design

# Themes
# git clone --depth=1 -b 18.06 https://github.com/kiddin9/luci-theme-edge package/luci-theme-edge
# git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
# git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
# git clone --depth=1 https://github.com/kenzok78/luci-theme-design package/luci-theme-design
# git clone --depth=1 https://github.com/xiaoqingfengATGH/luci-theme-infinityfreedom package/luci-theme-infinityfreedom
# git_sparse_clone main https://github.com/haiibo/packages luci-theme-opentomcat
# merge_package master https://github.com/coolsnowwolf/luci feeds/luci/themes themes/luci-theme-design

# 更改 Argon 主题背景
rm -rf feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/background/*
# cp -f $GITHUB_WORKSPACE/images/bg1.jpg feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
# mkdir -p package/luci-theme-argon/htdocs/luci-static/argon/img
# cp -f $GITHUB_WORKSPACE/images/bg1.jpg package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg

# iStore
git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
git_sparse_clone main https://github.com/linkease/istore luci

# 在线用户
git_sparse_clone main https://github.com/haiibo/packages luci-app-onliner
sed -i '$i uci set nlbwmon.@nlbwmon[0].refresh_interval=2s' package/lean/default-settings/files/zzz-default-settings
sed -i '$i uci commit nlbwmon' package/lean/default-settings/files/zzz-default-settings
chmod 755 package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh

# 修改本地时间格式
sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/*/index.htm

# 修改版本为编译日期
date_version=$(date +"%y.%m.%d")
orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
sed -i "s/${orig_version}/R${date_version} by xiaomeng9597/g" package/lean/default-settings/files/zzz-default-settings

# 修改 Makefile
# find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/\$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
# find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/\$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
# find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
# find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}

# samba解除root限制
sed -i 's/invalid users = root/#&/g' feeds/packages/net/samba4/files/smb.conf.template

# 修改 design 为默认主题
# sed -i '/set luci.main.mediaurlbase=\/luci-static\/bootstrap/d' feeds/luci/themes/luci-theme-bootstrap/root/etc/uci-defaults/30_luci-theme-bootstrap
# sed -i 's/Bootstrap theme/Design theme/g' feeds/luci/collections/*/Makefile
# sed -i 's/luci-theme-bootstrap/luci-theme-design/g' feeds/luci/collections/*/Makefile

# 最大连接数修改为65535
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=65535' package/base-files/files/etc/sysctl.conf

# 默认不开启WiFi
# sed -i "s/wireless.radio\${devidx}.disabled=0/wireless.radio\${devidx}.disabled=1/g" package/kernel/mac80211/files/lib/wifi/mac80211.sh

# 替换需要编译的内核版本
# sed -i -E 's/KERNEL_PATCHVER:=[0-9]+\.[0-9]+/KERNEL_PATCHVER:=5.15/' target/linux/rockchip/Makefile
# sed -i -E 's/KERNEL_TESTING_PATCHVER:=[0-9]+\.[0-9]+/KERNEL_TESTING_PATCHVER:=5.15/' target/linux/rockchip/Makefile

rm -f feeds/luci/applications/luci-app-ttyd/luasrc/view/terminal/terminal.htm
wget -P feeds/luci/applications/luci-app-ttyd/luasrc/view/terminal https://xiaomeng9597.github.io/terminal.htm

# 集成CPU性能跑分脚本
cp -f $GITHUB_WORKSPACE/configfiles/coremark/coremark-arm64 package/base-files/files/bin/coremark-arm64
cp -f $GITHUB_WORKSPACE/configfiles/coremark/coremark-arm64.sh package/base-files/files/bin/coremark.sh
chmod 755 package/base-files/files/bin/coremark-arm64
chmod 755 package/base-files/files/bin/coremark.sh




# 动态适配农商云g68,农商云g16,彼度云g18机型，不懂的别乱修改
# 复制 02_network 网络配置文件到 target/linux/rockchip/armv8/base-files/etc/board.d/ 目录下
cp -f $GITHUB_WORKSPACE/configfiles/02_network target/linux/rockchip/armv8/base-files/etc/board.d/02_network


# cp -f $GITHUB_WORKSPACE/configfiles/uboot-Makefile package/boot/uboot-rockchip/Makefile
grep -q 'seewo_sv21 \\$' package/boot/uboot-rockchip/Makefile && sed -i "s/seewo_sv21 \\\\/seewo_sv21 \\\\\n    nsy_g68-plus \\\\\n    nsy_g16-plus \\\\\n    bdy_g18-pro \\\\/g" package/boot/uboot-rockchip/Makefile || sed -i "s/seewo_sv21/seewo_sv21 \\\\\n    nsy_g68-plus \\\\\n    nsy_g16-plus \\\\\n    bdy_g18-pro/g" package/boot/uboot-rockchip/Makefile


echo -e "\\ndefine Device/nsy_g68-plus
  DEVICE_VENDOR := NSY
  DEVICE_MODEL := G68
  SOC := rk3568
  DEVICE_DTS := rockchip/rk3568-nsy-g68-plus
  SUPPORTED_DEVICES := nsy,g68-plus
  UBOOT_DEVICE_NAME := generic-rk3568
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | pine64-img | gzip | append-metadata
  DEVICE_PACKAGES := kmod-gpio-button-hotplug kmod-nvme kmod-scsi-core kmod-hwmon-pwmfan kmod-thermal kmod-switch-rtl8306 kmod-switch-rtl8366-smi kmod-switch-rtl8366rb kmod-switch-rtl8366s kmod-switch-rtl8367b swconfig kmod-swconfig kmod-r8168 kmod-mt7916-firmware
endef
TARGET_DEVICES += nsy_g68-plus" >> target/linux/rockchip/image/armv8.mk


echo -e "\\ndefine Device/nsy_g16-plus
  DEVICE_VENDOR := NSY
  DEVICE_MODEL := G16
  SOC := rk3568
  DEVICE_DTS := rockchip/rk3568-nsy-g16-plus
  SUPPORTED_DEVICES := nsy,g16-plus
  UBOOT_DEVICE_NAME := generic-rk3568
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | pine64-img | gzip | append-metadata
  DEVICE_PACKAGES := kmod-gpio-button-hotplug kmod-nvme kmod-scsi-core kmod-hwmon-pwmfan kmod-thermal kmod-switch-rtl8306 kmod-switch-rtl8366-smi kmod-switch-rtl8366rb kmod-switch-rtl8366s kmod-switch-rtl8367b swconfig kmod-swconfig kmod-r8168 kmod-mt7615-firmware
endef
TARGET_DEVICES += nsy_g16-plus" >> target/linux/rockchip/image/armv8.mk


echo -e "\\ndefine Device/bdy_g18-pro
  DEVICE_VENDOR := BDY
  DEVICE_MODEL := G18
  SOC := rk3568
  DEVICE_DTS := rockchip/rk3568-bdy-g18-pro
  SUPPORTED_DEVICES := bdy,g18-pro
  UBOOT_DEVICE_NAME := generic-rk3568
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | pine64-img | gzip | append-metadata
  DEVICE_PACKAGES := kmod-gpio-button-hotplug kmod-nvme kmod-scsi-core kmod-hwmon-pwmfan kmod-thermal kmod-switch-rtl8306 kmod-switch-rtl8366-smi kmod-switch-rtl8366rb kmod-switch-rtl8366s kmod-switch-rtl8367b swconfig kmod-swconfig kmod-r8168 kmod-mt7615-firmware
endef
TARGET_DEVICES += bdy_g18-pro" >> target/linux/rockchip/image/armv8.mk


# 加入初始化交换机脚本
cp -f $GITHUB_WORKSPACE/configfiles/swconfig_install package/base-files/files/etc/init.d/swconfig_install
chmod 755 package/base-files/files/etc/init.d/swconfig_install


cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3568-nsy-g68-plus.dts target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/rk3568-nsy-g68-plus.dts
cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3568-nsy-g16-plus.dts target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/rk3568-nsy-g16-plus.dts
cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3568-bdy-g18-pro.dts target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/rk3568-bdy-g18-pro.dts
cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3588-orangepi-5-plus.dts target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/rk3588-orangepi-5-plus.dts


# 集成 nsy_g68-plus WiFi驱动
mkdir -p package/base-files/files/lib/firmware/mediatek
cp -f $GITHUB_WORKSPACE/configfiles/WirelessDriver/mt7916_eeprom.bin package/base-files/files/lib/firmware/mediatek/mt7916_eeprom.bin
cp -f $GITHUB_WORKSPACE/configfiles/WirelessDriver/mt7916_eeprom_backup.bin package/base-files/files/lib/firmware/mediatek/mt7916_eeprom_backup.bin


# rtl8367b驱动资源包，暂时使用这样替换
wget https://github.com/xiaomeng9597/files/releases/download/files/rtl8367b-lede.tar.gz
tar -xvf rtl8367b-lede.tar.gz


# openwrt主线rtl8367b驱动资源包，暂时使用这样替换
# wget https://github.com/xiaomeng9597/files/releases/download/files/rtl8367b-openwrt.tar.gz
# tar -xvf rtl8367b-openwrt.tar.gz
# 适配机型代码结束




# 定时限速插件
git clone --depth=1 https://github.com/sirpdboy/luci-app-eqosplus package/luci-app-eqosplus


./scripts/feeds update -a
./scripts/feeds install -a
