#!/usr/bin/env bash

# Launch a desktop application by its desktop-entry id using gtk-launch, the
# standard entry resolver. Accepts ids with or without the .desktop suffix.
archwarts_launch_app() {
  local id=${1:-} entry

  [[ -n $id ]] || {
    printf 'archwarts-launch-app: a desktop entry id is required\n' >&2
    return 2
  }
  [[ $id =~ ^[a-zA-Z0-9._-]+$ ]] || {
    printf 'archwarts-launch-app: invalid desktop entry id: %s\n' "$id" >&2
    return 2
  }
  entry=$id
  [[ $entry == *.desktop ]] || entry="$entry.desktop"
  command -v gtk-launch >/dev/null || {
    printf 'gtk-launch is unavailable\n' >&2
    return 1
  }
  gtk-launch "$entry" >/dev/null 2>&1 &
}