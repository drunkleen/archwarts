#!/usr/bin/env bash

# Archwarts conservative uninstall. Uses the ownership manifest to remove only
# Archwarts-managed files whose current content still matches the recorded
# state. Modified managed files are never removed. State and user data under
# the state home are preserved by default.

archwarts_uninstall_plan() {
  local file path sha current include_state=${1:-no}
  local would_remove=0 refuse=0 preserved=0

  file=$(archwarts_ownership_file)
  [[ -r $file ]] || {
    printf 'No ownership manifest; nothing Archwarts-managed to uninstall\n'
    return 0
  }
  while IFS=$'\t' read -r _stage path sha _when; do
    [[ -n $path ]] || continue
    if [[ $path == "$ARCHWARTS_STATE_HOME"* && $include_state == no ]]; then
      printf 'preserve\t%s\tstate preserved by default\n' "$path"
      preserved=$((preserved + 1))
      continue
    fi
    if [[ ! -e $path ]]; then
      printf 'remove\t%s\talready absent\n' "$path"
      would_remove=$((would_remove + 1))
      continue
    fi
    current=$(archwarts_sha256 "$path")
    if [[ $current == "$sha" ]]; then
      printf 'remove\t%s\tmanaged and unmodified\n' "$path"
      would_remove=$((would_remove + 1))
    else
      printf 'refuse\t%s\tmanaged but modified\n' "$path"
      refuse=$((refuse + 1))
    fi
  done <"$file"
  printf 'summary\twould-remove=%s\trefuse=%s\tpreserve=%s\n' \
    "$would_remove" "$refuse" "$preserved"
  (( refuse == 0 ))
}

# Remove only unmodified managed files. Refuses to remove drifted files and
# preserves state by default. Packages are reported, never removed.
archwarts_uninstall() {
  local include_state=${1:-no} file path sha current rc=0
  local removed=0 refused=0 preserved=0

  file=$(archwarts_ownership_file)
  [[ -r $file ]] || {
    printf 'No ownership manifest; nothing Archwarts-managed to uninstall\n'
    return 0
  }
  while IFS=$'\t' read -r _stage path sha _when; do
    [[ -n $path ]] || continue
    if [[ $path == "$ARCHWARTS_STATE_HOME"* && $include_state == no ]]; then
      printf 'preserve\t%s\tstate preserved by default\n' "$path"
      preserved=$((preserved + 1))
      continue
    fi
    if [[ ! -e $path ]]; then
      removed=$((removed + 1))
      continue
    fi
    current=$(archwarts_sha256 "$path")
    if [[ $current == "$sha" ]]; then
      rm -f -- "$path"
      printf 'removed\t%s\n' "$path"
      removed=$((removed + 1))
    else
      printf 'refuse\t%s\tmanaged but modified\n' "$path" >&2
      refused=$((refused + 1))
      rc=1
    fi
  done <"$file"
  printf 'summary\tremoved=%s\trefused=%s\tpreserved=%s\n' \
    "$removed" "$refused" "$preserved"
  printf 'packages\tmay now be unused; review with: archwarts install preflight\n'
  return "$rc"
}