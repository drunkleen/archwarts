# Archwarts pre-VM readiness

Generated 2026-10-04 from the static pre-VM audit (`archwarts preflight-audit`).
This is a readiness classification for the clean-Arch VM phase, not a claim of
system or graphical acceptance.

## READY

Features sufficiently implemented for VM testing:

- Staged, idempotent, unprivileged installer (`base`, `desktop-core`) with an
  ownership manifest and conflict refusal.
- Self-contained staged runtime (no source-tree or inherited dependency).
- Independent Hyprland + Quickshell desktop core (bar, launcher, menu,
  notifications, clipboard with sensitive-content boundary,
  audio/network/bluetooth/media panels, OSD, lock, theme).
- Independent update system: locking, durable logs, preflight (network, pacman
  lock, disk, Arch News), exactly one gated `pacman -Syu`, independent AUR
  phase, ordered unprivileged migrations, orphan/foreign/pacnew/reboot/failed
  service reporting.
- Hardware detection/profile system with fixture-based testability; NVIDIA
  selects the current official `nvidia-open-dkms`; T2 is explicitly
  unsupported/deferred; the kernel is never replaced.
- Default application integration: Firefox (browser), Dolphin (file manager),
  Bitwarden (password manager); no Chromium/Nautilus/1Password dependencies.
- Conservative uninstall based on the ownership manifest.
- Read-only `doctor` diagnostics.
- Privilege boundaries explicit: update executes only with
  `ARCHWARTS_UPDATE_EXECUTE=1`; hardware plans never execute.

## NEEDS VM VALIDATION

Implemented but requiring real clean-Arch/Wayland/system behavior:

- Shell rendering and interaction (workspaces, launcher, menu, panels).
- DBus notifications daemon and history.
- Clipboard watchers against a real Wayland clipboard.
- PipeWire/audio, NetworkManager, and BlueZ service integration.
- Hyprland session start via `archwarts-session`.
- Firefox/Dolphin/Bitwarden launch and defaults under a real session.
- `pacman -Syu` execution path (mocked on the development host).
- Firefox enterprise policy install (`/etc/firefox/policies/policies.json`).

## BLOCKERS

None. The static audit passes with READY.

## DEFERRED

Intentionally postponed:

- Apple T2 and any vendor-specific sources requiring a signed, defensible
  source model (opt-in only once justified).
- Omarchy plugin compatibility layer.
- Optional AUR packages and optional desktop applications not in the default
  profile.
- Graphical shell polish and plugin ecosystem beyond the desktop core.