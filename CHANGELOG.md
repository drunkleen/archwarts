# Changelog

All notable changes to Archwarts are documented here. Archwarts follows
Semantic Versioning (see `docs/archwarts/versioning.md`).

## 0.1.0

First release candidate.

### Desktop

- Independent Hyprland + Quickshell desktop core staged under the Archwarts
  XDG config home: bar (workspaces, active window, clock, tray, status
  indicators), searchable application launcher, main menu, notifications with
  history and do-not-disturb, clipboard history with sensitive-content
  exclusion, audio/network/bluetooth/media panels, OSD, lock (hyprlock), and
  palette-driven theme.
- No inherited Omarchy shell code or runtime paths.

### Installer

- Staged, idempotent, unprivileged installer (`base`, `desktop-core`) with an
  ownership manifest (SHA-256, conflict refusal, stale-row purge).
- Self-contained staged runtime with no source-tree dependency.
- Explicit, non-executed privileged plan (packages by official/AUR source,
  systemd actions, system files).

### Applications

- Firefox default browser (Wayland, enterprise policy, PiP rule, web-app URL
  entries).
- Dolphin default file manager (KIO, Ark, foot terminal, LocalSend/transcode
  service menus).
- Bitwarden default password manager (`bitwarden-cli`).
- No Chromium, Nautilus, or 1Password dependencies.

### Updates

- Independent updater: flock, durable logs, preflight (network, pacman lock,
  disk, Arch News), exactly one gated `pacman -Syu`, separate independent AUR
  phase, ordered idempotent migrations, and reporting (orphans, foreign,
  pacnew/pacsave, reboot, failed services).

### Hardware

- Detection-driven hardware model (PCI/DMI/sysfs) with separable planning;
  NVIDIA selects the official `nvidia-open-dkms`; the kernel is never replaced;
  Apple T2 is unsupported/deferred.

### Recovery

- Read-only `doctor` diagnostics.
- Conservative ownership-based uninstall (refuses modified files, preserves
  state and unrelated data, reports packages without removing them).

### Security

- Validated input at trust boundaries (IPC, launch-app id, web-app URL).
- Explicit privilege gating; no implicit sudo; no unsigned repositories.

### Testing

- Host test suite (21 suites) covering packages, paths, ownership, installer,
  shell, defaults, updates and failure recovery, hardware, doctor, uninstall,
  runtime independence, and release audit.
- Clean-Arch QEMU/KVM acceptance (PASS WITH DEFERRED ITEMS) covering installer
  idempotency, session, desktop, applications, update, doctor, uninstall, and
  negative independence.