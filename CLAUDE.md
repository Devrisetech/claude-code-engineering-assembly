# CLAUDE.md

A public Claude Code plugin marketplace owned by Devrise Technology. It contains a marketplace index and plugins. Each plugin ships whichever components it needs: skills, agents, hooks, MCP server definitions, and tests. There is no build system. Content is JSON, Markdown, and Bash. The `git` plugin has a Bash test suite, and `.github/workflows/` holds the superproject-notification workflow.

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Guideline

### Structure

```
.claude-plugin/
  marketplace.json            # Marketplace index listing all plugins
.github/                      # Issue/PR templates, CODEOWNERS, workflows
plugins/<plugin-name>/
  .claude-plugin/plugin.json  # Plugin manifest (name, description, version, author, homepage, repository, license)
  .mcp.json                   # MCP server definitions (optional)
  agents/<agent-name>.md      # Subagent definitions (optional)
  hooks/hooks.json            # Event hooks + scripts (optional)
  skills/<skill-name>/
    SKILL.md                  # Skill definition (frontmatter + instruction body)
  tests/                      # Test suite (optional; run.sh entry point)
  README.md                   # Plugin documentation
README.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md, LICENSE
```

### Adding a plugin

1. Create `plugins/<plugin-name>/.claude-plugin/plugin.json` with `name`, `description`, `version`, `author`, `homepage`, `repository`, `license`. Copy `author`, `repository` and `license` from an existing plugin, and set `homepage` to `https://github.com/Devrisetech/claude-code-engineering-assembly/tree/main/plugins/<plugin-name>`.
2. Add the components under `plugins/<plugin-name>/` (skills, agents, hooks, `.mcp.json`).
3. Write `plugins/<plugin-name>/README.md`: overview, configuration, requirements, installation.
4. Register the plugin in `.claude-plugin/marketplace.json` under `"plugins"`. Apply every update in [README consistency](#readme-consistency).

### Marketplace registration

`.claude-plugin/marketplace.json` must list every plugin. The `source` field is a relative path from the marketplace root to the plugin directory. Each entry's `description` is copied verbatim from that plugin's `plugin.json`, which is the single source.

### Ownership & metadata

- Every `author` (plugin.json) and `owner` (marketplace.json) is `{"name": "Devrise Technology", "email": "hello@devrisetech.com"}`.
- Every repository URL uses `Devrisetech/claude-code-engineering-assembly`. Never use a personal account.
- Install instructions use the owner/repo form: `/plugin marketplace add Devrisetech/claude-code-engineering-assembly`.
- `LICENSE` names both copyright holders, Duy Lam and Devrise Technology. Keep both lines.

### README consistency

The root `README.md` is the public face of the repo. Keep it aligned with the code:

- **Any plugin add, remove, rename, or description change** updates, in the same change:
  1. the `.claude-plugin/marketplace.json` entry
  2. the root README **Plugins** table, plus the **Requirements** list when its dependencies change
  3. the plugin's own `README.md`
- **Section contract.** The root README keeps these sections in this order: badges and description, Table of contents, About, Plugins, Requirements, Installation, Repository structure, Development, Contributing, Support, Maintainers, License. Add a section only for genuinely new top-level content, and update the table of contents when you do.
- **Link, don't duplicate.** Contribution workflow lives in `CONTRIBUTING.md`, conduct rules in `CODE_OF_CONDUCT.md`, vulnerability reporting in `SECURITY.md`. The README links to them.
- **Commands stay true.** When a validation or test command changes, update README **Development**, `CONTRIBUTING.md`, and the [Development model](#development-model) below together.
- Use relative links for in-repo files.

### Development model

1. Validate the marketplace and every manifest: `claude plugin validate .` (and `claude plugin validate plugins/<name>` for one plugin).
2. When touching the `git` plugin, run its suite: `bash plugins/git/tests/run.sh`.
3. Install locally and exercise the change:

   ```
   /plugin marketplace add ./
   /plugin install <plugin-name>@engineering-assembly
   ```

   Then invoke the skill, agent, or hook and check its behaviour matches the plugin's README and `SKILL.md`.

## Workflow

- **Version bump on plugin change:** any edit to a published plugin under `plugins/<name>/` must bump
  the `version` in that plugin's `plugins/<name>/.claude-plugin/plugin.json`. One logical change = one
  bump (semver: patch for fixes, minor for new capability, major for breaking layout/manifest change).
- **Commit each unit of work:** when a unit of work is complete, make a git commit. Use the
  `commit-commands:commit` skill (or `commit-commands:commit-push-pr` when a PR is wanted) rather than
  raw `git commit`. Messages follow Conventional Commits (`feat(git): …`, `fix(marketplace): …`).
