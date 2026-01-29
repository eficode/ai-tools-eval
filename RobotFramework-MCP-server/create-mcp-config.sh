#!/bin/bash

################################################################################
# MCP Configuration Generator
# 
# This script generates tool-specific MCP (Model Context Protocol) configuration
# files for the RobotFramework MCP Server.
#
# Usage: ./create-mcp-config.sh <tool>
# Examples:
#   ./create-mcp-config.sh copilot
#   ./create-mcp-config.sh claude-code
#   ./create-mcp-config.sh gitlab
#   ./create-mcp-config.sh amazonq
#
# Supported tools: copilot, claude-code, gitlab, amazonq
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Configuration
CONFIG_DIR=""
TOOL_NAME=""
AGENT_NAME=""
DESCRIPTION=""
TOOLS_ARRAY=""
ALLOWED_TOOLS=""
TOOLS_SETTINGS=""

################################################################################
# Helper Functions
################################################################################

print_usage() {
    cat << EOF
Usage: $(basename "$0") <tool>

Generate MCP configuration for specified IDE/Tool.

Supported tools:
  copilot      - GitHub Copilot
  claude-code  - Claude Code
  gitlab       - GitLab Duo
  amazonq      - Amazon Q in IDE

Examples:
  $(basename "$0") copilot
  $(basename "$0") claude-code
  $(basename "$0") gitlab
  $(basename "$0") amazonq

EOF
}

print_error() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

################################################################################
# Tool Configuration Functions
################################################################################

configure_copilot() {
    TOOL_NAME="copilot"
    CONFIG_DIR=".vscode"
    AGENT_NAME="mcp"
    DESCRIPTION="MCP server configuration for GitHub Copilot"
}

configure_gitlab() {
    TOOL_NAME="gitlab"
    CONFIG_DIR=".gitlab/duo"
    AGENT_NAME="mcp"
    DESCRIPTION="MCP server configuration for GitLab Duo"
    TOOLS_SETTINGS=""
}

configure_amazonq() {
    TOOL_NAME="amazonq"
    CONFIG_DIR=".amazonq"
    AGENT_NAME="default"
    DESCRIPTION="MCP server configuration for Amazon Q"
    TOOLS_SETTINGS='
    "execute_bash": {
      "preset": "readOnly"
    }'
}

configure_claude_code() {
    TOOL_NAME="claude-code"
    CONFIG_DIR="../"
    AGENT_NAME=".claude"
    DESCRIPTION="MCP server configuration for Claude Code"
    TOOLS_SETTINGS=""
}

################################################################################
# Main Functions
################################################################################

validate_tool() {
    local tool="$1"
    case "$tool" in
        copilot|gitlab|amazonq|claude-code)
            return 0
            ;;
        *)
            print_error "Unknown tool: $tool"
            print_usage
            return 1
            ;;
    esac
}

generate_config_file() {
    local config_path config_file
    
    # All tools should create their config in the PROJECT ROOT
    # VS Code: <project_root>/.vscode/mcp.json
    # Claude Code: <project_root>/.claude.json
    # Amazon Q: <project_root>/.amazonq/default.json
    # GitLab: <project_root>/.gitlab/duo/mcp.json
    
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    
    if [ "$TOOL_NAME" = "claude-code" ]; then
        # Claude Code: .claude.json directly in project root
        config_path="$PROJECT_ROOT"
        config_file="$config_path/${AGENT_NAME}.json"
    else
        # Other tools: subdirectory in project root
        config_path="$PROJECT_ROOT/$CONFIG_DIR"
        config_file="$config_path/${AGENT_NAME}.json"
    fi

    # Create directory structure if it doesn't exist
    if [ ! -d "$config_path" ]; then
        mkdir -p "$config_path"
        print_info "Created directory: $config_path"
    fi

    # Generate the JSON configuration
    # Use simplified format for GitHub Copilot (native MCP support)
    if [ "$TOOL_NAME" = "copilot" ]; then
        cat > "$config_file" << EOF
{
  "mcpServers": {
    "RobotFramework": {
      "command": "/usr/bin/docker",
      "args": [
        "exec",
        "-i",
        "robotframework-mcp",
        "python",
        "/app/server.py"
      ]
    },
    "rf-docs": {
      "command": "/usr/bin/docker",
      "args": [
        "exec",
        "-i",
        "rf-docs-mcp",
        "python",
        "/app/rf_docs_server.py"
      ]
    }
  }
}
EOF
    else
        # Extended format for other tools (Cline, Claude, etc.)
        cat > "$config_file" << EOF
{
  "name": "$AGENT_NAME",
  "description": "$DESCRIPTION",
  "prompt": "",
  "mcpServers": {
    "RobotFramework": {
      "command": "/usr/bin/docker",
      "disabled": false,
      "timeout": 60000,
      "args": [
        "exec",
        "-i",
        "robotframework-mcp",
        "python",
        "/app/server.py"
      ]
    },
    "rf-docs": {
      "command": "/usr/bin/docker",
      "disabled": false,
      "timeout": 60000,
      "args": [
        "exec",
        "-i",
        "rf-docs-mcp",
        "python",
        "/app/rf_docs_server.py"
      ]
    }
  },
  "tools": [
$TOOLS_ARRAY
  ],
  "toolAliases": {},
  "allowedTools": [
$ALLOWED_TOOLS
  ],
  "toolsSettings": {$TOOLS_SETTINGS
  },
  "hooks": {
    "agentSpawn": [],
    "userPromptSubmit": []
  },
  "useLegacyMcpJson": true
}
EOF
    fi

    print_success "Generated configuration: $config_file"
}

display_next_steps() {
    local file_path
    if [ -z "$CONFIG_DIR" ]; then
        file_path="${AGENT_NAME}.json"
    else
        file_path="${CONFIG_DIR}/${AGENT_NAME}.json"
    fi
    cat << EOF

${GREEN}Configuration generated successfully!${NC}

Next steps:
1. Ensure the MCP Server container is running:
   ${YELLOW}docker-compose up -d${NC}

2. Verify the Docker container name matches the MCP config:
   ${YELLOW}docker ps | grep robotframework-mcp${NC}

3. If using $TOOL_NAME, restart your IDE to load the new configuration

Configuration details:
  Tool:       $TOOL_NAME
  File:       <project_root>/$file_path

For more information, see docs/ in the project root
EOF
}

################################################################################
# Main Execution
################################################################################

main() {
    # Validate arguments
    if [ $# -eq 0 ]; then
        print_error "No tool specified"
        print_usage
        exit 1
    fi

    if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        print_usage
        exit 0
    fi

    # Validate and configure tool
    if ! validate_tool "$1"; then
        exit 1
    fi

    # Run configuration based on tool
    case "$1" in
        copilot)
            configure_copilot
            ;;
        gitlab)
            configure_gitlab
            ;;
        amazonq)
            configure_amazonq
            ;;
        claude-code)
            configure_claude_code
            ;;
    esac

    # Generate the configuration file
    print_info "Generating MCP configuration for $TOOL_NAME..."
    generate_config_file

    # Stop and rebuild containers
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    print_info "Stopping containers..."
    cd "$PROJECT_ROOT"
    docker compose down
    
    print_info "Building images..."
    docker compose build
    
    print_success "Containers stopped and images rebuilt"

    # Display next steps
    display_next_steps
}

# Run main function
main "$@"
