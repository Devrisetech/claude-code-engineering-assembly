# Claude Code Engineering Assembly

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code plugin marketplace](https://img.shields.io/badge/Claude%20Code-plugin%20marketplace-d97757.svg)](https://code.claude.com/docs/en/plugin-marketplaces)

A [Claude Code](https://code.claude.com) plugin marketplace of software-engineering workflow plugins, maintained by [Devrise Technology](https://github.com/Devrisetech). It covers requirement validation and QA automation, git housekeeping at session start, and ready-made MCP server bundles for Context7 and Atlassian.

## Table of contents

- [About](#about)
- [Plugins](#plugins)
- [Requirements](#requirements)
- [Installation](#installation)
- [Repository structure](#repository-structure)
- [Development](#development)
- [Contributing](#contributing)
- [Support](#support)
- [Maintainers](#maintainers)
- [License](#license)

## About

Engineering teams lose time on the same few things. They start work before a requirement is clear. They ship without anyone driving the change through the app. They open a session on stale branches or detached submodules. And they wire the same MCP servers into every project by hand. Each plugin in this marketplace takes one of those problems away, so every engineer on the team starts from the same baseline, installed with one command and kept up to date through the marketplace.

## Plugins

| Plugin | Category | What it does |
| --- | --- | --- |
| [implementation](plugins/implementation) | development | Validates a requirement (bug, story, or task) for completeness. Runs manual test cases on web or Android (`adb`) through the `automation-expert` agent. Retrieves Jira tickets and posts results back to them. |
| [git](plugins/git) | development | Fetches, prunes, and fast-forwards the branch and its top-level submodules at `SessionStart`. Fast-forward only, never fails a session. Adds `launch-status` and `recap` skills. |
| [context7](plugins/context7) | development | Bundles the [Context7](https://context7.com) MCP server for up-to-date, version-specific library documentation. |
| [atlassian-sso](plugins/atlassian-sso) | development | Bundles the Atlassian Remote MCP Server (Rovo) for Jira, Confluence, Jira Service Management, Bitbucket, and Compass, with OAuth 2.1 SSO login. |
| [atlassian-api-token](plugins/atlassian-api-token) | development | The same Atlassian Remote MCP Server, authenticated with a personal API token (Basic auth) for headless or CI use. |

Each plugin's own README documents its skills, configuration, and requirements.

> [!IMPORTANT]
> Make sure you trust a plugin before installing or using it. Hooks run shell commands on your machine, and MCP servers receive the credentials you configure. Review each plugin's README for what it runs and which tools it uses.

## Requirements

- [Claude Code](https://code.claude.com/docs/en/overview) with plugin support.
- Per-plugin extras:
  - **git**: `git` and `bash` 3.2 or newer. `jq` is optional. `gh` is optional, and only the `recap` skill's pull-request section uses it.
  - **implementation**: `adb` and an emulator or device for Android test runs. The Jira skills need two things: a connected Jira MCP integration, such as either `atlassian-*` plugin, and `MCP_ATLASSIAN_ACCOUNT_USERNAME` / `MCP_ATLASSIAN_ACCOUNT_API_TOKEN` for attachment transfer.
  - **context7**: a Context7 API key in `MCP_CONTEXT7_API_KEY`.
  - **atlassian-sso**: an Atlassian Cloud account and a browser for the OAuth login.
  - **atlassian-api-token**: `base64(email:api_token)` in `MCP_ATLASSIAN_BASE64_ENCODED_EMAIL_AND_API_TOKEN`.

## Installation

Add the marketplace in a Claude Code session:

```
/plugin marketplace add Devrisetech/claude-code-engineering-assembly
```

Install a plugin by its name and the marketplace name, `engineering-assembly`:

```
/plugin install implementation@engineering-assembly
```

You can also browse and install plugins from the `/plugin` menu. From a shell, the same commands are `claude plugin marketplace add Devrisetech/claude-code-engineering-assembly` and `claude plugin install <plugin>@engineering-assembly`.

## Repository structure

```
claude-code-engineering-assembly/
├── .claude-plugin/
│   └── marketplace.json        # Marketplace index (lists every plugin)
├── .github/                    # Issue/PR templates, CODEOWNERS, workflows
└── plugins/
    └── <plugin-name>/
        ├── .claude-plugin/
        │   └── plugin.json     # Plugin manifest (name, version, author)
        ├── .mcp.json           # MCP server definitions (optional)
        ├── agents/             # Subagent definitions (optional)
        ├── hooks/              # Event hooks (optional)
        ├── skills/             # Skill definitions (optional)
        ├── tests/              # Test suite (optional)
        └── README.md           # Plugin documentation
```

A plugin ships only the components it needs:
- `implementation` provides skills and an agent.
- `git` provides hooks, skills, and a test suite.
- `context7` and the `atlassian-*` plugins are thin wrappers around an MCP server.

## Development

Validate the marketplace and every plugin manifest:

```bash
claude plugin validate .
```

Run the git plugin's test suite (no network needed):

```bash
bash plugins/git/tests/run.sh
```

To try your changes, add your local checkout as a marketplace with `/plugin marketplace add ./` and install from it. [CONTRIBUTING.md](CONTRIBUTING.md) has the full workflow, including the version-bump rule.

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Everyone taking part in the project is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

Report security vulnerabilities privately as described in [SECURITY.md](SECURITY.md), not in a public issue.

## Support

- **Bugs and feature requests:** [open an issue](https://github.com/Devrisetech/claude-code-engineering-assembly/issues/new/choose).
- **Questions about Claude Code itself:** the [Claude Code documentation](https://code.claude.com/docs).

## Maintainers

Maintained by [Devrise Technology](https://github.com/Devrisetech) — [hello@devrisetech.com](mailto:hello@devrisetech.com).

## License

Released under the [MIT License](LICENSE). The license covers every plugin in this repository.
