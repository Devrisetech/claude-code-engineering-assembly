#!/bin/bash
# The recap skill's collect-git-state.sh must look up pull requests FOR EACH
# repo it reports on, superproject and submodules alike - never the
# superproject's PRs reused for every submodule block.
#
# `gh` isn't stubbed to avoid a real GitHub call; instead it is replaced with a
# fake that reports which repo's `origin` remote it was asked about, so the
# test can assert each block queried its own repo.
set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

RECAP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../skills/recap/scripts" && pwd)/collect-git-state.sh"

SANDBOX="$(sandbox recap-prs)"
trap 'rm -rf "$SANDBOX"' EXIT

make_origin "$SANDBOX"
make_sub_origin "$SANDBOX" sub
attach_submodule "$SANDBOX" sub

export GIT_ALLOW_PROTOCOL=file
make_clone "$SANDBOX" clone
CLONE="$SANDBOX/clone"
git -C "$CLONE" -c protocol.file.allow=always submodule update --init -q
# `submodule update --init` leaves the submodule on a detached HEAD; put it on
# a branch so collect-git-state.sh's branch-gated prs lookup actually runs.
git -C "$CLONE/sub" checkout -q -B main

# A fake `gh` that answers `pr list` by naming the `origin` remote of whatever
# directory it is run from - the one fact a real `gh` would also key off.
GH_STUB_DIR="$SANDBOX/bin"
mkdir -p "$GH_STUB_DIR"
cat > "$GH_STUB_DIR/gh" <<'STUB'
#!/bin/bash
if [[ "${1:-}" == "pr" && "${2:-}" == "list" ]]; then
    remote="$(git remote get-url origin 2>/dev/null || echo none)"
    echo "#1 [ready] stub for $remote -- http://example.invalid/1"
    exit 0
fi
exit 1
STUB
chmod +x "$GH_STUB_DIR/gh"

echo "--- each repo's prs line names its OWN remote, not the superproject's ---"
out="$(cd "$CLONE" && GH_BIN="$GH_STUB_DIR/gh" bash "$RECAP" 2>&1)"
SUPER_REMOTE="$(git -C "$CLONE" remote get-url origin)"
SUB_REMOTE="$(git -C "$CLONE/sub" remote get-url origin)"

super_block="$(sed -n '/^== Superproject ==/,/^$/p' <<<"$out")"
sub_block="$(sed -n '/^== Submodule: sub ==/,/^$/p' <<<"$out")"

check "superproject block queried its own remote" "yes" \
      "$([[ "$super_block" == *"stub for $SUPER_REMOTE"* ]] && echo yes || echo no)"
check "submodule block queried its OWN remote, not the superproject's" "yes" \
      "$([[ "$sub_block" == *"stub for $SUB_REMOTE"* ]] && echo yes || echo no)"
check "submodule block did not reuse the superproject's remote" "no" \
      "$([[ "$sub_block" == *"stub for $SUPER_REMOTE"* ]] && echo yes || echo no)"
echo

report
