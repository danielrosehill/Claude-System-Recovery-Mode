#!/bin/bash
#
# Claude Recovery Mode Updater
#
# Updates the recovery agents and commands from the GitHub repository.
#
# Usage: sudo update-claude-recovery
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Repository URL
REPO_URL="https://github.com/danielrosehill/Claude-System-Recovery-Mode"
RAW_BASE="https://raw.githubusercontent.com/danielrosehill/Claude-System-Recovery-Mode/main"

# Installation directory
INSTALL_DIR="/usr/local/share/claude-recovery"

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

# Check for curl or wget
check_download_tool() {
    if command -v curl &>/dev/null; then
        DOWNLOAD_CMD="curl -fsSL"
    elif command -v wget &>/dev/null; then
        DOWNLOAD_CMD="wget -qO-"
    else
        error "Neither curl nor wget found. Please install one of them."
    fi
}

# Download a file
download_file() {
    local url="$1"
    local dest="$2"

    if [[ "$DOWNLOAD_CMD" == "curl -fsSL" ]]; then
        curl -fsSL "$url" -o "$dest" 2>/dev/null
    else
        wget -qO "$dest" "$url" 2>/dev/null
    fi
}

# Update agents
update_agents() {
    info "Updating recovery agents..."

    local agents=("diagnose" "logs" "network" "disk" "services" "packages")
    local updated=0

    mkdir -p "$INSTALL_DIR/agents"

    for agent in "${agents[@]}"; do
        local url="${RAW_BASE}/claude-config/agents/${agent}.md"
        local dest="$INSTALL_DIR/agents/${agent}.md"

        if download_file "$url" "$dest"; then
            ((updated++))
        else
            warn "Failed to download agent: $agent"
        fi
    done

    success "Updated $updated agents"
}

# Update commands
update_commands() {
    info "Updating recovery commands..."

    local commands=("status" "errors" "failed" "network-check" "boot-log" "fix-packages")
    local updated=0

    mkdir -p "$INSTALL_DIR/commands"

    for cmd in "${commands[@]}"; do
        local url="${RAW_BASE}/claude-config/commands/${cmd}.md"
        local dest="$INSTALL_DIR/commands/${cmd}.md"

        if download_file "$url" "$dest"; then
            ((updated++))
        else
            warn "Failed to download command: $cmd"
        fi
    done

    success "Updated $updated commands"
}

# Update the launcher script
update_launcher() {
    info "Updating launcher script..."

    local url="${RAW_BASE}/scripts/claude-recovery-launcher.sh"
    local dest="/usr/local/bin/claude-recovery-launcher"

    if download_file "$url" "$dest"; then
        chmod 755 "$dest"
        success "Updated launcher script"
    else
        warn "Failed to update launcher script"
    fi
}

# Main update function
main() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          Claude Recovery Mode - Updater                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    check_root
    check_download_tool

    info "Fetching updates from: $REPO_URL"
    echo ""

    update_agents
    update_commands
    update_launcher

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          Update Complete!                                    ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Recovery agents and commands have been updated."
    echo "Changes will take effect on next boot into Claude Recovery Mode."
    echo ""
}

main "$@"
