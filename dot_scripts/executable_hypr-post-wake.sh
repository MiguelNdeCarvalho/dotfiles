#!/bin/bash
# hypridle after_sleep_cmd
#
# Does all the heavy lifting: restores displays, restarts hyprlock on
# the correct monitor. If we were docked, re-docks so hyprlock shows
# on the G9 (where the user can see it, even with lid closed).

LOG="$HOME/.cache/hypr/sleep.log"
echo "[$(date)] post-wake start" >> "$LOG"

# Restore laptop screen and brightness immediately
hyprctl dispatch "hl.dsp.dpms({ action = 'enable', monitor = 'eDP-1' })"
brightnessctl -r

PRE_SLEEP_STATE=$(cat "$HOME/.cache/hypr/dock-state-pre-sleep" 2>/dev/null)
echo "[$(date)] pre-sleep state: ${PRE_SLEEP_STATE:-undocked}" >> "$LOG"

# Kill any orphaned/crashed hyprlock from before sleep
kill $(pgrep -x hyprlock) 2>/dev/null
sleep 0.5

if [ "$PRE_SLEEP_STATE" = "docked" ]; then
    (
        # Wait for G9 to reconnect via DRM hotplug (up to 20s).
        # Filter out transient 0x0 mode during DP link negotiation.
        DP1=""
        for i in $(seq 1 20); do
            DP1=$(hyprctl monitors -j 2>/dev/null \
                  | jq -r '.[] | select(.name=="DP-1") | select(.width > 0) | .name' \
                  2>/dev/null)
            [ "$DP1" = "DP-1" ] && break
            sleep 1
        done
        echo "[$(date)] post-wake: DP-1 after wait: '${DP1}'" >> "$LOG"

        if [ "$DP1" = "DP-1" ]; then
            sleep 0.3
            # Re-dock: turns off eDP-1, moves workspaces to G9.
            # hyprlock is not running so dock script won't auto-restart it.
            ~/.scripts/hyprland-docking dock
            sleep 0.5
            # Start hyprlock on G9 (the only active monitor after dock)
            hyprctl eval "hl.config({ misc = { allow_session_lock_restore = true } })"
            hyprctl dispatch "hl.dsp.exec_cmd('hyprlock')"
            echo "[$(date)] post-wake: hyprlock started on G9 (DP-1)" >> "$LOG"
        else
            # G9 didn't reconnect — fall back to eDP-1
            hyprctl eval "hl.config({ misc = { allow_session_lock_restore = true } })"
            hyprctl dispatch "hl.dsp.exec_cmd('hyprlock')"
            echo "[$(date)] post-wake: G9 timeout, hyprlock on eDP-1 (fallback)" >> "$LOG"
        fi
    ) &
else
    # Undocked: just restart hyprlock on eDP-1
    hyprctl eval "hl.config({ misc = { allow_session_lock_restore = true } })"
    hyprctl dispatch "hl.dsp.exec_cmd('hyprlock')"
    echo "[$(date)] post-wake: hyprlock started on eDP-1 (undocked)" >> "$LOG"
fi

echo "[$(date)] post-wake done" >> "$LOG"
