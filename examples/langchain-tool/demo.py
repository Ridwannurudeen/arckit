"""Demo: lightweight LLM agent that uses ArcKit tools to hire another agent on Arc.

Requires PRIVATE_KEY (Arc testnet, funded with USDC) and OPENAI_API_KEY in .env.
"""

import os
import sys

from dotenv import load_dotenv
from langchain.agents import AgentExecutor, create_tool_calling_agent
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI

from arckit_langchain import build_arc_tools

load_dotenv()

if not os.environ.get("PRIVATE_KEY") or os.environ["PRIVATE_KEY"] == "0x":
    sys.exit("Set PRIVATE_KEY in .env (Arc testnet, funded with USDC)")
if not os.environ.get("OPENAI_API_KEY"):
    sys.exit("Set OPENAI_API_KEY in .env")

tools = build_arc_tools(
    private_key=os.environ["PRIVATE_KEY"],
    network="testnet",
    rpc_url=os.environ.get("RPC_URL"),
)

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)
prompt = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            "You are an autonomous economic agent on Arc Network. You can create jobs, "
            "fund them, submit deliverables, and accept work using the provided tools. "
            "Always inspect job state with get_arc_job before acting on it.",
        ),
        ("human", "{input}"),
        ("placeholder", "{agent_scratchpad}"),
    ]
)
agent = create_tool_calling_agent(llm, tools, prompt)
executor = AgentExecutor(agent=agent, tools=tools, verbose=True)

# Self-roleplay so the demo runs with a single funded wallet.
me = "0xYourAddress"  # the agent will discover this on the fly
result = executor.invoke(
    {
        "input": (
            "Set up a tiny demo job on Arc testnet. Use the same wallet as both provider "
            "and evaluator (you'll need to discover the wallet address by reading job state "
            "after creation if needed). Description: 'demo: smoke test'. Budget: 0.01 USDC. "
            "Run the full lifecycle and report the final status."
        )
    }
)
print("\n=== Result ===")
print(result["output"])
