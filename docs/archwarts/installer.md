# Archwarts installer

## Model

The installer is staged, idempotent, user-run, and user-space-first.

- `base` — creates the Archwarts-owned XDG runtime tree (config, data, state,
  cache). The transient runtime home is optional when `/run/user/$UID` does not
  exist (no graphical session).
- `desktop-core` — stages the Hyprland config, the Quickshell shell, the
  session launcher, the default theme palette, and a self-contained runtime
  copy of the CLI.
- Privileged plan — generated explicitly (`install plan`), never auto-executed:
  packages (by official/AUR source), systemd actions (`enable`/`mask`), and
  system files (Firefox enterprise policy).

## Ownership

Every staged file is recorded in
`$XDG_STATE_HOME/archwarts/install/ownership.tsv` with a SHA-256. Re-staging
is idempotent; an unmanaged or modified file is never overwritten (conflict
refusal); deleting and re-staging a file purges its stale ownership row.

## Privilege boundary

`install stage`, `preflight`, `plan`, `status`, `theme`, `defaults`, `doctor`,
`hardware`, `capture`, `launch-app`, `shell ipc` are unprivileged. The
privileged plan is executed by the operator only. No command requests or caches
elevation implicitly.

See `architecture.md`, `security.md`, `release-artifacts.md`.