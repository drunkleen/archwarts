#!/usr/bin/env bash

archwarts_shell_dir() {
  printf '%s/shell\n' "$ARCHWARTS_CONFIG_HOME"
}

archwarts_shell_ipc_dir() {
  printf '%s/ipc\n' "$ARCHWARTS_RUNTIME_HOME"
}

# Write an IPC trigger the shell watches. The shell dispatches by target and
# action and removes the file. Payload is a JSON document (default {}).
archwarts_shell_ipc() {
  local target=$1 action=$2 payload=${3:-"{}"} dir file seq

  [[ -n $target && -n $action ]] || {
    printf 'archwarts-shell: target and action are required\n' >&2
    return 2
  }
  [[ $target =~ ^[a-zA-Z0-9_.-]+$ ]] || {
    printf 'archwarts-shell: invalid target: %s\n' "$target" >&2
    return 2
  }
  [[ $action =~ ^[a-zA-Z0-9_.-]+$ ]] || {
    printf 'archwarts-shell: invalid action: %s\n' "$action" >&2
    return 2
  }
  dir=$(archwarts_shell_ipc_dir)
  mkdir -p "$dir"
  seq=$(date +%s%N)
  file="$dir/$seq-$target-$action.json"
  printf '%s' "$payload" >"$file"
}

# The exact argv for launching the Archwarts shell with Quickshell. Exposed
# separately so tests can assert command construction without running it.
archwarts_shell_launch_command() {
  printf 'QS_DISABLE_FILE_WATCHER=1 QS_NO_RELOAD_POPUP=1 quickshell -n -p %s\n' \
    "$(archwarts_shell_dir)"
}

archwarts_shell_launch() {
  local shell_dir
  shell_dir=$(archwarts_shell_dir)
  [[ -f $shell_dir/shell.qml ]] || {
    printf 'Archwarts shell is not staged: %s\n' "$shell_dir" >&2
    return 1
  }
  # shellcheck disable=SC2091
  $(archwarts_shell_launch_command) &
}

archwarts_shell_status() {
  if [[ -f $(archwarts_shell_dir)/shell.qml ]]; then
    printf 'shell\tstaged\t%s\n' "$(archwarts_shell_dir)"
  else
    printf 'shell\tnot-staged\n'
  fi
  printf 'ipc\t%s\n' "$(archwarts_shell_ipc_dir)"
}