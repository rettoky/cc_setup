# Claude Code Pro Plugins

Professional Claude Code plugin suite with 100+ specialized agents, multi-agent orchestration, custom statusline, and MCP integrations.

## Features

| Component | Description |
|-----------|-------------|
| **100+ Agents** | Specialized subagents for development, infrastructure, security, data/AI, and more |
| **Multi-Agent Orchestrator** | `/ag` command for Planner-Developer-Reviewer workflow |
| **Awesome Statusline** | Catppuccin-themed statusline with API usage tracking |
| **MCP Servers** | Pre-configured Context7, Chrome DevTools, n8n, Supabase |
| **Skills** | Interactive statusline configuration |

## Quick Start

### Windows (PowerShell)

```powershell
# Clone the repository
git clone https://github.com/yourusername/claude-code-pro-plugins
cd claude-code-pro-plugins

# Install all components globally
.\install.ps1 -Components all -Scope global

# Or install specific components
.\install.ps1 -Components agents,statusline -Scope project
```

### macOS / Linux

```bash
# Clone the repository
git clone https://github.com/yourusername/claude-code-pro-plugins
cd claude-code-pro-plugins

# Make installer executable
chmod +x install.sh

# Install all components globally
./install.sh -c all -s global

# Or install specific components
./install.sh -c agents,statusline -s project
```

## Components

### 1. Agents (100+)

Specialized subagents organized in 10 categories:

| Category | Examples |
|----------|----------|
| **01-core-development** | api-designer, backend-developer, frontend-developer, fullstack-developer |
| **02-language-specialists** | react-specialist, nextjs-developer, python-pro, typescript-pro, rust-engineer |
| **03-infrastructure** | kubernetes-specialist, terraform-engineer, cloud-architect, devops-engineer |
| **04-quality-security** | code-reviewer, security-auditor, penetration-tester, performance-engineer |
| **05-data-ai** | ml-engineer, data-scientist, llm-architect, prompt-engineer |
| **06-developer-experience** | refactoring-specialist, mcp-developer, git-workflow-manager |
| **07-specialized-domains** | blockchain-developer, iot-engineer, fintech-engineer, game-developer |
| **08-business-product** | product-manager, business-analyst, project-manager |
| **09-meta-orchestration** | agent-organizer, workflow-orchestrator, multi-agent-coordinator |
| **10-research-analysis** | research-analyst, competitive-analyst, trend-analyst |

### 2. Multi-Agent Orchestrator (`/ag`)

The `/ag` command implements a Planner-Developer-Reviewer workflow:

```bash
# General usage
/ag "Add user authentication feature"

# With specific context
/ag "Optimize database queries" backend/src/db/

# Large scale feature
/ag "Implement new dashboard with charts and export"
```

**Workflow:**
1. **Planning Phase** - `agent-organizer` analyzes requirements and selects team
2. **Development Phase** - Multiple developers work in parallel
3. **Review Phase** - Code reviewers and security auditors validate changes

### 3. Awesome Statusline

Catppuccin-themed statusline with real-time usage tracking:

```
Opus | ~/projects/myapp | git:(main)*
Ctx [████████▒▒] 80%  |  5H [███▒▒▒▒▒▒▒] 38%  |  7D [██████▒▒▒▒] 62%
```

**Modes:**
- `compact` - Minimal 2-line layout (default)
- `default` - Standard with reset times
- `full` - Detailed 5-line layout

**Change mode:**
```bash
/awesome-statusline-mode
```

### 4. MCP Servers

Pre-configured MCP servers:

| Server | Description |
|--------|-------------|
| **context7** | Library documentation search |
| **chrome-devtools** | Browser automation and debugging |
| **n8n-mcp** | n8n workflow automation |
| **supabase** | Supabase project management |

### 5. Skills

Interactive configuration skills:

- `/awesome-statusline-start` - Installation wizard
- `/awesome-statusline-mode` - Change statusline mode

## Installation Options

### By Scope

| Scope | Location | Use Case |
|-------|----------|----------|
| `global` | `~/.claude/` | User-wide settings |
| `project` | `./.claude/` | Project-specific settings |

### By Component

```powershell
# Windows examples
.\install.ps1 -Components agents              # Agents only
.\install.ps1 -Components statusline -StatuslineMode full  # Full statusline
.\install.ps1 -Components mcp                 # MCP servers only
.\install.ps1 -Components all -Scope project  # Everything in project
```

```bash
# Unix examples
./install.sh -c agents              # Agents only
./install.sh -c statusline -m full  # Full statusline
./install.sh -c mcp                 # MCP servers only
./install.sh -c all -s project      # Everything in project
```

## Directory Structure

```
claude-code-pro-plugins/
├── plugin.json              # Plugin metadata
├── install.ps1              # Windows installer
├── install.sh               # Unix installer
├── CLAUDE.md                # Project instructions
├── README.md                # This file
│
├── .claude/
│   ├── agents/              # 100+ agent definitions
│   │   ├── 01-core-development/
│   │   ├── 02-language-specialists/
│   │   └── ...
│   ├── skills/              # Skill files
│   ├── commands/            # Custom commands
│   └── templates/           # Session templates
│
├── statusline/              # Statusline scripts
│   ├── config.json
│   └── scripts/
│       ├── compact.ps1
│       ├── default.ps1
│       └── full.ps1
│
└── mcp/                     # MCP configurations
    └── servers.json
```

## Requirements

### Windows
- PowerShell 5.1+ or PowerShell 7+
- Claude Code CLI

### macOS / Linux
- Bash 4+
- `jq` (for JSON processing)
- Claude Code CLI

## Uninstallation

```powershell
# Windows
.\install.ps1 -Uninstall -Components all
```

```bash
# Unix
./install.sh --uninstall -c all
```

## Configuration

### Statusline API

The statusline uses Claude's OAuth API for usage tracking. Credentials are automatically read from `~/.claude/.credentials.json`.

### MCP Servers

Some MCP servers require additional configuration:

- **n8n-mcp**: Set `N8N_API_URL` and `N8N_API_KEY` in environment
- **supabase**: Set access token in `.mcp.json`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add your agent/skill/command
4. Submit a pull request

## License

MIT License

## Credits

- [Catppuccin](https://github.com/catppuccin/catppuccin) - Color theme
- [Claude Code](https://claude.ai/code) - AI coding assistant
