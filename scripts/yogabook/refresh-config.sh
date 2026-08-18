#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only

set -euo pipefail

if (( $# != 0 )); then
	echo "Usage: $0" >&2
	exit 2
fi

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

# Pin the official Ubuntu amd64-generic package so identical source commits
# always start from identical distro configuration policy. These values may be
# deliberately overridden together when refreshing the generic baseline.
ubuntu_kernel_release=${UBUNTU_KERNEL_RELEASE:-7.0.0-29-generic}
ubuntu_package_version=${UBUNTU_PACKAGE_VERSION:-7.0.0-29.29}
ubuntu_package_sha256=${UBUNTU_PACKAGE_SHA256:-f2cb0d39f99b4adb05d2ee648265df3d552ac522735c17d396162447cc2d4b6a}
ubuntu_archive_base=${UBUNTU_ARCHIVE_BASE:-https://archive.ubuntu.com/ubuntu}

package_name="linux-headers-${ubuntu_kernel_release}_${ubuntu_package_version}_amd64.deb"
package_url="${ubuntu_archive_base}/pool/main/l/linux/${package_name}"
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/yogabook-config.XXXXXXXX")
trap 'rm -rf -- "$work_dir"' EXIT

echo "Downloading official Ubuntu generic configuration: $package_url"
curl --fail --location --silent --show-error \
	--output "$work_dir/$package_name" "$package_url"
printf '%s  %s\n' "$ubuntu_package_sha256" "$work_dir/$package_name" |
	sha256sum --check --status

dpkg-deb --extract "$work_dir/$package_name" "$work_dir/package"
ubuntu_config="$work_dir/package/usr/src/linux-headers-${ubuntu_kernel_release}/.config"
if [[ ! -s "$ubuntu_config" ]]; then
	echo "Ubuntu generic configuration not found in $package_name" >&2
	exit 1
fi

cp "$ubuntu_config" .config

# Platform enumeration and Yoga Book mode/backlight control.
scripts/config --enable X86_ANDROID_TABLETS
scripts/config --module YOGABOOK

# Display and LPSS PWM. Modular i915 plus built-in LPSS PWM matches the
# physically working generic-kernel arrangement on the YB1-X91L.
scripts/config --enable DRM
scripts/config --module DRM_I915
scripts/config --enable DRM_SIMPLEDRM
scripts/config --enable SYSFB_SIMPLEFB
scripts/config --enable PWM
scripts/config --enable PWM_LPSS
scripts/config --enable PWM_LPSS_PLATFORM
scripts/config --enable I2C_DESIGNWARE_PLATFORM

# Halo keyboard, touchscreens, digitizer and dual DRV2604 haptics.
scripts/config --module KEYBOARD_GPIO
scripts/config --module INPUT_SOC_BUTTON_ARRAY
scripts/config --module TOUCHSCREEN_GOODIX
scripts/config --module TOUCHSCREEN_HIDEEP
scripts/config --module HID_MULTITOUCH
scripts/config --module HID_WACOM
scripts/config --module I2C_HID_ACPI
scripts/config --module INPUT_DRV260X_HAPTICS

# RT5677 uses intel/fw_sst_22a8.bin through the legacy Cherry Trail SST ACPI
# frontend. There is no published sof-cht-rt5677 topology, so never inherit
# Ubuntu's SOF preference here. Other SOF modules remain available.
scripts/config --module SND_SST_ATOM_HIFI2_PLATFORM_ACPI
scripts/config --disable SND_INTEL_BYT_PREFER_SOF
scripts/config --module SND_SOC_INTEL_CHT_YOGABOOK_MACH
scripts/config --module SND_SOC_RT5677
scripts/config --module SND_SOC_RT5677_SPI
scripts/config --module SND_SOC_TS3A227E

# Front/rear cameras, rear autofocus and AtomISP pipeline.
scripts/config --module IPU_BRIDGE
scripts/config --module VIDEO_OV2740
scripts/config --module VIDEO_OV8858
scripts/config --module VIDEO_WV517S
scripts/config --enable INTEL_ATOMISP
scripts/config --module VIDEO_ATOMISP

# Battery, charger, storage and Cherry Trail connector support.
scripts/config --module BATTERY_BQ27XXX
scripts/config --module BATTERY_BQ27XXX_I2C
scripts/config --module CHARGER_BQ25890
scripts/config --enable MMC
scripts/config --module MMC_SDHCI
scripts/config --module MMC_SDHCI_ACPI
scripts/config --enable USB_ROLE_SWITCH
scripts/config --enable EXTCON
scripts/config --module EXTCON_INTEL_CHT_WC
scripts/config --module TYPEC
scripts/config --module TYPEC_TCPM
scripts/config --module TYPEC_FUSB302

# Ubuntu certificate files are not part of an upstream Linux checkout.
scripts/config --set-str SYSTEM_TRUSTED_KEYS ""
scripts/config --set-str SYSTEM_REVOCATION_KEYS ""
scripts/config --set-str LOCALVERSION ""
scripts/config --disable LOCALVERSION_AUTO

make olddefconfig
make syncconfig

scripts/yogabook/check-config.sh .config

kernel_release=$(make -s LOCALVERSION= kernelrelease)
if [[ "$kernel_release" != "7.2.0" ]]; then
	echo "Unexpected baseline kernel release: $kernel_release (expected 7.2.0)" >&2
	exit 1
fi

make savedefconfig
mv defconfig arch/x86/configs/yogabook_x91l_defconfig

echo "Ubuntu baseline: ${ubuntu_kernel_release} (${ubuntu_package_version})"
echo "Ubuntu package SHA-256: $ubuntu_package_sha256"
echo "Updated: arch/x86/configs/yogabook_x91l_defconfig"
