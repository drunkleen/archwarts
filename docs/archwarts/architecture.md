# Archwarts architecture

Archwarts is an independent, user-space-first Arch Linux and Hyprland desktop
bootstrap. Omarchy remains a behavioral reference while subsystems are migrated
individually; inherited files are not authoritative Archwarts interfaces.

## Runtime ownership

Archwarts-owned user files use the XDG base directories:

- configuration: `${XDG_CONFIG_HOME:-~/.config}/archwarts`
- runtime data: `${XDG_DATA_HOME:-~/.local/share}/archwarts`
- persistent state: `${XDG_STATE_HOME:-~/.local/state}/archwarts`
- disposable cache: `${XDG_CACHE_HOME:-~/.cache}/archwarts`
- transient state: `${XDG_RUNTIME_DIR:-/run/user/$UID}/archwarts`
- user commands: `~/.local/bin`

Relative `XDG_*` values are invalid under the XDG Base Directory
specification and fall back to paths below `$HOME`.

`ARCHWARTS_PATH` identifies the installed runtime data root. It defaults to
`ARCHWARTS_DATA_HOME`. `ARCHWARTS_SOURCE_ROOT` identifies the source tree from
which a command is executing and is not persisted as session configuration.

## Source layout during migration

- `bin/archwarts` is the new public command entry point.
- `lib/archwarts/` contains shared code with multiple real callers or an
  independently testable responsibility.
- `packages/` defines intended Archwarts package groups without changing the
  host.
- `test/archwarts/` validates new interfaces independently of inherited tests.
- Inherited Omarchy directories remain temporarily as migration inputs.

New code must not source an inherited `omarchy-*` command merely to avoid
implementing an Archwarts responsibility. Each subsystem is adopted only after
its dependencies, paths, privileges, and tests are understood.

## Privilege boundary

The normal runtime is unprivileged. The installer is staged: unprivileged
stages write only Archwarts-owned files under the XDG runtime tree and
`~/.local/bin`, record an ownership manifest in
`ARCHWARTS_STATE_HOME/install`, and never overwrite unmanaged user content.
The privileged plan is generated explicitly and is not executed by any
unprivileged command. Future installer and update commands will request
elevation only around package transactions and required machine-wide
configuration. User hooks, plugins, AUR builds, theme operations, shell logic,
and user migrations must not execute with a cached sudo authorization.

## Installer stages

- `base` (unprivileged): creates the Archwarts-owned XDG runtime tree and
  records stage ownership.
- `desktop-core` (unprivileged): stages the independent Archwarts desktop core
  — the Hyprland configuration, the Quickshell shell (`desktop/shell`), the
  session launcher, the default theme palette, and a self-contained runtime
  copy of the management CLI — rendered/copied from templates and source that
  reference only Archwarts-owned paths.
- privileged plan (not executed): `archwarts install plan` writes an explicit,
  timestamped transaction plan (`phase`, `kind`, `name`, `source`, `state`)
  under the install state directory for a later explicit privileged execution
  path. The plan includes both the package transaction (from the profile
  manifests and `packages/sources.tsv`) and the machine-wide service actions
  declared in `install/privileged-actions.tsv` (`enable`/`mask`). Unit state is
  queried read-only with `systemctl is-enabled`/`is-masked`.

## Desktop core

The staged desktop shell (`$ARCHWARTS_CONFIG_HOME/shell`) is an independent
Quickshell implementation: bar, launcher, menu, notifications, clipboard,
audio/network/bluetooth/media panels, OSD, lock (hyprlock), and palette-driven
theme. The shell communicates with session keybindings through an IPC trigger
directory under `$ARCHWARTS_RUNTIME_HOME/ipc` written by
`archwarts shell ipc`. Session commands resolve through the self-contained
runtime copy of the CLI on `~/.local/bin` and `$ARCHWARTS_DATA_HOME/runtime/bin`.

Shell behavior that touches the compositor, DBus, Pipewire, BlueZ,
NetworkManager, or a live Wayland session is validated in the clean Arch VM;
the development host exercises headless config loading, pure-logic tests, and
fixture-based script tests only.
