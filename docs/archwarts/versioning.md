# Archwarts versioning

Archwarts follows Semantic Versioning 2.0.0 for tagged releases.

## Canonical version source

The single source of truth is `ARCHWARTS_VERSION` at the repository root.
`archwarts version`, `archwarts --version`, `archwarts -V`, and
`archwarts doctor` all read this file. The version is not duplicated across
the tree.

## Rules

- `MAJOR.MINOR.PATCH` for released versions (e.g. `0.1.0`).
- Pre-release identifiers for development states (e.g. `0.1.1-dev`) are
  written to `ARCHWARTS_VERSION` only when developing toward the next release.
- `archwarts --version` must report the exact `ARCHWARTS_VERSION` content.
- Release archives are named `archwarts-<version>.tar.gz` and built only from
  the release tree (see `release-artifacts.md`).

## Current

Version: `0.1.0` (first release candidate).