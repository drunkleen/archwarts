#!/usr/bin/env bash

archwarts_xdg_home() {
  local variable=$1 fallback=$2 value=${!1:-}

  if [[ $value == /* ]]; then
    printf '%s\n' "${value%/}"
  else
    printf '%s/%s\n' "${HOME:?HOME must be set}" "$fallback"
  fi
}

archwarts_init_paths() {
  local config_home data_home state_home cache_home

  config_home=$(archwarts_xdg_home XDG_CONFIG_HOME .config)
  data_home=$(archwarts_xdg_home XDG_DATA_HOME .local/share)
  state_home=$(archwarts_xdg_home XDG_STATE_HOME .local/state)
  cache_home=$(archwarts_xdg_home XDG_CACHE_HOME .cache)

  ARCHWARTS_CONFIG_HOME=${ARCHWARTS_CONFIG_HOME:-$config_home/archwarts}
  ARCHWARTS_DATA_HOME=${ARCHWARTS_DATA_HOME:-$data_home/archwarts}
  ARCHWARTS_STATE_HOME=${ARCHWARTS_STATE_HOME:-$state_home/archwarts}
  ARCHWARTS_CACHE_HOME=${ARCHWARTS_CACHE_HOME:-$cache_home/archwarts}
  ARCHWARTS_RUNTIME_HOME=${ARCHWARTS_RUNTIME_HOME:-${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/archwarts}
  ARCHWARTS_PATH=${ARCHWARTS_PATH:-$ARCHWARTS_DATA_HOME}

  export ARCHWARTS_CONFIG_HOME ARCHWARTS_DATA_HOME ARCHWARTS_STATE_HOME
  export ARCHWARTS_CACHE_HOME ARCHWARTS_RUNTIME_HOME ARCHWARTS_PATH
}

archwarts_user_bin() {
  printf '%s/.local/bin\n' "${HOME:?HOME must be set}"
}
