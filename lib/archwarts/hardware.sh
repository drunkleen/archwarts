#!/usr/bin/env bash

# Archwarts hardware detection and planning.
#
# Detection describes the machine (read-only, fixture-friendly). Planning
# decides required actions from a detection. Privileged execution of those
# actions is a separate installer/system phase and never happens here.
#
# All inputs are env-overridable so PCI/DMI/sysfs state can be faked in tests:
#   ARCHWARTS_LSPCI  (default lspci)        PCI device listing
#   ARCHWARTS_LSUSB  (default lsusb)        USB device listing
#   ARCHWARTS_DMI_ROOT (default /sys/class/dmi/id)
#   ARCHWARTS_SYS_ROOT (default /sys)

archwarts_hw_lspci() {
  local cmd
  cmd=${ARCHWARTS_LSPCI:-lspci}
  if [[ -n ${ARCHWARTS_LSPCI:-} ]]; then
    "$cmd" -nn 2>/dev/null || true
  elif command -v "$cmd" >/dev/null 2>&1; then
    "$cmd" -nn 2>/dev/null || true
  fi
}

archwarts_hw_lsusb() {
  local cmd
  cmd=${ARCHWARTS_LSUSB:-lsusb}
  if [[ -n ${ARCHWARTS_LSUSB:-} ]]; then
    "$cmd" 2>/dev/null || true
  elif command -v "$cmd" >/dev/null 2>&1; then
    "$cmd" 2>/dev/null || true
  fi
}

archwarts_hw_dmi() {
  local root=$1 name
  root=${ARCHWARTS_DMI_ROOT:-/sys/class/dmi/id}
  name=$(cat "$root/$name" 2>/dev/null || true)
}

# Describe the machine as TSV `key<TAB>value` lines. Read-only.
archwarts_hw_detect() {
  local pci usb dmi_root sys_root
  local gpu="unknown" laptop="unknown" vendor="" chassis="" audio="absent"
  local bluetooth="absent" network="absent" wifi_vendor="" t2="no" battery="no"

  pci=$(archwarts_hw_lspci)
  usb=$(archwarts_hw_lsusb)
  dmi_root=${ARCHWARTS_DMI_ROOT:-/sys/class/dmi/id}
  sys_root=${ARCHWARTS_SYS_ROOT:-/sys}

  if rg -qi 'nvidia' <<<"$pci"; then
    gpu=nvidia
  elif rg -qi 'advanced micro devices|amd/ati|\[amd' <<<"$pci"; then
    gpu=amd
  elif rg -qi 'intel.*(vga|3d|display)' <<<"$pci"; then
    gpu=intel
  fi

  vendor=$(cat "$dmi_root/sys_vendor" 2>/dev/null || true)
  chassis=$(cat "$dmi_root/chassis_type" 2>/dev/null || true)
  case "$chassis" in
    8|9|10|14) laptop=yes ;;
    "") laptop=unknown ;;
    *) laptop=no ;;
  esac

  if rg -qi 'audio device|multimedia audio' <<<"$pci"; then
    audio=present
  fi
  if rg -qi 'bluetooth' <<<"$usb" || rg -qi 'bluetooth' <<<"$pci"; then
    bluetooth=present
  fi
  if rg -qi 'ethernet|network controller|wireless' <<<"$pci"; then
    network=present
    wifi_vendor=$(rg -io 'intel|realtek|broadcom|mediatek|qualcomm' <<<"$pci" | head -1 | tr '[:upper:]' '[:lower:]')
  fi

  if rg -q '106b:180[12]' <<<"$pci"; then
    t2=yes
  fi

  if [[ -d "$sys_root/class/power_supply" ]] \
    && rg -q 'BAT[0-9]' <<<"$(ls "$sys_root/class/power_supply" 2>/dev/null)"; then
    battery=yes
  fi

  printf 'gpu\t%s\n' "$gpu"
  printf 'vendor\t%s\n' "${vendor:-unknown}"
  printf 'laptop\t%s\n' "$laptop"
  printf 'audio\t%s\n' "$audio"
  printf 'bluetooth\t%s\n' "$bluetooth"
  printf 'network\t%s\n' "$network"
  printf 'wifi-vendor\t%s\n' "${wifi_vendor:-unknown}"
  printf 'battery\t%s\n' "$battery"
  printf 'apple-t2\t%s\n' "$t2"
}

# Decide required actions from a detection. Outputs
# `action<TAB>kind<TAB>name<TAB>source<TAB>reason`. Planning never installs.
archwarts_hw_plan() {
  local gpu laptop t2

  gpu=$(printf '%s\n' "$1" | awk -F'\t' '$1=="gpu" {print $2}')
  laptop=$(printf '%s\n' "$1" | awk -F'\t' '$1=="laptop" {print $2}')
  t2=$(printf '%s\n' "$1" | awk -F'\t' '$1=="apple-t2" {print $2}')

  case "$gpu" in
    nvidia)
      printf 'action\tpackage\tnvidia-open-dkms\tofficial\tNVIDIA detected; open kernel modules (current official package)\n'
      printf 'action\tnote\tproprietary-driver\tdeferred\tclosed NVIDIA branch deferred to a verified source model\n'
      ;;
    amd|intel)
      printf 'action\tnote\tmesa-vaapi\tstandard\t%s GPU uses standard mesa/libva stack\n' "$gpu"
      ;;
    *)
      printf 'action\tnote\tgpu-unknown\tsafe\tno automatic GPU package selected\n'
      ;;
  esac

  if [[ $laptop == yes ]]; then
    printf 'action\tpackage\tpower-profiles-daemon\tofficial\tlaptop power profiles\n'
  fi

  if [[ $t2 == yes ]]; then
    printf 'action\tunsupported\tapple-t2\tdeferred\tT2 support requires a defensible signed source model; not enabled\n'
  fi

  printf 'action\tnote\tkernel-unchanged\tsafe\tArchwarts never replaces the kernel automatically\n'
}

archwarts_hw_status() {
  local detection
  detection=$(archwarts_hw_detect)
  printf '== detection ==\n'
  printf '%s\n' "$detection"
  printf '== plan ==\n'
  archwarts_hw_plan "$detection"
}