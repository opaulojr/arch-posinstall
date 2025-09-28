#!/bin/bash

# ================================
#   Arch Post-Installation Script
# ================================

set -e  # Exit on error

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
log "Updating the system..."
pacman -Syu --noconfirm || error "Failed to update the system"

# --- ... ---

