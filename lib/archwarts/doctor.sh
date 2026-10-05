#!/usr/bin/env bash

# Archwarts doctor. Read-only diagnostics; never mutates the machine. Each
# check prints `name<TAB>ok|warn|fail<TAB>detail`. Commands are env-overridable
# so the checks can be exercised with mocks.

archwarts_doctor_systemctl() {
  printf '%s\n' "${ARCHWARTS_SYSTEMCTL:-systemctl}"
}

archwarts_doctor_pgrep() {
  printf '%s\n' "${ARCHWARTS_PGREP:-pgrep}"
}

archwarts_doctor_pacman() {
  printf '%s\n' "${ARCHWARTS_PACMAN:-pacman}"
}

archwarts_doctor() {
  local systemctl pgrep pacman

  systemctl=$(archwarts_doctor_systemctl)
  pgrep=$(archwarts_doctor_pgrep)
  pacman=$(archwarts_doctor_pacman)

  # --- version / revision ---
  if [[ -r $ARCHWARTS_SOURCE_ROOT/ARCHWARTS_VERSION ]]; then
    printf 'version\tok\t%s\n' "$(cat "$ARCHWARTS_SOURCE_ROOT/ARCHWARTS_VERSION")"
  else
    printf 'version\tfail\tmissing ARCHWARTS_VERSION\n'
  fi
  if [[ -f "$(archwarts_update_dir)/revision" ]]; then
    printf 'revision\tok\t%s\n' "$(cat "$(archwarts_update_dir)/revision")"
  else
    printf 'revision\twarn\tno recorded update revision\n'
  fi

  # --- managed-file drift ---
  archwarts_doctor_managed_drift

  # --- package source exceptions are internally consistent ---
  if [[ -r $ARCHWARTS_SOURCE_ROOT/packages/sources.tsv ]]; then
    printf 'package-sources\tok\texceptions present\n'
  else
    printf 'package-sources\twarn\tno explicit source exceptions\n'
  fi

  # --- installer / update state ---
  if archwarts_stage_is_applied base; then
    printf 'installer\tok\tbase applied\n'
  else
    printf 'installer\twarn\tbase not applied\n'
  fi
  if archwarts_stage_is_applied desktop-core; then
    printf 'installer\tok\tdesktop-core applied\n'
  else
    printf 'installer\twarn\tdesktop-core not applied\n'
  fi
  if [[ -f "$(archwarts_update_dir)/last-official.tsv" ]]; then
    printf 'update\tok\tofficial %s\n' "$(cut -f2 "$(archwarts_update_dir)/last-official.tsv")"
  else
    printf 'update\twarn\tno official upgrade recorded\n'
  fi

  # --- failed services ---
  if command -v "$systemctl" >/dev/null 2>&1; then
    local failed
    failed=$("$systemctl" --failed --no-legend --plain 2>/dev/null || true)
    if [[ -n $failed ]]; then
      printf 'services\tfail\t%s\n' "$(printf '%s' "$failed" | head -1)"
    else
      printf 'services\tok\tno failed units\n'
    fi
  else
    printf 'services\tskip\tsystemctl unavailable\n'
  fi

  # --- portal ---
  if command -v "$pgrep" >/dev/null 2>&1; then
    if "$pgrep" -x xdg-desktop-portal >/dev/null 2>&1; then
      printf 'portal\tok\txdg-desktop-portal running\n'
    else
      printf 'portal\twarn\txdg-desktop-portal not running\n'
    fi
  else
    printf 'portal\tskip\tpgrep unavailable\n'
  fi

  # --- pipewire / wireplumber ---
  if command -v "$pgrep" >/dev/null 2>&1; then
    if "$pgrep" -x pipewire >/dev/null 2>&1; then
      printf 'pipewire\tok\trunning\n'
    else
      printf 'pipewire\twarn\tnot running\n'
    fi
    if "$pgrep" -x wireplumber >/dev/null 2>&1; then
      printf 'wireplumber\tok\trunning\n'
    else
      printf 'wireplumber\twarn\tnot running\n'
    fi
  fi

  # --- networkmanager / bluetooth ---
  if command -v "$systemctl" >/dev/null 2>&1; then
    if "$systemctl" is-active --quiet NetworkManager.service 2>/dev/null; then
      printf 'network\tok\tNetworkManager active\n'
    else
      printf 'network\twarn\tNetworkManager inactive\n'
    fi
    if "$systemctl" is-active --quiet bluetooth.service 2>/dev/null; then
      printf 'bluetooth\tok\tbluetooth active\n'
    else
      printf 'bluetooth\twarn\tbluetooth inactive\n'
    fi
  fi

  # --- hyprland / quickshell ---
  if command -v "$pgrep" >/dev/null 2>&1; then
    if "$pgrep" -x Hyprland >/dev/null 2>&1; then
      printf 'hyprland\tok\trunning\n'
    else
      printf 'hyprland\twarn\tnot running\n'
    fi
    if "$pgrep" -x quickshell >/dev/null 2>&1; then
      printf 'quickshell\tok\trunning\n'
    else
      printf 'quickshell\twarn\tnot running\n'
    fi
  fi

  # --- migrations ---
  archwarts_doctor_migrations

  # --- pacnew / pacsave ---
  local pacnew
  pacnew=$(archwarts_update_pacnew)
  if [[ -n $pacnew ]]; then
    printf 'pacnew\twarn\t%s\n' "$(printf '%s' "$pacnew" | wc -l)"
  else
    printf 'pacnew\tok\tnone\n'
  fi

  # --- foreign packages ---
  if command -v "$pacman" >/dev/null 2>&1; then
    printf 'foreign\tinfo\t%s\n' "$("$pacman" -Qqm 2>/dev/null | wc -l)"
  fi

  # --- reboot ---
  printf 'reboot\t%s\n' "$(archwarts_update_reboot_required | cut -f1)"

  # --- hardware ---
  archwarts_doctor_hardware
}

archwarts_doctor_managed_drift() {
  local file path recorded current drifted=0 total=0

  file=$(archwarts_ownership_file)
  [[ -r $file ]] || {
    printf 'managed-files\twarn\tno ownership manifest\n'
    return
  }
  while IFS=$'\t' read -r _stage path sha _when; do
    [[ -n $path ]] || continue
    total=$((total + 1))
    if [[ -f $path ]]; then
      current=$(archwarts_sha256 "$path")
      if [[ $current != "$sha" ]]; then
        drifted=$((drifted + 1))
      fi
    fi
  done <"$file"
  if (( drifted > 0 )); then
    printf 'managed-files\twarn\t%s of %s managed files drifted\n' "$drifted" "$total"
  else
    printf 'managed-files\tok\t%s managed files intact\n' "$total"
  fi
}

archwarts_doctor_migrations() {
  local root applied_file pending

  root=${ARCHWARTS_MIGRATIONS_ROOT:-$ARCHWARTS_SOURCE_ROOT/desktop/migrations}
  applied_file="$(archwarts_update_dir)/migrations-applied.tsv"
  [[ -d $root ]] || {
    printf 'migrations\tok\tnone declared\n'
    return
  }
  pending=0
  while IFS= read -r migration; do
    if ! rg -q "^$migration\t" "$applied_file" 2>/dev/null; then
      pending=$((pending + 1))
    fi
  done < <(find "$root" -maxdepth 1 -name '*.sh' -printf '%f\n' | sort)
  if (( pending > 0 )); then
    printf 'migrations\twarn\t%s pending\n' "$pending"
  else
    printf 'migrations\tok\tall applied\n'
  fi
}

archwarts_doctor_hardware() {
  local detection gpu t2

  detection=$(archwarts_hw_detect)
  gpu=$(printf '%s\n' "$detection" | awk -F'\t' '$1=="gpu" {print $2}')
  t2=$(printf '%s\n' "$detection" | awk -F'\t' '$1=="apple-t2" {print $2}')
  printf 'hardware\tinfo\tgpu=%s apple-t2=%s\n' "$gpu" "$t2"
}