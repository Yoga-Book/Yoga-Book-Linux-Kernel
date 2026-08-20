#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Schedule and collect one early-boot SOF audio validation pass on a Lenovo
# Yoga Book YB1-X91L. Automated transport/routing results remain separate from
# the physical speaker, microphone, jack, and headset-button acceptance gate.

set -Eeuo pipefail

readonly installed_copy=/usr/local/sbin/yogabook-sof-test
readonly collector_unit=/etc/systemd/system/yogabook-sof-test-collect.service
readonly result_log=/var/log/yogabook-sof-test.log
readonly topology=/lib/firmware/intel/sof-tplg/sof-cht-rt5677.tplg
readonly firmware=/lib/firmware/intel/sof/sof-cht.ri
readonly ucm_alias=/usr/share/alsa/ucm2/conf.d/SOF/LENOVO-LenovoYB1_X91L-X91L.conf

die() {
	echo "ERROR: $*" >&2
	exit 1
}

usage() {
	cat <<'EOF'
Usage:
  sudo ./run-sof-test.sh [--no-reboot] [KERNEL_RELEASE]

The default KERNEL_RELEASE is the currently running kernel when its name
contains "yogabook". The collector runs before the display manager on the
next boot so desktop audio services cannot occupy the capture PCM first.
EOF
}

sha256() {
	sha256sum -- "$1" | awk '{print $1}'
}

collect_results() {
	local expected_release=$1
	local expected_topology_checksum=$2
	local expected_firmware_checksum=$3
	local temporary_log work_dir kernel_log audio_kernel_log trace_log capture_wav
	local running_release dsp_driver card_number card_id_file
	local topology_checksum firmware_checksum ucm_version device output_file trace_source
	local automated_result=PASS
	local sof_selected=false

	temporary_log=$(mktemp /var/log/yogabook-sof-test.XXXXXX)
	work_dir=$(mktemp -d /tmp/yogabook-sof-test.XXXXXX)
	kernel_log=$work_dir/kernel-journal.log
	audio_kernel_log=$work_dir/kernel-audio.log
	trace_log=$work_dir/sof-trace.log
	: >"$trace_log"
	capture_wav=$work_dir/mic1.wav
	running_release=$(uname -r)
	dsp_driver=unavailable
	card_number=""
	card_id_file=""

	mark_fail() {
		echo "FAIL: $*"
		automated_result=FAIL
	}

	run_check() {
		local label=$1
		shift
		echo "-- $label"
		if timeout 20 "$@"; then
			echo "PASS: $label"
		else
			mark_fail "$label"
		fi
		echo
	}

	# sound.target registers the card before this collector starts. Keep a
	# bounded fallback wait for slow probe/deferred-probe boots.
	for _ in {1..30}; do
		for card_id_file in /proc/asound/card*/id; do
			[[ -r $card_id_file ]] || continue
			if [[ $(< "$card_id_file") == yogabook ]]; then
				card_number=${card_id_file#/proc/asound/card}
				card_number=${card_number%/id}
				break 2
			fi
		done
		sleep 1
	done

	if [[ -r /sys/module/snd_intel_dspcfg/parameters/dsp_driver ]]; then
		dsp_driver=$(< /sys/module/snd_intel_dspcfg/parameters/dsp_driver)
	fi
	journalctl -b -k --no-pager >"$kernel_log" 2>&1 || true
	grep -Ei 'sof|snd|audio|topology|tplg|rt5677|yogabook|ipc|pcm' "$kernel_log" \
		>"$audio_kernel_log" || true

	{
		echo "Yoga Book SOF early-boot validation"
		echo "Captured: $(date --iso-8601=seconds)"
		echo "Expected kernel: $expected_release"
		echo "Expected topology SHA-256: $expected_topology_checksum"
		echo "Expected firmware SHA-256: $expected_firmware_checksum"
		echo

		echo '== Running kernel and command line =='
		uname -a
		cat /proc/cmdline
		echo

		echo '== GRUB environment =='
		grub-editenv list || true
		echo

		echo '== Intel DSP selection =='
		echo "dsp_driver=$dsp_driver"
		lsmod | grep -E '^(snd_sof|snd_soc_sst)' || true
		echo

		echo '== ALSA card discovery =='
		cat /proc/asound/cards 2>/dev/null || true
		for output_file in /proc/asound/card*/id; do
			[[ -r $output_file ]] || continue
			printf '%s: ' "$output_file"
			cat "$output_file"
		done
		if [[ -n $card_number ]]; then
			echo "Discovered yogabook card number: $card_number"
		else
			mark_fail "ALSA card ID yogabook was not found"
		fi
		echo

		echo '== ALSA card files =='
		if [[ -n $card_number ]]; then
			find "/proc/asound/card$card_number" -maxdepth 2 -type f -print -exec sh -c \
				'for file do echo "--- $file"; cat "$file" 2>/dev/null || true; done' sh {} + || true
		fi
		echo

		[[ $running_release == "$expected_release" ]] ||
			mark_fail "running kernel $running_release does not match $expected_release"
		if grep -Fq 'snd_intel_dspcfg.dsp_driver=2' /proc/cmdline; then
			mark_fail "legacy SST is forced on the kernel command line"
		fi

		if [[ $dsp_driver == 3 ]]; then
			sof_selected=true
		elif [[ $dsp_driver == 0 && -n $card_number && -s $firmware && -s $topology ]] &&
			lsmod | grep -q '^snd_sof'; then
			sof_selected=true
		fi
		$sof_selected || mark_fail "SOF was not selected (dsp_driver=$dsp_driver)"
		lsmod | grep -q '^snd_sof' || mark_fail "no snd_sof module is loaded"

		echo '== Deployed artifacts =='
		if [[ -s $topology ]]; then
			topology_checksum=$(sha256 "$topology")
			echo "$topology_checksum  $topology"
			[[ $topology_checksum == "$expected_topology_checksum" ]] ||
				mark_fail "topology checksum differs from the scheduled artifact"
		else
			mark_fail "SOF topology is missing: $topology"
		fi
		if [[ -s $firmware ]]; then
			firmware_checksum=$(sha256 "$firmware")
			echo "$firmware_checksum  $firmware"
			[[ $firmware_checksum == "$expected_firmware_checksum" ]] ||
				mark_fail "firmware checksum differs from the scheduled artifact"
		else
			mark_fail "exact SOF firmware is missing: $firmware"
		fi
		if [[ -L $ucm_alias ]]; then
			printf '%s -> %s\n' "$ucm_alias" "$(readlink -- "$ucm_alias")"
			[[ $(readlink -- "$ucm_alias") == ../../cht-yogabook/cht-yogabook.conf ]] ||
				mark_fail "UCM SOF alias has an unexpected target"
			readlink -e -- "$ucm_alias" >/dev/null || mark_fail "UCM SOF alias is broken"
		else
			mark_fail "UCM SOF long-name alias is missing"
		fi
		ucm_version=$(dpkg-query -W -f='${Version}' alsa-ucm-conf-yogabook 2>/dev/null || true)
		echo "alsa-ucm-conf-yogabook=$ucm_version"
		if [[ -z $ucm_version ]] || ! dpkg --compare-versions "$ucm_version" ge 1.6; then
			mark_fail "alsa-ucm-conf-yogabook 1.6 or newer is not installed"
		fi
		echo

		echo '== ALSA device enumeration =='
		aplay -l 2>&1 | tee "$work_dir/aplay-l.log" || mark_fail "aplay device enumeration failed"
		arecord -l 2>&1 | tee "$work_dir/arecord-l.log" || mark_fail "arecord device enumeration failed"
		if [[ -n $card_number ]]; then
			grep -Eq "^card[[:space:]]+$card_number:.*device[[:space:]]+0:" "$work_dir/aplay-l.log" ||
				mark_fail "PCM0 playback device is missing"
			grep -Eq "^card[[:space:]]+$card_number:.*device[[:space:]]+1:" "$work_dir/aplay-l.log" ||
				mark_fail "PCM1 deep-buffer playback device is missing"
			grep -Eq "^card[[:space:]]+$card_number:.*device[[:space:]]+0:" "$work_dir/arecord-l.log" ||
				mark_fail "PCM0 capture device is missing"
		fi
		echo

		echo '== UCM import and devices =='
		if alsaucm -c hw:yogabook list _verbs >"$work_dir/ucm-verbs.log" 2>&1; then
			cat "$work_dir/ucm-verbs.log"
		else
			cat "$work_dir/ucm-verbs.log"
			mark_fail "alsaucm could not import the yogabook configuration"
		fi
		if alsaucm -c hw:yogabook set _verb HiFi list _devices \
			>"$work_dir/ucm-devices.log" 2>&1; then
			cat "$work_dir/ucm-devices.log"
			for device in Speaker1 Headphones Mic1 Headset; do
				grep -Fq "$device" "$work_dir/ucm-devices.log" ||
					mark_fail "UCM device $device is not enumerated"
			done
		else
			cat "$work_dir/ucm-devices.log"
			mark_fail "alsaucm could not enumerate yogabook devices"
		fi
		if grep -Eiq '(error|failed|unable|syntax|import)' "$work_dir"/ucm-*.log; then
			mark_fail "UCM output contains an import/configuration error"
		fi
		echo

		if [[ -n $card_number ]]; then
			device="hw:$card_number,0"
			run_check "enable HiFi Speaker1 and Mic1 routes" \
				alsaucm -c hw:yogabook set _verb HiFi \
				set _enadev Speaker1 set _enadev Mic1

			echo '== Direct PCM0 transport matrix =='
			for format in S16_LE S24_LE S32_LE; do
				run_check "PCM0 playback $format 48 kHz stereo" \
					aplay -q -D "$device" -t raw -f "$format" -r 48000 -c 2 -d 1 /dev/zero
				run_check "PCM0 capture $format 48 kHz stereo" \
					arecord -q -D "$device" -t raw -f "$format" -r 48000 -c 2 -d 1 /dev/null
			done
			run_check "PCM1 deep-buffer playback S32_LE 48 kHz stereo" \
				aplay -q -D "hw:$card_number,1" -t raw -f S32_LE -r 48000 -c 2 -d 1 /dev/zero

			echo '== Routed tone and microphone signal =='
			run_check "bounded Speaker1 test tone" \
				speaker-test -D "$device" -t sine -f 440 -c 2 -r 48000 -F S16_LE -l 1
			run_check "Mic1 three-second WAV capture" \
				arecord -q -D "$device" -t wav -f S16_LE -r 48000 -c 2 -d 3 "$capture_wav"
			if [[ -s $capture_wav ]]; then
				if python3 - "$capture_wav" <<'PY'
import math
import struct
import sys
import wave

with wave.open(sys.argv[1], "rb") as recording:
    if recording.getsampwidth() != 2:
        raise SystemExit("unexpected WAV sample width")
    frames = recording.readframes(recording.getnframes())
samples = struct.unpack(f"<{len(frames) // 2}h", frames)
if not samples:
    raise SystemExit("WAV contains no samples")
peak = max(abs(sample) for sample in samples)
rms = math.sqrt(sum(sample * sample for sample in samples) / len(samples))
print(f"Mic1 peak={peak} ({peak / 32768:.6f} FS)")
print(f"Mic1 RMS={rms:.2f} ({rms / 32768:.6f} FS)")
if peak == 0 or rms == 0:
    raise SystemExit("Mic1 capture is digitally empty")
PY
				then
					echo 'PASS: Mic1 WAV contains a non-empty signal'
				else
					mark_fail "Mic1 WAV is empty or invalid"
				fi
			else
				mark_fail "Mic1 WAV was not created"
			fi
		fi

		echo
		echo '== SOF debugfs and firmware trace =='
		if [[ -d /sys/kernel/debug/sof ]]; then
			find /sys/kernel/debug/sof -maxdepth 2 -printf '%M %s %p\n' 2>&1 || true
			trace_source=""
			for output_file in /sys/kernel/debug/sof/trace /sys/kernel/debug/sof/etrace; do
				if [[ -r $output_file ]]; then
					trace_source=$output_file
					break
				fi
			done
			if [[ -n $trace_source ]]; then
				echo "SOF trace source: $trace_source"
				timeout 5 head -c 1048576 "$trace_source" >"$trace_log" 2>&1 || true
				if [[ ! -s $trace_log ]]; then
					echo 'SOF trace is empty (no firmware trace records).'
				fi
				cat "$trace_log"
			else
				mark_fail "SOF trace and error trace are unavailable"
			fi
		else
			mark_fail "SOF debugfs directory is unavailable"
		fi

		echo
		echo '== Complete kernel journal =='
		cat "$kernel_log"

		failure_pattern='((error|fail).*(firmware|topology|tplg)|(firmware|topology|tplg).*(error|fail))|ipc.*(error|fail|timeout|timed out)|(error|fail).*ipc|STREAM_PCM_PARAMS.*(error|fail)|(error|fail).*STREAM_PCM_PARAMS|failed to set pcm params|((error|fail).*pcm params|pcm params.*(error|fail))'
		if grep -Eiq "$failure_pattern" "$audio_kernel_log" "$trace_log" 2>/dev/null; then
			mark_fail "kernel journal or SOF trace contains a firmware/topology/IPC/PCM_PARAMS failure"
		fi

		echo
		echo "AUTOMATED_TRANSPORT_RESULT: $automated_result"
		echo 'PHYSICAL_ACCEPTANCE_RESULT: PENDING'
		echo 'Automated PASS covers SOF selection, artifacts, UCM routing, direct PCM opens,'
		echo 'a bounded routed tone, and a non-empty capture. It does not prove transducers.'
		echo 'Still required: speakers, headphones, internal microphone, headset microphone,'
		echo 'jack detection, headset buttons, three cold boots, and five suspend/resume cycles.'
	} >"$temporary_log" 2>&1

	chmod 0644 "$temporary_log"
	mv -f -- "$temporary_log" "$result_log"
	rm -rf -- "$work_dir"
	systemctl disable yogabook-sof-test-collect.service >/dev/null 2>&1 || true

	[[ $automated_result == PASS ]]
}

if [[ ${1:-} == --collect ]]; then
	[[ $(id -u) -eq 0 ]] || die "the collector must run as root"
	[[ $# -eq 4 ]] || die "the collector requires kernel, topology, and firmware expectations"
	collect_results "$2" "$3" "$4"
	exit $?
fi

reboot_after_prepare=true
if [[ ${1:-} == --no-reboot ]]; then
	reboot_after_prepare=false
	shift
fi

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
	usage
	exit 0
fi

[[ $# -le 1 ]] || {
	usage >&2
	exit 2
}
[[ $(id -u) -eq 0 ]] || die "run this script as root (for example, with sudo)"

for command in alsaucm aplay arecord awk dpkg dpkg-query find grub-editenv \
	grub-reboot grub-set-default install journalctl lsmod python3 readlink \
	realpath sha256sum speaker-test systemctl timeout update-grub; do
	command -v "$command" >/dev/null 2>&1 || die "required command is missing: $command"
done

[[ -r /etc/os-release ]] || die "cannot identify the operating system"
# shellcheck disable=SC1091
. /etc/os-release
[[ ${ID:-} == ubuntu ]] || die "unsupported operating system: ${PRETTY_NAME:-unknown}"
case ${VERSION_ID:-} in
	24.04 | 26.04) ;;
	*) die "unsupported Ubuntu release: ${VERSION_ID:-unknown}" ;;
esac

[[ -r /sys/class/dmi/id/product_name ]] || die "DMI product name is unavailable"
product_name=$(< /sys/class/dmi/id/product_name)
[[ $product_name == *YB1-X91L* ]] || die "unsupported hardware: $product_name"

running_release=$(uname -r)
target_release=${1:-}
if [[ -z $target_release && $running_release == *yogabook* ]]; then
	target_release=$running_release
fi
[[ -n $target_release ]] || die "specify the installed Yoga Book kernel release to test"
[[ $target_release =~ ^[A-Za-z0-9._+-]+$ ]] || die "invalid kernel release: $target_release"
[[ $target_release == *yogabook* ]] || die "not a Yoga Book kernel: $target_release"

[[ -r /boot/vmlinuz-$target_release ]] || die "kernel image is missing: /boot/vmlinuz-$target_release"
[[ -r /boot/initrd.img-$target_release ]] || die "initramfs is missing: /boot/initrd.img-$target_release"
[[ -r /boot/config-$target_release ]] || die "kernel configuration is missing: /boot/config-$target_release"
grep -Fqx 'CONFIG_SND_INTEL_BYT_PREFER_SOF=y' /boot/config-"$target_release" ||
	die "the target kernel is not configured to prefer SOF"
grep -Fqx 'CONFIG_SND_SOC_SOF_BAYTRAIL=m' /boot/config-"$target_release" ||
	die "the target kernel does not provide Cherry Trail SOF support"

[[ -s $topology ]] || die "SOF topology is missing: $topology"
[[ -s $firmware ]] || die "exact SOF firmware is missing: $firmware"
[[ -L $ucm_alias ]] || die "Yoga Book SOF UCM alias is missing: $ucm_alias"
[[ $(readlink -- "$ucm_alias") == ../../cht-yogabook/cht-yogabook.conf ]] ||
	die "Yoga Book SOF UCM alias has an unexpected target"
readlink -e -- "$ucm_alias" >/dev/null || die "Yoga Book SOF UCM alias is broken"
ucm_version=$(dpkg-query -W -f='${Version}' alsa-ucm-conf-yogabook 2>/dev/null) ||
	die "alsa-ucm-conf-yogabook is not installed"
dpkg --compare-versions "$ucm_version" ge 1.6 ||
	die "alsa-ucm-conf-yogabook 1.6 or newer is required"
topology_checksum=$(sha256 "$topology")
firmware_checksum=$(sha256 "$firmware")

saved_entry=$(grub-editenv list | sed -n 's/^saved_entry=//p')
fallback_release=""
if [[ $saved_entry == *'Ubuntu, with Linux '* ]]; then
	fallback_release=${saved_entry##*Ubuntu, with Linux }
fi
if [[ $fallback_release == *yogabook* || ! -r /boot/vmlinuz-$fallback_release ]]; then
	fallback_release=""
fi
if [[ -z $fallback_release && $running_release != *yogabook* && -r /boot/vmlinuz-$running_release ]]; then
	fallback_release=$running_release
fi
if [[ -z $fallback_release ]]; then
	for candidate in /boot/vmlinuz-*; do
		[[ -e $candidate ]] || continue
		if [[ ${candidate##*/} != *yogabook* ]]; then
			fallback_release=${candidate##*/vmlinuz-}
			break
		fi
	done
fi
[[ -n $fallback_release ]] || die "no generic fallback kernel was found"

backup_timestamp=$(date +%Y%m%d-%H%M%S)
grub_sources=(/etc/default/grub)
[[ -e /etc/kernel/cmdline ]] && grub_sources+=(/etc/kernel/cmdline)
for source in /etc/default/grub.d/*.cfg; do
	[[ -e $source ]] && grub_sources+=("$source")
done

changed_sources=()
for source in "${grub_sources[@]}"; do
	if grep -Fq 'snd_intel_dspcfg.dsp_driver=2' "$source"; then
		if [[ ${source##*/} == 99-yogabook-sst-test.cfg ]]; then
			disabled_source="$source.disabled-$backup_timestamp"
			mv -- "$source" "$disabled_source"
			changed_sources+=("$source -> $disabled_source")
		else
			cp --archive -- "$source" "$source.backup-$backup_timestamp"
			sed -i 's/snd_intel_dspcfg\.dsp_driver=2//g' "$source"
			changed_sources+=("$source")
		fi
	fi
done

active_sst_sources=()
for source in /etc/default/grub /etc/kernel/cmdline /etc/default/grub.d/*.cfg; do
	[[ -e $source ]] || continue
	grep -Fq 'snd_intel_dspcfg.dsp_driver=2' "$source" && active_sst_sources+=("$source")
done
[[ ${#active_sst_sources[@]} -eq 0 ]] ||
	die "legacy SST remains forced by: ${active_sst_sources[*]}"

update-grub
grep -Fq 'snd_intel_dspcfg.dsp_driver=2' /boot/grub/grub.cfg &&
	die "the generated GRUB menu still contains the legacy SST override"
# GRUB expands this variable at boot; the generated script must retain it.
# shellcheck disable=SC2016
grep -Fq 'set default="${saved_entry}"' /boot/grub/grub.cfg ||
	die "the generated GRUB menu does not honor the saved generic fallback"
fallback_entry="Advanced options for Ubuntu>Ubuntu, with Linux $fallback_release"
test_entry="Advanced options for Ubuntu>Ubuntu, with Linux $target_release"
grep -Fq "Ubuntu, with Linux $fallback_release" /boot/grub/grub.cfg ||
	die "the generic fallback entry is missing from GRUB"
grep -Fq "Ubuntu, with Linux $target_release" /boot/grub/grub.cfg ||
	die "the Yoga Book test entry is missing from GRUB"

grub-set-default "$fallback_entry"
grub-reboot "$test_entry"
grub_environment=$(grub-editenv list)
grep -Fqx "saved_entry=$fallback_entry" <<<"$grub_environment" ||
	die "GRUB did not retain the generic fallback"
grep -Fqx "next_entry=$test_entry" <<<"$grub_environment" ||
	die "GRUB did not retain the one-shot test entry"

install -D -m 0755 -- "$(realpath -e -- "$0")" "$installed_copy"
cat >"$collector_unit" <<EOF
[Unit]
Description=Collect Yoga Book SOF early-boot evidence
After=local-fs.target systemd-modules-load.service sound.target
Before=display-manager.service graphical.target

[Service]
Type=oneshot
ExecStart=$installed_copy --collect $target_release $topology_checksum $firmware_checksum

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable yogabook-sof-test-collect.service >/dev/null

echo "Tablet:                  $product_name"
echo "SOF test kernel:         $target_release"
echo "Persistent fallback:     $fallback_release"
echo "Topology SHA-256:        $topology_checksum"
echo "Firmware SHA-256:        $firmware_checksum"
echo "Automatic result log:    $result_log"
if [[ ${#changed_sources[@]} -eq 0 ]]; then
	echo "Legacy SST override:     already absent"
else
	printf 'Changed GRUB source:     %s\n' "${changed_sources[@]}"
fi
echo "One-shot GRUB entry:     $test_entry"
echo "Physical acceptance:     pending"

if $reboot_after_prepare; then
	echo "Rebooting in 5 seconds. Press Ctrl+C now to cancel the reboot."
	sleep 5
	systemctl reboot
else
	echo "Preparation complete. Run 'sudo systemctl reboot' when ready."
fi
