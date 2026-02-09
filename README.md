# Agent Template

A starter template for building AI agents using Claude Agent SDK and OpenAI Agent SDK with AMD LLM Gateway.

## Prerequisites

- **AMD LLM Gateway API Key**: You must have an AMD LLM Gateway API key
- **Python 3**: Required for running the agent examples
- **Bash shell**: For running the setup script

## Quick Start

### 1. Export your API key

```bash
export AMD_LLM_API_KEY=<Your Key>
```

### 2. Run the setup script

```bash
./setup.sh
```

This will automatically:
- Install nvm (if not already installed)
- Install Node.js LTS
- Install `@anthropic-ai/claude-code` globally
- Install `@openai/codex` globally
- Copy `codex.config` to `~/.codex/config.toml`
- Copy `CLAUDE.md` to `~/.claude/`
- Set up environment variables in your shell configuration
- Install Python SDKs (`openai-agents` and `claude-agent-sdk`)

### 3. Source your shell configuration

```bash
source ~/.bashrc  # or ~/.zshrc if using zsh
```

### 4. Run example agents

```bash
./run-examples.sh
```

This interactive script allows you to run:
- Claude Agent SDK examples (basic and with Codex MCP)
- OpenAI Agent SDK examples (GPT-5 and GPT-5 Codex)

## What's Included

### Configuration Files

- **`.mcp.json`**: MCP server configuration for codex, context7, and playwright
- **`codex.config`**: Codex configuration for AMD LLM Gateway
- **`CLAUDE.md`**: Claude Code configuration (copied to `~/.claude/` for all projects)

### Example Agents

#### Claude Agent SDK (`ClaudeAgent/`)
- **`basic.py`**: Simple examples of using Claude Agent SDK
- **`codex-mcp.py`**: Using Codex MCP tools with Claude Agent SDK

#### OpenAI Agent SDK (`OpenAIAgent/`)
- **`gpt5.py`**: GPT-5 agent example using AMD LLM Gateway
- **`gpt5-codex.py`**: GPT-5 Codex agent example using AMD LLM Gateway

## Using .mcp.json in Your Projects

To use the MCP servers (codex, context7, playwright) in your own projects:

```bash
cp .mcp.json /path/to/your/project/
```

## Environment Variables

The setup script configures these environment variables:

- `ANTHROPIC_API_KEY`: Your AMD LLM Gateway key (from `AMD_LLM_API_KEY`)
- `ANTHROPIC_CUSTOM_HEADERS`: Subscription key header
- `ANTHROPIC_BASE_URL`: `https://llm-api.amd.com/Anthropic`
- `ANTHROPIC_MODEL`: `claude-opus-4.6`
- `LLM_GATEWAY_KEY`: Your AMD LLM Gateway key (from `AMD_LLM_API_KEY`)

## Customizing Your Agents

All example files use the `AMD_LLM_API_KEY` environment variable, so you don't need to hardcode keys. You can use these examples as templates for your own agents.

## Troubleshooting

### "AMD_LLM_API_KEY environment variable is not set"
Make sure you've exported your API key:
```bash
export AMD_LLM_API_KEY=<Your Key>
```

### "Python 3 is not installed"
Install Python 3 for your operating system before running the setup script.

### pip installation fails
The script tries to use `--break-system-packages` flag. If you're using a virtual environment, this shouldn't be necessary. Consider creating a venv:
```bash
python3 -m venv venv
source venv/bin/activate
pip install openai-agents claude-agent-sdk
```

## Project Structure

```
.
├── .mcp.json                 # MCP server configuration
├── CLAUDE.md                 # Claude Code configuration
├── codex.config              # Codex configuration
├── setup.sh                  # Automated setup script
├── run-examples.sh           # Interactive example runner
├── ClaudeAgent/
│   ├── basic.py              # Basic Claude Agent examples
│   └── codex-mcp.py          # Claude Agent with Codex MCP
└── OpenAIAgent/
    ├── gpt5.py               # GPT-5 agent example
    └── gpt5-codex.py         # GPT-5 Codex agent example
```

## Usage Instructions

### Using Claude Code in Any Project

After running the setup script, you can use `claude` in **ANY project folder** you want.

To enable the 3 common MCP servers (context7, codex, playwright) in your project:

```bash
cp .mcp.json /path/to/your/project/
```

Then navigate to your project folder and run:

```bash
claude
```

### Using Codex Agent in Any Folder

You can use the Codex agent in **ANY folder** with:

```bash
codex -c model_provider="amd-openai"
```

This allows you to leverage the Codex agent anywhere without additional configuration.

## Next Steps

1. **Test the SDKs**: Run the example agents to verify your setup and see the SDKs in action
   ```bash
   ./run-examples.sh
   ```
   This will let you test both Claude Agent SDK and OpenAI Agent SDK examples interactively.

2. Explore the example agents to understand the SDK usage
3. Modify the examples to fit your use case
4. Create your own agents using the provided templates
5. Use `claude` or `codex` in any of your projects

## Resources

- [Claude Agent SDK Documentation](https://github.com/anthropics/claude-agent-sdk-python)
- [OpenAI Agents Documentation](https://github.com/openai/openai-agents-python)
