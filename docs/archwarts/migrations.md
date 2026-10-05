# Archwarts migrations

- Migrations live in `desktop/migrations/` and are unprivileged shell scripts,
  ordered by filename.
- The updater applies each not-yet-applied migration once and records it in
  `$XDG_STATE_HOME/archwarts/update/migrations-applied.tsv`.
- Re-running migrations is idempotent: applied migrations are skipped.
- A failed migration is reported and not recorded as applied.
- Inherited Omarchy migrations are never executed.
- Privileged migration work belongs to the privileged update plan, not to a
  migration script.