# Archwarts VM acceptance

Clean Arch Linux x86_64 functional acceptance, run in a disposable QEMU/KVM
VM. This establishes clean-Arch functional acceptance, not final release
readiness.

## Environment

- Host: development machine; QEMU 11.1.1 + KVM (`/dev/kvm`), OVMF UEFI,
  user-mode NAT (`10.0.2.2` gateway, host SSH forward `2222→22`), VNC console
  on `127.0.0.1:5901`, monitor screendumps.
- ISO: official `archlinux-2026.10.01-x86_64.iso` (SHA256 verified against
  `archlinux.org/iso/latest/sha256sums.txt`).
- VM: q35, KVM, 4 vCPU, 4 GiB RAM, 24 GiB qcow2, virtio disk/network,
  virtio-vga, systemd-boot UEFI.
- Automation (disposable only, under `test/vm/`, never part of the Archwarts
  product installer): `test/vm/install`, `test/vm/run`, `test/vm/session`,
  `test/vm/acceptance`, `test/vm/regression`.

## VM baseline (pre-install)

Recorded in `test/vm/baseline/baseline.txt`:

- `/etc/os-release`: Arch Linux (ID=arch, BUILD_ID=rolling)
- `uname -a`: `Linux arch-clean 7.2.8-arch1-2 ... x86_64 GNU/Linux`
- Installed packages: 178 explicit (minimal base)
- Enabled services: getty, NetworkManager, systemd-userdbd
- Repositories: `[core]`, `[extra]` only — no Omarchy
- Filesystem: ext4 `/`, vfat ESP `/boot`
- Bootloader: systemd-boot 262, UEFI 2.70 (EDK II)
- Hardware visible to the VM: virtio device tree (no discrete GPU/audio/
  network controller; no battery)
- Users/groups: root, archtest (wheel)
- No Omarchy, no Archwarts, no inherited repositories/keyrings/config

## Installer acceptance — PASS

- Preflight and package plan (`default`): 88 official packages + `localsend`
  (AUR).
- Official package installation: succeeded (pacman, real, in-VM).
- Privileged plan execution: services enabled, Firefox enterprise policy
  installed to `/etc/firefox/policies/policies.json`.
- User-space staging (as `archtest`): `base` + `desktop-core`; ownership
  manifest with 92 entries; shell, Hyprland config, session launcher, theme,
  runtime CLI staged.
- Idempotency: second `desktop-core` run left files byte-identical and the
  stage marker single.
- Hardware detection/planning: `gpu unknown` (virtio), safe note, kernel
  unchanged.
- First-run state recorded.

## Reboot / session acceptance — PASS

Boot → SDDM (autologin, configured via an Archwarts wayland-session entry) →
`archwarts-session` → `Hyprland -c <Archwarts config>` → Quickshell.
Evidence: serial process checks (`Hyprland` and `quickshell` running with the
Archwarts config/shell paths), journal free of Hyprland/Quickshell errors, and
VNC screendumps (`runtime/session-*.ppm`) showing a rendered desktop
(1280x800, ~24k colors). Graphical screenshots cannot be embedded here; the
PPM/PNG captures are retained in `test/vm/runtime/`.

## Desktop acceptance

PASS:
- Quickshell starts automatically
- Bar renders (Quickshell `archwarts-bar` layer surface present)
- Workspaces update (`hyprctl workspaces`)
- Hyprland keybindings present (`hyprctl binds`)
- Shell IPC (OSD trigger reaches the shell)
- Screenshot/capture (`archwarts capture fullscreen`)
- Theme/palette
- Defaults status
- Clipboard sensitive-content exclusion (`x-kde-passwordManagerHint`)

NOT TESTABLE IN CURRENT VM (require interactive VNC input or real hardware):
- Launcher/menu/notification-history/DND interaction (click/keyboard input)
- Audio/network/bluetooth panel interaction (no real audio/BlueZ/NetworkManager
  radio in the VM; services present but no hardware)
- Media/MPRIS with a player (no player started)
- Lock screen interaction (hyprlock launch is bound but interactive lock was
  not exercised)
- OSD visual appearance (trigger written; rendering on screendump not
  verified frame-by-frame)

## Application acceptance — PASS

- Firefox: installed, launches in Wayland session, HTTP/HTTPS default binding
  (Hyprland `SUPER+B` → `archwarts launch-app firefox`), enterprise policy
  installed, PiP window rule present, web-app URL entries created; no Chromium
  requirement.
- Dolphin: installed, launches, directory MIME default, foot terminal
  integration, KIO/Ark/thumbnails packages present, LocalSend/transcode
  service menus staged; no Nautilus or Plasma desktop requirement.
- Bitwarden: installed, `SUPER+P` binding, menu action, `bitwarden-cli`
  present; no 1Password dependency. Interactive Firefox-extension onboarding
  was not exercised in the VM.

## Update acceptance — PASS

- Preflight: network ok, no pacman lock, disk ok, pacman ok (Arch News
  `skip` — informant not installed).
- Real `pacman -Syu` executed once via `archwarts update run` with the execute
  gate: `official ok`.
- Controlled migration fixture (`10-acceptance-fixture.sh`) ran once and was
  idempotent on the second run.
- AUR phase with a failing helper reported `aur failed` while official status
  remained `ok` — an AUR failure does not corrupt a successful official
  upgrade.
- Report/status: revision `0.1.0-dev`, orphans 0, foreign 0, pacnew 0,
  reboot no, failed services 0.

## Doctor acceptance — PASS

- Baseline: managed files ok, migrations ok.
- Modified managed file → `managed-files warn` detected; doctor did not alter
  the file (non-mutating).
- Pending migration fixture → `migrations warn` detected.
- After restoration (file re-staged, migration removed) both returned to ok.

## Uninstall / recovery acceptance — PASS

- Uninstall plan lists removals and refuses the deliberately modified managed
  file.
- Uninstall removed unmodified managed files (shell, session launcher) and
  protected the modified Hyprland config.
- Unrelated user data preserved; Archwarts state preserved by default.
- Packages reported (not removed); bootloader, kernel, and NetworkManager
  intact before and after.
- Reboot after uninstall: system boots, `systemctl is-system-running` =
  `running`, bootloader entry intact.

## Negative independence test — PASS

- No Omarchy repository/mirror in pacman configuration.
- No Omarchy package installed.
- No `omarchy-*` command on the user PATH.
- No unexplained inherited-runtime reference in the staged Archwarts runtime.
- Remaining textual occurrences are classified: removal policy
  (`packages/remove.packages`), documentation (`README.md`), diagnostic
  patterns (`lib/archwarts/audit.sh`), attribution (LICENSE/NOTICE).

## Defects discovered and fixed

1. Acceptance harness could hang indefinitely when a task never emitted its
   completion marker (QEMU/HTTP left running). Fixed: bounded per-phase and
   overall timeouts in `driver.py` and `boot.sh`/`session-run.sh`, guaranteed
   marker emission via an EXIT trap in every acceptance script, and verified
   cleanup. Regression test: `test/vm/regression/hang-test.sh`.
2. `archwarts install stage base` failed when `/run/user/$UID` did not exist
   (no graphical session). Fixed: the transient runtime home is optional with
   a warning. Host regression test added.
3. `power-profiles-daemon.service` was enabled by the privileged plan but the
   package was absent from the manifests. Fixed: added to `default.packages`.
4. Re-staging a managed file after deletion left a stale ownership row that
   produced false managed-file drift. Fixed: `archwarts_ownership_purge`
   removes prior rows for a target before recording. Host regression test
   added.

## Tests added

- `test/vm/regression/hang-test.sh` (harness bounded timeout + cleanup).
- Host: runtime-home tolerance (stages), ownership purge (ownership-test).
- All 19 host test suites still pass; the static pre-VM audit reports READY.

## Remaining limitations

- Interactive desktop items (launcher/menu/notification/DND interaction, lock,
  OSD visuals) and real-hardware items (audio/BlueZ/NetworkManager radios,
  MPRIS with a player, Firefox extension onboarding) require an interactive
  VNC session or real hardware; not exercised in this headless harness.
- The multi-user wayland-session entry uses a per-user launcher path; a
  portable system session entry for general deployment remains future work.
- Auto-login was used to exercise the display-manager → Hyprland → Quickshell
  path; manual interactive SDDM login still requires a human-driven pass.

## Classification

**PASS WITH DEFERRED ITEMS**

- PASSED: installer, idempotency, reboot/session, bar/workspaces/binds/IPC/
  capture/theme/clipboard-sensitivity, application launch and defaults,
  update (real pacman -Syu, migrations, AUR independence), doctor, conservative
  uninstall, bootability after uninstall, negative independence.
- NOT TESTABLE: interactive launcher/menu/notification/DND/lock/OSD visuals,
  audio/network/bluetooth panels, MPRIS playback.
- DEFERRED: Apple T2 and vendor-specific unsigned sources; Omarchy plugin
  compatibility layer; optional AUR/optional packages; multi-user session
  entry; interactive login pass.
- BLOCKERS: none.

Archwarts is not declared production-ready by this milestone; it establishes
clean-Arch functional acceptance only.