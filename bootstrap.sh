#!/bin/bash
#
# Claude Recovery Mode - Bootstrap Installer
#
# One-command installation from anywhere:
#   curl -fsSL https://raw.githubusercontent.com/danielrosehill/Claude-System-Recovery-Mode/main/bootstrap.sh | sudo bash
#
# Or with a custom domain:
#   curl -fsSL https://recovery.danielrosehill.com/install | sudo bash
#
# Options (pass after bash):
#   curl -fsSL <url> | sudo bash -s -- --user myuser
#   curl -fsSL <url> | sudo bash -s -- --root
#

set -e

# Configuration
REPO_URL="https://github.com/danielrosehill/Claude-System-Recovery-Mode"
RAW_BASE="https://raw.githubusercontent.com/danielrosehill/Claude-System-Recovery-Mode/main"
TEMP_DIR=""
VERSION="1.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Print functions
info() { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Show banner
show_banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     ${BOLD}Claude Recovery Mode - Bootstrap Installer${NC}${CYAN}              ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║     AI-assisted system recovery for Linux                    ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Cleanup on exit
cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# Check for root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root. Use: curl -fsSL <url> | sudo bash"
    fi
}

# Check prerequisites
check_prerequisites() {
    info "Checking prerequisites..."

    # Check for curl or wget
    if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
        error "curl or wget is required but not found"
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

    success "Prerequisites check passed"
}

# Download a file
download_file() {
    local url="$1"
    local dest="$2"

    if command -v curl &>/dev/null; then
        curl -fsSL "$url" -o "$dest"
    elif command -v wget &>/dev/null; then
        wget -q "$url" -O "$dest"
    fi
}

# Download all required files
download_files() {
    info "Downloading Claude Recovery Mode files..."

    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    # Create directory structure
    mkdir -p scripts systemd grub claude-config/agents claude-config/commands

    # List of files to download
    local files=(
        "install.sh"
        "uninstall.sh"
        "update.sh"
        "scripts/claude-recovery-launcher.sh"
        "systemd/claude-recovery.target"
        "systemd/claude-recovery-getty@.service"
        "grub/45_claude-recovery"
        "claude-config/agents/diagnose.md"
        "claude-config/agents/logs.md"
        "claude-config/agents/network.md"
        "claude-config/agents/disk.md"
        "claude-config/agents/services.md"
        "claude-config/agents/packages.md"
        "claude-config/commands/status.md"
        "claude-config/commands/errors.md"
        "claude-config/commands/failed.md"
        "claude-config/commands/network-check.md"
        "claude-config/commands/boot-log.md"
        "claude-config/commands/fix-packages.md"
    )

    local failed=0
    for file in "${files[@]}"; do
        if download_file "${RAW_BASE}/${file}" "$file"; then
            echo -e "  ${GREEN}✓${NC} $file"
        else
            echo -e "  ${RED}✗${NC} $file"
            failed=1
        fi
    done

    if [[ $failed -eq 1 ]]; then
        error "Failed to download some required files"
    fi

    # Make scripts executable
    chmod +x install.sh uninstall.sh update.sh scripts/claude-recovery-launcher.sh

    success "All files downloaded"
}

# Alternative: Clone the repo if git is available
try_git_clone() {
    if command -v git &>/dev/null; then
        info "Git available, cloning repository..."
        TEMP_DIR=$(mktemp -d)
        if git clone --depth 1 "$REPO_URL" "$TEMP_DIR/repo" 2>/dev/null; then
            cd "$TEMP_DIR/repo"
            success "Repository cloned"
            return 0
        fi
    fi
    return 1
}

# Run the installer
run_installer() {
    info "Running installer..."
    echo ""

    # Pass through any arguments
    ./install.sh "$@"
}

# Main
main() {
    show_banner
    check_root
    check_prerequisites

    # Try git clone first, fall back to individual downloads
    if ! try_git_clone; then
        download_files
    fi

    run_installer "$@"

    echo ""
    echo -e "${GREEN}Bootstrap complete!${NC}"
    echo ""
    echo "The temporary files have been cleaned up."
    echo "Your system now has Claude Recovery Mode installed."
    echo ""
    echo "Reboot and select 'Claude Recovery Mode' from the GRUB menu to use it."
    echo ""
}

main "$@"
