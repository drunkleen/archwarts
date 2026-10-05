#!/usr/bin/env bash

archwarts_stages_root() {
  printf '%s/stages\n' "$ARCHWARTS_SOURCE_ROOT"
}

archwarts_render_template() {
  local template=$1 output=$2
  local content

  [[ -r $template ]] || {
    printf 'Template is not readable: %s\n' "$template" >&2
    return 1
  }
  content=$(sed \
    -e "s|@ARCHWARTS_CONFIG_HOME@|$ARCHWARTS_CONFIG_HOME|g" \
    -e "s|@ARCHWARTS_DATA_HOME@|$ARCHWARTS_DATA_HOME|g" \
    -e "s|@ARCHWARTS_STATE_HOME@|$ARCHWARTS_STATE_HOME|g" \
    -e "s|@ARCHWARTS_CACHE_HOME@|$ARCHWARTS_CACHE_HOME|g" \
    -e "s|@ARCHWARTS_RUNTIME_HOME@|$ARCHWARTS_RUNTIME_HOME|g" \
    -e "s|@ARCHWARTS_SOURCE_ROOT@|$ARCHWARTS_SOURCE_ROOT|g" \
    <"$template")
  mkdir -p "$(dirname "$output")"
  printf '%s\n' "$content" >"$output"
}

archwarts_stage_base() {
  local dir
  for dir in "$ARCHWARTS_CONFIG_HOME" "$ARCHWARTS_DATA_HOME" \
    "$ARCHWARTS_STATE_HOME" "$ARCHWARTS_CACHE_HOME"; do
    mkdir -p "$dir"
  done
  # The transient runtime home may not be creatable outside a graphical/login
  # session (e.g. /run/user/$UID does not exist yet). It is optional for
  # staging, so a failure here is a warning, not a staging failure.
  if mkdir -p "$ARCHWARTS_RUNTIME_HOME" 2>/dev/null; then
    :
  else
    printf 'warning: cannot create transient runtime home: %s\n' \
      "$ARCHWARTS_RUNTIME_HOME" >&2
  fi
  archwarts_stage_mark_applied base
}

archwarts_stage_desktop_core() {
  local stages_root template target render_tmp source_root runtime_dir

  stages_root=$(archwarts_stages_root)
  source_root=$(archwarts_stages_root)/..
  runtime_dir="$ARCHWARTS_DATA_HOME/runtime"
  archwarts_stage_base

  template="$stages_root/desktop-core/hypr/hyprland.conf.tpl"
  target="$ARCHWARTS_CONFIG_HOME/hypr/hyprland.conf"
  if [[ -r $template ]]; then
    render_tmp=$(mktemp)
    archwarts_render_template "$template" "$render_tmp" || {
      rm -f "$render_tmp"
      return 1
    }
    archwarts_install_apply_file desktop-core "$render_tmp" "$target"
    rm -f "$render_tmp"
  fi

  template="$stages_root/desktop-core/bin/archwarts-session.tpl"
  target="$ARCHWARTS_DATA_HOME/bin/archwarts-session"
  if [[ -r $template ]]; then
    render_tmp=$(mktemp)
    archwarts_render_template "$template" "$render_tmp" || {
      rm -f "$render_tmp"
      return 1
    }
    archwarts_install_apply_file desktop-core "$render_tmp" "$target"
    chmod +x "$target"
    archwarts_install_apply_file desktop-core "$render_tmp" \
      "$(archwarts_user_bin)/archwarts-session"
    chmod +x "$(archwarts_user_bin)/archwarts-session"
    rm -f "$render_tmp"
  fi

  # Independent Archwarts desktop shell.
  archwarts_install_apply_tree desktop-core "$source_root/desktop/shell" \
    "$ARCHWARTS_CONFIG_HOME/shell" || return 1

  # Self-contained runtime copy of the management CLI and its data, so the
  # staged desktop has no dependency on the source tree. Only Archwarts-owned
  # paths are staged; inherited migration input is never copied into the
  # runtime.
  archwarts_install_apply_file desktop-core \
    "$source_root/bin/archwarts" "$runtime_dir/bin/archwarts" || return 1
  archwarts_install_apply_tree desktop-core "$source_root/lib/archwarts" \
    "$runtime_dir/lib/archwarts" || return 1
  archwarts_install_apply_tree desktop-core "$source_root/packages" \
    "$runtime_dir/packages" || return 1
  archwarts_install_apply_tree desktop-core "$source_root/stages" \
    "$runtime_dir/stages" || return 1
  archwarts_install_apply_file desktop-core \
    "$source_root/install/privileged-actions.tsv" \
    "$runtime_dir/install/privileged-actions.tsv" || return 1
  archwarts_install_apply_tree desktop-core "$source_root/desktop" \
    "$runtime_dir/desktop" || return 1
  archwarts_install_apply_file desktop-core \
    "$source_root/ARCHWARTS_VERSION" "$runtime_dir/ARCHWARTS_VERSION" || return 1

  # Default theme palette.
  archwarts_install_apply_file desktop-core \
    "$source_root/desktop/themes/default/palette.conf" \
    "$(archwarts_theme_palette)" || return 1

  archwarts_stage_mark_applied desktop-core
}

archwarts_stage_requires() {
  case $1 in
    base) ;;
    desktop-core) printf 'base\n' ;;
    *)
      printf 'Unknown stage: %s\n' "$1" >&2
      return 2
      ;;
  esac
}

archwarts_stage_list() {
  printf 'stage\trequires\tdescription\n'
  printf 'base\tnone\tCreate the Archwarts-owned XDG runtime tree\n'
  printf 'desktop-core\tbase\tStage independent Hyprland and Quickshell launch configuration\n'
}

archwarts_stage_apply() {
  local stage=${1:-} requirement
  local -a requirements=()

  archwarts_stage_requires "$stage" >/dev/null || return 2

  while IFS= read -r requirement; do
    [[ -n $requirement ]] && requirements+=("$requirement")
  done <<<"$(archwarts_stage_requires "$stage")"

  for requirement in "${requirements[@]}"; do
    if ! archwarts_stage_is_applied "$requirement"; then
      printf 'Stage %s requires %s first; run: archwarts install stage %s\n' \
        "$stage" "$requirement" "$requirement" >&2
      return 1
    fi
  done

  case $stage in
    base) archwarts_stage_base ;;
    desktop-core) archwarts_stage_desktop_core ;;
  esac
}

archwarts_stage_status() {
  local stage
  printf 'stage\tapplied\n'
  for stage in base desktop-core; do
    if archwarts_stage_is_applied "$stage"; then
      printf '%s\tyes\n' "$stage"
    else
      printf '%s\tno\n' "$stage"
    fi
  done
}