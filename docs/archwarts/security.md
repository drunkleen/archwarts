# Archwarts security model

This document describes the trust boundaries, privilege model, and remaining
trust assumptions of Archwarts.

## Trust boundaries

- **USER INPUT** — command-line arguments, IPC payloads, URLs, and desktop-entry
  ids supplied by the invoking user.
- **ARCHWARTS-MANAGED DATA** — files written under the Archwarts XDG runtime
  tree (`~/.config/archwarts`, `~/.local/state/archwarts`, etc.) and recorded in
  the ownership manifest.
- **DOWNLOADED DATA** — Arch package data handled by pacman, and the optional
  AUR helper phase.
- **ROOT EXECUTION** — any privileged phase (package transactions, systemd
  actions, system file installation). Root execution never occurs from
  unprivileged commands; it is explicit and gated.

## Privilege model

- Normal operation is unprivileged. `install stage`, `doctor`, `update` (plan/
  preflight/report/status), `hardware detect/plan`, `defaults`, `web-app`,
  `shell ipc`, `launch-app`, `capture`, and `theme` never require elevation.
- The update system executes privileged phases only when the operator sets
  `ARCHWARTS_UPDATE_EXECUTE=1`; the development host never sets it. The
  privileged plan is generated explicitly and is never auto-executed.
- No command uses `sudo` implicitly, caches authorization, or installs a
  passwordless sudoers grant.

## Input handling

- `archwarts shell ipc <target> <action>` validates target and action against
  `^[a-zA-Z0-9_.-]+$`, preventing path traversal and injection into the IPC
  filename.
- `archwarts launch-app <id>` validates the desktop-entry id against
  `^[a-zA-Z0-9._-]+$` and passes it as a single argument to `gtk-launch`.
- `archwarts web-app` sanitizes the name and URL: the Exec line is a single
  quoted `firefox --new-window "<url>"` argument; the url must be `http(s)`
  and metacharacters are removed.
- Shell QML launches use `Util.execArgv` (no shell re-tokenization) or
  `Util.shellQuote` for embedded strings. Screenshot mode is shell-quoted.
- Captured clipboard content is treated as data (JSON), never executed.

## Temporary files

- `mktemp` is used for temporary files (clipboard image staging, ownership
  manifest rewrite). Temporary paths are under the user's own runtime/state
  dirs or `/tmp`.
- The ownership manifest rewrite uses a temp file followed by `mv` (atomic).

## AUR phase

- The AUR phase is optional and disabled by default (`ARCHWARTS_AUR_HELPER`
  unset). Core Archwarts does not require, install, or execute AUR PKGBUILDs.
  If the operator configures an AUR helper, it runs with the operator's
  privileges; the official upgrade result is recorded independently and an AUR
  failure never marks a successful official upgrade as failed.

## Remaining trust assumptions

- The operator trusts the Arch package manager and the configured repositories
  (official `[core]`/`[extra]`). Archwarts never configures unsigned or
  external repositories, mirrors, or keyrings.
- Apple T2 and other vendor-specific sources requiring unsigned repositories
  are unsupported/deferred by default and require an explicit, signed source
  decision before they can be adopted.
- `ARCHWARTS_SUDO`/`ARCHWARTS_PACMAN`/`ARCHWARTS_AUR_HELPER` are trusted
  operator-controlled environment settings.
- The Firefox enterprise policy (`/etc/firefox/policies/policies.json`) is
  shipped from Archwarts source and installed by the privileged plan; it does
  not execute user input.
- Root-execution phases must be reviewed before execution; Archwarts does not
  claim transactional rollback. On failure it records diagnostics and leaves
  recovery information in the update log.