# Archwarts

Archwarts is an independent, opinionated Arch Linux + Hyprland desktop
bootstrap. It is derived in behavior from the useful functionality of Omarchy,
but is Arch-native, user-space-first, and has no required Omarchy package,
mirror, key, update, release, or runtime infrastructure.

## Project status

Version 0.1.0 — first release candidate. The core is validated by host/static
tests and by a clean-Arch QEMU/KVM acceptance run
(`docs/archwarts/vm-acceptance.md`). This is an early release; it is not
production-ready software.

## Supported platform

- Arch Linux x86_64 (clean, minimal).
- Hyprland + Quickshell desktop; SDDM as the display manager.

## Major features

- Staged, idempotent, user-space installer with an ownership manifest.
- Independent Hyprland + Quickshell desktop core: bar, launcher, menu,
  notifications, clipboard (with sensitive-content exclusion),
  audio/network/bluetooth/media panels, OSD, lock, theme.
- Independent updater (preflight, gated `pacman -Syu`, separate AUR phase,
  ordered migrations, reporting).
- Hardware detection/planning (detection-driven, safe for unknown hardware).
- Read-only `doctor` diagnostics and a conservative ownership-based uninstall.
- Explicit privilege boundary; the privileged plan is never auto-executed.

## Default applications

- Browser: **Firefox** (Wayland, enterprise policy, PiP window rule).
- File manager: **Dolphin** (KIO, Ark, foot terminal, LocalSend/transcode
  service menus).
- Password manager: **Bitwarden** (+ `bitwarden-cli`).
- Terminal: **foot**.

No Chromium, Nautilus, or 1Password dependencies.

## Installation prerequisites

- A clean Arch Linux x86_64 system.
- A non-root user in `wheel`.
- Official `[core]`/`[extra]` repositories configured.

## Installation flow

1. Extract the Archwarts source archive to a writable location.
2. `bin/archwarts install preflight default`
3. `bin/archwarts install plan default` — review the generated privileged plan.
4. Execute the privileged plan explicitly (official packages from the plan,
   `systemctl enable/mask` per `install/privileged-actions.tsv`, and the
   Firefox policy file) — elevation is requested only for these steps.
5. `bin/archwarts install stage base` and `bin/archwarts install stage desktop-core`
6. `bin/archwarts theme apply default`
7. Install a display-manager session entry that runs `archwarts-session`, then
   reboot and log in.

The distribution design is documented in `docs/archwarts/release-artifacts.md`.

## Update flow

`bin/archwarts update run` performs preflight, exactly one `pacman -Syu`, the
optional AUR phase, and ordered migrations. Privileged phases require
`ARCHWARTS_UPDATE_EXECUTE=1`. `bin/archwarts update report` and `... status`
summarize results.

## Recovery / doctor

`bin/archwarts doctor` reports version, managed-file drift, services, portals,
PipeWire, NetworkManager, Bluetooth, Hyprland/Quickshell, migrations,
`.pacnew`/`.pacsave`, foreign packages, and reboot state — read-only.

## Uninstall

`bin/archwarts uninstall plan` previews; `bin/archwarts uninstall` removes only
unmodified Archwarts-managed files, refuses modified files, preserves state and
unrelated data, and reports (never removes) packages.

## Known limitations

- Interactive desktop items and real-hardware panels require a human-driven
  graphical pass; the headless VM validated the programmatic surface.
- The display-manager session entry uses a per-user launcher path in the
  acceptance environment; a portable system session entry is future work.
- The privileged installer/update phases are documented, not yet wrapped in a
  single convenience command.

## Deferred functionality

- Apple T2 and vendor-specific unsigned sources (unsupported/deferred).
- Omarchy plugin compatibility layer (post-v1, optional).
- Optional AUR packages and optional desktop applications.
- A PKGBUILD/AUR package for Archwarts.

## Security / trust model

Summarized in `docs/archwarts/security.md`: unprivileged normal operation,
explicit gated elevation, validated user input at trust boundaries, no implicit
sudo, no unsigned repositories, AUR optional and independent.

## Derivation / credits

Archwarts is derived from Omarchy. The original MIT copyright and permission
notice are preserved in `LICENSE`. Attribution: `THIRD_PARTY_NOTICES.md`,
`docs/archwarts/provenance.md`, `docs/archwarts/asset-provenance.md`.

## License

MIT. See `LICENSE`.