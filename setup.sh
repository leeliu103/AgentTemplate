#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================"
echo "Agent Template Setup Script"
echo -e "======================================${NC}\n"

# Check if AMD_LLM_API_KEY is set
if [ -z "$AMD_LLM_API_KEY" ]; then
    echo -e "${RED}ERROR: AMD_LLM_API_KEY environment variable is not set!${NC}"
    echo "Please export your AMD LLM Gateway API key first:"
    echo "  export AMD_LLM_API_KEY=<Your Key>"
    exit 1
fi

echo -e "${GREEN}✓ AMD_LLM_API_KEY detected${NC}\n"

# Check if nvm is installed
if [ ! -d "$HOME/.nvm" ]; then
    echo -e "${YELLOW}Installing nvm...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

    # Load nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
else
    echo -e "${GREEN}✓ nvm already installed${NC}"
    # Load nvm if not already loaded
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Install Node.js LTS
echo -e "${YELLOW}Installing Node.js LTS...${NC}"
nvm install node
nvm alias default node
echo -e "${GREEN}✓ Node.js $(node -v) installed${NC}\n"

# Install claude-code
echo -e "${YELLOW}Installing claude-code...${NC}"
npm install -g @anthropic-ai/claude-code
echo -e "${GREEN}✓ claude-code installed${NC}\n"

# Install codex
echo -e "${YELLOW}Installing @openai/codex...${NC}"
npm install -g @openai/codex
echo -e "${GREEN}✓ @openai/codex installed${NC}\n"

# Copy codex.config to ~/.codex/config.toml
echo -e "${YELLOW}Setting up codex configuration...${NC}"
mkdir -p ~/.codex
cp codex.config ~/.codex/config.toml
echo -e "${GREEN}✓ Copied codex.config to ~/.codex/config.toml${NC}\n"

# Copy CLAUDE.md to ~/.claude/
echo -e "${YELLOW}Setting up Claude code configuration...${NC}"
mkdir -p ~/.claude
cp CLAUDE.md ~/.claude/
echo -e "${GREEN}✓ Copied CLAUDE.md to ~/.claude/${NC}\n"

# Set up environment variables
echo -e "${YELLOW}Setting up environment variables...${NC}"

# Determine shell config file
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
else
    SHELL_CONFIG="$HOME/.profile"
fi

# Create environment variable exports
ENV_EXPORTS="
# Agent Template - AMD LLM Gateway Configuration
export ANTHROPIC_API_KEY=\"\${AMD_LLM_API_KEY}\"
export ANTHROPIC_CUSTOM_HEADERS=\"Ocp-Apim-Subscription-Key:\${AMD_LLM_API_KEY}\"
export ANTHROPIC_BASE_URL=\"https://llm-api.amd.com/Anthropic\"
export ANTHROPIC_MODEL=\"claude-opus-4.6\"
export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1
export LLM_GATEWAY_KEY=\"\${AMD_LLM_API_KEY}\"
"

# Remove existing configuration if present and add new one
if grep -q "Agent Template - AMD LLM Gateway Configuration" "$SHELL_CONFIG" 2>/dev/null; then
    echo -e "${YELLOW}Removing existing AMD LLM Gateway Configuration...${NC}"
    sed -i '/# Agent Template - AMD LLM Gateway Configuration/,/^export LLM_GATEWAY_KEY=/d' "$SHELL_CONFIG"
    echo -e "${GREEN}✓ Removed existing configuration${NC}"
fi

echo "$ENV_EXPORTS" >> "$SHELL_CONFIG"
echo -e "${GREEN}✓ Environment variables added to $SHELL_CONFIG${NC}"

# Export for current session
export ANTHROPIC_API_KEY="$AMD_LLM_API_KEY"
export ANTHROPIC_CUSTOM_HEADERS="Ocp-Apim-Subscription-Key:$AMD_LLM_API_KEY"
export ANTHROPIC_BASE_URL="https://llm-api.amd.com/Anthropic"
export ANTHROPIC_MODEL="claude-opus-4.6"
export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1
export LLM_GATEWAY_KEY="$AMD_LLM_API_KEY"

echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}ERROR: Python 3 is not installed!${NC}"
    echo "Please install Python 3 before continuing."
    exit 1
fi

echo -e "${GREEN}✓ Python $(python3 --version) detected${NC}\n"

# Install Python SDKs
echo -e "${YELLOW}Installing Python SDKs...${NC}"

# Check if pip is available
if ! command -v pip &> /dev/null && ! command -v pip3 &> /dev/null; then
    echo -e "${RED}ERROR: pip is not installed!${NC}"
    exit 1
fi

PIP_CMD=$(command -v pip3 || command -v pip)

$PIP_CMD install openai-agents --break-system-packages 2>/dev/null || $PIP_CMD install openai-agents
echo -e "${GREEN}✓ openai-agents installed${NC}"

$PIP_CMD install claude-agent-sdk --break-system-packages 2>/dev/null || $PIP_CMD install claude-agent-sdk
echo -e "${GREEN}✓ claude-agent-sdk installed${NC}\n"

# Success message
echo -e "${GREEN}======================================"
echo "✓ Setup Complete!"
echo -e "======================================${NC}\n"

echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Source your shell configuration to load environment variables:"
echo -e "   ${GREEN}source $SHELL_CONFIG${NC}"
echo ""
echo "2. Test the SDKs by running the example agents:"
echo -e "   ${GREEN}./run-examples.sh${NC}"
echo ""
echo -e "${YELLOW}Usage Instructions:${NC}"
echo ""
echo "• Using Claude Code:"
echo "  After running this setup, you can use 'claude' in ANY project folder."
echo "  To enable the 3 common MCP servers (context7, codex, playwright):"
echo -e "  ${GREEN}cp .mcp.json /path/to/your/project/${NC}"
echo ""
echo "• Using Codex Agent:"
echo "  You can use Codex in ANY folder with:"
echo -e "  ${GREEN}codex -c model_provider=\"amd-openai\"${NC}"
echo ""
