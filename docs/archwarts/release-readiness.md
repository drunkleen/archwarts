# Archwarts release readiness

Classification of the release-candidate audit findings and overall result.

## Overall result

**RELEASE CANDIDATE READY** (with deferred items).

This is a first-release candidate, not production-ready software.

---

## Finding classifications

### RELEASE BLOCKER

None.

### SHOULD FIX BEFORE RELEASE

- **Portable display-manager session entry.** The acceptance environment uses a
  per-user `archwarts-session` launcher path in the wayland-session entry. A
  deployable, multi-user session entry is required before general installation
  is ergonomic. Documented in `docs/archwarts/release-artifacts.md`.
- **Convenience install executor.** The privileged plan is executed manually by
  the operator; a single `install apply` command with explicit per-step
  elevation would reduce operator error. Not yet implemented.

### ACCEPTABLE DEFERRED

- Omarchy plugin compatibility layer (post-v1, optional).
- Apple T2 and vendor-specific unsigned sources (unsupported until a signed
  source model exists).
- Optional AUR packages and optional desktop applications.
- PKGBUILD/AUR package for Archwarts.
- Interactive desktop items and real-hardware panels (audio/BlueZ/NetworkManager
  radios, MPRIS playback, lock interaction, launcher/menu/notification clicks)
  require a human-driven graphical pass.
- Interactive SDDM login pass (acceptance used autologin).

### INFORMATIONAL

- The development source tree still contains the inherited Omarchy migration
  input; it is excluded from the release artifact.
- `archwarts update` does not provide transactional rollback; Snapper
  integration is optional and never mandatory.

---

## VALIDATED

- 21 host test suites (packages, paths, ownership, stages, install, shell,
  capture, defaults, update + failure recovery, hardware, doctor, uninstall,
  runtime independence, pre-VM audit, release audit).
- Static pre-VM audit: READY.
- Static release-candidate audit: RELEASE CANDIDATE READY.
- Clean-Arch QEMU/KVM acceptance: PASS WITH DEFERRED ITEMS
  (`docs/archwarts/vm-acceptance.md`) — installer idempotency, SDDM → Hyprland
  → Quickshell session, bar/workspaces/binds/IPC/capture/theme, application
  launch, real `pacman -Syu` update + migrations + AUR independence, doctor
  fixtures, conservative uninstall + bootability, negative independence.
- 4 VM-discovered defects fixed in the source tree with regression tests
  (harness timeout/cleanup, `/run/user/$UID` tolerance,
  `power-profiles-daemon` ownership, stale ownership rows).

## KNOWN LIMITATIONS

- Interactive and real-hardware desktop behavior is not exercised headlessly.
- The wayland-session entry is not yet portable (see SHOULD FIX).
- No convenience privileged-plan executor yet.
- Doctor/uninstall/update operate conservatively and intentionally do not
  auto-rollback.

## DEFERRED

See ACCEPTABLE DEFERRED above.

## SECURITY ASSUMPTIONS

Full model in `docs/archwarts/security.md`. Summary:

- Normal operation is unprivileged; elevation is explicit and gated
  (`ARCHWARTS_UPDATE_EXECUTE=1`); no implicit or cached sudo.
- User input is validated at trust boundaries (IPC target/action,
  launch-app id, web-app URL/name); no `eval`; no `curl | sh`.
- The operator trusts pacman and official `[core]`/`[extra]` repositories;
  Archwarts never configures unsigned or external repositories, mirrors, or
  keyrings.
- The AUR phase is optional and independent; core Archwarts does not require
  executing AUR PKGBUILDs.
- `ARCHWARTS_SUDO`/`ARCHWARTS_PACMAN`/`ARCHWARTS_AUR_HELPER` are trusted
  operator-controlled settings.
- The Firefox enterprise policy ships from Archwarts source and does not
  execute user input.

## LICENSING / PROVENANCE

- MIT (`LICENSE`) preserves Omarchy's copyright and claims Archwarts work.
- `NOTICE`, `THIRD_PARTY_NOTICES.md`, `docs/archwarts/provenance.md`, and
  `docs/archwarts/asset-provenance.md` document derivation and attribution.
- Third-party: Omarchy (MIT, behavior source), Catppuccin Mocha palette (MIT),
  Nerd Fonts glyphs (MIT). No bundled binary assets.
- No inherited work is claimed as original authorship.

## DISTRIBUTION PLAN

Source archive (tarball) + documented install flow; no custom repository, no
AUR package yet. See `docs/archwarts/release-artifacts.md`. The tarball
excludes inherited migration input and VM artifacts (verified by the release
audit).

## REMAINING BLOCKERS

None for the first release candidate. The SHOULD FIX items above are
recommended before a public release but do not block the candidate.