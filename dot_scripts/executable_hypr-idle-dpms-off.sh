#!/bin/bash
# hypridle on-timeout (3 min idle): blank displays for OLED protection.
#
# IMPORTANT: We never DPMS DP-1 while hyprlock is running on it.
# The G9 OLED physically drops the DP link on DPMS, which destroys
# hyprlock's Wayland surface → crash (hyprwm/hyprlock#991, unfixed in 0.9.5).
#
# When DOCKED:  G9 stays on with hyprlock until suspend (max 27 more min).
#               eDP-1 is already DPMS-off from the docking script — no-op.
# When UNDOCKED: eDP-1 blanks safely (internal eDP never physically disconnects).

hyprctl dispatch dpms off eDP-1
