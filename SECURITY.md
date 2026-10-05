# Security policy for Archwarts

## Supported status

Archwarts is a first release candidate (`0.1.0`). It is not production-ready.
Security fixes are handled on a best-effort basis by the maintainers.

## Reporting a vulnerability

**Do not post sensitive vulnerability details in public issues or discussions
before a fix is available.**

Report vulnerabilities privately to the project maintainers. No private
security email address has been established yet; this is a pre-publication
item that the project owner must configure before general publication. Until a
private channel exists, contact the maintainers through the project's issue
tracker and clearly mark the report as security-related, keeping exploit
details out of the public body.

A useful report should contain:

- The affected version (`archwarts version`).
- A description of the vulnerability and its impact.
- The trust boundary crossed (user input / Archwarts-managed data / downloaded
  data / root execution).
- Steps to reproduce, or a minimal proof of concept.
- Any suggested mitigation.

## Security boundaries

- Normal operation is unprivileged; elevation is explicit and gated.
- No implicit or cached sudo; no passwordless sudoers grants.
- User input is validated at trust boundaries; no `eval`; no `curl | sh`.
- Archwarts never configures unsigned or external repositories, mirrors, or
  keyrings.
- The AUR phase is optional and independent; core Archwarts does not require
  executing AUR PKGBUILDs.
- The ownership manifest and uninstall are conservative: modified managed
  files are never removed.

See `docs/archwarts/security.md` for the full model.

## Out of scope

- Vulnerabilities in Arch Linux packages or third-party desktop components;
  report those upstream.