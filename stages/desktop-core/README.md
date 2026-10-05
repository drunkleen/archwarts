# desktop-core stage
#
# Stages the independent Archwarts desktop core under ARCHWARTS_CONFIG_HOME and
# ARCHWARTS_DATA_HOME:
#
# - the Hyprland configuration (rendered from a template, Archwarts-owned);
# - the Archwarts Quickshell shell (desktop/shell) under config home/shell;
# - the session launcher (data home/bin and ~/.local/bin);
# - a self-contained runtime copy of the management CLI and its data under
#   data home/runtime, with no dependency on the source tree;
# - the default theme palette.
#
# Requires the base stage. Unprivileged and idempotent. Never overwrites an
# unmanaged user file.