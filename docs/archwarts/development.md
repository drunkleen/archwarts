# Archwarts development and testing

## Layout

- `bin/archwarts` — the CLI entry point.
- `lib/archwarts/` — shared libraries (paths, packages, ownership, stages,
  install, shell, capture, apps, theme, defaults, update, hardware, doctor,
  uninstall, audit).
- `packages/` — package groups and source exceptions.
- `stages/` — installer templates.
- `desktop/` — shell, apps, themes, migrations.
- `docs/archwarts/` — project documentation.
- `test/archwarts/` — host test suite (all suites run via `test/archwarts/all`).
- `test/vm/` — disposable clean-Arch acceptance environment (test/vm/README.md).

## Host tests

```
./test/archwarts/all
./bin/archwarts doctor
./bin/archwarts preflight-audit
```

Suites cover packages, paths, ownership, stages, install plan/preflight,
shell IPC/static/JS, capture, defaults, update (+ failure recovery), hardware,
doctor, uninstall, runtime independence, and the pre-VM audit.

## VM acceptance

`test/vm/scripts/acceptance.sh` runs the full sequence. See
`test/vm/README.md` for reproduction.

## Conventions

- Shell: `set -euo pipefail`, no `eval`, no `curl | sh`, input validated at
  trust boundaries (see `security.md`).
- Tests are added alongside functionality; VM-discovered defects require a host
  regression test where practical.
- The pinned upstream Omarchy tree is read-only reference; the original
  checkout is never modified.