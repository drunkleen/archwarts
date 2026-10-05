#!/usr/bin/env bash
set -euo pipefail
# Archwarts-owned session launcher (staged by `archwarts install stage desktop-core`).
# References only Archwarts-owned paths; no inherited runtime is required.
config="@ARCHWARTS_CONFIG_HOME@/hypr/hyprland.conf"
runtime="@ARCHWARTS_DATA_HOME@/runtime"

export ARCHWARTS_CONFIG_HOME="@ARCHWARTS_CONFIG_HOME@"
export ARCHWARTS_DATA_HOME="@ARCHWARTS_DATA_HOME@"
export ARCHWARTS_STATE_HOME="@ARCHWARTS_STATE_HOME@"
export ARCHWARTS_CACHE_HOME="@ARCHWARTS_CACHE_HOME@"
export ARCHWARTS_RUNTIME_HOME="@ARCHWARTS_RUNTIME_HOME@"

export PATH="$HOME/.local/bin:$runtime/bin:$PATH"

if command -v Hyprland >/dev/null 2>&1; then
  exec Hyprland -c "$config"
fi
printf 'Hyprland is not installed; the Archwarts session cannot start.\n' >&2
exit 1