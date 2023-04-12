#!/bin/sh

export WLR_EGL_NO_MODIFIERS=1
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland

exec Hyprland
