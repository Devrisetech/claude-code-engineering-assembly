# CLAUDE.md

A public Claude Code plugin marketplace owned by Devrise Technology. It contains a marketplace index and plugins. Each plugin ships whichever components it needs: skills, agents, hooks, MCP server definitions, and tests. There is no build system. Content is JSON, Markdown, and Bash. The `git` plugin has a Bash test suite, and `.github/workflows/` holds the superproject-notification workflow.

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Guideline

### Structure

```
.claude-plugin/
  marketplace.json            # Marketplace index listing all plugins
.github/                      # Issue/PR templates, workflows
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
- **Platform support.** A plugin that runs scripts, from a hook or invoked by a skill or agent, supports only Linux and macOS. Mark it `**Linux, macOS only**` in the README **Plugins** table's Platforms column, list it in the warning under that table and in **Requirements**, and put the same warning in the plugin README's **Requirements** section. A plugin without scripts is `Any`.
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

<!-- BEGIN agent-plugin-harness -->
## Claude Code plugin review

This repo holds Claude Code plugins, and its PRs are gated by
`.github/workflows/plugin-harness.yml`. The `ai-review-status` check in that workflow passes only
when the PR head commit carries the commit status **`ci/ai/plugin-review`**. You post that status
when you finish the review below. Run the review before you report plugin work as done, and again
after every push that changes a plugin.

Plugin and marketplace roots in this repo:

- `.`
- `plugins/*`

### 1. Identify the in-progress plugins

Work out which plugins this session is working on:

- the files you created or edited in this session;
- `git diff --name-only "origin/$BASE...HEAD"`, where `BASE` is the PR base branch
  (`gh pr view --json baseRefName -q .baseRefName`) or the default branch when no PR is open;
- `git status --porcelain` for uncommitted changes.

Map each changed file to its nearest plugin root, the closest parent directory that has
`.claude-plugin/plugin.json` under the roots above. A changed `.claude-plugin/marketplace.json`
puts that marketplace in scope. If nothing maps to a plugin, stop here: there is nothing to review
and no status to post.

### 2. Review each plugin with `plugin-dev:` agents and skills

For each plugin in scope:

- Run `claude plugin validate --strict <plugin-root>`. Every error-level finding is **critical**.
- Delegate an audit to the `plugin-dev:plugin-validator` agent. Do this for every plugin.
- If skills changed, delegate to the `plugin-dev:skill-reviewer` agent.
- For other changed components, load the matching skill and check the changes against it:
  `plugin-dev:agent-development` for agents, `plugin-dev:command-development` for commands,
  `plugin-dev:hook-development` for hooks, `plugin-dev:mcp-integration` for MCP servers,
  `plugin-dev:plugin-settings` for plugin settings, and `plugin-dev:plugin-structure` for layout
  and the manifest.

Give every finding one severity:

| Severity | Meaning |
| --- | --- |
| **blocker** | The plugin fails to load, or a component is broken or unsafe. |
| **critical** | A validation error, or a component that won't trigger or run as intended. |
| **major** | A real defect that does not break the plugin but should be fixed. |
| **minor** / **info** | Style, wording, suggestions. |

### 3. Post the commit status `ci/ai/plugin-review`

The status goes on the commit GitHub has. Push first, then use the pushed head:
`SHA=$(git rev-parse HEAD)`, which must equal `git rev-parse @{upstream}`.

1. **Pick a credential, or stop.** If `gh auth status` succeeds, use `gh`. Otherwise, if
   `GH_TOKEN` or `GITHUB_TOKEN` is set, use the REST API with `curl`. If neither works, **stop**:
   tell the user that the status could not be posted, and why. Do not mark the review as done.
2. **Choose the state:** `failure` if any finding is **critical or blocker**, `success` otherwise.
3. **Post it.** Posting the same context again replaces the earlier status, so this both creates
   and edits it. The `description` must be at most 140 characters; summarize the counts there, e.g.
   `0 critical, 2 major, 3 minor — plugins: foo, bar`.

   ```bash
   REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)   # or owner/repo from the remote URL
   # With gh:
   gh api "repos/$REPO/statuses/$SHA" -f state="$STATE" \
     -f context=ci/ai/plugin-review -f description="$DESCRIPTION"
   # With a token:
   curl -fsS -X POST -H "Authorization: Bearer ${GH_TOKEN:-$GITHUB_TOKEN}" \
     -H "Accept: application/vnd.github+json" \
     "https://api.github.com/repos/$REPO/statuses/$SHA" \
     -d "$(jq -n --arg s "$STATE" --arg d "$DESCRIPTION" \
           '{state:$s, context:"ci/ai/plugin-review", description:$d}')"
   ```

4. **Re-run the gate.** If a PR is open for the branch, its `ai-review-status` job ran before the
   status existed and failed. Re-run it with `gh`:

   ```bash
   RUN=$(gh run list --workflow plugin-harness.yml --commit "$SHA" --limit 1 --json databaseId -q '.[0].databaseId')
   [ -n "$RUN" ] && gh run rerun "$RUN" --failed
   ```

### 4. Report

Tell the user:

- which plugins you reviewed and the findings for each, grouped by severity;
- the state you posted and the commit it is on, or why you could not post it.

Fix critical and blocker findings only when the user asks you to. After a fix and a push, run the
review again so the status is on the new commit.
<!-- END agent-plugin-harness -->
