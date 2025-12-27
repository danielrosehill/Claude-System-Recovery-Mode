#!/bin/bash
#
# Claude Recovery Mode Launcher
# Sets up recovery agents/commands and launches Claude CLI for system recovery
#

# Colors for the banner
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Recovery config source location (installed by installer)
RECOVERY_CONFIG_SOURCE="/usr/local/share/claude-recovery"

# Clear screen
clear

# Display warning banner
echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                         CLAUDE RECOVERY MODE                                 ║
║                                                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
EOF
echo -e "${YELLOW}"
cat << 'EOF'
║  WARNING: This is a third-party tool and is NOT affiliated with Anthropic.  ║
║                                                                              ║
║  You are about to use an agentic AI to interact with system files.          ║
║  This involves inherent risks including potential data loss or system       ║
║  instability. No warranty is provided. Use at your own discretion.          ║
EOF
echo -e "${CYAN}"
cat << 'EOF'
╠══════════════════════════════════════════════════════════════════════════════╣
║  Type 'exit' or press Ctrl+C to exit Claude and return to shell             ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Recovery Commands:  /status  /errors  /failed  /network-check  /boot-log   ║
║  Recovery Agents:    @diagnose  @logs  @network  @disk  @services  @packages║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Ensure PATH includes common locations for claude
export PATH="$HOME/.local/bin:$HOME/.claude/local/bin:/usr/local/bin:$PATH"

# Check if Claude CLI is installed
if ! command -v claude &>/dev/null; then
    echo -e "${YELLOW}Claude CLI not found. Attempting to install...${NC}"
    echo ""

    # Check for curl
    if ! command -v curl &>/dev/null; then
        echo -e "${RED}Error: curl is not installed. Cannot auto-install Claude CLI.${NC}"
        echo "Please install Claude CLI manually: https://claude.ai/download"
        echo ""
        echo "Dropping to shell..."
        exec /bin/bash
    fi

    # Attempt installation
    if curl -fsSL https://claude.ai/install.sh | bash; then
        echo -e "${GREEN}Claude CLI installed successfully.${NC}"
        # Refresh PATH
        export PATH="$HOME/.local/bin:$HOME/.claude/local/bin:$PATH"

        # Verify installation
        if ! command -v claude &>/dev/null; then
            echo -e "${RED}Installation completed but claude command not found in PATH.${NC}"
            echo "Dropping to shell. Try running: ~/.local/bin/claude"
            exec /bin/bash
        fi
    else
        echo -e "${RED}Failed to install Claude CLI.${NC}"
        echo "Dropping to shell..."
        exec /bin/bash
    fi

    echo ""
fi

# Set up .claude directory with recovery agents and commands
setup_claude_config() {
    local claude_dir="$HOME/.claude"
    local agents_dir="$claude_dir/agents"
    local commands_dir="$claude_dir/commands"

    echo -e "${CYAN}Setting up recovery agents and commands...${NC}"

    # Create directories
    mkdir -p "$agents_dir" 2>/dev/null
    mkdir -p "$commands_dir" 2>/dev/null

    # Copy agents if source exists
    if [[ -d "$RECOVERY_CONFIG_SOURCE/agents" ]]; then
        cp -f "$RECOVERY_CONFIG_SOURCE/agents"/*.md "$agents_dir/" 2>/dev/null
    fi

    # Copy commands if source exists
    if [[ -d "$RECOVERY_CONFIG_SOURCE/commands" ]]; then
        cp -f "$RECOVERY_CONFIG_SOURCE/commands"/*.md "$commands_dir/" 2>/dev/null
    fi

    # Verify setup
    local agent_count=$(ls -1 "$agents_dir"/*.md 2>/dev/null | wc -l)
    local command_count=$(ls -1 "$commands_dir"/*.md 2>/dev/null | wc -l)

    if [[ $agent_count -gt 0 || $command_count -gt 0 ]]; then
        echo -e "${GREEN}Loaded $agent_count agents and $command_count commands${NC}"
    else
        echo -e "${YELLOW}No recovery agents/commands found at $RECOVERY_CONFIG_SOURCE${NC}"
        echo -e "${YELLOW}Run update-claude-recovery to fetch the latest recovery tools${NC}"
    fi
    echo ""
}

# Run setup
setup_claude_config

# Change to root directory for system-wide access
cd /

# Display current info
echo -e "${WHITE}Starting Claude CLI...${NC}"
echo -e "Working directory: ${CYAN}$(pwd)${NC}"
echo -e "User: ${CYAN}$(whoami)${NC}"
echo ""

# Launch Claude CLI
# Using exec to replace this shell with claude
exec claude
