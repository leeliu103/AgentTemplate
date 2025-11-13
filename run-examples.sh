#!/usr/bin/env bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================"
echo "Agent Template - Run Examples"
echo -e "======================================${NC}\n"

# Check if AMD_LLM_API_KEY is set
if [ -z "$AMD_LLM_API_KEY" ]; then
    echo -e "${RED}ERROR: AMD_LLM_API_KEY environment variable is not set!${NC}"
    echo "Please export your AMD LLM Gateway API key:"
    echo "  export AMD_LLM_API_KEY=<Your Key>"
    exit 1
fi

# Menu function
show_menu() {
    echo -e "${BLUE}Select an example to run:${NC}"
    echo "1) Claude Agent SDK - Basic Example"
    echo "2) Claude Agent SDK - Codex MCP Example"
    echo "3) OpenAI Agent SDK - GPT-5 Example"
    echo "4) OpenAI Agent SDK - GPT-5 Codex Example"
    echo "5) Run all examples"
    echo "0) Exit"
    echo ""
}

# Run example function
run_example() {
    local example=$1
    echo -e "\n${YELLOW}Running: $example${NC}\n"
    echo -e "${GREEN}======================================${NC}"
    python3 "$example"
    echo -e "${GREEN}======================================${NC}\n"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice [0-5]: " choice

    case $choice in
        1)
            run_example "ClaudeAgent/basic.py"
            ;;
        2)
            run_example "ClaudeAgent/codex-mcp.py"
            ;;
        3)
            run_example "OpenAIAgent/gpt5.py"
            ;;
        4)
            run_example "OpenAIAgent/gpt5-codex.py"
            ;;
        5)
            echo -e "\n${YELLOW}Running all examples...${NC}\n"
            run_example "ClaudeAgent/basic.py"
            run_example "ClaudeAgent/codex-mcp.py"
            run_example "OpenAIAgent/gpt5.py"
            run_example "OpenAIAgent/gpt5-codex.py"
            echo -e "${GREEN}All examples completed!${NC}\n"
            ;;
        0)
            echo -e "${GREEN}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}\n"
            ;;
    esac

    read -p "Press Enter to continue..."
    echo ""
done
