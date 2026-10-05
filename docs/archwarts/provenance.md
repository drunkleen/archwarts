# Archwarts provenance and derivation

Archwarts is an independent implementation derived in behavior from the useful
functionality of Omarchy. This document records, per product area, whether
material is original Archwarts work, adapted from Omarchy behavior, or
third-party. It is the derivation record required by the MIT attribution in
`LICENSE`.

## Product areas

| Area | Classification | Notes |
| --- | --- | --- |
| `bin/archwarts` (CLI) | Original Archwarts work | New command surface; no Omarchy code copied. |
| `lib/archwarts/*.sh` | Original Archwarts work, behaviorally adapted | Installer stages, ownership manifest, updater phases, hardware detection, doctor, uninstall, defaults. Behaviors informed by audited Omarchy interfaces but written independently. |
| `desktop/shell/` (QML/JS) | Original Archwarts work, behaviorally informed | Shell root, bar, panels, clipboard, notifications, launcher, menu. No inherited QML/JS copied; Quickshell native services used directly. |
| `desktop/apps/` | Original Archwarts work | Dolphin service menus, dolphinrc, Firefox enterprise policy, wayland-session entry. |
| `desktop/themes/default/palette.conf` | Original structure; third-party colors | Color values from the Catppuccin Mocha palette (MIT); see `THIRD_PARTY_NOTICES.md`. |
| `packages/` | Original Archwarts work | Package selection policy (official Arch → AUR → upstream). |
| `stages/` | Original Archwarts work | Rendered templates for Hyprland config and session launcher. |
| `install/privileged-*.tsv` | Original Archwarts work | Explicit privileged action and file declarations. |
| `test/archwarts/`, `test/vm/` | Original Archwarts work | Test and acceptance scaffolding. |
| `docs/archwarts/` | Original Archwarts work | Project documentation. |

## Inherited migration input (not shipped)

The development source tree still contains the inherited Omarchy implementation
(`bin/omarchy-*`, `default/`, `config/`, `shell/`, `migrations/`, `manual/`,
etc.). It is migration input only. The Archwarts release artifact includes only
the product areas listed above; inherited material is never copied into the
staged runtime or the release. See `docs/archwarts/release-artifacts.md`.

## Attribution requirements

- The Omarchy MIT copyright and permission notice are preserved verbatim in
  `LICENSE`.
- `THIRD_PARTY_NOTICES.md` records Omarchy, Catppuccin, and Nerd Fonts
  attribution.
- No inherited work is claimed as original Archwarts authorship.
- Any future bundled third-party asset must be added to
  `docs/archwarts/asset-provenance.md` before release.