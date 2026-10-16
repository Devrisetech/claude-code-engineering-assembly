# Implementation Plugin

QA test automation for software development tasks: drive a change through the running app — web or Android — and confirm it works before it ships.

## Overview

Development tasks often fail not because the code is wrong, but because nobody actually drives the change through the app to confirm it works. This plugin bundles the `automation-expert` agent, which executes manual test cases and reproduction steps step-by-step on web or Android (via `adb`). Use it to verify acceptance criteria, reproduce a bug, or run a regression check once a change is made.

To work from Jira tickets — pull a ticket's content in, post QA results back — install the companion **`atlassian-api-token`** plugin, which ships the `retrieve-jira-ticket` and `create-jira-ticket-comment` skills.

## Agents

### `automation-expert`

Executes manual test cases and flows step-by-step — end-to-end flows, smoke tests, regression checks, bug reproduction, or acceptance criteria verification. Detects the target platform from the input:

- **Web** — drives the browser using whatever browser automation skill or MCP tool is available in the session context, with each flow running in its own isolated session where the tool supports it.
- **Android** — inspects the UI via `adb exec-out uiautomator dump` and drives the emulator via `adb shell input`.

Before running any steps, it rebuilds and restarts the app under test (dev server for web, fresh APK install for Android) so results reflect the current codebase, not stale state. It inspects app state before every action, tries multiple locator fallbacks before failing a step, and reports a final PASS/FAIL table with per-step notes. Artifacts (screenshots, UI dumps) are only captured when a step explicitly asks for one, and are saved to the launching directory using a `<type>_<slug>_<timestamp>.<ext>` naming convention.

## System prerequisites

The `automation-expert` agent requires **adb** (Android platform-tools) and a running emulator or device for Android runs. Web runs use whatever browser automation skill or MCP tool is available in the session.

## Installation

```
/plugin marketplace add Devrisetech/claude-code-engineering-assembly
/plugin install implementation@engineering-assembly
```

## Recommended workflow

Once a change is in place, hand acceptance criteria or a bug's steps to reproduce to the `automation-expert` agent to drive the app and confirm the result:

```
Run these test steps against staging and report pass/fail: ...
```

With the `atlassian-api-token` plugin installed, you can work from a Jira ticket and post the results back:

```
Fetch https://yourname.atlassian.net/browse/DT-123 and run its steps to reproduce against staging.
```

```
Post the QA results as a comment on https://yourname.atlassian.net/browse/DT-123, attaching the failure screenshot.
```
