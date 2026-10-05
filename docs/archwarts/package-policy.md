# Package policy

Archwarts resolves packages in this order:

1. Official Arch repositories.
2. AUR when no suitable official package exists.
3. An official upstream method when neither Arch source is appropriate.

It does not use an Archwarts binary repository and must not configure Omarchy
repositories, mirrors, or keys.

Package purpose is represented by `packages/core.packages`,
`packages/default.packages`, and `packages/optional.packages`. Explicit source
exceptions are represented by `packages/sources.tsv`; absence from that file
means the package is expected from official Arch repositories.

`packages/remove.packages` is a migration/audit list. It does not authorize an
uninstaller to remove a package automatically, because a package may predate
Archwarts or be required by unrelated software.

The research workspace contains a generated `package-source-status.tsv`.
Results labeled `official-repository-name` came from configured pacman sync
database metadata and prove the repository namespace, not the mirror operator.
Results labeled `official-api` came from `archlinux.org`; `aur` results came
from aurweb RPC v5. Package availability must be refreshed before release.
