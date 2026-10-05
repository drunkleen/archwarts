# Archwarts desktop shell

The Archwarts desktop core is an independent Quickshell implementation. It is
behaviorally informed by the audited Omarchy shell but contains no inherited
code, path, command, or repository reference.

## Subsystems

- `shell.qml` — root/lifecycle and the IPC trigger loop
  (`archwarts shell ipc <target> <action>`).
- `bar/` — per-monitor bar: workspaces, active window, clock, tray, and status
  indicators.
- `launcher/` — searchable application launcher over desktop entries
  (`archwarts launch-app` resolver).
- `menu/` — main menu with approved default applications and session actions.
- `notifications/` — live popups and persisted history (DND aware).
- `clipboard/` — clipboard history with a sensitive-content boundary in
  `capture.sh` (skips `x-kde-passwordManagerHint` and `CLIPBOARD_STATE=sensitive`).
- `panels/` — audio, network, bluetooth, media, and OSD.
- `lock/` — lock integration via hyprlock.
- `theme/` — palette-driven colors (`archwarts theme apply`).
- `js/` — pure logic modules tested directly with node.
- `Ui/`, `Commons/` — shared panel surface and helpers.

## Validation status

Static and fixture validation (runs on the development host):

- `test/archwarts/shell-static-test` loads the config headlessly with
  `quickshell -p` and asserts `Configuration Loaded`.
- `test/archwarts/shell-js-test` exercises the search, clipboard, and
  notification logic with node.
- `test/archwarts/runtime-independence-test` scans the staged runtime for any
  inherited-runtime reference.
- `test/archwarts/stages-test` asserts the staged ownership and idempotency.

Graphical acceptance (interaction with Hyprland, DBus, Pipewire, BlueZ,
NetworkManager, and the Wayland compositor) still requires the clean Arch VM.
The headless load and the fixture tests are not a substitute for it.