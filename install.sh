#!/bin/bash
#
# Claude Recovery Mode Installer
#
# Installs the Claude Recovery Mode boot option for Ubuntu/Debian systems
# with systemd and GRUB2.
#
# Usage: sudo ./install.sh [--user <username>]
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default values
INSTALL_USER=""
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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

# Show usage
usage() {
    cat << EOF
Claude Recovery Mode Installer

Usage: sudo $0 [OPTIONS]

Options:
    --user <username>   User to auto-login in recovery mode (default: current user)
    --root              Use root as the auto-login user
    -h, --help          Show this help message

Examples:
    sudo $0                     # Install with current user
    sudo $0 --user daniel       # Install with specific user
    sudo $0 --root              # Install with root user

EOF
    exit 0
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user)
                if [[ -z "$2" || "$2" == --* ]]; then
                    error "Option --user requires a username"
                fi
                INSTALL_USER="$2"
                shift 2
                ;;
            --root)
                INSTALL_USER="root"
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                error "Unknown option: $1\nUse --help for usage information."
                ;;
        esac
    done
}

# Check prerequisites
check_prerequisites() {
    info "Checking prerequisites..."

    # Check for root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
    fi

    # Check for systemd
    if ! command -v systemctl &>/dev/null; then
        error "systemd is required but not found"
    fi

    # Check for GRUB
    if [[ ! -d /etc/grub.d ]]; then
        error "GRUB configuration directory not found (/etc/grub.d)"
    fi

    if ! command -v update-grub &>/dev/null && ! command -v grub-mkconfig &>/dev/null; then
        error "update-grub or grub-mkconfig not found"
    fi

    # Check for required files
    local required_files=(
        "${SCRIPT_DIR}/scripts/claude-recovery-launcher.sh"
        "${SCRIPT_DIR}/systemd/claude-recovery.target"
        "${SCRIPT_DIR}/systemd/claude-recovery-getty@.service"
        "${SCRIPT_DIR}/grub/45_claude-recovery"
    )

    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            error "Required file not found: $file"
        fi
    done

    success "Prerequisites check passed"
}

# Determine the user for auto-login
determine_user() {
    if [[ -z "$INSTALL_USER" ]]; then
        # Try to get the user who invoked sudo
        if [[ -n "$SUDO_USER" && "$SUDO_USER" != "root" ]]; then
            INSTALL_USER="$SUDO_USER"
        else
            error "Could not determine user. Please specify with --user <username>"
        fi
    fi

    # Validate user exists (unless root)
    if [[ "$INSTALL_USER" != "root" ]]; then
        if ! id "$INSTALL_USER" &>/dev/null; then
            error "User '$INSTALL_USER' does not exist"
        fi
    fi

    info "Recovery mode will auto-login as: ${CYAN}${INSTALL_USER}${NC}"
}

# Install the launcher script
install_launcher() {
    info "Installing launcher script..."

    cp "${SCRIPT_DIR}/scripts/claude-recovery-launcher.sh" /usr/local/bin/claude-recovery-launcher
    chmod 755 /usr/local/bin/claude-recovery-launcher

    success "Launcher installed to /usr/local/bin/claude-recovery-launcher"
}

# Install recovery agents and commands
install_recovery_config() {
    info "Installing recovery agents and commands..."

    local dest="/usr/local/share/claude-recovery"

    # Create destination directories
    mkdir -p "$dest/agents"
    mkdir -p "$dest/commands"

    # Copy agents
    if [[ -d "${SCRIPT_DIR}/claude-config/agents" ]]; then
        cp -f "${SCRIPT_DIR}/claude-config/agents"/*.md "$dest/agents/" 2>/dev/null || true
        local agent_count=$(ls -1 "$dest/agents"/*.md 2>/dev/null | wc -l)
        success "Installed $agent_count recovery agents"
    fi

    # Copy commands
    if [[ -d "${SCRIPT_DIR}/claude-config/commands" ]]; then
        cp -f "${SCRIPT_DIR}/claude-config/commands"/*.md "$dest/commands/" 2>/dev/null || true
        local command_count=$(ls -1 "$dest/commands"/*.md 2>/dev/null | wc -l)
        success "Installed $command_count recovery commands"
    fi

    # Install update script
    cp "${SCRIPT_DIR}/update.sh" /usr/local/bin/update-claude-recovery 2>/dev/null || true
    chmod 755 /usr/local/bin/update-claude-recovery 2>/dev/null || true
}

# Install systemd units
install_systemd() {
    info "Installing systemd units..."

    # Install target
    cp "${SCRIPT_DIR}/systemd/claude-recovery.target" /etc/systemd/system/claude-recovery.target

    # Install getty service with user substitution
    sed "s/__CLAUDE_RECOVERY_USER__/${INSTALL_USER}/g" \
        "${SCRIPT_DIR}/systemd/claude-recovery-getty@.service" \
        > /etc/systemd/system/claude-recovery-getty@.service

    # Reload systemd
    systemctl daemon-reload

    success "Systemd units installed"
}

# Install GRUB entry
install_grub() {
    info "Installing GRUB entry..."

    cp "${SCRIPT_DIR}/grub/45_claude-recovery" /etc/grub.d/45_claude-recovery
    chmod 755 /etc/grub.d/45_claude-recovery

    info "Updating GRUB configuration..."
    if command -v update-grub &>/dev/null; then
        update-grub
    else
        grub-mkconfig -o /boot/grub/grub.cfg
    fi

    success "GRUB entry installed"
}

# Create marker file for uninstall
create_marker() {
    cat > /etc/claude-recovery-mode.conf << EOF
# Claude Recovery Mode Configuration
# Created: $(date)
INSTALL_USER=${INSTALL_USER}
INSTALL_VERSION=1.0.0
EOF
}

# Main installation
main() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          Claude Recovery Mode - Installer                    ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    parse_args "$@"
    check_prerequisites
    determine_user
    install_launcher
    install_recovery_config
    install_systemd
    install_grub
    create_marker

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          Installation Complete!                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Claude Recovery Mode has been installed successfully."
    echo ""
    echo "To use it:"
    echo "  1. Reboot your system"
    echo "  2. At the GRUB menu, select 'Claude Recovery Mode'"
    echo "  3. The system will boot to a TTY with Claude CLI"
    echo ""
    echo "Available recovery commands: /status /errors /failed /network-check /boot-log /fix-packages"
    echo "Available recovery agents:   @diagnose @logs @network @disk @services @packages"
    echo ""
    echo "To update recovery tools:  sudo update-claude-recovery"
    echo "To uninstall:              sudo ./uninstall.sh"
    echo ""
}

main "$@"
