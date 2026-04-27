# Examples

Reference apps that use ArcKit. Each is self-contained and runnable against Arc testnet.

| Example | Stack | What it shows |
|---|---|---|
| [`python-lifecycle/`](./python-lifecycle) | Python + `arckit` | Full ERC-8183 lifecycle: createJob → setBudget → fund → submit → complete |
| [`langchain-tool/`](./langchain-tool) | Python + LangChain + `arckit` | Wraps ArcKit operations as LangChain Tools so any LLM agent can hire other agents on Arc |

For TypeScript users: `npx create-arc-app my-app` scaffolds a working project — see [`packages/create-arc-app`](../packages/create-arc-app).

For a production reference: see [arc-agent-commerce](https://github.com/Ridwannurudeen/arc-agent-commerce) — a deployed multi-stage pipeline orchestrator built on top of ArcKit's primitives.
