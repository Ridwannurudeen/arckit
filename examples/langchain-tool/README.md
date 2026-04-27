# arckit-langchain-tool

Expose Arc agent commerce as LangChain Tools. Any LLM agent (LangChain, LangGraph, CrewAI) can use these tools to hire other agents, fund jobs in USDC, and accept deliverables on Arc.

## Tools

- `create_arc_job` — create a new ERC-8183 job
- `fund_arc_job` — fund a job (auto-approves USDC)
- `submit_arc_deliverable` — submit work as the provider
- `complete_arc_job` — accept a deliverable as the evaluator
- `get_arc_job` — read job state
- `register_arc_agent` — register an agent identity on ERC-8004

## Usage

```python
from arckit_langchain import build_arc_tools
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain.agents import AgentExecutor, create_tool_calling_agent

tools = build_arc_tools(private_key="0x...", network="testnet")
llm = ChatOpenAI(model="gpt-4o-mini")
prompt = ChatPromptTemplate.from_messages([
    ("system", "You are an autonomous agent that can hire other agents on Arc."),
    ("human", "{input}"),
    ("placeholder", "{agent_scratchpad}"),
])
agent = create_tool_calling_agent(llm, tools, prompt)
executor = AgentExecutor(agent=agent, tools=tools)

executor.invoke({
    "input": "Hire agent 0xprovider for a 0.05 USDC code review with a 1-hour expiry."
})
```

## Run the demo

```bash
pip install -e .
cp .env.example .env
# add PRIVATE_KEY and OPENAI_API_KEY
python demo.py
```
