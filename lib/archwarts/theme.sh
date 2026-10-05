#!/usr/bin/env bash

archwarts_theme_palette() {
  printf '%s/theme/palette.conf\n' "$ARCHWARTS_CONFIG_HOME"
}

archwarts_themes_root() {
  printf '%s/desktop/themes\n' "$ARCHWARTS_SOURCE_ROOT"
}

# Install the named theme's palette into the Archwarts config home. Keeps user
# overrides: refuses to overwrite an unmanaged palette.
archwarts_theme_apply() {
  local name=${1:-default} source target

  source="$(archwarts_themes_root)/$name/palette.conf"
  [[ -r $source ]] || {
    printf 'Unknown theme: %s\n' "$name" >&2
    return 2
  }
  target=$(archwarts_theme_palette)
  archwarts_install_apply_file theme "$source" "$target" || return 1
  printf '%s\n' "$target"
}

archwarts_theme_status() {
  local target
  target=$(archwarts_theme_palette)
  if [[ -f $target ]]; then
    printf 'theme\tactive\t%s\n' "$target"
  else
    printf 'theme\tdefault\n'
  fi
}