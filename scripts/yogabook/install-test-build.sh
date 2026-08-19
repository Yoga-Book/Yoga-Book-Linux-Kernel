#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Install and validate a Yoga Book kernel, SOF topology, and UCM package on a
# Lenovo Yoga Book YB1-X91L. The generic Ubuntu kernel remains the persistent
# default; --schedule-next-boot selects the Yoga Book kernel for one boot only.

set -Eeuo pipefail

usage() {
	cat <<'EOF'
Usage:
  sudo ./install-test-build.sh [--schedule-next-boot] \
    LINUX_IMAGE_DEB LINUX_HEADERS_DEB SOF_TOPOLOGY UCM_DEB

Example:
  sudo ./install-test-build.sh --schedule-next-boot \
    ./linux-image-7.2.0-yogabook-20260819-004412_*.deb \
    ./linux-headers-7.2.0-yogabook-20260819-004412_*.deb \
    ./sof-cht-rt5677.tplg \
    ./alsa-ucm-conf-yogabook_1.6_all.deb
EOF
}

die() {
	echo "ERROR: $*" >&2
	exit 1
}

sha256() {
	sha256sum -- "$1" | awk '{print $1}'
}

verify_topology() {
	python3 - "$1" <<'PY'
import struct
import sys

path = sys.argv[1]
data = open(path, "rb").read()
header = struct.Struct("<9I")
offset = 0
links = []

while offset < len(data):
    if len(data) - offset < header.size:
        raise SystemExit("truncated topology header")
    magic, abi, _, block_type, size, _, payload_size, _, count = header.unpack_from(data, offset)
    if magic != 0x41536F43 or abi != 5 or size != header.size:
        raise SystemExit("invalid topology header or ABI")
    start = offset + size
    end = start + payload_size
    if end > len(data):
        raise SystemExit("truncated topology payload")
    if block_type == 10:
        record_offset = start
        for _ in range(count):
            if end - record_offset < 1656:
                raise SystemExit("truncated backend-link record")
            record_size = struct.unpack_from("<I", data, record_offset)[0]
            private_size = struct.unpack_from("<I", data, record_offset + 1652)[0]
            if record_size != 1656 or record_offset + record_size + private_size > end:
                raise SystemExit("invalid backend-link record")
            links.append(data[record_offset:record_offset + record_size + private_size])
            record_offset += record_size + private_size
        if record_offset != end:
            raise SystemExit("backend-link block contains trailing data")
    offset = end

if offset != len(data) or len(links) != 1:
    raise SystemExit(f"expected one backend link, found {len(links)}")

link = links[0]
name = link[8:52].split(b"\0", 1)[0].decode("ascii")
u32 = lambda at: struct.unpack_from("<I", link, at)[0]
if name != "SSP2-Codec" or u32(1636) != 1 or u32(1640) != 0:
    raise SystemExit("invalid SSP2-Codec hardware-configuration selection")

hw = link[676:796]
word = lambda at: struct.unpack_from("<I", hw, at)[0]
actual = (
    word(0), word(4), word(8), hw[13], hw[14], hw[15], hw[16], hw[17],
    word(20), word(24), word(28), word(32), word(36), word(40), word(44),
)
expected = (
    120, 0, 5, 1, 0, 1, 1, 1,
    19_200_000, 4_800_000, 48_000, 4, 25, 0x3, 0x3,
)
if actual != expected:
    raise SystemExit(f"invalid SSP2 hardware configuration: {actual!r}")

private_size = u32(1652)
private = link[1656:1656 + private_size]
offset = 0
sample_bits = []
while offset < len(private):
    if len(private) - offset < 12:
        raise SystemExit("truncated SSP2 vendor array")
    array_size, tuple_type, count = struct.unpack_from("<III", private, offset)
    element_size = 48 if tuple_type == 1 else 8
    if array_size < 12 or offset + array_size > len(private) or 12 + count * element_size != array_size:
        raise SystemExit("invalid SSP2 vendor array")
    for element in range(count):
        element_offset = offset + 12 + element * element_size
        token, value = struct.unpack_from("<II", private, element_offset)
        if token == 502:
            sample_bits.append(value)
    offset += array_size
if sample_bits != [24]:
    raise SystemExit(f"SSP2 valid sample bits must be 24, found {sample_bits!r}")
PY
}

schedule_next_boot=false
if [[ ${1:-} == --schedule-next-boot ]]; then
	schedule_next_boot=true
	shift
fi

[[ $# -eq 4 ]] || {
	usage >&2
	exit 2
}
[[ $(id -u) -eq 0 ]] || die "run this script as root (for example, with sudo)"

image_deb=$(realpath -e -- "$1")
headers_deb=$(realpath -e -- "$2")
topology_file=$(realpath -e -- "$3")
ucm_deb=$(realpath -e -- "$4")

for command in apt-get awk cmp dpkg dpkg-deb find grub-editenv grub-reboot \
	grub-set-default install mokutil python3 readlink realpath sha256sum \
	update-grub update-initramfs; do
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

secure_boot_state=$(mokutil --sb-state 2>&1 || true)
grep -qi "SecureBoot disabled" <<<"$secure_boot_state" ||
	die "Secure Boot is not confirmed disabled: $secure_boot_state"

package_field() {
	dpkg-deb -f "$1" "$2"
}

image_package=$(package_field "$image_deb" Package)
headers_package=$(package_field "$headers_deb" Package)
ucm_package=$(package_field "$ucm_deb" Package)
image_arch=$(package_field "$image_deb" Architecture)
headers_arch=$(package_field "$headers_deb" Architecture)
ucm_version=$(package_field "$ucm_deb" Version)

[[ $image_package == linux-image-*yogabook* ]] ||
	die "not a Yoga Book kernel image package: $image_package"
[[ $headers_package == linux-headers-*yogabook* ]] ||
	die "not a Yoga Book kernel headers package: $headers_package"
kernel_release=${image_package#linux-image-}
headers_release=${headers_package#linux-headers-}
[[ $kernel_release == "$headers_release" ]] ||
	die "kernel image and headers releases do not match"

host_arch=$(dpkg --print-architecture)
[[ $image_arch == "$host_arch" && $headers_arch == "$host_arch" ]] ||
	die "kernel package architecture does not match the tablet ($host_arch)"
[[ $ucm_package == alsa-ucm-conf-yogabook ]] || die "unexpected UCM package: $ucm_package"
dpkg --compare-versions "$ucm_version" ge 1.6 ||
	die "alsa-ucm-conf-yogabook 1.6 or newer is required for SOF discovery"

[[ ${topology_file##*/} == sof-cht-rt5677.tplg ]] ||
	die "the topology must be named sof-cht-rt5677.tplg"
[[ -s $topology_file ]] || die "the SOF topology is empty"
verify_topology "$topology_file" || die "compiled SOF topology verification failed"

package_root=$(mktemp -d /tmp/yogabook-ucm.XXXXXX)
trap 'rm -rf -- "$package_root"' EXIT
dpkg-deb -x "$ucm_deb" "$package_root"
ucm_root=$package_root/usr/share/alsa/ucm2
sof_alias=$ucm_root/conf.d/SOF/LENOVO-LenovoYB1_X91L-X91L.conf
packaged_ucm_config=$ucm_root/cht-yogabook/cht-yogabook.conf
[[ -L $sof_alias ]] || die "UCM package is missing the SOF long-name alias"
[[ $(readlink -- "$sof_alias") == ../../cht-yogabook/cht-yogabook.conf ]] ||
	die "UCM SOF alias has an unexpected target"
while IFS= read -r -d '' link; do
	target=$(readlink -- "$link")
	[[ $target != /* ]] || die "UCM package contains an absolute symlink: $link"
	readlink -e -- "$link" >/dev/null || die "UCM package contains a broken symlink: $link"
done < <(find "$ucm_root" -type l -print0)

topology_checksum=$(sha256 "$topology_file")
ucm_deb_checksum=$(sha256 "$ucm_deb")
ucm_config_checksum=$(sha256 "$packaged_ucm_config")

fallback_kernel=""
running_release=$(uname -r)
if [[ $running_release != *yogabook* && -r /boot/vmlinuz-$running_release ]]; then
	fallback_kernel=/boot/vmlinuz-$running_release
fi
for candidate in /boot/vmlinuz-*; do
	[[ -e $candidate ]] || continue
	if [[ -z $fallback_kernel && ${candidate##*/} != *yogabook* ]]; then
		fallback_kernel=$candidate
	fi
done
[[ -n $fallback_kernel ]] || die "no generic fallback kernel was found in /boot"
fallback_release=${fallback_kernel##*/vmlinuz-}

echo "Tablet:            $product_name"
echo "Kernel release:    $kernel_release"
echo "Fallback kernel:   ${fallback_kernel##*/}"
echo "UCM package:       $ucm_package $ucm_version"
echo "Topology SHA-256:  $topology_checksum"
echo "UCM DEB SHA-256:   $ucm_deb_checksum"
echo "UCM config SHA-256:$ucm_config_checksum"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install --yes \
	alsa-utils \
	firmware-sof-signed \
	"$headers_deb" \
	"$image_deb" \
	"$ucm_deb"

readonly topology_destination=/lib/firmware/intel/sof-tplg/sof-cht-rt5677.tplg
readonly firmware=/lib/firmware/intel/sof/sof-cht.ri
readonly deployed_ucm_root=/usr/share/alsa/ucm2
readonly deployed_sof_alias=$deployed_ucm_root/conf.d/SOF/LENOVO-LenovoYB1_X91L-X91L.conf

if [[ -e $topology_destination ]] && ! cmp -s "$topology_file" "$topology_destination"; then
	backup_timestamp=$(date +%Y%m%d-%H%M%S)
	cp --archive -- "$topology_destination" "$topology_destination.backup-$backup_timestamp"
fi
install -D -m 0644 -- "$topology_file" "$topology_destination"
update-initramfs -u -k "$kernel_release"

[[ -s $firmware ]] || die "exact Cherry Trail SOF firmware is missing: $firmware"
[[ -s $topology_destination ]] || die "deployed SOF topology is missing"
cmp -s "$topology_file" "$topology_destination" || die "deployed topology differs from input"
verify_topology "$topology_destination" || die "deployed topology verification failed"
[[ $(sha256 "$topology_destination") == "$topology_checksum" ]] ||
	die "deployed topology checksum does not match"
[[ -L $deployed_sof_alias ]] || die "deployed UCM SOF alias is missing"
[[ $(readlink -- "$deployed_sof_alias") == ../../cht-yogabook/cht-yogabook.conf ]] ||
	die "deployed UCM SOF alias has an unexpected target"
readlink -e -- "$deployed_sof_alias" >/dev/null || die "deployed UCM SOF alias is broken"
[[ -r $deployed_ucm_root/cht-yogabook/cht-yogabook.conf ]] ||
	die "deployed Yoga Book UCM configuration is missing"
[[ $(sha256 "$deployed_ucm_root/cht-yogabook/cht-yogabook.conf") == "$ucm_config_checksum" ]] ||
	die "deployed Yoga Book UCM configuration checksum does not match the package"
[[ -r /boot/vmlinuz-$kernel_release ]] || die "the new kernel image is missing from /boot"

installed_ucm_version=$(dpkg-query -W -f='${Version}' alsa-ucm-conf-yogabook)
[[ $installed_ucm_version == "$ucm_version" ]] || die "installed UCM version differs from input"
firmware_checksum=$(sha256 "$firmware")
echo "Firmware path:     $firmware"
echo "Firmware SHA-256:  $firmware_checksum"

grub_defaults=/etc/default/grub
[[ -r $grub_defaults ]] || die "$grub_defaults is unavailable"
if ! grep -Eq '^[[:space:]]*GRUB_DEFAULT="?saved"?[[:space:]]*$' "$grub_defaults" ||
	grep -Eq '^[[:space:]]*GRUB_SAVEDEFAULT="?true"?[[:space:]]*$' "$grub_defaults"; then
	grub_backup="$grub_defaults.yogabook-backup-$(date +%Y%m%d-%H%M%S)"
	cp --archive -- "$grub_defaults" "$grub_backup"
	if grep -Eq '^[[:space:]]*GRUB_DEFAULT=' "$grub_defaults"; then
		sed -i -E 's/^[[:space:]]*GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' "$grub_defaults"
	else
		printf '\nGRUB_DEFAULT=saved\n' >>"$grub_defaults"
	fi
	if grep -Eq '^[[:space:]]*GRUB_SAVEDEFAULT=' "$grub_defaults"; then
		sed -i -E 's/^[[:space:]]*GRUB_SAVEDEFAULT=.*/GRUB_SAVEDEFAULT=false/' "$grub_defaults"
	else
		printf 'GRUB_SAVEDEFAULT=false\n' >>"$grub_defaults"
	fi
	echo "Backed up the previous GRUB defaults to $grub_backup"
fi

update-grub
fallback_entry="Advanced options for Ubuntu>Ubuntu, with Linux $fallback_release"
test_entry="Advanced options for Ubuntu>Ubuntu, with Linux $kernel_release"
grep -Fq "Ubuntu, with Linux $fallback_release" /boot/grub/grub.cfg ||
	die "the generic fallback entry was not found in /boot/grub/grub.cfg"
grep -Fq "Ubuntu, with Linux $kernel_release" /boot/grub/grub.cfg ||
	die "the new kernel entry was not found in /boot/grub/grub.cfg"

grub-set-default "$fallback_entry"
grep -Fq "saved_entry=$fallback_entry" < <(grub-editenv list) ||
	die "GRUB did not retain the generic fallback as its saved default"
echo "Persistent GRUB fallback: $fallback_entry"

if $schedule_next_boot; then
	# All artifact and deployment checks above must pass before this one-shot
	# selection is allowed to change the next boot.
	grub-reboot "$test_entry"
	grep -Fq "next_entry=$test_entry" < <(grub-editenv list) ||
		die "GRUB did not retain the one-shot Yoga Book entry"
	echo "Scheduled one-shot GRUB entry: $test_entry"
else
	echo "The Yoga Book kernel is installed but is not selected for the next boot."
fi

cat <<EOF

Installation and artifact verification complete. This script does not reboot.

After the SOF boot, run the one-shot collector before accepting the hardware:
  sudo ./run-sof-test.sh
  alsaucm -c yogabook list _verbs

Expected kernel:      $kernel_release
Expected topology:    $topology_checksum
Expected firmware:    $firmware_checksum
Physical acceptance: pending speaker, headphone, microphone, jack, and button tests
EOF
