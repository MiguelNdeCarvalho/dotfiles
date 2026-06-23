#!/bin/bash

show_status() {
    mux=$(asusctl armoury get gpu_mux_mode 2>/dev/null | grep "current:" | sed 's/.*: //')
    dgpu=$(asusctl armoury get dgpu_disable 2>/dev/null | grep "current:" | sed 's/.*: //')

    # gpu_mux_mode: 0 = dGPU, 1 = iGPU
    if echo "$mux" | grep -q "(0)"; then
        mux_current="dGPU"
        mux_other="iGPU"
    else
        mux_current="iGPU"
        mux_other="dGPU"
    fi

    # dgpu_disable: 0 = enabled, 1 = disabled
    if echo "$dgpu" | grep -q "(1)"; then
        dgpu_current="off"
        dgpu_other="on"
    else
        dgpu_current="on"
        dgpu_other="off"
    fi

    gum style \
        --border rounded \
        --margin "1 0" \
        --padding "0 2" \
        --border-foreground 212 \
        --align left \
        "Currently using the $(gum style --foreground 212 --bold "$mux_current") through the MUX" \
        "The dGPU is $(gum style --foreground 220 --bold "$dgpu_current")"
}

switch_to() {
    local mode="$1"
    local mux_val="$2"
    local dgpu_val="$3"
    local mode_label="$4"

    if ! gum confirm "Switch to $mode_label mode? (reboot required)"; then
        gum style --foreground 240 "Cancelled."
        return
    fi

    gum spin --spinner dot --title "Setting gpu_mux_mode to $mux_val..." -- \
        asusctl armoury set gpu_mux_mode "$mux_val"

    gum spin --spinner dot --title "Setting dgpu_disable to $dgpu_val..." -- \
        asusctl armoury set dgpu_disable "$dgpu_val"

    gum style \
        --border rounded \
        --margin "1 0" \
        --padding "0 2" \
        --border-foreground 82 \
        "✔  Switched to $mode_label mode" \
        "" \
        "Run $(gum style --foreground 220 'sudo reboot') to apply."
}

main() {
    gum style \
        --border double \
        --margin "0 0" \
        --padding "0 2" \
        --border-foreground 99 \
        "🖥  GPU Mode Switcher"

    show_status
    echo

    choice=$(gum choose \
        --header "Select mode:" \
        --cursor "▸ " \
        "📱  Mobile (iGPU only, dGPU off — best battery)" \
        "🖥  Docked (dGPU via MUX — for external monitor)")

    case "$choice" in
        *"Mobile"*) switch_to "mobile" 1 1 "Mobile (iGPU)" ;;
        *"Docked"*) switch_to "dock"   0 0 "Docked (dGPU)" ;;
        "") gum style --foreground 240 "Cancelled." ;;
    esac
}

main
