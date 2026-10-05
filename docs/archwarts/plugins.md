# Plugin compatibility decision

## Recommendation

Plugin compatibility with the Omarchy plugin API is **deferred to post-v1**.
The first Archwarts release is complete and functional without it.

## Current native Archwarts plugin capability

Archwarts has **no plugin system** in its first release. The desktop shell is a
fixed, cohesive Quickshell implementation (bar, launcher, menu, panels). It
uses Quickshell's native services directly and does not load third-party QML.

## Omarchy plugin API dependencies observed during audit

The audited Omarchy shell's plugin surface is large and intertwined:

- A plugin registry with manifests (`manifest.json`), service/bar-widget/panel
  APIs, first-party service injection, plugin lifecycle and reload handling,
  and clone/importer tooling.
- Plugin APIs that reference the host shell (ShellRoot), bar widget registry,
  IPC targeting by plugin id, and configuration mutation.
- A compatibility surface that assumes `OMARCHY_PATH`, Omarchy IPC ids, and the
  Omarchy config layout.

Reimplementing or importing this safely requires the full host/API surface,
which conflicts with the simplicity rule and the runtime-independence goal.

## Complexity and security implications

- High: a safe importer must validate untrusted QML and JS, isolate plugin
  filesystem/command access, and define a stable first-party service contract.
- Untrusted plugin code executing in the shell process would have the user's
  session privileges; that is a significant trust boundary to design and test.
- Compatibility metadata (legacy plugin ids, config paths) would reintroduce
  Omarchy-identifying surfaces into the core runtime.

## What a safe importer/compatibility layer would require

1. A native Archwarts plugin manifest and a stable first-party service API.
2. A sandboxed/validated plugin loader (no arbitrary command execution by
   default; explicit capabilities).
3. A migration/import path that translates legacy plugin manifests and ids,
   gated as an explicit optional feature.
4. Tests and a VM acceptance pass for third-party plugins.

## Classification

- Core Archwarts: no plugin system required — **deferred**.
- Compatibility layer: **post-v1**, optional, opt-in, and never required for
  the core desktop.