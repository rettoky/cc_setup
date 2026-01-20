#!/bin/bash
#
# Claude Code Pro Plugins - Unix Installer
# Supports macOS and Linux
#
# Usage:
#   ./install.sh                              # Interactive installation
#   ./install.sh -c all -s global             # Install all globally
#   ./install.sh -c agents,statusline -s project
#   ./install.sh --uninstall -c statusline
#

set -e

# Colors (Catppuccin Mocha)
PINK='\033[38;2;245;194;231m'
GREEN='\033[38;2;166;227;161m'
YELLOW='\033[38;2;249;226;175m'
BLUE='\033[38;2;137;180;250m'
RED='\033[38;2;243;139;168m'
MAUVE='\033[38;2;203;166;247m'
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Defaults
COMPONENTS="all"
SCOPE="global"
FORCE=false
UNINSTALL=false
STATUSLINE_MODE="compact"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    echo "Claude Code Pro Plugins Installer"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -c, --components    Components to install (comma-separated)"
    echo "                      Options: agents, skills, commands, mcp, statusline, claude_md, all"
    echo "                      Default: all"
    echo "  -s, --scope         Installation scope: global or project"
    echo "                      Default: global"
    echo "  -m, --mode          Statusline mode: compact, default, full"
    echo "                      Default: compact"
    echo "  -f, --force         Skip confirmation prompts"
    echo "  -u, --uninstall     Remove installed components"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -c all -s global"
    echo "  $0 -c agents,statusline -s project"
    echo "  $0 --uninstall -c statusline"
}

write_header() {
    echo ""
    echo -e "${MAUVE}${BOLD}============================================${RESET}"
    echo -e "${MAUVE}${BOLD}  Claude Code Pro Plugins Installer v1.0   ${RESET}"
    echo -e "${MAUVE}${BOLD}============================================${RESET}"
    echo ""
}

write_step() {
    local message="$1"
    local status="${2:-info}"
    local icon

    case "$status" in
        success) icon="${GREEN}[OK]${RESET}" ;;
        error) icon="${RED}[FAIL]${RESET}" ;;
        warning) icon="${YELLOW}[WARN]${RESET}" ;;
        skip) icon="${DIM}[SKIP]${RESET}" ;;
        *) icon="${BLUE}[..]${RESET}" ;;
    esac

    echo -e "$icon $message"
}

get_paths() {
    PLUGIN_ROOT="$SCRIPT_DIR"
    CLAUDE_HOME="$HOME/.claude"

    if [ "$SCOPE" = "project" ]; then
        TARGET_DIR="$(pwd)"
        CLAUDE_DIR="$(pwd)/.claude"
    else
        TARGET_DIR="$CLAUDE_HOME"
        CLAUDE_DIR="$CLAUDE_HOME"
    fi
}

backup_existing() {
    local backup_dir="$CLAUDE_HOME/.claude-backup"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_path="$backup_dir/$timestamp"
    local backed_up=false

    mkdir -p "$backup_dir"

    local items=("agents" "skills" "commands" "templates" "CLAUDE.md")
    for item in "${items[@]}"; do
        if [ -e "$CLAUDE_DIR/$item" ]; then
            if [ "$backed_up" = false ]; then
                mkdir -p "$backup_path"
                backed_up=true
            fi
            cp -r "$CLAUDE_DIR/$item" "$backup_path/"
        fi
    done

    if [ "$backed_up" = true ]; then
        write_step "Backed up existing files to: $backup_path" "success"
    fi
}

install_agents() {
    echo ""
    echo -e "${PINK}${BOLD}Installing Agents...${RESET}"

    local source="$PLUGIN_ROOT/.claude/agents"
    local target="$CLAUDE_DIR/agents"

    if [ ! -d "$source" ]; then
        write_step "Agents source not found" "error"
        return
    fi

    mkdir -p "$target"

    local total_agents=0
    for category in "$source"/*; do
        if [ -d "$category" ]; then
            local category_name=$(basename "$category")
            cp -r "$category" "$target/"
            local agent_count=$(find "$category" -name "*.md" ! -name "README.md" | wc -l | tr -d ' ')
            total_agents=$((total_agents + agent_count))
            write_step "  $category_name: $agent_count agents" "success"
        fi
    done

    write_step "Installed $total_agents agents" "success"
}

install_skills() {
    echo ""
    echo -e "${PINK}${BOLD}Installing Skills...${RESET}"

    local source="$PLUGIN_ROOT/.claude/skills"
    local target="$CLAUDE_DIR/skills"

    if [ ! -d "$source" ]; then
        write_step "Skills source not found" "error"
        return
    fi

    mkdir -p "$target"

    for skill in "$source"/*.md; do
        if [ -f "$skill" ]; then
            cp "$skill" "$target/"
            write_step "  $(basename "$skill")" "success"
        fi
    done

    local count=$(find "$source" -name "*.md" | wc -l | tr -d ' ')
    write_step "Installed $count skills" "success"
}

install_commands() {
    echo ""
    echo -e "${PINK}${BOLD}Installing Commands...${RESET}"

    local source="$PLUGIN_ROOT/.claude/commands"
    local target="$CLAUDE_HOME/commands"  # Always global

    if [ ! -d "$source" ]; then
        write_step "Commands source not found" "error"
        return
    fi

    mkdir -p "$target"

    for cmd in "$source"/*.md; do
        if [ -f "$cmd" ]; then
            cp "$cmd" "$target/"
            local name=$(basename "$cmd" .md)
            write_step "  /$name command" "success"
        fi
    done
}

install_templates() {
    echo ""
    echo -e "${PINK}${BOLD}Installing Templates...${RESET}"

    local source="$PLUGIN_ROOT/.claude/templates"
    local target="$CLAUDE_DIR/templates"

    mkdir -p "$target"

    if [ ! -d "$source" ]; then
        # Create default template
        cat > "$target/agents-template.md" << 'EOF'
# Agent Session Context

## Current Session
- **Session ID:** {SESSION_ID}
- **Started:** {DATETIME}
- **Status:** ACTIVE
- **Phase:** PLANNING

## Mission Objective
{USER_REQUEST}

## Acceptance Criteria
- [ ] Criteria 1
- [ ] Criteria 2

## Active Team
| Role | Agent | Status |
|------|-------|--------|
| Planner | agent-organizer | Active |

## Artifact Registry
| File | Action | Agent | Notes |
|------|--------|-------|-------|

## Decision Log
| Time | Agent | Decision | Rationale |
|------|-------|----------|-----------|

## Communication
### Messages
- [Orchestrator] Session started

## Progress Tracker
### Phase 1: Planning
- [ ] Analyze requirements

### Phase 2: Development
- [ ] Task 1

### Phase 3: Review
- [ ] Code review

## Error Log
(None)

## Handoff Notes
(None)
EOF
        write_step "Created default session template" "success"
        return
    fi

    cp -r "$source"/* "$target/"
    write_step "Installed templates" "success"
}

install_mcp() {
    echo ""
    echo -e "${PINK}${BOLD}Installing MCP Servers...${RESET}"

    local source="$PLUGIN_ROOT/.mcp.json"
    local global_mcp="$CLAUDE_HOME/mcp.json"

    if [ ! -f "$source" ]; then
        write_step "MCP config not found" "error"
        return
    fi

    # Check for jq
    if ! command -v jq &> /dev/null; then
        write_step "jq is required for MCP merge. Installing raw config." "warning"
        # Convert Windows paths to Unix
        sed 's|"cmd"|"npx"|g; s|"/c",||g; s|"args": \["cmd", "/c", "npx"|"args": ["npx"|g' "$source" > "$global_mcp"
    else
        # Convert Windows config to Unix format
        local unix_config=$(cat "$source" | jq '
            .mcpServers | to_entries | map({
                key: .key,
                value: {
                    command: "npx",
                    args: (.value.args | map(select(. != "/c" and . != "cmd"))),
                    env: .value.env
                } | if .env == null then del(.env) else . end
            }) | from_entries | {mcpServers: .}
        ')

        if [ -f "$global_mcp" ]; then
            # Merge with existing
            local merged=$(jq -s '.[0].mcpServers * .[1].mcpServers | {mcpServers: .}' <(echo "$unix_config") "$global_mcp")
            echo "$merged" > "$global_mcp"
            write_step "Merged MCP servers into existing config" "success"
        else
            echo "$unix_config" > "$global_mcp"
            write_step "Created new MCP config" "success"
        fi
    fi

    # List servers
    for server in context7 chrome-devtools n8n-mcp supabase; do
        write_step "  $server" "success"
    done
}

install_statusline() {
    echo ""
    echo -e "${PINK}${BOLD}Installing Statusline ($STATUSLINE_MODE mode)...${RESET}"

    # Check for jq (required for statusline)
    if ! command -v jq &> /dev/null; then
        write_step "jq is required for statusline. Please install: brew install jq (macOS) or apt install jq (Linux)" "error"
        return
    fi

    local source="$PLUGIN_ROOT/statusline/scripts/$STATUSLINE_MODE.sh"
    local target="$CLAUDE_HOME/awesome-statusline.sh"
    local settings="$CLAUDE_HOME/settings.json"

    # Try alternate locations
    if [ ! -f "$source" ]; then
        source="$PLUGIN_ROOT/plugins/awesome-statusline/scripts/awesome-statusline-2.1.0-$STATUSLINE_MODE.sh"
    fi

    if [ ! -f "$source" ]; then
        write_step "Statusline script not found. Creating from template..." "warning"

        # Create bash statusline script
        cat > "$target" << 'STATUSLINE_EOF'
#!/bin/bash
# Awesome Statusline for Claude Code (Unix)
# Catppuccin-themed with usage API integration

# Read JSON from stdin
INPUT=$(cat)

# Parse with jq
MODEL_ID=$(echo "$INPUT" | jq -r '.model.id // .model // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')
CTX_PERCENT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0')

# Get short model name
case "$MODEL_ID" in
    *opus*) MODEL="\033[38;2;203;166;247mOpus\033[0m" ;;
    *sonnet*) MODEL="\033[38;2;137;180;250mSonnet\033[0m" ;;
    *haiku*) MODEL="\033[38;2;166;227;161mHaiku\033[0m" ;;
    *) MODEL="$MODEL_ID" ;;
esac

# Shorten path
SHORT_PATH=$(echo "$CWD" | sed "s|$HOME|~|")

# Get usage from API (with caching)
CACHE_FILE="/tmp/.claude_usage_cache"
CACHE_MAX_AGE=300

get_usage() {
    local cred_file="$HOME/.claude/.credentials.json"
    if [ ! -f "$cred_file" ]; then
        echo '{"five_hour":{"utilization":0},"seven_day":{"utilization":0}}'
        return
    fi

    # Check cache
    if [ -f "$CACHE_FILE" ]; then
        local cache_age=$(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null)))
        if [ "$cache_age" -lt "$CACHE_MAX_AGE" ]; then
            cat "$CACHE_FILE"
            return
        fi
    fi

    local token=$(jq -r '.claudeAiOauth.accessToken // empty' "$cred_file")
    if [ -z "$token" ]; then
        echo '{"five_hour":{"utilization":0},"seven_day":{"utilization":0}}'
        return
    fi

    local response=$(curl -s --max-time 5 \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -H "anthropic-beta: oauth-2025-04-20" \
        "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

    if [ -n "$response" ]; then
        echo "$response" > "$CACHE_FILE"
        echo "$response"
    elif [ -f "$CACHE_FILE" ]; then
        cat "$CACHE_FILE"
    else
        echo '{"five_hour":{"utilization":0},"seven_day":{"utilization":0}}'
    fi
}

USAGE=$(get_usage)
USAGE_5H=$(echo "$USAGE" | jq -r '.five_hour.utilization // 0' | xargs printf "%.1f")
USAGE_7D=$(echo "$USAGE" | jq -r '.seven_day.utilization // 0' | xargs printf "%.1f")

# Generate progress bar
progress_bar() {
    local percent=$1
    local width=10
    local filled=$(echo "$percent * $width / 100" | bc)
    local empty=$((width - filled))

    printf "["
    for ((i=0; i<filled; i++)); do printf "="; done
    for ((i=0; i<empty; i++)); do printf "-"; done
    printf "]"
}

# Colors
PINK='\033[38;2;245;194;231m'
LAVENDER='\033[38;2;180;190;254m'
YELLOW='\033[38;2;249;226;175m'
TEAL='\033[38;2;148;226;213m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# Output
echo -e "$MODEL ${DIM}|${RESET} ${TEAL}$SHORT_PATH${RESET}"
echo -e "${PINK}Ctx${RESET} $(progress_bar $CTX_PERCENT) ${BOLD}${CTX_PERCENT}%${RESET}  ${DIM}|${RESET}  ${LAVENDER}5H${RESET} $(progress_bar $USAGE_5H) ${BOLD}${USAGE_5H}%${RESET}  ${DIM}|${RESET}  ${YELLOW}7D${RESET} $(progress_bar $USAGE_7D) ${BOLD}${USAGE_7D}%${RESET}"
STATUSLINE_EOF

        chmod +x "$target"
        write_step "Created statusline script" "success"
    else
        cp "$source" "$target"
        chmod +x "$target"
        write_step "Copied statusline script" "success"
    fi

    # Update settings.json
    local statusline_config="{\"type\":\"command\",\"command\":\"$target\"}"

    if [ -f "$settings" ]; then
        if command -v jq &> /dev/null; then
            jq --arg cmd "$target" '.statusLine = {"type":"command","command":$cmd}' "$settings" > "$settings.tmp"
            mv "$settings.tmp" "$settings"
        fi
    else
        echo "{\"statusLine\":$statusline_config}" > "$settings"
    fi

    write_step "Updated settings.json" "success"
}

install_claude_md() {
    echo ""
    echo -e "${PINK}${BOLD}Installing CLAUDE.md...${RESET}"

    local source="$PLUGIN_ROOT/CLAUDE.md"
    local target="$CLAUDE_DIR/CLAUDE.md"

    if [ ! -f "$source" ]; then
        write_step "CLAUDE.md not found" "error"
        return
    fi

    cp "$source" "$target"
    write_step "Installed CLAUDE.md" "success"
}

show_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}============================================${RESET}"
    echo -e "${GREEN}${BOLD}  Installation Complete!                    ${RESET}"
    echo -e "${GREEN}${BOLD}============================================${RESET}"
    echo ""
    echo -e "Installed components (${BLUE}$SCOPE${RESET}):"
    for item in "${INSTALLED[@]}"; do
        echo -e "  ${GREEN}*${RESET} $item"
    done
    echo ""
    echo -e "${YELLOW}Next steps:${RESET}"
    echo "  1. Restart Claude Code to apply changes"
    echo -e "  2. Use ${BLUE}/ag${RESET} command for multi-agent orchestration"
    echo -e "  3. Run ${BLUE}/awesome-statusline-mode${RESET} to change statusline mode"
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--components) COMPONENTS="$2"; shift 2 ;;
        -s|--scope) SCOPE="$2"; shift 2 ;;
        -m|--mode) STATUSLINE_MODE="$2"; shift 2 ;;
        -f|--force) FORCE=true; shift ;;
        -u|--uninstall) UNINSTALL=true; shift ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

# Main execution
write_header
get_paths

# Parse components
if [ "$COMPONENTS" = "all" ]; then
    COMPONENT_LIST=(agents skills commands templates mcp statusline claude_md)
else
    IFS=',' read -ra COMPONENT_LIST <<< "$COMPONENTS"
fi

echo -e "Installation scope: ${BLUE}$SCOPE${RESET}"
echo -e "Components: ${BLUE}${COMPONENT_LIST[*]}${RESET}"
echo ""

if [ "$FORCE" = false ]; then
    read -p "Proceed with installation? (y/N) " confirm
    if [[ ! "$confirm" =~ ^[Yy] ]]; then
        echo -e "${YELLOW}Installation cancelled.${RESET}"
        exit 0
    fi
fi

# Backup
backup_existing

# Ensure directories exist
mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/sessions"
mkdir -p "$CLAUDE_DIR/history"

INSTALLED=()

for component in "${COMPONENT_LIST[@]}"; do
    component=$(echo "$component" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
    case "$component" in
        agents)
            install_agents
            INSTALLED+=("100+ Specialized Agents")
            ;;
        skills)
            install_skills
            INSTALLED+=("Skills (Statusline)")
            ;;
        commands)
            install_commands
            INSTALLED+=("Commands (/ag orchestrator)")
            ;;
        templates)
            install_templates
            INSTALLED+=("Session Templates")
            ;;
        mcp)
            install_mcp
            INSTALLED+=("MCP Servers")
            ;;
        statusline)
            install_statusline
            INSTALLED+=("Statusline ($STATUSLINE_MODE mode)")
            ;;
        claude_md)
            install_claude_md
            INSTALLED+=("CLAUDE.md")
            ;;
    esac
done

show_summary
