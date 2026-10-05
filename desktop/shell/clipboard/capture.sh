#!/usr/bin/env bash
# Archwarts clipboard capture. Emits one JSON entry per clipboard state on
# stdout. In watch mode wl-paste invokes this with the payload on stdin and the
# mime as $1; without arguments it snapshots the current selection itself.
#
# Sensitive-content boundary: password managers flag clipboard content with the
# x-kde-passwordManagerHint MIME type, and the shell sets CLIPBOARD_STATE=sensitive
# around copies of secrets. Either signal makes this script emit nothing, so
# secrets never enter the Archwarts clipboard history.

set -o pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/archwarts"
image_dir="$state_dir/clipboard-images"
mkdir -p "$image_dir"

types=$(wl-paste --list-types 2>/dev/null || true)

if [[ ${CLIPBOARD_STATE:-} == "sensitive" ]] || grep -qx 'x-kde-passwordManagerHint' <<<"$types"; then
  exit 0
fi

emit_image() {
  local mime=$1 ext tmp hash file
  ext=${mime#image/}
  [[ $ext == jpeg ]] && ext=jpg
  tmp=$(mktemp --tmpdir="$image_dir" clipboard.XXXXXX) || return 0
  cat >"$tmp"
  if [[ ! -s $tmp ]]; then
    rm -f "$tmp"
    return 0
  fi
  hash=$(sha256sum "$tmp" | awk '{print $1}')
  file="$image_dir/$hash.$ext"
  if [[ -e $file ]]; then
    rm -f "$tmp"
  else
    mv "$tmp" "$file"
  fi
  jq -cn --arg mime "$mime" --arg path "$file" --arg captured_at "$(date +'%A %H:%M')" \
    '{type:"image", mime:$mime, path:$path, capturedAt:$captured_at}'
}

emit_text() {
  local raw
  raw=$(cat)
  [[ -n $raw ]] || exit 0
  jq -cn --arg text "$raw" '{type:"text", text:$text}'
}

case "${1:-}" in
  text) emit_text; exit 0 ;;
  image/*) emit_image "$1"; exit 0 ;;
esac

for mime in image/png image/jpeg image/webp image/gif image/bmp image/tiff; do
  if grep -qx "$mime" <<<"$types"; then
    timeout 2s wl-paste --type "$mime" 2>/dev/null | emit_image "$mime"
    exit 0
  fi
done

if grep -q '^text/' <<<"$types" || grep -qx 'UTF8_STRING' <<<"$types" || grep -qx 'STRING' <<<"$types"; then
  wl-paste --type text --no-newline 2>/dev/null | emit_text
fi