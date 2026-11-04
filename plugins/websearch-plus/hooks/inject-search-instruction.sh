#!/bin/bash

# ============================================================================
# inject-search-instruction.sh - SessionStart hook: carry the web-search tool
# order with the plugin instead of hand-pasting it into each project's CLAUDE.md.
#
# Driven by hooks.json on SessionStart (startup|resume|clear|compact): stdout is
# added to the session context. The instruction is static, so every fresh or
# wiped context simply gets the full file once via `cat`.
#
# Never fails a session: a missing instruction file is a silent no-op.
# ============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INSTRUCTION="$SCRIPT_DIR/search-instruction.md"

[[ -f "$INSTRUCTION" ]] || exit 0
cat "$INSTRUCTION"
exit 0
