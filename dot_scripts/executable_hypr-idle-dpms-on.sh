#!/bin/bash
# hypridle on-resume (3 min idle): restore display after idle blanking.

hyprctl dispatch "hl.dsp.dpms({ action = 'enable', monitor = 'eDP-1' })"
brightnessctl -r
