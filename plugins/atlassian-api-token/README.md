# Atlassian API Token Plugin

Bundles the [Atlassian Remote MCP Server](https://www.atlassian.com/platform/remote-mcp-server)
(Rovo) into Claude Code so it can work with **Jira, Confluence, Jira Service Management,
Bitbucket, and Compass** directly — reading issues, searching pages, creating tickets, and
more — with every action respecting your existing Atlassian access controls.

Authentication uses a **personal API token** (HTTP Basic auth) instead of an interactive
browser SSO flow. This is the right choice for headless environments, CI, or shared machines
where a browser login is impractical.

## Overview

Atlassian hosts a remote MCP server that exposes your Atlassian Cloud products as MCP tools.
This plugin authenticates by sending an `Authorization: Basic <base64>` header, where the
base64 value encodes `email:api_token`. The credential is read from the
`MCP_ATLASSIAN_BASE64_ENCODED_EMAIL_AND_API_TOKEN` environment variable, so no secret is stored
in this repo.

This plugin ships the server configuration (`.mcp.json`) so you don't have to add it to each
project's `.mcp.json` by hand. It also bundles two Jira skills, `retrieve-jira-ticket` and
`create-jira-ticket-comment`, for moving ticket content in and results out.

## Configuration

The server is defined as a streamable HTTP MCP server with a Basic auth header:

```json
{
  "mcpServers": {
    "atlassian-api-token": {
      "type": "http",
      "url": "https://mcp.atlassian.com/v2/mcp",
      "headers": {
        "Authorization": "Basic ${MCP_ATLASSIAN_BASE64_ENCODED_EMAIL_AND_API_TOKEN}"
      }
    }
  }
}
```

> The API-token endpoint is `https://mcp.atlassian.com/v2/mcp` (**not** the `/authv2`
> path used for OAuth SSO; `/v1/mcp` also still answers Basic-auth requests as of this
> writing, but Atlassian has deprecated it for removal on 2027-03-01 — this plugin uses
> `/v2/mcp`, which responds to the same Basic auth header). Claude Code expands
> `${MCP_ATLASSIAN_BASE64_ENCODED_EMAIL_AND_API_TOKEN}` from your environment at connect
> time.

## Setup

1. **Create an Atlassian API token.** Go to
   <https://id.atlassian.com/manage-profile/security/api-tokens>, click **Create API token with scopes**,
   give it a label, choose **Rovo MCP** at `Select API token app`, and copy the generated token. Note the email address of the account that
   owns the token.

2. **Base64-encode `email:api_token`.** Encode the email and token joined by a single colon —
   do not add a trailing newline (`-n`):

   ```bash
   echo -n "your.email@example.com:YOUR_API_TOKEN_HERE" | base64
   ```

3. **Export the encoded value** as the environment variable this plugin reads. Add it to your
   shell profile (e.g. `~/.zshrc`) so it persists:

   ```bash
   export MCP_ATLASSIAN_BASE64_ENCODED_EMAIL_AND_API_TOKEN="<paste base64 output here>"
   ```

   The resulting request header becomes
   `Authorization: Basic <base64 of email:api_token>`.

4. Install the plugin (see below), then confirm the server is connected and authorized:

   ```
   /mcp
   ```

You need an Atlassian Cloud account with access to the products you want to use. Your admin may
need to enable the Remote MCP Server / Rovo for your site.

> **Security:** Treat the base64 value as a secret — it is only encoded, **not** encrypted, and
> anyone with it can act as you. Keep it out of version control and shell history where
> possible.

## Installation

```
/plugin marketplace add Devrisetech/claude-code-engineering-assembly
/plugin install atlassian-api-token@engineering-assembly
```

## Skills

### `retrieve-jira-ticket`

Fetches one or more Jira tickets by URL and saves structured content (title, description,
comments, attachments) to a local directory for downstream processing. Invoke it whenever a Jira
ticket URL appears in the input and its content needs to be pulled locally.

### `create-jira-ticket-comment`

Posts a comment to a Jira ticket as Markdown, optionally uploading file attachments first and
replacing `attachment:<filename>` placeholders in the comment body with a plain `📎 \`filename\``
reference. Jira Cloud's markdown comment API has no working syntax to inline-embed an
already-uploaded attachment (that's a Jira platform limitation, not something this skill works
around), so an uploaded file is referenced by name rather than embedded. `@mentions` are replaced
with the person's resolved display name in bold, for readability; Jira only sends a real
notification for a mention built as a native ADF node, which this skill does not construct, so
tag people directly in the Jira UI when a notification is required.

Both skills use the MCP server for ticket, comment and account-lookup calls. Attachment upload and
download fall outside the MCP tool surface, so the bundled `download-attachment-file.sh` and
`upload-file-to-attachment.sh` scripts call the Jira Cloud REST API directly (`curl`, credentials
via `.netrc`, never on the command line) with the `MCP_ATLASSIAN_ACCOUNT_USERNAME` and
`MCP_ATLASSIAN_ACCOUNT_API_TOKEN` environment variables; `download-attachment-file.sh` only ever
sends that credential to an `https://*.atlassian.net` host. `create-jira-ticket-comment` also uses
`jq` to read the uploaded file's name back out of the upload script's JSON response.

## Usage

Once connected, ask Claude to work with your Atlassian data, e.g.:

> Summarize the open bugs assigned to me in the PLATFORM Jira project.

> Find the Confluence page describing our on-call rotation and give me the escalation steps.

> Fetch https://yourname.atlassian.net/browse/DT-123 and summarize the open questions.

> Post the QA results as a comment on https://yourname.atlassian.net/browse/DT-123, attaching the failure screenshot.

## Requirements

> [!WARNING]
> **Linux and macOS only.** The Jira skills run Bash scripts for attachment upload and download. Windows is not supported.

- An Atlassian Cloud account (Jira / Confluence / etc.) with the Remote MCP Server enabled.
- A personal Atlassian API token, base64-encoded as `email:api_token` and exported as
  `MCP_ATLASSIAN_BASE64_ENCODED_EMAIL_AND_API_TOKEN`.
- Network access to `https://mcp.atlassian.com`.
- For the Jira skills' attachment transfer: `curl` and `jq`, plus `MCP_ATLASSIAN_ACCOUNT_USERNAME`
  (your Atlassian account email) and `MCP_ATLASSIAN_ACCOUNT_API_TOKEN` (an API token from
  <https://id.atlassian.com/manage-profile/security/api-tokens>).

## References

- [Configuring authentication via API token](https://support.atlassian.com/atlassian-rovo-mcp-server/docs/configuring-authentication-via-api-token/)
- [Getting started with the Atlassian Rovo MCP Server](https://support.atlassian.com/atlassian-rovo-mcp-server/docs/getting-started-with-the-atlassian-remote-mcp-server/)
- [Manage API tokens for your Atlassian account](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/)
- [Official atlassian/atlassian-mcp-server repo](https://github.com/atlassian/atlassian-mcp-server)
