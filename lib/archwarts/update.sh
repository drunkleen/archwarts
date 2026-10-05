#!/usr/bin/env bash

# Archwarts update system. Independent: it never calls an inherited updater,
# repository, mirror, keyring, or channel. Privileged phases (pacman -Syu,
# pacdiff) are planned and reported; they execute only when explicitly gated
# by ARCHWARTS_UPDATE_EXECUTE=1, which is never set on the development host.

archwarts_update_dir() {
  printf '%s/update\n' "$ARCHWARTS_STATE_HOME"
}

archwarts_update_log_file() {
  printf '%s/log\n' "$(archwarts_update_dir)"
}

archwarts_update_lock_file() {
  printf '%s/lock\n' "$(archwarts_update_dir)"
}

archwarts_update_log() {
  local dir file
  dir=$(archwarts_update_dir)
  file=$(archwarts_update_log_file)
  mkdir -p "$dir"
  printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" >>"$file"
}

archwarts_update_pacman() {
  printf '%s\n' "${ARCHWARTS_PACMAN:-pacman}"
}

archwarts_update_sudo() {
  printf '%s\n' "${ARCHWARTS_SUDO:-sudo}"
}

archwarts_update_revision() {
  local dir file
  dir=$(archwarts_update_dir)
  file="$dir/revision"
  mkdir -p "$dir"
  read -r version <"$ARCHWARTS_SOURCE_ROOT/ARCHWARTS_VERSION" 2>/dev/null || version=unknown
  printf '%s' "$version" >"$file"
  printf '%s\n' "$version"
}

# A shared flock serializes updates. Returns 1 when another update holds it.
archwarts_update_lock_acquire() {
  local lock
  lock=$(archwarts_update_lock_file)
  mkdir -p "$(dirname "$lock")"
  exec {ARCHWARTS_UPDATE_LOCK_FD}>"$lock" || return 1
  flock -n "${ARCHWARTS_UPDATE_LOCK_FD}" || {
    printf 'Another Archwarts update is already running\n' >&2
    return 1
  }
}

archwarts_update_lock_release() {
  if [[ -n ${ARCHWARTS_UPDATE_LOCK_FD:-} ]]; then
    flock -u "${ARCHWARTS_UPDATE_LOCK_FD}" 2>/dev/null || true
    exec {ARCHWARTS_UPDATE_LOCK_FD}>&- 2>/dev/null || true
  fi
}

archwarts_update_network_ok() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsS --connect-timeout 5 --max-time 10 -o /dev/null \
      'https://archlinux.org/' >/dev/null 2>&1
  else
    getent hosts archlinux.org >/dev/null 2>&1
  fi
}

archwarts_update_pacman_locked() {
  [[ -e /var/lib/pacman/db.lck ]]
}

archwarts_update_disk_space() {
  local mount=$1 threshold_mb=$2 available
  available=$(df -Pk "$mount" 2>/dev/null | awk 'NR==2 {print $4}')
  [[ -n $available ]] && (( available >= threshold_mb ))
}

# Preflight findings, one per line: `check<TAB>ok|fail<TAB>detail`. Non-mutating.
archwarts_update_preflight() {
  local pacman_command network pacman_locked disk news

  pacman_command=$(archwarts_update_pacman)

  if archwarts_update_network_ok; then
    printf 'network\tok\tarchlinux.org reachable\n'
  else
    printf 'network\tfail\tarchlinux.org unreachable\n'
  fi

  if archwarts_update_pacman_locked; then
    printf 'pacman-lock\tfail\t/var/lib/pacman/db.lck present\n'
  else
    printf 'pacman-lock\tok\tno pacman database lock\n'
  fi

  if archwarts_update_disk_space / 1048576; then
    printf 'disk\tok\t>= 1 GiB free on /\n'
  else
    printf 'disk\tfail\t< 1 GiB free on /\n'
  fi

  if command -v informant >/dev/null 2>&1; then
    news=$(informant check 2>/dev/null || echo error)
    printf 'arch-news\t%s\t%s\n' "$([[ $news == error ]] && echo fail || echo ok)" "$news"
  else
    printf 'arch-news\tskip\tinformant not installed\n'
  fi

  command -v "$pacman_command" >/dev/null 2>&1 \
    && printf 'pacman\tok\t%s available\n' "$pacman_command" \
    || printf 'pacman\tfail\t%s unavailable\n' "$pacman_command"
}

# Exactly one full official Arch upgrade via pacman -Syu. Executes only when
# ARCHWARTS_UPDATE_EXECUTE=1; otherwise it is planned and reported.
archwarts_update_official() {
  local pacman_command sudo_command result status_file

  pacman_command=$(archwarts_update_pacman)
  sudo_command=$(archwarts_update_sudo)
  status_file="$(archwarts_update_dir)/last-official.tsv"
  mkdir -p "$(dirname "$status_file")"

  if [[ ${ARCHWARTS_UPDATE_EXECUTE:-0} != 1 ]]; then
    printf 'official\tplanned\t%s %s -Syu --noconfirm (not executed; requires ARCHWARTS_UPDATE_EXECUTE=1)\n' \
      "$sudo_command" "$pacman_command"
    printf 'official\tplanned\n' >"$status_file"
    return 0
  fi

  archwarts_update_log "official: starting pacman -Syu"
  if [[ ${ARCHWARTS_UPDATE_INHIBIT:-1} == 1 ]] && command -v systemd-inhibit >/dev/null 2>&1; then
    if systemd-inhibit --what=handle-lid-switch:sleep --who=archwarts-update \
      "$sudo_command" "$pacman_command" -Syu --noconfirm; then
      result=0
    else
      result=$?
    fi
  else
    if "$sudo_command" "$pacman_command" -Syu --noconfirm; then
      result=0
    else
      result=$?
    fi
  fi
  if (( result == 0 )); then
    printf 'official\tok\n' >"$status_file"
    printf 'official\tok\tpacman -Syu succeeded\n'
    archwarts_update_log "official: pacman -Syu succeeded"
  else
    printf 'official\tfailed\n' >"$status_file"
    printf 'official\tfailed\tpacman -Syu exited %s\n' "$result"
    archwarts_update_log "official: pacman -Syu failed ($result)"
  fi
  return $result
}

# Optional AUR phase. Its result is independent of the official phase; a
# failure here never marks a successful pacman upgrade as failed.
archwarts_update_aur() {
  local helper status_file
  helper=${ARCHWARTS_AUR_HELPER:-}
  status_file="$(archwarts_update_dir)/last-aur.tsv"
  mkdir -p "$(dirname "$status_file")"

  if [[ -z $helper ]]; then
    printf 'aur\tskip\tno AUR helper configured (ARCHWARTS_AUR_HELPER)\n'
    printf 'aur\tskip\n' >"$status_file"
    return 0
  fi
  command -v "$helper" >/dev/null 2>&1 || {
    printf 'aur\tfailed\tAUR helper %s is not installed\n' "$helper"
    printf 'aur\tfailed\n' >"$status_file"
    return 1
  }
  if [[ ${ARCHWARTS_UPDATE_EXECUTE:-0} != 1 ]]; then
    printf 'aur\tplanned\t%s -Sua (not executed)\n' "$helper"
    printf 'aur\tplanned\n' >"$status_file"
    return 0
  fi
  if "$helper" -Sua --noconfirm; then
    printf 'aur\tok\n' >"$status_file"
    printf 'aur\tok\t%s -Sua succeeded\n' "$helper"
  else
    printf 'aur\tfailed\n' >"$status_file"
    printf 'aur\tfailed\t%s -Sua exited nonzero\n' "$helper"
    return 1
  fi
}

# Ordered Archwarts migrations. Runs each not-yet-applied migration once, in
# filename order, recording applied migrations in state. Migrations must be
# unprivileged; privileged migration work belongs to the update plan.
archwarts_update_migrations() {
  local migrations_root applied_file migration applied

  migrations_root=${ARCHWARTS_MIGRATIONS_ROOT:-$ARCHWARTS_SOURCE_ROOT/desktop/migrations}
  applied_file="$(archwarts_update_dir)/migrations-applied.tsv"
  mkdir -p "$(dirname "$applied_file")"
  [[ -d $migrations_root ]] || return 0

  while IFS= read -r migration; do
    applied=no
    if [[ -f $applied_file ]]; then
      while IFS=$'\t' read -r done_name _when; do
        [[ $done_name == "$migration" ]] && applied=yes
      done <"$applied_file"
    fi
    [[ $applied == yes ]] && continue
    printf 'migration\t%s\n' "$migration"
    if [[ ${ARCHWARTS_UPDATE_EXECUTE:-0} == 1 ]]; then
      if bash "$migrations_root/$migration"; then
        printf '%s\t%s\n' "$migration" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >>"$applied_file"
        archwarts_update_log "migration applied: $migration"
      else
        printf 'migration\tfailed\t%s\n' "$migration"
        return 1
      fi
    fi
  done < <(find "$migrations_root" -maxdepth 1 -name '*.sh' -printf '%f\n' | sort)
}

archwarts_update_foreign() {
  local pacman_command
  pacman_command=$(archwarts_update_pacman)
  if command -v "$pacman_command" >/dev/null 2>&1; then
    "$pacman_command" -Qqm 2>/dev/null || true
  fi
}

archwarts_update_orphans() {
  local pacman_command
  pacman_command=$(archwarts_update_pacman)
  if command -v "$pacman_command" >/dev/null 2>&1; then
    "$pacman_command" -Qdt 2>/dev/null || true
  fi
}

archwarts_update_pacnew() {
  find /etc -name '*.pacnew' -o -name '*.pacsave' 2>/dev/null || true
}

archwarts_update_reboot_required() {
  local running newest
  running=$(uname -r 2>/dev/null || true)
  newest=$(find /usr/lib/modules -maxdepth 1 -mindepth 1 -type d -printf '%f\n' 2>/dev/null | sort -V | tail -1)
  if [[ -n $running && $running == "$newest" ]]; then
    printf 'no\n'
  else
    printf 'yes\tinstalled kernel (%s) differs from running (%s)\n' "$newest" "$running"
  fi
}

archwarts_update_failed_services() {
  local systemctl_command
  systemctl_command=${ARCHWARTS_SYSTEMCTL:-systemctl}
  if command -v "$systemctl_command" >/dev/null 2>&1; then
    "$systemctl_command" --failed --no-legend --plain 2>/dev/null || true
  fi
}

archwarts_update_report() {
  local official aur orphans foreign pacnew reboot failed revision
  local update_dir

  update_dir=$(archwarts_update_dir)
  mkdir -p "$update_dir"
  archwarts_update_revision >/dev/null

  if [[ -f "$update_dir/last-official.tsv" ]]; then
    official=$(cut -f2 "$update_dir/last-official.tsv")
  else
    official=never
  fi
  if [[ -f "$update_dir/last-aur.tsv" ]]; then
    aur=$(cut -f2 "$update_dir/last-aur.tsv")
  else
    aur=never
  fi

  printf 'official\t%s\n' "$official"
  printf 'aur\t%s\n' "$aur"
  printf 'revision\t%s\n' "$(cat "$update_dir/revision" 2>/dev/null || echo unknown)"

  orphans=$(archwarts_update_orphans | wc -l)
  printf 'orphans\t%s\n' "$orphans"

  foreign=$(archwarts_update_foreign | wc -l)
  printf 'foreign-packages\t%s\n' "$foreign"

  pacnew=$(archwarts_update_pacnew | wc -l)
  printf 'pacnew-pacsave\t%s\n' "$pacnew"

  reboot=$(archwarts_update_reboot_required)
  printf 'reboot\t%s\n' "$reboot"

  failed=$(archwarts_update_failed_services | wc -l)
  printf 'failed-services\t%s\n' "$failed"

  printf 'log\t%s\n' "$(archwarts_update_log_file)"
}

archwarts_update_status() {
  local update_dir
  update_dir=$(archwarts_update_dir)
  printf 'revision\t%s\n' "$(cat "$update_dir/revision" 2>/dev/null || echo never)"
  printf 'official\t%s\n' "$(cut -f2 "$update_dir/last-official.tsv" 2>/dev/null || echo never)"
  printf 'aur\t%s\n' "$(cut -f2 "$update_dir/last-aur.tsv" 2>/dev/null || echo never)"
  if [[ -f "$(archwarts_update_lock_file)" ]]; then
    printf 'lock\texists\n'
  else
    printf 'lock\tabsent\n'
  fi
  printf 'log\t%s\n' "$(archwarts_update_log_file)"
}

# Orchestrate a full update. The execute gate is only enabled by the operator;
# without it every phase is planned and reported, never executed.
archwarts_update_run() {
  local preflight rc

  archwarts_update_lock_acquire || return 1
  archwarts_update_revision >/dev/null
  archwarts_update_log "update run started (execute=${ARCHWARTS_UPDATE_EXECUTE:-0})"

  printf '== preflight ==\n'
  preflight=$(archwarts_update_preflight)
  printf '%s\n' "$preflight"
  if rg -q $'^\S+\tfail\t' <<<"$preflight"; then
    archwarts_update_log "update preflight failed"
    archwarts_update_lock_release
    return 1
  fi

  printf '== official upgrade ==\n'
  archwarts_update_official || rc=1

  printf '== AUR phase ==\n'
  archwarts_update_aur || true

  printf '== migrations ==\n'
  archwarts_update_migrations

  printf '== report ==\n'
  archwarts_update_report

  archwarts_update_log "update run finished (official rc=${rc:-0})"
  archwarts_update_lock_release
  return ${rc:-0}
}