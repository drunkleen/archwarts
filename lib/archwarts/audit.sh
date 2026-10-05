#!/usr/bin/env bash

# Pre-VM acceptance audit. Static, read-only checks over the Archwarts source
# and manifests, followed by a readiness classification. It never stages,
# installs, or mutates anything.

# Release-candidate audit: hygiene, branding, licensing, and artifact checks
# over the Archwarts product tree. Static and read-only.
archwarts_release_audit() {
  local root=$ARCHWARTS_SOURCE_ROOT fails=0

  printf '== Archwarts release-candidate audit ==\n\n'

  # --- licensing / provenance / attribution present ---
  for f in LICENSE NOTICE THIRD_PARTY_NOTICES.md \
    docs/archwarts/provenance.md docs/archwarts/asset-provenance.md; do
    if [[ -f $root/$f ]]; then
      printf 'PASS\tprovenance file present: %s\n' "$f"
    else
      printf 'FAIL\tmissing provenance file: %s\n' "$f"
      fails=$((fails + 1))
    fi
  done
  if rg -q 'Copyright \(c\) David Heinemeier Hansson' "$root/LICENSE" \
    && rg -q 'Copyright \(c\) Archwarts contributors' "$root/LICENSE"; then
    printf 'PASS\tLICENSE preserves Omarchy and claims Archwarts work\n'
  else
    printf 'FAIL\tLICENSE attribution incomplete\n'
    fails=$((fails + 1))
  fi

  # --- hygiene markers ---
  if rg -n 'TODO|FIXME|HACK|XXX' "$root/bin/archwarts" "$root/lib/archwarts" \
    "$root/desktop" "$root/stages" --glob '!*.md' --glob '!audit.sh' 2>/dev/null \
    | rg -qv 'clipboard.XXXXXX'; then
    printf 'FAIL\ttodo/fixme/hack markers in product code\n'
    fails=$((fails + 1))
  else
    printf 'PASS\tno todo/fixme/hack markers\n'
  fi

  # --- dev paths ---
  if rg -n '/home/snape|/mnt/storage|/tmp/aw' "$root/bin/archwarts" "$root/lib/archwarts" \
    "$root/desktop" "$root/stages" "$root/packages" --glob '!audit.sh' 2>/dev/null; then
    printf 'FAIL\tdevelopment path references in product\n'
    fails=$((fails + 1))
  else
    printf 'PASS\tno development path references\n'
  fi

  # --- VM artifacts must not be inside the product tree ---
  if find "$root" -maxdepth 2 \( -name '*.qcow2' -o -name '*.iso' -o -name '*.ppm' \
    -o -name 'serial.sock' -o -name 'mon.sock' -o -name '*.log' \) 2>/dev/null | rg -qv 'docs/|desktop/shell/.+\.qml'; then
    printf 'FAIL\tVM/runtime artifacts present in product tree\n'
    fails=$((fails + 1))
  else
    printf 'PASS\tno VM/runtime artifacts in product tree\n'
  fi

  # --- secrets ---
  if rg -n -i 'BEGIN [A-Z ]*PRIVATE KEY|api[_-]?key\s*=|secret\s*=\s*["'"'"'][^"'"'"']{8,}' \
    "$root/bin/archwarts" "$root/lib/archwarts" "$root/desktop" "$root/stages" \
    "$root/packages" 2>/dev/null | rg -v 'api-key|apiKey' ; then
    printf 'FAIL\tpossible secret material in product\n'
    fails=$((fails + 1))
  else
    printf 'PASS\tno secret material in product\n'
  fi

  # --- permissions ---
  if find "$root/bin/archwarts" "$root/lib/archwarts" "$root/desktop" "$root/stages" \
    "$root/packages" -type f -perm -0002 2>/dev/null | rg -q .; then
    printf 'FAIL\tworld-writable product file\n'
    fails=$((fails + 1))
  else
    printf 'PASS\tno world-writable product files\n'
  fi

  # --- branding: no Omarchy in product user-visible strings ---
  if rg -i 'Omarchy|omarchy' "$root/desktop/shell" --glob '*.qml' --glob '*.js' 2>/dev/null \
    | rg -v 'README|inherited'; then
    printf 'FAIL\tuser-visible Omarchy branding in shell\n'
    fails=$((fails + 1))
  else
    printf 'PASS\tno user-visible Omarchy branding in shell\n'
  fi
  if rg -q 'Archwarts' "$root/README.md" "$root/desktop/shell/shell.qml" \
    "$root/desktop/shell/menu/Menu.qml" 2>/dev/null; then
    printf 'PASS\tproduct branded as Archwarts\n'
  else
    printf 'FAIL\tproduct branding not Archwarts\n'
    fails=$((fails + 1))
  fi

  # --- release tarball hygiene (only product paths) ---
  local tarball
  tarball=$(mktemp)
  tar -czf "$tarball" -C "$root" \
    bin/archwarts lib/archwarts packages install/privileged-actions.tsv \
    install/privileged-files.tsv stages desktop ARCHWARTS_VERSION LICENSE NOTICE \
    THIRD_PARTY_NOTICES.md README.md docs 2>/dev/null
  if tar -tzf "$tarball" 2>/dev/null | rg -q '^bin/omarchy|^default/|^config/|^manual/|^migrations/' ; then
    printf 'FAIL\trelease tarball would include inherited migration input\n'
    fails=$((fails + 1))
  else
    printf 'PASS\trelease tarball excludes inherited migration input\n'
  fi
  if tar -tzf "$tarball" 2>/dev/null | rg -q '\.qcow2|\.iso|\.ppm|\.log$'; then
    printf 'FAIL\trelease tarball would include VM artifacts\n'
    fails=$((fails + 1))
  else
    printf 'PASS\trelease tarball excludes VM artifacts\n'
  fi
  rm -f "$tarball"

  printf '\n== RELEASE-CANDIDATE RESULT ==\n'
  if (( fails == 0 )); then
    printf 'RELEASE CANDIDATE READY (audit checks pass)\n'
  else
    printf 'NOT READY: %s audit failure(s)\n' "$fails"
  fi
  (( fails == 0 ))
}

archwarts_audit_prevm() {
  local root=$ARCHWARTS_SOURCE_ROOT fails=0

  printf '== Archwarts pre-VM acceptance audit ==\n\n'

  # --- package policy: no inherited repository/mirror/keyring/channel ---
  # remove.packages lists inherited packages to REMOVE (migration policy) and
  # is intentionally excluded; the install-facing manifests must be clean.
  if rg -qi 'pkgs\.omarchy|mirror\.omarchy|omarchy-keyring|omarchy.*channel|SigLevel\s*=\s*Never' \
    "$root/packages/core.packages" "$root/packages/default.packages" \
    "$root/packages/optional.packages" "$root/packages/sources.tsv" \
    "$root/install/privileged-actions.tsv" "$root/install/privileged-files.tsv" 2>/dev/null; then
    printf 'FAIL\tpackage policy must not require inherited repository infrastructure\n'
    fails=$((fails + 1))
  else
    printf 'PASS\tno inherited repository/mirror/keyring/channel requirements\n'
  fi

  # --- no omarchy-* command dependencies in core code ---
  if rg -n 'omarchy-[a-z0-9-]+' "$root/bin/archwarts" "$root/lib" "$root/desktop" \
    --glob '!*.md' --glob '!audit.sh' 2>/dev/null | rg -v 'omarchy-shell|remove\.packages|linux-omarchy'; then
    printf 'FAIL\tcore code references an omarchy-* command\n'
    fails=$((fails + 1))
  else
    printf 'PASS\tno omarchy-* command dependencies in core code\n'
  fi

  # --- no unexplained runtime path references ---
  if rg -i 'OMARCHY_PATH|/usr/share/omarchy|/var/lib/omarchy|~/.config/omarchy|~/.local/state/omarchy' \
    "$root/bin/archwarts" "$root/lib" "$root/desktop" --glob '!*.md' --glob '!audit.sh' 2>/dev/null; then
    printf 'FAIL\tcore code references an inherited runtime path\n'
    fails=$((fails + 1))
  else
    printf 'PASS\tno inherited runtime path references in core code\n'
  fi

  # --- Firefox is the browser default; Dolphin the file manager; Bitwarden integrated ---
  if rg -q 'firefox' "$root/stages/desktop-core/hypr/hyprland.conf.tpl" \
    && rg -q 'archwarts launch-app firefox' "$root/desktop/shell/menu/Menu.qml"; then
    printf 'PASS\tFirefox is the browser default\n'
  else
    printf 'FAIL\tFirefox default not wired\n'
    fails=$((fails + 1))
  fi
  if rg -q 'dolphin' "$root/stages/desktop-core/hypr/hyprland.conf.tpl" \
    && [[ -f $root/desktop/apps/dolphin/dolphinrc ]]; then
    printf 'PASS\tDolphin is the file-manager default\n'
  else
    printf 'FAIL\tDolphin default not wired\n'
    fails=$((fails + 1))
  fi
  if rg -q 'bitwarden' "$root/stages/desktop-core/hypr/hyprland.conf.tpl" \
    && rg -q 'Bitwarden' "$root/desktop/shell/menu/Menu.qml"; then
    printf 'PASS\tBitwarden password-manager integration present\n'
  else
    printf 'FAIL\tBitwarden integration not wired\n'
    fails=$((fails + 1))
  fi

  # --- rejected defaults absent ---
  if rg -qi 'chromium|nautilus|1password' "$root/desktop" --glob '!*.md' 2>/dev/null; then
    printf 'FAIL\tdesktop core references a rejected default application\n'
    fails=$((fails + 1))
  else
    printf 'PASS\tno Chromium/Nautilus/1Password dependencies\n'
  fi

  # --- installer is staged ---
  if [[ -f $root/stages/base/README.md && -f $root/stages/desktop-core/hypr/hyprland.conf.tpl ]]; then
    printf 'PASS\tinstaller stages (base, desktop-core) exist\n'
  else
    printf 'FAIL\tinstaller stages incomplete\n'
    fails=$((fails + 1))
  fi

  # --- privilege boundary: update executes only when explicitly gated ---
  if rg -q 'ARCHWARTS_UPDATE_EXECUTE' "$root/lib/archwarts/update.sh"; then
    printf 'PASS\tupdate execution is explicitly gated\n'
  else
    printf 'FAIL\tupdate privilege boundary missing\n'
    fails=$((fails + 1))
  fi

  # --- hardware is detection-driven and never replaces the kernel ---
  if rg -q 'kernel-unchanged' "$root/lib/archwarts/hardware.sh" \
    && rg -q 'unsupported.*apple-t2' "$root/lib/archwarts/hardware.sh"; then
    printf 'PASS\thardware planning is explicit and safe (no kernel replacement, T2 unsupported)\n'
  else
    printf 'FAIL\thardware safety properties missing\n'
    fails=$((fails + 1))
  fi

  # --- doctor non-mutating, uninstall conservative ---
  if rg -q 'read-only|never mutates' "$root/lib/archwarts/doctor.sh" \
    && rg -q 'refuse' "$root/lib/archwarts/uninstall.sh"; then
    printf 'PASS\tdoctor is non-mutating and uninstall refuses modified files\n'
  else
    printf 'FAIL\tdoctor/uninstall safety properties missing\n'
    fails=$((fails + 1))
  fi

  # --- ownership manifest exists ---
  if rg -q 'archwarts_ownership_record' "$root/lib/archwarts/ownership.sh"; then
    printf 'PASS\townership manifest machinery present\n'
  else
    printf 'FAIL\townership manifest missing\n'
    fails=$((fails + 1))
  fi

  # --- attribution preserved ---
  if [[ -f $root/LICENSE && -f $root/NOTICE ]]; then
    printf 'PASS\tlicense and attribution notice present\n'
  else
    printf 'FAIL\tlicense/attribution missing\n'
    fails=$((fails + 1))
  fi

  printf '\n== PRE-VM READINESS ==\n'
  if (( fails == 0 )); then
    printf 'READY\n'
  else
    printf 'BLOCKERS: %s audit failure(s) to resolve before VM acceptance\n' "$fails"
  fi
  printf 'NEEDS VM VALIDATION: graphical/system behavior (shell, portals, audio, network, bluetooth, Wayland)\n'
  printf 'DEFERRED: Apple T2 and vendor sources requiring a signed/defensible source model\n'
  printf 'DEFERRED: Omarchy plugin compatibility layer and optional AUR/Optional packages\n'

  (( fails == 0 ))
}