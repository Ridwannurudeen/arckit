# create-arc-app

Scaffold a working ERC-8183 agent commerce app on [Arc](https://arc.network) in one command.

## Usage

```bash
npx create-arc-app my-agent-app
cd my-agent-app
pnpm install
pnpm dev
```

You're prompted to pick a template:

| Template | Includes |
|---|---|
| `minimal` | TypeScript + viem + `@arckit/sdk` — single-script agent that creates and completes one ERC-8183 job |
| `fullstack` | Next.js frontend + Foundry contracts + `@arckit/sdk` + working client + provider + evaluator triad on Arc testnet |
| `agent-only` | Python + `arckit` + LangChain — autonomous provider agent that listens for jobs and submits work |

## License

MIT
