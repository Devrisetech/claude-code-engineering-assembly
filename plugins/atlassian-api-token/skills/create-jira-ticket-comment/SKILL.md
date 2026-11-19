---
name: create-jira-ticket-comment
description: >
  Posts a comment to a JIRA ticket, optionally uploading file attachments and noting them
  in the comment. Use when feedback, enrichment results, validation output, or any
  structured content needs to be posted as a comment on a JIRA ticket.
argument-hint: "[JIRA ticket URL] [comment content] [file paths (optional)]"
when_to_use: >
  Invoke when a comment needs to be posted to a JIRA ticket — especially when the comment
  includes file attachments like images or documents that need to be uploaded and referenced.
  Also invoke when the user says "post to JIRA", "comment on this ticket", "send feedback
  to the ticket", or when another skill needs to deliver output as a JIRA comment.
context: fork
agent: general-purpose
---

# Create JIRA Ticket Comment

You post a comment to a JIRA ticket, handling file uploads and attachment references.

## Input

Extract from `$ARGUMENTS` (quote any value containing spaces, since they are positional):

1. **jira_ticket_url** (required) — the JIRA ticket URL to post the comment on. Extract the
   ticket ID from the URL (e.g., `DT-123` from `https://....atlassian.net/browse/DT-123`).
2. **comment_content** (required) — the comment body in **Markdown**, matching the
   `contentFormat: "markdown"` this skill posts with. May contain attachment placeholders
   like `![description](attachment:filename.png)` or `[filename](attachment:filename.png)`
   that reference files to be uploaded.
3. **file_paths** (optional) — zero or more local file paths, last in the argument list, to
   upload as ticket attachments.

If `jira_ticket_url` or `comment_content` is missing, report a fatal error and stop.

## Procedure

### Step 1 — Upload attachments (if files provided)

If `file_paths` are provided, extract the JIRA site URL from `jira_ticket_url`
(e.g., `https://yourname.atlassian.net/` from `https://yourname.atlassian.net/browse/DT-123`).

For each file path:

1. Verify the file exists locally before attempting upload.
2. **Invoke the upload script** — run:
   ```
   bash ${CLAUDE_SKILL_DIR}/upload-file-to-attachment.sh \
     --jira-site-url <jira-site-url> \
     --file-path <absolute path to the file> \
     --ticket-key <ticket-key>
   ```
   Read the stdout of the invocation for the result. A successful upload prints the JSON
   response from JIRA. Extract the uploaded `filename` by feeding that captured response
   straight into `jq` as a bash here-string (`jq -r '.[0].filename' <<<"$response"`), not by
   pasting the response text back into a new `echo '...'` shell command — a filename
   containing a `'` breaks that quoting.
3. If any upload fails, log a warning with the filename and the error output — continue with
   remaining files.

### Step 2 — Note uploaded files in the comment body

Every uploaded file already appears in the ticket's **Attachments** panel; nothing further
is needed for that. This step only makes the comment body itself mention the file, in plain
Markdown — the comment is posted with `contentFormat: "markdown"` (see Step 4), and Jira
Cloud's markdown comment API has **no working syntax to inline-embed an already-uploaded
attachment** (not `![](filename)` — that only loads an external URL — and not the Jira wiki
markup `!filename!` / `[filename|^filename]`, which is not markdown and renders as literal
text under `contentFormat: "markdown"`; embedding an existing attachment inline is a
long-standing Jira Cloud platform limitation, not something this skill can work around).

For each successfully uploaded file:

- **If the comment body already contains a placeholder** for this file (pattern:
  `attachment:<filename>`, in either `![desc](attachment:filename)` or
  `[filename](attachment:filename)` form) — replace the placeholder with a plain reference:
  `` 📎 `filename` `` (or, if the placeholder had descriptive text, `` 📎 <description>
  (`filename`) ``).
- **If the comment body does NOT contain a placeholder** for this file — append a line at
  the end of the comment body: `` 📎 `filename` ``.

If a placeholder references a file that was not uploaded (due to failure or absence), leave
the placeholder as-is and add a warning note at the end of the comment.

### Step 3 — User mentions

When the comment body mentions users (e.g. `@John`, `@john.doe`), the same limitation
applies: there is no plain-text mention syntax that `contentFormat: "markdown"` turns into a
real Jira mention (and so no in-product/email notification). Do not emit Jira's
`[~accountid:...]` wiki syntax — it is not markdown and would render as literal text.

- Look up the account using the available JIRA tool `lookupJiraAccountId` (search by display
  name or email), **only** to get the person's correct display name.
- Replace the mention with that display name in **bold** Markdown (e.g. `**Jane Doe**`).
- Add one note at the end of the comment: "Note: @mentions above do not trigger a Jira
  notification from this skill; tag the person directly in the Jira UI if one is needed."
- If the account cannot be resolved, leave the original mention text as-is instead.

### Step 4 — Post the comment

Post the comment body built above (Markdown, by this point free of any placeholder or
mention syntax Jira can't render) with the JIRA tool `addCommentToJiraIssue`, passing
`contentFormat: "markdown"` explicitly.

## Final Report

Report back to the caller:

- **Success**: "Comment posted successfully to `<TICKET-ID>`" with any notes about attachment
  uploads
- **Failure**: The specific error encountered, with details about what step failed
- **Warnings**: Any attachment upload failures or unresolved placeholders
