# Archwarts desktop shell

The Archwarts desktop core is an independent Quickshell implementation under
`desktop/shell/`, staged to `$XDG_CONFIG_HOME/archwarts/shell`.

- `shell.qml` — root/lifecycle and the IPC trigger loop
  (`archwarts shell ipc <target> <action>`).
- `bar/` — per-monitor bar: workspaces, active window, clock, tray, status
  indicators.
- `launcher/` — searchable application launcher (`archwarts launch-app`).
- `menu/` — main menu with the approved defaults and session actions.
- `notifications/` — live popups and persisted history (DND aware).
- `clipboard/` — clipboard history with a sensitive-content boundary
  (`x-kde-passwordManagerHint` and `CLIPBOARD_STATE=sensitive` are excluded).
- `panels/` — audio, network, bluetooth, media, OSD.
- `lock/` — hyprlock integration.
- `theme/` — palette-driven colors (`archwarts theme apply`).
- `Ui/`, `Commons/`, `js/` — shared components, helpers, and pure logic.

The shell uses Quickshell native services directly (Tray, Pipewire, Mpris,
UPower, Notifications, Hyprland, Networking, Bluetooth). No inherited shell
code is used.

## Validation

Host: headless config load, node-tested logic, fixture script tests, staged
runtime independence. VM: session, bar layer, workspaces, binds, IPC, capture,
theme, defaults, application launch. Interactive items require a human-driven
VNC pass. See `vm-acceptance.md`.