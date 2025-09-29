#!/bin/bash

# ================================
#   Arch Post-Installation Script
# ================================

set -e  # Exit on error

PKG_REMOVE_LIST=(
    cheese
    epiphany
    gnome-contacts
    gnome-maps
    gnome-music
    gnome-software
    gnome-tour
    gnome-weather
    showtime
    vlc
    totem
    vim
)

run_with_spinner() {
    local msg_running
    local msg_done
    local use_dual_msg=false

    if [ $# -ge 3 ]; then
        msg_running="$1"
        msg_done="$2"
        shift 2
        use_dual_msg=true
    else
        msg_running="$1"
        msg_done="$1"
        shift 1
    fi

    local cmd=("$@")

    local delay=0.1
    local spinstr='⠀⠀⠀⠉⠉⠉⠛⠛⠛⠿⠿⣿⣿⣿⣿'

    mapfile -t spinarr < <(echo -n "$spinstr" | grep -o .)

    "${cmd[@]}" &> /dev/null &
    local pid=$!

    local i=0
    while kill -0 $pid 2>/dev/null; do
        local c=${spinarr[i++ % ${#spinarr[@]}]}
        printf "\r\e[1;34m  %s\e[0m %s" "$c" "$msg_running"
        sleep "$delay"
    done

    wait $pid
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        printf "\r\e[1;32m  ✔\e[0m %s\n" "$msg_done"
    else
        printf "\r\e[1;31m  ✖\e[0m %s\n" "$msg_running"
    fi

    return $exit_code
}

# --- Check if running as root ---
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# --- Colored logs ---
log() {
    echo -e "\e[1;32m[INFO] $1\e[0m"
}

error() {
    echo -e "\e[1;31m[ERROR] $1\e[0m"
    exit 1
}

# --- Update system ---
update_system() {
    echo
    log "Updating the system..."
    echo

    run_with_spinner " Updating..." " Updated!" pacman -Syyu --noconfirm || error "Failed to update the system"
}

# --- Cleaning system ---
remove_pkgs() {
    echo
    log "Removing packages..."
    echo

    for pkg in "${PKG_REMOVE_LIST[@]}"; do
        if pacman -Q "$pkg" &> /dev/null; then
            run_with_spinner " $pkg..." " $pkg" pacman -Rns --noconfirm "$pkg"
            sleep 1
        else
            printf "\r\e[1;33m  ✖  %s\e[0m\n" "$pkg"
        fi
    done
}

# --- Editing files ---
edit_pacman_conf() {
    local PACMAN_CONF="/etc/pacman.conf"
    cp "$PACMAN_CONF" "${PACMAN_CONF}.bak" || return 1

    sed -i '/^#Color$/{
        s/^#//
        a\
IloveCandy
    }' "$PACMAN_CONF" || return 1
}

edit_loader_conf() {
    local LOADER_CONF="/boot/loader/loader.conf"
    cp "$LOADER_CONF" "${LOADER_CONF}.bak" || return 1

    sed -i '1d' "$LOADER_CONF" || return 1
}

edit_configs() {
    echo
    log "Editing files..."
    echo

    run_with_spinner " Editing pacman.conf..." " pacman.conf edited!" edit_pacman_conf || error "Failed to edit pacman.conf"

    run_with_spinner " Editing loader.conf..." " loader.conf edited!" edit_loader_conf || error "Failed to edit loader.conf"
}

# --- RUNNING ---
main() {
    update_system
    remove_pkgs
    edit_configs
}

main
