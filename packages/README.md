# Package groups

These manifests describe intended Archwarts installation groups. They are data
only: Phase 1 does not install packages or modify pacman configuration.

- `core.packages`: required for the supported desktop and runtime.
- `default.packages`: useful applications and integrations installed by the
  normal profile.
- `optional.packages`: supported choices that are not installed by default.
- `remove.packages`: inherited defaults that must not be installed by
  Archwarts.
- `sources.tsv`: explicit exceptions to the official-repository default.

Before a package is consumed by the installer it must have a recorded purpose
and source in the package ledger. Official Arch repositories take priority,
then AUR, then an official upstream installation method. These lists must not
be used to configure a custom binary repository.

Packages absent from `sources.tsv` are expected to resolve from official Arch
repositories. An AUR or upstream package must be explicitly listed with its
reason before installer code may consume it.
