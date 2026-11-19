#!/bin/bash
# With two remotes configured, a tag the repo already has from its PRIMARY
# remote must survive the session-start fetch even when a SECOND remote
# doesn't have that tag. Tags are one shared refs/tags/* namespace (unlike
# branches, which are namespaced per remote under refs/remotes/<remote>/*), so
# pruning tags against every remote in turn - as a single
# `fetch --all --prune-tags` does - deletes a tag as soon as any one remote
# lacks it, even though the primary remote still has it.
set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SANDBOX="$(sandbox tagmultiremote)"
SID="tagmultiremote-$$"
trap 'rm -rf "$SANDBOX" "${TMPDIR:-/tmp}/claude-git/$SID"' EXIT

make_origin "$SANDBOX"
git -C "$SANDBOX/seed" tag v1
git -C "$SANDBOX/seed" push -q origin v1

make_clone "$SANDBOX" clone
CLONE="$SANDBOX/clone"
check "precondition: v1 fetched from origin into the clone" "yes" \
      "$(git -C "$CLONE" rev-parse --verify --quiet refs/tags/v1 >/dev/null && echo yes || echo no)"

# A second remote, "upstream" - alphabetically after "origin", so first_remote
# still resolves to "origin" - with the SAME branch history but WITHOUT v1
# (only the branch, never the tag, was pushed to it).
git init -q --bare "$SANDBOX/upstream.git" -b main
git -C "$SANDBOX/seed" remote add upstream "$SANDBOX/upstream.git"
git -C "$SANDBOX/seed" push -q upstream main
git -C "$CLONE" remote add upstream "$SANDBOX/upstream.git"
check "precondition: upstream lacks v1" "no" \
      "$(git ls-remote --tags "$SANDBOX/upstream.git" v1 | grep -q . && echo yes || echo no)"

echo "--- a tag present on the primary remote survives fetching a second remote without it ---"
printf '{"cwd":"%s","session_id":"%s"}' "$CLONE" "$SID" \
    | GIT_PLUGIN_WORKTREE_ATTACHED_MODE_DISABLED=1 bash "$HOOKS/session-start.sh" >/dev/null 2>&1
check "v1 still present after fetching both remotes" "yes" \
      "$(git -C "$CLONE" rev-parse --verify --quiet refs/tags/v1 >/dev/null && echo yes || echo no)"
check "the branch from the second remote was still fetched" "yes" \
      "$(git -C "$CLONE" rev-parse --verify --quiet refs/remotes/upstream/main >/dev/null && echo yes || echo no)"
echo

report
