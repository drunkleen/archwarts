#!/usr/bin/env bash

# Default application integration for the Archwarts desktop. All commands are
# user-space (XDG config/data) or staged Archwarts-owned files; nothing here
# modifies host system configuration.

archwarts_xdg_settings() {
  printf '%s\n' "${ARCHWARTS_XDG_SETTINGS:-xdg-settings}"
}

archwarts_xdg_mime() {
  printf '%s\n' "${ARCHWARTS_XDG_MIME:-xdg-mime}"
}

# Set the desktop-wide defaults for the approved applications. Writes the
# user mimeapps.list (user-space) via the standard xdg tools.
archwarts_defaults_apply() {
  local xdg_settings xdg_mime

  xdg_settings=$(archwarts_xdg_settings)
  xdg_mime=$(archwarts_xdg_mime)

  command -v "$xdg_settings" >/dev/null 2>&1 || {
    printf 'xdg-settings is unavailable\n' >&2
    return 1
  }
  command -v "$xdg_mime" >/dev/null 2>&1 || {
    printf 'xdg-mime is unavailable\n' >&2
    return 1
  }

  "$xdg_settings" set default-web-browser firefox.desktop
  "$xdg_mime" default org.kde.dolphin.desktop inode/directory
  "$xdg_mime" default org.codeberg.dnkl.foot.desktop x-scheme-handler/terminal
  "$xdg_mime" default org.kde.ark.desktop application/zip application/x-7z-compressed

  archwarts_dolphin_integration
  printf 'Archwarts default applications configured\n'
}

# Stage the Dolphin integration files: KIO service menus (LocalSend, transcode)
# and dolphinrc (foot terminal, preview plugins). All user-space and owned.
archwarts_dolphin_integration() {
  local source_root apps_root kio_target dolphin_target

  source_root=$(archwarts_defaults_source_root)
  apps_root="$source_root/desktop/apps"
  kio_target="${XDG_DATA_HOME:-$HOME/.local/share}/kio/servicemenus"
  dolphin_target="${XDG_CONFIG_HOME:-$HOME/.config}/dolphinrc"

  archwarts_install_apply_file apps \
    "$apps_root/kio/servicemenus/archwarts-localsend.desktop" \
    "$kio_target/archwarts-localsend.desktop" || return 1
  archwarts_install_apply_file apps \
    "$apps_root/kio/servicemenus/archwarts-transcode.desktop" \
    "$kio_target/archwarts-transcode.desktop" || return 1
  archwarts_install_apply_file apps \
    "$apps_root/dolphin/dolphinrc" "$dolphin_target" || return 1
}

archwarts_defaults_source_root() {
  if [[ -n ${ARCHWARTS_SOURCE_ROOT:-} ]]; then
    printf '%s\n' "$ARCHWARTS_SOURCE_ROOT"
  else
    printf '%s\n' "$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/../..")"
  fi
}

archwarts_defaults_status() {
  local xdg_settings xdg_mime browser file_manager

  xdg_settings=$(archwarts_xdg_settings)
  xdg_mime=$(archwarts_xdg_mime)

  if command -v "$xdg_settings" >/dev/null 2>&1; then
    browser=$("$xdg_settings" get default-web-browser 2>/dev/null || echo unknown)
    printf 'browser\t%s\n' "$browser"
  fi
  if command -v "$xdg_mime" >/dev/null 2>&1; then
    file_manager=$("$xdg_mime" query default inode/directory 2>/dev/null || echo unknown)
    printf 'file-manager\t%s\n' "$file_manager"
  fi
}

# Create a URL desktop entry that opens the given web application in Firefox
# as a normal browser window (no Chromium app mode is required). Name and URL
# are sanitized for the desktop-entry format and the Exec line.
archwarts_web_app() {
  local name=$1 url=$2 entry target_dir target safe_name safe_url

  [[ -n $name && -n $url ]] || {
    printf 'archwarts web-app <name> <url>\n' >&2
    return 2
  }
  # Safe for the filename and the Name= field.
  safe_name=$(printf '%s' "$name" | tr -d '\n=[]' | tr '[:upper:]' '[:lower:]')
  [[ -n $safe_name ]] || {
    printf 'archwarts web-app: name is empty after sanitization\n' >&2
    return 2
  }
  # Safe for the Exec line: single line, no quotes, no shell metacharacters.
  safe_url=$(printf '%s' "$url" | tr -d '\n"`$\\' | tr -d ';&|<>(){}')
  [[ $safe_url == http* ]] || {
    printf 'archwarts web-app: url must be http(s)\n' >&2
    return 2
  }
  entry=$(printf '%s' "$safe_name" | tr -cs 'a-z0-9' '-')
  target_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
  mkdir -p "$target_dir"
  target="$target_dir/archwarts-$entry.desktop"
  if [[ -f $target ]] && ! archwarts_path_is_managed "$target"; then
    printf 'Refusing to overwrite an unmanaged desktop entry: %s\n' "$target" >&2
    return 1
  fi
  cat >"$target" <<EOF
[Desktop Entry]
Type=Application
Name=$safe_name
Comment=$safe_url
Exec=firefox --new-window "$safe_url"
Icon=firefox
Terminal=false
Categories=Network;WebBrowser;
EOF
  printf '%s\n' "$target"
}