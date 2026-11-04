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
2. **Stay on a tool while it works.** Keep using the same tool for every search, including follow-up and parallel searches, until it reports a rate limit, exhausted quota, or runtime error (rule 3). Do not switch tools for variety, to compare results, or because a result was weak. Reword the query instead.
3. **Move on only on rate limit, quota, or runtime error.** Go to the next tool when the current one fails with:
   - a rate limit or quota error: HTTP 429 or 402, or a message saying rate limit, too many requests, quota exceeded, credits exhausted, or usage limit reached;
   - a runtime error: HTTP 5xx (500, 502, 503, 504), a timeout, or a connection failure.

   Retry the same query on the next tool. An error caused by your own call (bad input, HTTP 400 or 422) is not a reason to switch: fix the call and keep the tool.
4. **Remember what you learned for the session.** After a tool reports a rate limit or quota error, do not call it again in this session. After a runtime error, use the next tool for that query only, and try the failed tool again on the next search. If it fails with a runtime error on two searches in a row, treat it as exhausted for the rest of the session. For every later search, start from the first tool in the table that is neither exhausted nor unavailable.
5. **Built-in `WebSearch` is last.** Call it only when every tool above is unavailable or exhausted. Once you are on it, stay on it for the rest of the session.
6. **Do not mention the rotation** to the user unless every tool is exhausted and the built-in `WebSearch` also fails, or the user asks.
