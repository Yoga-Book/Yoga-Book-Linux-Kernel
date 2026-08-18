#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only

set -euo pipefail

config_file=${1:-.config}
if [[ ! -f "$config_file" ]]; then
	echo "Kernel configuration not found: $config_file" >&2
	exit 2
fi

require_config() {
	local symbol=$1
	local expected=$2

	if ! grep -Fqx "$symbol=$expected" "$config_file"; then
		echo "Required kernel option is missing: $symbol=$expected" >&2
		exit 1
	fi
}

require_config CONFIG_X86_ANDROID_TABLETS y
require_config CONFIG_YOGABOOK m

require_config CONFIG_DRM y
require_config CONFIG_DRM_I915 m
require_config CONFIG_DRM_SIMPLEDRM y
require_config CONFIG_SYSFB_SIMPLEFB y
require_config CONFIG_PWM_LPSS y
require_config CONFIG_PWM_LPSS_PLATFORM y
require_config CONFIG_I2C_DESIGNWARE_PLATFORM y

require_config CONFIG_KEYBOARD_GPIO m
require_config CONFIG_INPUT_SOC_BUTTON_ARRAY m
require_config CONFIG_TOUCHSCREEN_GOODIX m
require_config CONFIG_TOUCHSCREEN_HIDEEP m
require_config CONFIG_HID_MULTITOUCH m
require_config CONFIG_HID_WACOM m
require_config CONFIG_I2C_HID_ACPI m
require_config CONFIG_INPUT_DRV260X_HAPTICS m

# Prefer SOF for the RT5677 topology while retaining the complete SST ACPI
# frontend for explicit fallback testing with snd_intel_dspcfg.dsp_driver=2.
require_config CONFIG_SND_SST_ATOM_HIFI2_PLATFORM m
require_config CONFIG_SND_SST_ATOM_HIFI2_PLATFORM_ACPI m
require_config CONFIG_SND_SOC_SOF_BAYTRAIL m
require_config CONFIG_SND_SOC_SOF_IPC3 y
require_config CONFIG_SND_INTEL_BYT_PREFER_SOF y
require_config CONFIG_SND_SOC_INTEL_CHT_YOGABOOK_MACH m
require_config CONFIG_SND_SOC_RT5677 m
require_config CONFIG_SND_SOC_RT5677_SPI m
require_config CONFIG_SND_SOC_TS3A227E m

require_config CONFIG_IPU_BRIDGE m
require_config CONFIG_VIDEO_OV2740 m
require_config CONFIG_VIDEO_OV8858 m
require_config CONFIG_VIDEO_WV517S m
require_config CONFIG_INTEL_ATOMISP y
require_config CONFIG_VIDEO_ATOMISP m

require_config CONFIG_BATTERY_BQ27XXX_I2C m
require_config CONFIG_CHARGER_BQ25890 m
require_config CONFIG_MMC y
require_config CONFIG_MMC_SDHCI m
require_config CONFIG_MMC_SDHCI_ACPI m
require_config CONFIG_USB_ROLE_SWITCH y
require_config CONFIG_EXTCON y
require_config CONFIG_EXTCON_INTEL_CHT_WC m
require_config CONFIG_TYPEC m
require_config CONFIG_TYPEC_TCPM m
require_config CONFIG_TYPEC_FUSB302 m

echo "Yoga Book YB1-X91L configuration check passed: $config_file"
