# Archwarts-owned Hyprland configuration (staged by `archwarts install stage desktop-core`)
#
# This file is rendered from a template and references only Archwarts-owned
# paths. No inherited runtime paths, commands, or repositories are used.
#
# User overrides: append `source = ~/.config/hypr/custom.conf` (the file does
# not need to exist) or edit this file; Archwarts will not overwrite an
# unmanaged modified copy.

monitor = ,preferred,auto,1

# Session environment for the approved defaults
env = MOZ_ENABLE_WAYLAND,1
env = BROWSER,firefox
env = QT_QPA_PLATFORM,wayland

# Session essentials.
exec-once = foot
exec-once = sh -c 'if [ -f @ARCHWARTS_CONFIG_HOME@/shell/shell.qml ]; then QS_DISABLE_FILE_WATCHER=1 QS_NO_RELOAD_POPUP=1 quickshell -n -p @ARCHWARTS_CONFIG_HOME@/shell; fi'
exec-once = udiskie --automount --no-notify --no-tray
exec-once = systemctl --user import-environment
exec-once = dbus-update-activation-environment --systemd --all

# Core window management
bind = SUPER, Return, exec, foot
bind = SUPER, Q, killactive
bind = SUPER, Space, togglefloating
bind = SUPER, W, closewindow
bind = SUPER, F, fullscreen
bind = SUPER, Escape, exit
bind = SUPER, L, exec, hyprlock

# Workspace switching and movement
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5
bind = SUPER, 6, workspace, 6
bind = SUPER, 7, workspace, 7
bind = SUPER, 8, workspace, 8
bind = SUPER, 9, workspace, 9
bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4
bind = SUPER SHIFT, 5, movetoworkspace, 5
bind = SUPER, mouse_down, workspace, e+1
bind = SUPER, mouse_up, workspace, e-1

# Approved default applications
bind = SUPER, B, exec, archwarts launch-app firefox
bind = SUPER, E, exec, archwarts launch-app dolphin
bind = SUPER, P, exec, archwarts launch-app bitwarden
bind = SUPER, T, exec, foot

# Shell integration
bind = SUPER, R, exec, archwarts shell ipc launcher toggle
bind = SUPER, A, exec, archwarts shell ipc menu toggle
bind = SUPER, V, exec, archwarts shell ipc clipboard toggle
bind = SUPER, N, exec, archwarts shell ipc notifications toggle
bind = SUPER, M, exec, archwarts shell ipc audio toggle
bind = SUPER, I, exec, archwarts shell ipc network toggle
bind = SUPER, O, exec, archwarts shell ipc media toggle

# Screenshots
bind = , PRINT, exec, archwarts capture fullscreen
bind = SHIFT, PRINT, exec, archwarts capture window
bind = SUPER SHIFT, S, exec, archwarts capture region

# Media keys
bindl = , XF86AudioRaiseVolume, exec, pamixer -i 5
bindl = , XF86AudioLowerVolume, exec, pamixer -d 5
bindl = , XF86AudioMute, exec, pamixer -t
bindl = , XF86AudioPlay, exec, playerctl play-pause
bindl = , XF86AudioNext, exec, playerctl next
bindl = , XF86AudioPrev, exec, playerctl previous

# Window rules
windowrulev2 = float, class:^(yad)$
windowrulev2 = float, title:^(Firefox.*Picture-in-Picture)$
windowrulev2 = size 420 260, title:^(Firefox.*Picture-in-Picture)$
windowrulev2 = opacity 0.95 override, class:^(foot)$

# User override file (optional)
source = ~/.config/hypr/custom.conf