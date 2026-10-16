---
paths:
  - "**/agents/*.md"
---

# Authoring subagent definitions

Before you create or edit a subagent file, fetch the current official reference. Do not work from memory: the frontmatter fields and their behaviour change between Claude Code releases.

- Subagents: https://code.claude.com/docs/en/sub-agents.md
- Plugin components (how agents ship inside a plugin): https://code.claude.com/docs/en/plugins-reference.md
- Full documentation index: https://code.claude.com/docs/llms.txt

Ground `name`, `description`, `tools`, `model` and every other frontmatter field in those pages. Write the `description` so Claude knows when to delegate to the agent. Grant only the tools the agent needs.
