#!/usr/bin/env bash

archwarts_plan_file() {
  printf '%s/plan.tsv\n' "$(archwarts_install_state_dir)"
}

archwarts_install_preflight() {
  local source_root=$1 profile=${2:-default} package source status plan
  local pacman_command=${ARCHWARTS_PACMAN:-pacman}

  command -v "$pacman_command" >/dev/null || {
    printf 'Required command is unavailable: %s\n' "$pacman_command" >&2
    return 1
  }
  plan=$(archwarts_package_plan "$source_root" "$profile") || return

  printf 'package\tsource\tstatus\n'
  while IFS= read -r package; do
    [[ -n $package ]] || continue
    source=$(archwarts_package_source "$source_root" "$package")
    if "$pacman_command" -Q -- "$package" >/dev/null 2>&1; then
      status=installed
    else
      status=missing
    fi
    printf '%s\t%s\t%s\n' "$package" "$source" "$status"
  done <<<"$plan"
}

archwarts_install_plan() {
  local source_root=$1 profile=${2:-default} package source state plan
  local pacman_command=${ARCHWARTS_PACMAN:-pacman}
  local systemctl_command=${ARCHWARTS_SYSTEMCTL:-systemctl}
  local plan_file kind name reason unit_state

  command -v "$pacman_command" >/dev/null || {
    printf 'Required command is unavailable: %s\n' "$pacman_command" >&2
    return 1
  }
  plan=$(archwarts_package_plan "$source_root" "$profile") || return
  plan_file=$(archwarts_plan_file)
  mkdir -p "$(dirname "$plan_file")"

  printf '# generated_at_utc\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$plan_file"
  printf '# profile\t%s\n' "$profile" >>"$plan_file"
  printf '# The privileged transaction plan is explicit and not executed here.\n' >>"$plan_file"
  printf 'phase\tkind\tname\tsource\tstate\n' >>"$plan_file"

  while IFS= read -r package; do
    [[ -n $package ]] || continue
    source=$(archwarts_package_source "$source_root" "$package")
    if "$pacman_command" -Q -- "$package" >/dev/null 2>&1; then
      state=installed
    else
      state=missing
    fi
    printf 'packages\tpackage\t%s\t%s\t%s\n' "$package" "$source" "$state" >>"$plan_file"
  done <<<"$plan"

  if [[ -r $source_root/install/privileged-actions.tsv ]]; then
    while IFS=$'\t' read -r kind name _reason; do
      [[ $kind == kind || $kind == \#* ]] && continue
      [[ -n $kind && -n $name ]] || continue
      if "$systemctl_command" is-enabled --quiet -- "$name" 2>/dev/null; then
        unit_state=enabled
      elif "$systemctl_command" is-masked --quiet -- "$name" 2>/dev/null; then
        unit_state=masked
      else
        unit_state=inactive
      fi
      printf 'services\t%s\t%s\tsystemd\t%s\n' "$kind" "$name" "$unit_state" >>"$plan_file"
    done <"$source_root/install/privileged-actions.tsv"
  fi

  if [[ -r $source_root/install/privileged-files.tsv ]]; then
    while IFS=$'\t' read -r source target _mode; do
      [[ $source == source || $source == \#* ]] && continue
      [[ -n $source && -n $target ]] || continue
      if [[ -e $target ]]; then
        file_state=present
      else
        file_state=absent
      fi
      printf 'files\tinstall\t%s\t%s\t%s\n' "$target" "archwarts-policy-file" "$file_state" >>"$plan_file"
    done <"$source_root/install/privileged-files.tsv"
  fi

  printf 'privileged-plan\tfile\t%s\n' "$plan_file"
}

archwarts_install_status() {
  local plan_file

  archwarts_stage_status
  plan_file=$(archwarts_plan_file)
  if [[ -r $plan_file ]]; then
    printf 'plan\t%s\n' "$plan_file"
  else
    printf 'plan\tnot-generated\n'
  fi
}