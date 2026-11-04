# Web search tool order

For any web search, use the tools below in the order listed. Use the built-in `WebSearch` tool only as the final fallback, because it is the costly option.

| Order | Tool | Provider |
| --- | --- | --- |
| 1 | `mcp__plugin_websearch-plus_wsplus-exa__web_search_exa` | Exa |
| 2 | `mcp__plugin_websearch-plus_wsplus-parallel__web_search` | Parallel |
| 3 | `mcp__plugin_websearch-plus_wsplus-tavily__tavily_search` | Tavily |
| 4 | `mcp__plugin_websearch-plus_wsplus-youcom__you-search` | You.com |
| 5 (final fallback) | `WebSearch` | Claude built-in |

## Rules

1. **Start at the top.** Use the first tool in the table that is available in this session. A tool is unavailable when it is not in your tool list (its API key is not set, or its server did not connect). Skip it silently, without retrying or telling the user.
2. **Stay on a tool while it works.** Keep using the same tool for every search, including follow-up and parallel searches, until it reports a rate limit or exhausted quota. Do not switch tools for variety, to compare results, or because a result was weak. Reword the query instead.
3. **Move on only on rate limit or quota.** Go to the next tool when the current one fails with HTTP 429 or 402, or with an error that says rate limit, too many requests, quota exceeded, credits exhausted, or usage limit reached. Retry the same query on the next tool. Any other error (bad input, timeout, a single server error) is not exhaustion: fix the call or retry once, then keep the tool.
4. **Remember exhaustion for the session.** After a tool reports a rate limit or quota error, do not call it again in this session. Start from the next tool in the table for every later search.
5. **Built-in `WebSearch` is last.** Call it only when every tool above is unavailable or exhausted. Once you are on it, stay on it for the rest of the session.
6. **Do not mention the rotation** to the user unless every tool is exhausted and the built-in `WebSearch` also fails, or the user asks.
