# Contributing

Thanks for your interest in improving the Claude Code Engineering Assembly. This guide shows you how to report problems, propose changes, and get a pull request merged.

Everyone taking part in this project is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Reporting bugs and requesting features

- To report a bug or request a feature, [open an issue](https://github.com/Devrisetech/claude-code-engineering-assembly/issues/new/choose) using the matching form. Name the plugin and its version.
- To report a security vulnerability, follow [SECURITY.md](SECURITY.md). Do not open a public issue.
- To propose a large change, such as a new plugin or a breaking change to an existing one, open an issue first so the design can be agreed before you write code.

## Setting up

You need [Claude Code](https://code.claude.com/docs/en/overview), `git` and `bash`. Fork the repository, clone your fork, and create a branch:

```bash
git clone https://github.com/<you>/claude-code-engineering-assembly.git
cd claude-code-engineering-assembly
git checkout -b feat/<short-description>
```

To try your working copy, add it as a local marketplace in a Claude Code session and install the plugin you are changing:

```
/plugin marketplace add ./
/plugin install <plugin-name>@engineering-assembly
```

Edits to a locally added marketplace take effect at the next session start, or right away when you run `/reload-plugins`.

## Making a change

The repository layout and the authoring rules live in [CLAUDE.md](CLAUDE.md). They apply to human and AI contributors alike. The rules that most often block a review:

- **Bump the plugin version.** Any change under `plugins/<name>/` bumps `version` in `plugins/<name>/.claude-plugin/plugin.json`, once per logical change: patch for fixes, minor for new capabilities, major for breaking changes.
- **Keep the indexes in sync.** If you add, remove, or rename a plugin, or change its description, update these in the same pull request:
  - `.claude-plugin/marketplace.json`, with the entry `description` copied verbatim from `plugin.json`
  - the **Plugins** table in [README.md](README.md)
  - the plugin's own `README.md`
- **Keep ownership metadata.** `author` is `Devrise Technology <hello@devrisetech.com>`, and repository URLs point at `Devrisetech/claude-code-engineering-assembly`.
- **Document behaviour.** A new or changed skill, agent, hook, or MCP server is described in the plugin's `README.md`.

## Checking your change

Run these before you push:

```bash
claude plugin validate .            # marketplace and every plugin manifest
bash plugins/git/tests/run.sh       # if you touched plugins/git
```

Both must pass. Then install the plugin from your local marketplace and exercise the change in a real session.

## Commits

Write commit messages in [Conventional Commits](https://www.conventionalcommits.org/) form, scoped to the plugin or area you changed:

```
feat(git): show branch and commit ids in launch-status
fix(marketplace): sync descriptions with plugin manifests
docs(readme): add requirements section
```

When a commit makes a design decision, say why in the body and name the alternative you rejected. Mark breaking changes with `!` and a `BREAKING CHANGE:` footer.

## Pull requests

1. Push your branch to your fork and open a pull request against `main`.
2. Fill in the pull request template: what changed, which plugins are affected, and the checks you ran.
3. Keep each pull request to one logical change. Unrelated fixes go in their own pull request.
4. A maintainer reviews it. Address the comments with new commits rather than force-pushing, so the review history stays readable.
5. Maintainers merge with a merge commit, which keeps your individual commits.

## Design history

`.claude/memory/decisions.md` and `.claude/memory/diary.md` record past design decisions and the work behind them. Read them before reworking an existing plugin, to see what was already tried and why.

## License

By contributing, you agree that your contributions are licensed under the repository's [MIT License](LICENSE).
