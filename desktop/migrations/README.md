# Archwarts-owned migrations.
#
# Only migrations in this directory are ever run by the Archwarts updater.
# They are unprivileged and ordered by filename. Inherited migration input is
# never executed. Privileged migration work belongs to the update plan, not to
# a migration script.