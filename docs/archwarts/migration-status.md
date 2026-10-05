# Migration status

| Subsystem | Status | Notes |
| --- | --- | --- |
| Workspace and pinned baseline | done | External workspace records provenance and inventories |
| Archwarts CLI skeleton | done | `version`, `paths`, `doctor`, and package inspection are independent |
| XDG path contract | done | Implemented and covered by isolated tests |
| Package policy | done | Target groups verify cleanly; all inherited package names have a source audit |
| Installer | in progress | Unprivileged staged installer: base + desktop-core stages, ownership manifest, explicit non-executed privileged plan |
| Update system | in progress | Independent updater: locking, logs, preflight, gated pacman -Syu, independent AUR phase, ordered migrations, reporting; real in-VM pacman -Syu accepted |
| Hyprland configuration | done | Independent Archwarts Hyprland config staged with shell integration bindings; VM session acceptance passed |
| Quickshell desktop | done | Independent Archwarts shell staged; VM session acceptance passed (bar layer, workspaces, binds, IPC, capture) |
| Firefox migration | done | Default browser, keybindings, menu, web-app entries, PiP rule, enterprise policy in privileged plan; VM launch accepted |
| Dolphin migration | done | Directory MIME, service menus (LocalSend/transcode), dolphinrc (foot terminal), window rules; VM launch accepted |
| Bitwarden migration | done | Hotkey, menu, CLI presence; no 1Password dependency; VM launch accepted |
| Hardware profiles | in progress | Detection/planning model with fixtures; NVIDIA selects official open module; T2 deferred/unsupported |
| Recovery and uninstall | done | Read-only doctor diagnostics; conservative ownership-based uninstall; VM acceptance passed |
| Plugins | not started | Existing schema and host are reference-only |

Status changes require implementation and validation. Presence of inherited
Omarchy code does not make a subsystem migrated.
