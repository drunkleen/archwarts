# Archwarts 0.1.0 release dry run

Local release-preparation dry run. Nothing was published.

## Archive

- Name: `archwarts-0.1.0.tar.gz`
- Size: 76906 bytes
- SHA256: `6fedc316d076b427da4e3a036b4157bc69fe74a365ffdb999dca298c24ac166c`
- Location: `release/archwarts-0.1.0.tar.gz` (untracked build artifact; see `.gitignore`).

## Contents

149 files: CLI, libraries, packages, stages, desktop, tests (host + VM
acceptance), and `docs/archwarts/`.

## Verification

- Version: `ARCHWARTS_VERSION` = `0.1.0`; `bin/archwarts version` and
  `--version` report `0.1.0`.
- Self-contained: host test suite passes from the release tree.
- Release-candidate audit: RELEASE CANDIDATE READY.
- Pre-VM audit: READY.
- No `.git/` internals, no VM runtime artifacts, no ISO/qcow2/screendumps,
  no `*.log`/`*.out`, no inherited `omarchy-*` commands, no
  `project_structure.xml`, no upstream Omarchy checkout, no developer paths.
- LICENSE, NOTICE, THIRD_PARTY_NOTICES.md, provenance/asset docs included.

## Rebuild

From `release/archwarts-0.1.0/`:

```
cd release/archwarts-0.1.0
tar -czf ../archwarts-0.1.0.tar.gz .
sha256sum ../archwarts-0.1.0.tar.gz
```

The release tree and archive are local-only and intentionally untracked.