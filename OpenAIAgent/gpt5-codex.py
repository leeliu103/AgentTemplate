import asyncio
import os

from openai import AsyncAzureOpenAI

from agents import Agent, OpenAIResponsesModel, Runner, function_tool, set_tracing_disabled

url = 'https://llm-api.amd.com/OpenAI'
api_key = os.environ.get('AMD_LLM_API_KEY')
if not api_key:
    raise ValueError("AMD_LLM_API_KEY environment variable is not set")
headers = {
    'Ocp-Apim-Subscription-Key': api_key
}
model_api_version = '2025-04-01-preview'
model_id = 'dvue-aoai-001-gpt-5.1-codex-max'
model_name = 'gpt-5.1-codex-max'

client = AsyncAzureOpenAI(
    api_key='dummy',
    api_version=model_api_version,
    base_url=url,
    default_headers=headers
    )

# Update the base url to use the OpenAI deployments API.
#client.base_url = '{0}/openai/deployments/{1}'.format(url, model_id)

set_tracing_disabled(disabled=True)

@function_tool
def get_weather(city: str):
    print(f"[debug] getting weather for {city}")
    return f"The weather in {city} is sunny."


async def main():
    # This agent will use the custom LLM provider
    agent = Agent(
        name="Assistant",
        instructions="You only respond in haikus.",
        model=OpenAIResponsesModel(model=model_name, openai_client=client),
        tools=[get_weather],
    )

    result = await Runner.run(agent, "What's the weather in Tokyo?")
    print(result.final_output)


if __name__ == "__main__":
    asyncio.run(main())