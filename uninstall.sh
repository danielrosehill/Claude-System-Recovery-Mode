#!/bin/bash
#
# Claude Recovery Mode Uninstaller
#
# Removes all Claude Recovery Mode components from the system.
#
# Usage: sudo ./uninstall.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Print colored message
info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check for root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
    fi
}

# Remove systemd units
remove_systemd() {
    info "Removing systemd units..."

    # Stop any running services (ignore errors)
    systemctl stop claude-recovery-getty@tty1.service 2>/dev/null || true

    # Remove files
    rm -f /etc/systemd/system/claude-recovery.target
    rm -f /etc/systemd/system/claude-recovery-getty@.service

    # Reload systemd
    systemctl daemon-reload

    success "Systemd units removed"
}

# Remove GRUB entry
remove_grub() {
    info "Removing GRUB entry..."

    rm -f /etc/grub.d/45_claude-recovery

    info "Updating GRUB configuration..."
    if command -v update-grub &>/dev/null; then
        update-grub
    else
        grub-mkconfig -o /boot/grub/grub.cfg
    fi

    success "GRUB entry removed"
}

# Remove launcher script
remove_launcher() {
    info "Removing launcher script..."

    rm -f /usr/local/bin/claude-recovery-launcher

    success "Launcher removed"
}

# Remove recovery agents and commands
remove_recovery_config() {
    info "Removing recovery agents and commands..."

    rm -rf /usr/local/share/claude-recovery
    rm -f /usr/local/bin/update-claude-recovery

    success "Recovery config removed"
}

# Remove configuration marker
remove_config() {
    rm -f /etc/claude-recovery-mode.conf
}

# Main uninstallation
main() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          Claude Recovery Mode - Uninstaller                  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    check_root

    # Confirm uninstallation
    echo "This will remove Claude Recovery Mode from your system."
    echo ""
    read -p "Are you sure you want to continue? [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstallation cancelled."
        exit 0
    fi

    echo ""

    remove_systemd
    remove_grub
    remove_launcher
    remove_recovery_config
    remove_config

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          Uninstallation Complete!                            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Claude Recovery Mode has been removed from your system."
    echo "The GRUB menu entry will be gone on next reboot."
    echo ""
}

main "$@"
