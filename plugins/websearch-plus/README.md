# websearch-plus Plugin

Cuts the cost of Claude Code's built-in `WebSearch` by bundling four remote-hosted web-search MCP servers that have a free plan, and by telling Claude to use them first.

## Overview

The plugin has two parts:

1. **MCP servers** (`.mcp.json`): Exa, Parallel, Tavily and You.com, each authenticated with an API key read from an environment variable.
2. **SessionStart hook**: injects [`hooks/search-instruction.md`](hooks/search-instruction.md) into the session context (on `startup`, `resume`, `clear` and `compact`). It tells Claude to search with these tools in a fixed order, to keep using one tool until it hits a rate limit or quota, then move to the next, and to use the built-in `WebSearch` only as the final fallback.

### Providers

Selected from [Exa's roundup of web search MCP servers](https://exa.ai/blog/best-web-search-mcp-servers) and [Keirolabs' 2026 web search API comparison](https://keirolabs.cloud/blog/web-search-apis-for-agents-2026): each has a hosted MCP endpoint, API-key authentication, and a free plan. Endpoints and tool names were checked against each provider's own docs.

| Order | Server name | Endpoint | Env var | Search tool | Free plan |
| --- | --- | --- | --- | --- | --- |
| 1 | `wsplus-exa` | `https://mcp.exa.ai/mcp` | `MCP_EXA_API_KEY` | `web_search_exa` | 20,000 searches/month ([Keirolabs](https://keirolabs.cloud/blog/web-search-apis-for-agents-2026)) |
| 2 | `wsplus-parallel` | `https://search.parallel.ai/mcp` | `MCP_PARALLEL_API_KEY` | `web_search` | 5,000 requests/month plus $5 credit |
| 3 | `wsplus-tavily` | `https://mcp.tavily.com/mcp/` | `MCP_TAVILY_API_KEY` | `tavily_search` | 1,000 credits/month |
| 4 | `wsplus-youcom` | `https://api.you.com/mcp` | `MCP_YOUCOM_API_KEY` | `you-search` | 100 queries/day plus $100 credit |
| 5 | built-in | n/a | n/a | `WebSearch` | final fallback |

Free-plan figures are as reported by the sources above and may change; check each provider's pricing page.

Considered and left out: Linkup (free access is a trial, not a plan), Firecrawl (scrape-first, search is secondary), Brave and Serper (local MCP only), Perplexity (no free tier).

## Configuration

The servers are streamable HTTP MCP servers. Each key is read from its environment variable at connect time, so no secret is committed:

```json
{
  "mcpServers": {
    "wsplus-exa": {
      "type": "http",
      "url": "https://mcp.exa.ai/mcp",
      "headers": { "x-api-key": "${MCP_EXA_API_KEY}" }
    }
  }
}
```

(Only one server is shown. See [`.mcp.json`](.mcp.json) for all four.)

You do not need all four keys. A server whose variable is unset is not loaded, and the instruction tells Claude to skip tools that are not in its tool list.

## Setup

1. Get an API key from each provider you want to use:
   - Exa: https://dashboard.exa.ai/api-keys
   - Parallel: https://platform.parallel.ai
   - Tavily: https://app.tavily.com
   - You.com: https://you.com/platform
2. Export the keys in your shell environment (for example in `~/.zshrc`):

   ```sh
   export MCP_EXA_API_KEY="..."
   export MCP_PARALLEL_API_KEY="..."
   export MCP_TAVILY_API_KEY="..."
   export MCP_YOUCOM_API_KEY="..."
   ```

3. Install the plugin (see below) and restart Claude Code so the variables are in scope.

## Permissions

The server names share the `wsplus-` prefix so they are easy to allow in Claude Code settings. MCP tools are named `mcp__plugin_websearch-plus_<server>__<tool>`, so add the search tools to `permissions.allow` in `settings.json` to avoid approval prompts:

```json
{
  "permissions": {
    "allow": [
      "mcp__plugin_websearch-plus_wsplus-exa__web_search_exa",
      "mcp__plugin_websearch-plus_wsplus-parallel__web_search",
      "mcp__plugin_websearch-plus_wsplus-tavily__tavily_search",
      "mcp__plugin_websearch-plus_wsplus-youcom__you-search"
    ]
  }
}
```

## Installation

```
/plugin marketplace add Devrisetech/claude-code-engineering-assembly
/plugin install websearch-plus@engineering-assembly
```

## Usage

Nothing to invoke. Ask Claude anything that needs a web search and it uses the tools in the order above. Verify the servers are connected with `/mcp`, and the hook with `/hooks`.

To change the order or the rules, edit [`hooks/search-instruction.md`](hooks/search-instruction.md).

## Requirements

- **Linux or macOS.** The `SessionStart` hook runs a Bash script. Windows is not supported.
- At least one API key from the table above, exposed through its `MCP_*` environment variable.
- Network access to the provider endpoints.
