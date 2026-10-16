# Security Policy

## Supported versions

Only the latest commit on `main` is supported. The marketplace serves plugins straight from `main`, so a security fix ships as a new plugin version there. Update to it with `/plugin marketplace update engineering-assembly`.

## Reporting a vulnerability

**Do not report security vulnerabilities in public GitHub issues, discussions, or pull requests.**

Email [hello@devrisetech.com](mailto:hello@devrisetech.com) with the subject line `SECURITY: claude-code-engineering-assembly`. Include:

- the affected plugin and its version (from `plugins/<name>/.claude-plugin/plugin.json`)
- a description of the issue and its impact
- steps to reproduce, or a proof of concept
- any suggested fix or mitigation

We acknowledge reports as quickly as we can, keep you informed while we investigate, and we agree a disclosure date with you before publishing a fix. We are glad to credit reporters who want to be credited.

## Scope

These plugins run inside Claude Code on the user's machine. Issues of particular interest:

- **Hooks**, such as the `git` plugin's `SessionStart` hook: shell commands that run automatically at session start, including any way to make them execute unintended commands or modify repositories beyond their documented fast-forward-only behaviour.
- **MCP server bundles** (`context7`, `atlassian-sso`, `atlassian-api-token`): leaking the API keys or tokens they read from environment variables.
- **Skills and agents**, such as the `implementation` plugin's Jira attachment scripts: handling credentials, downloaded files, or untrusted ticket content unsafely.

Out of scope here:
- Vulnerabilities in Claude Code itself: report them to Anthropic.
- Vulnerabilities in the third-party MCP services (Context7, Atlassian): report them to those vendors.
