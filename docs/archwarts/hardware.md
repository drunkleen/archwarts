# Archwarts hardware profiles

## Model

Detection is separate from planning.

- `archwarts hardware detect` describes the machine (read-only): GPU vendor,
  vendor/DMI, laptop chassis, audio, Bluetooth, network, Wi-Fi vendor,
  battery, Apple T2.
- `archwarts hardware plan` decides actions from a detection (never executes):
  NVIDIA → official `nvidia-open-dkms` (verified current official package);
  AMD/Intel → standard mesa/VA-API note; laptop → `power-profiles-daemon`;
  Apple T2 → unsupported/deferred; the kernel is never replaced.
- `archwarts hardware status` prints detection + plan.

## Testability

PCI/DMI/sysfs inputs are env-overridable (`ARCHWARTS_LSPCI`, `ARCHWARTS_LSUSB`,
`ARCHWARTS_DMI_ROOT`, `ARCHWARTS_SYS_ROOT`) so detection is tested with
fixtures representing different machines.

## Safety

Unknown hardware is safe (no automatic selection). No unsigned or external
repository is configured. Apple T2 and vendor-specific unsigned sources remain
unsupported/deferred until a defensible signed source model exists.

See `security.md`.