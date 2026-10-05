# Archwarts recovery

## Doctor

`archwarts doctor` is read-only. It reports version/revision, managed-file
drift, package-source consistency, installer/update state, failed services,
portal/PipeWire/WirePlumber/NetworkManager/Bluetooth state, Hyprland/Quickshell
state, pending migrations, `.pacnew`/`.pacsave`, foreign packages, reboot
requirement, and hardware. It diagnoses; it never mutates.

## Uninstall

`archwarts uninstall` uses the ownership manifest to remove only
Archwarts-managed files whose content still matches the recorded SHA-256.

- Modified managed files are refused (never removed).
- State under `$XDG_STATE_HOME/archwarts` is preserved by default.
- Unrelated user data is preserved.
- Packages are reported as possibly unused, never removed.
- The bootloader, kernel, network stack, and shared system packages are never
  touched.

`archwarts uninstall plan` previews removals/refusals.

## Update recovery

On failure the updater records the failing phase, keeps the durable log, and
returns non-zero. There is no transactional rollback; Snapper integration is
optional and never mandatory.

See `security.md`, `vm-acceptance.md`.