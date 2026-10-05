#!/usr/bin/env bash

archwarts_install_state_dir() {
  printf '%s/install\n' "$ARCHWARTS_STATE_HOME"
}

archwarts_ownership_file() {
  printf '%s/ownership.tsv\n' "$(archwarts_install_state_dir)"
}

archwarts_stages_file() {
  printf '%s/stages.tsv\n' "$(archwarts_install_state_dir)"
}

archwarts_stage_is_applied() {
  local stage=$1
  local file
  file=$(archwarts_stages_file)
  [[ -r $file ]] || return 1
  while IFS=$'\t' read -r applied _when; do
    [[ $applied == "$stage" ]] && return 0
  done <"$file"
  return 1
}

archwarts_stage_mark_applied() {
  local stage=$1
  local file
  file=$(archwarts_stages_file)
  mkdir -p "$(dirname "$file")"
  if ! archwarts_stage_is_applied "$stage"; then
    printf '%s\t%s\n' "$stage" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >>"$file"
  fi
}

archwarts_sha256() {
  sha256sum "$1" | cut -d ' ' -f 1
}

archwarts_ownership_lookup() {
  local target=$1 file
  file=$(archwarts_ownership_file)
  [[ -r $file ]] || return 1
  while IFS=$'\t' read -r _stage path sha _when; do
    [[ $path == "$target" ]] && {
      printf '%s\n' "$sha"
      return 0
    }
  done <"$file"
  return 1
}

archwarts_ownership_record() {
  local stage=$1 target=$2 sha=$3 file
  file=$(archwarts_ownership_file)
  mkdir -p "$(dirname "$file")"
  printf '%s\t%s\t%s\t%s\n' \
    "$stage" "$target" "$sha" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >>"$file"
}

# Remove every ownership row for a target. Keeps the manifest free of stale
# rows when a managed file is removed and later re-staged.
archwarts_ownership_purge() {
  local target=$1 file tmp stage path sha when
  file=$(archwarts_ownership_file)
  [[ -f $file ]] || return 0
  tmp=$(mktemp)
  while IFS=$'\t' read -r stage path sha when; do
    [[ $path == "$target" ]] && continue
    printf '%s\t%s\t%s\t%s\n' "$stage" "$path" "$sha" "$when"
  done <"$file" >"$tmp"
  mv "$tmp" "$file"
}

# True when a path does not exist or is recorded as Archwarts-managed. Used to
# refuse overwriting unmanaged user files.
archwarts_path_is_managed() {
  local target=$1
  [[ ! -e $target ]] && return 0
  archwarts_ownership_lookup "$target" >/dev/null
}

archwarts_install_apply_file() {
  local stage=$1 source=$2 target=$3
  local source_sha current recorded target_dir

  [[ -r $source ]] || {
    printf 'Source file is not readable: %s\n' "$source" >&2
    return 1
  }

  source_sha=$(archwarts_sha256 "$source")
  target_dir=$(dirname "$target")

  if [[ -f $target ]]; then
    current=$(archwarts_sha256 "$target")
    if [[ $current == "$source_sha" ]]; then
      recorded=$(archwarts_ownership_lookup "$target" || true)
      if [[ -z $recorded ]]; then
        archwarts_ownership_purge "$target"
        archwarts_ownership_record "$stage" "$target" "$current"
      fi
      return 0
    fi
    if recorded=$(archwarts_ownership_lookup "$target" || true) \
      && [[ $recorded == "$current" ]]; then
      return 0
    fi
    printf 'Conflict: %s already exists with unmanaged content; refusing to overwrite\n' \
      "$target" >&2
    return 1
  fi

  mkdir -p "$target_dir"
  cp -- "$source" "$target"
  current=$(archwarts_sha256 "$target")
  archwarts_ownership_purge "$target"
  archwarts_ownership_record "$stage" "$target" "$current"
}

# Apply every regular file under a source directory into a target directory,
# preserving relative paths and ownership semantics. Never overwrites an
# unmanaged file. Idempotent per file.
archwarts_install_apply_tree() {
  local stage=$1 source_dir=$2 target_dir=$3 relative source target

  [[ -d $source_dir ]] || {
    printf 'Source directory is missing: %s\n' "$source_dir" >&2
    return 1
  }
  while IFS= read -r -d '' relative; do
    source="$source_dir/$relative"
    [[ -f $source ]] || continue
    target="$target_dir/$relative"
    archwarts_install_apply_file "$stage" "$source" "$target" || return 1
  done < <(find "$source_dir" -type f -printf '%P\0')
}