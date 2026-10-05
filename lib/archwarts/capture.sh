#!/usr/bin/env bash

archwarts_screenshot_dir() {
  local pictures=${XDG_PICTURES_DIR:-$HOME/Pictures}
  printf '%s/Screenshots\n' "$pictures"
}

archwarts_capture_window_geometry() {
  hyprctl -j activewindow 2>/dev/null | jq -r \
    '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

# Capture a screenshot with grim/slurp and standard Wayland tools.
# mode: fullscreen | region | window
# Copies to the clipboard and saves under the Archwarts screenshot directory.
archwarts_capture() {
  local mode=${1:-region} out_dir geometry out_name output

  command -v grim >/dev/null || {
    printf 'grim is required for screenshots\n' >&2
    return 1
  }
  out_dir=$(archwarts_screenshot_dir)
  mkdir -p "$out_dir"
  out_name="screenshot-$(date +%Y-%m-%d_%H-%M-%S).png"
  output="$out_dir/$out_name"

  case $mode in
    fullscreen)
      grim "$output" || return 1
      ;;
    region)
      command -v slurp >/dev/null || {
        printf 'slurp is required for region selection\n' >&2
        return 1
      }
      grim -g "$(slurp -f '%g' 2>/dev/null)" "$output" || return 1
      ;;
    window)
      command -v slurp >/dev/null || {
        printf 'slurp is required for window capture\n' >&2
        return 1
      }
      geometry=$(archwarts_capture_window_geometry) || return 1
      grim -g "$geometry" "$output" || return 1
      ;;
    *)
      printf 'Unknown capture mode: %s\n' "$mode" >&2
      return 2
      ;;
  esac

  if command -v wl-copy >/dev/null; then
    wl-copy --type image/png <"$output" >/dev/null 2>&1 || true
  fi
  printf '%s\n' "$output"
}