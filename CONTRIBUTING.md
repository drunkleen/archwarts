# Contributing to Archwarts

Thanks for considering a contribution. Archwarts is a young project in its
first release candidate; small, well-tested changes are the priority.

## Supported development environment

- Arch Linux x86_64.
- Bash scripts (`set -euo pipefail`), QML/Quickshell, and a little JavaScript
  (node for pure-logic tests).
- Host tools for tests: `bash`, `rg`, `jq`, `node`, `quickshell` (for the
  headless config-load test), `pacman` (for fixture-free queries), `qemu` +
  KVM (for VM acceptance).

## Repository layout

- `bin/archwarts` — CLI entry point.
- `lib/archwarts/` — shared libraries.
- `packages/` — package groups and source exceptions.
- `stages/` — installer templates.
- `desktop/` — shell, applications, themes, migrations.
- `docs/archwarts/` — project documentation.
- `test/archwarts/` — host test suite (`./test/archwarts/all`).
- `test/vm/` — disposable clean-Arch acceptance environment (`test/vm/README.md`).

## Coding principles

- User-space-first: normal operation is unprivileged.
- Privilege boundaries are explicit and gated; never request or cache sudo
  implicitly.
- Package-source policy: official Arch → AUR when justified → verified
  upstream. Never configure unsigned or external repositories.
- Simple implementations; avoid wrapper commands and unnecessary layering.
- No `eval`, no `curl | sh`, and validate user input at trust boundaries
  (see `docs/archwarts/security.md`).
- Add a test alongside new functionality; VM-discovered defects need a host
  regression test where practical.

## Testing

- Host: `./test/archwarts/all`, plus `./bin/archwarts doctor` and
  `./bin/archwarts preflight-audit`.
- VM acceptance: `test/vm/scripts/acceptance.sh` (see `test/vm/README.md`).

## Security expectations

- Report vulnerabilities privately (see `SECURITY.md`), not in public issues.
- Do not weaken an acceptance check to make a test pass.

## Licensing / provenance expectations

- Archwarts is MIT. Preserve the Omarchy attribution in `LICENSE` and the
  notices in `NOTICE` / `THIRD_PARTY_NOTICES.md`.
- Do not copy Omarchy code and rename it; reimplement behavior independently
  or add it to the documented migration surface. Do not claim original
  authorship for inherited work.
- Bundled assets must be recorded in `docs/archwarts/asset-provenance.md`.

## Submitting changes

- Work in a fork/branch; open a pull request against `main`.
- Keep commits focused; describe the behavior change and the tests that cover
  it.
- No pull request should include VM runtime artifacts, archives, or generated
  files (see `.gitignore`).