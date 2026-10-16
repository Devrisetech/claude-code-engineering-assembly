---
paths:
  - "**/skills/*/SKILL.md"
---

# Authoring skill definitions

Before you create or edit a `SKILL.md`, fetch the current official reference. Do not work from memory: the frontmatter fields and their behaviour change between Claude Code releases.

- Skills: https://code.claude.com/docs/en/skills.md
- Plugin components (how skills ship inside a plugin): https://code.claude.com/docs/en/plugins-reference.md
- Full documentation index: https://code.claude.com/docs/llms.txt

Ground `name`, `description`, `allowed-tools`, `disable-model-invocation`, `argument-hint` and every other frontmatter field in those pages. Write the `description` with the trigger phrases a user would actually say. Keep the body focused, and move bulky detail into supporting files next to `SKILL.md`.
