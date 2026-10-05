# Archwarts release artifacts

How the first Archwarts release candidate is intended to be distributed.
Nothing here is published yet.

## Decision

First release mechanism: **source archive (tarball) + documented install flow**.
No custom package repository, no AUR package, no bootstrapped binary, and no
blind `curl | sh`.

Rationale:

- The package-source policy (official Arch → AUR when justified → verified
  upstream) is preserved without introducing an Archwarts repository.
- The installer is already the `archwarts` CLI: unprivileged staged install
  plus an explicit, operator-executed privileged plan.
- A PKGBUILD is a later step once the package layout is stable; publishing an
  AUR package is intentionally deferred.

## Tarball contents

The release tarball contains only the Archwarts product (never the inherited
migration input):

```
bin/archwarts
lib/archwarts/
packages/
install/privileged-actions.tsv
install/privileged-files.tsv
stages/
desktop/
ARCHWARTS_VERSION
LICENSE
NOTICE
THIRD_PARTY_NOTICES.md
README.md
docs/archwarts/
```

Excluded: inherited Omarchy `bin/omarchy-*`, `default/`, `config/`, `shell/`
(inherited), `migrations/` (inherited), `manual/`, `test/vm/` runtime
artifacts, and the development work tree.

## Install flow (documented, not auto-executed)

1. Extract the archive to a writable location (e.g. `/opt/archwarts`).
2. As the user: `bin/archwarts install preflight default` (review).
3. As the user: `bin/archwarts install plan default` — generates the explicit
   privileged plan (packages, systemd actions, system files).
4. Operator executes the privileged plan explicitly (e.g. the acceptance
   method: `pacman -S` from the plan, `systemctl enable/mask`, install the
   policy file), requesting elevation only for those steps.
5. As the user: `bin/archwarts install stage base` then
   `bin/archwarts install stage desktop-core`.
6. As the user: `bin/archwarts theme apply default`.
7. Install a display-manager wayland-session entry for `archwarts-session`
   (the per-user path used in acceptance is not portable; a deployable session
   entry is a documented limitation for the first release).
8. Reboot; log in; the session starts Hyprland + the Archwarts shell.

## Later options

- `PKGBUILD` for the `archwarts` source under the official/AUR policy when the
  layout stabilizes.
- A convenience `bin/archwarts install apply` that orchestrates steps 3–5 with
  explicit per-step elevation confirmation (not yet implemented).

## Hygiene

Release tarball generation must run the hygiene checks (no VM artifacts, no
credentials, no dev paths) before assembly. See `docs/archwarts/release-readiness.md`.