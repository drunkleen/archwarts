# Third-party notices

Archwarts is distributed under the MIT License (see `LICENSE`). The following
third-party material is used, referenced, or included and retains its own
licensing and attribution.

## Omarchy

- Project: Omarchy (https://github.com/omacom/omarchy)
- Copyright: (c) David Heinemeier Hansson
- License: MIT
- Relation: Archwarts is an independent, behaviorally informed reimplementation
  of useful Omarchy functionality. The MIT copyright and permission notice are
  preserved in `LICENSE`. Attribution and derivation are documented in
  `docs/archwarts/provenance.md`. No inherited Omarchy runtime,
  repository, mirror, keyring, channel, or command is required by Archwarts.

## Catppuccin

- Project: Catppuccin (https://github.com/catppuccin/palette)
- License: MIT
- Relation: the default Archwarts theme palette
  (`desktop/themes/default/palette.conf`) uses colors from the Catppuccin
  Mocha palette.

## Nerd Fonts

- Project: Nerd Fonts (https://github.com/ryanoasis/nerd-fonts)
- License: MIT
- Relation: the Archwarts desktop shell renders status glyphs using Nerd Font
  codepoints. The font itself is installed through the official Arch package
  `ttf-jetbrains-mono-nerd`; Archwarts ships no font files.

## Other assets

The Archwarts release ships no bundled icons, wallpapers, logos, sounds, or
font binaries. Text glyphs are Unicode codepoints rendered by the installed
system font. Any future bundled asset must be recorded in
`docs/archwarts/asset-provenance.md` before release.