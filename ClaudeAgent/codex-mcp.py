import os
import anyio

from claude_agent_sdk import (
    AssistantMessage,
    ClaudeAgentOptions,
    ResultMessage,
    TextBlock,
    query,
)

async def with_codex_mcp_example():
    """Use Codex MCP tools from Claude Agent SDK."""
    print("=== Codex MCP Example ===")

    options = ClaudeAgentOptions(
        # Approve the whole Codex server so both tools are usable
        # (codex() and codex-reply()).
        allowed_tools=["mcp__codex"],

        # Register Codex as an external stdio MCP server
        mcp_servers={
            "codex": {
                "type": "stdio",
                "command": "npx",
                "args": [
                    "-y", "@openai/codex",
                    "-c", 'model_provider="amd-openai"',
                    "mcp-server"
                ]
            }
        },
    )

    # Ask Claude to use Codex for a concrete task
    prompt = (
        "Use codex mcp to write a c++ helloworld"
    )

    async for message in query(prompt=prompt, options=options):
        if isinstance(message, AssistantMessage):
            for block in message.content:
                if isinstance(block, TextBlock):
                    print(f"Claude: {block.text}")
        elif isinstance(message, ResultMessage) and message.total_cost_usd > 0:
            print(f"\nCost: ${message.total_cost_usd:.4f}")
    print()

async def main():
    await with_codex_mcp_example()

if __name__ == "__main__":
    anyio.run(main)