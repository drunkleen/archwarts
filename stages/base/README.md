# base stage
#
# Creates the Archwarts-owned XDG runtime tree and records stage ownership in
# ARCHWARTS_STATE_HOME/install. This stage is unprivileged, idempotent, and
# only touches Archwarts-owned directories.