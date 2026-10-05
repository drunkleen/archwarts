# Archwarts updater

## Model

`archwarts update` is independent (no inherited updater, repository, mirror,
keyring, or channel).

- Locking: a flock on `$XDG_STATE_HOME/archwarts/update/lock`.
- Durable log: `$XDG_STATE_HOME/archwarts/update/log`.
- Preflight: network reachability, pacman database lock, disk space, Arch News
  (via `informant` when installed), pacman availability.
- Official phase: exactly one `pacman -Syu`, executed only with
  `ARCHWARTS_UPDATE_EXECUTE=1`; result recorded independently.
- AUR phase: optional (`ARCHWARTS_AUR_HELPER`); result recorded independently;
  a failure never marks a successful official upgrade as failed.
- Migrations: ordered, unprivileged scripts under `desktop/migrations/`, each
  recorded when applied; re-runs are idempotent.
- Reporting: revision, orphans, foreign packages, `.pacnew`/`.pacsave`,
  reboot requirement, failed services, log location.

## Privilege and inhibition

Privileged phases run through `ARCHWARTS_SUDO` (default `sudo`) only when
`ARCHWARTS_UPDATE_EXECUTE=1`. Sleep inhibition via `systemd-inhibit` is used
during the official upgrade unless `ARCHWARTS_UPDATE_INHIBIT=0`.

## Failure behavior

Preflight failure aborts before any upgrade. A failed upgrade records
`official failed` and returns non-zero. A failed migration is reported and not
recorded as applied. The log preserves recovery information. There is no
transactional rollback.

See `security.md`, `architecture.md`.