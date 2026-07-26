#!/bin/bash
# hypridle on-resume (3 min idle): restore display after idle blanking.

hyprctl dispatch dpms on eDP-1
brightnessctl -r
