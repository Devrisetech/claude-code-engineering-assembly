# websearch-plus Plugin

Cuts the cost of Claude Code's built-in `WebSearch` by bundling two remote-hosted web-search MCP servers that have a free plan, and by telling Claude to use them first.

## Overview

The plugin has two parts:

1. **MCP servers** (`.mcp.json`): Tavily and You.com, each authenticated with an API key read from an environment variable.
2. **SessionStart hook**: injects [`hooks/search-instruction.md`](hooks/search-instruction.md) into the session context (on `startup`, `resume`, `clear` and `compact`). It tells Claude to search with these tools in a fixed order, to keep using one tool until it hits a rate limit, a quota, or a runtime error (such as HTTP 500), then move to the next, and to use the built-in `WebSearch` only as the final fallback.

### Providers

The provider list is the maintainers' own choice: each has a hosted MCP endpoint, API-key authentication, and a free plan. Endpoints and tool names come from each provider's own docs. Free-plan limits change, so check each provider's pricing page.

| Order | Server name | Endpoint | Env var | Search tool |
| --- | --- | --- | --- | --- |
| 1 | `wsplus-tavily` | `https://mcp.tavily.com/mcp/` | `MCP_TAVILY_API_KEY` | `tavily_search` |
| 2 | `wsplus-youcom` | `https://api.you.com/mcp` | `MCP_YOUCOM_API_KEY` | `you-search` |
| 3 | built-in | n/a | n/a | `WebSearch` (final fallback) |

### Choosing providers

You decide which providers are used. Set the API key only for the providers you want: a server whose variable is unset is not loaded, and Claude skips it. The order above is fixed in [`hooks/search-instruction.md`](hooks/search-instruction.md).

## Configuration

The servers are streamable HTTP MCP servers. Each key is read from its environment variable at connect time, so no secret is committed:

```json
{
  "mcpServers": {
    "wsplus-tavily": {
      "type": "http",
      "url": "https://mcp.tavily.com/mcp/",
      "headers": { "Authorization": "Bearer ${MCP_TAVILY_API_KEY}" }
    }
  }
}
```

(Only one server is shown. See [`.mcp.json`](.mcp.json) for both.)

## Setup

1. Get an API key from each provider you want to use:
   - Tavily: https://app.tavily.com
   - You.com: https://you.com/platform
2. Export the keys in your shell environment (for example in `~/.zshrc`):

   ```sh
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
