#!/bin/bash
# hypridle before_sleep_cmd
#
# MUST complete within logind's InhibitDelayMaxSec (5s default).
# We do as little as possible here: just save state and lock the session.
#
# hyprlock may crash when DP-1 drops during suspend — that is acceptable.
# Hyprland's ext-session-lock crash fallback keeps the session secured.
# hypr-post-wake.sh handles restarting hyprlock on the right display after wake.

LOG="$HOME/.cache/hypr/sleep.log"
mkdir -p "$HOME/.cache/hypr"
echo "[$(date)] pre-sleep start" >> "$LOG"

DOCK_STATE=$(cat "$HOME/.cache/hypr/dock-state" 2>/dev/null)
echo "[$(date)] dock-state: ${DOCK_STATE:-undocked}" >> "$LOG"

# Save state so post-wake knows whether to re-dock
echo "${DOCK_STATE:-undocked}" > "$HOME/.cache/hypr/dock-state-pre-sleep"

# Lock — fast D-Bus call, always completes well within 5s
loginctl lock-session

echo "[$(date)] pre-sleep done" >> "$LOG"
