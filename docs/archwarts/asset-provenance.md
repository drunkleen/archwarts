# Asset provenance manifest

Every non-source asset shipped by an Archwarts release must be recorded here
with its origin and license. An asset whose provenance cannot be established is
a release blocker and must be removed or replaced.

## Current release assets

The current Archwarts release ships no binary assets: no bundled icons,
wallpapers, logos, sounds, or font files. User-visible visuals come from:

- Text glyphs (Unicode codepoints) rendered by the system font, installed via
  the official `ttf-jetbrains-mono-nerd` package (Nerd Fonts, MIT). See
  `THIRD_PARTY_NOTICES.md`.
- Theme colors in `desktop/themes/default/palette.conf` (Catppuccin Mocha,
  MIT). See `THIRD_PARTY_NOTICES.md`.

## Policy

Before adding any asset to a release:

1. Record the upstream source URL and exact version.
2. Verify the license permits redistribution and copy the license notice.
3. Add the asset row below with origin, license, and provenance evidence.

## Assets

| Asset | Origin | License | Provenance evidence |
| --- | --- | --- | --- |
| (none shipped) | — | — | — |