#!/bin/bash
# GIT_PLUGIN_SUBMODULE_INIT_RECURSIVE opts into populating nested submodules
# too. Off by default (unset, "0", or any value other than `1`/`true`), and
# recursion never grants a nested submodule a branch or a gitlink sync - that
# stays top-level only, same as the non-recursive default.
set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# See test-submodule-sync.sh for why this is needed: git 2.38+ requires it for
# `submodule add`/`update` over file://, and only the environment reaches the
# plugin's own `git submodule update` (not just the commands this test runs
# directly).
export GIT_ALLOW_PROTOCOL=file

SANDBOX="$(sandbox submodules-recursive)"
trap 'rm -rf "$SANDBOX"' EXIT

make_origin "$SANDBOX"
make_sub_origin "$SANDBOX" tracked
make_sub_origin "$SANDBOX" nested
make_sub_origin "$SANDBOX" deep

# A three-level chain: superproject -> tracked -> nested -> deep.
git -C "$SANDBOX/nested-seed" -c protocol.file.allow=always \
    submodule add -q "$SANDBOX/deep.git" deep 2>/dev/null
git -C "$SANDBOX/nested-seed" commit -qm "add deep submodule"
git -C "$SANDBOX/nested-seed" push -q origin main

git -C "$SANDBOX/tracked-seed" -c protocol.file.allow=always \
    submodule add -q "$SANDBOX/nested.git" nested 2>/dev/null
git -C "$SANDBOX/tracked-seed" commit -qm "add nested submodule"
git -C "$SANDBOX/tracked-seed" push -q origin main

attach_submodule "$SANDBOX" tracked main

# A fresh clone for each case, so each one starts from the same unpopulated state.
fresh_clone() { # fresh_clone <name> -> echoes the clone path
    local clone="$SANDBOX/$1"
    git clone -q "$SANDBOX/origin.git" "$clone" 2>/dev/null
    echo "$clone"
}

run() { # run <clone> [VAR=val ...] -> echoes ensure-submodules.sh stdout
    local clone="$1"; shift
    env "$@" bash "$HOOKS/ensure-submodules.sh" -C "$clone" 2>&1
}

nested_populated() { [[ -e "$1/tracked/nested/.git" ]] && echo yes || echo no; }
deep_populated() { [[ -e "$1/tracked/nested/deep/.git" ]] && echo yes || echo no; }

echo "--- default (unset): recursion stays off ---"
C="$(fresh_clone default)"
run "$C" >/dev/null
check "tracked populated" "yes" "$([[ -e "$C/tracked/.git" ]] && echo yes || echo no)"
check "nested left empty" "no" "$(nested_populated "$C")"
echo

echo "--- not a truthy value: recursion stays off ---"
C="$(fresh_clone zero)"
run "$C" GIT_PLUGIN_SUBMODULE_INIT_RECURSIVE=0 >/dev/null
check "'=0' leaves nested empty" "no" "$(nested_populated "$C")"
C="$(fresh_clone yes)"
run "$C" GIT_PLUGIN_SUBMODULE_INIT_RECURSIVE=yes >/dev/null
check "'=yes' leaves nested empty" "no" "$(nested_populated "$C")"
echo

echo "--- '=1': nested and deep are populated ---"
C="$(fresh_clone one)"
out="$(run "$C" GIT_PLUGIN_SUBMODULE_INIT_RECURSIVE=1)"
check "nested populated" "yes" "$(nested_populated "$C")"
check "deep populated" "yes" "$(deep_populated "$C")"
check "reported nested" "yes" "$([[ "$out" == *"initialized tracked/nested"* ]] && echo yes || echo no)"
check "reported deep" "yes" "$([[ "$out" == *"initialized tracked/nested/deep"* ]] && echo yes || echo no)"
check "nested stays detached, no branch" "" "$(git -C "$C/tracked/nested" symbolic-ref --short -q HEAD 2>/dev/null || true)"
check "tracked still gets its branch" "main" "$(git -C "$C/tracked" symbolic-ref --short -q HEAD)"
echo

echo "--- '=TRUE' (case-insensitive) ---"
C="$(fresh_clone caps)"
run "$C" GIT_PLUGIN_SUBMODULE_INIT_RECURSIVE=TRUE >/dev/null
check "nested populated" "yes" "$(nested_populated "$C")"
echo

echo "--- pre-populated tracked (with local work, already attached) is never rewound; nested still reached ---"
C="$(fresh_clone prepop)"
run "$C" >/dev/null   # populate + attach tracked to branch "main" (default, non-recursive)
# Commit directly on the already-attached branch, so it sits ahead of the
# gitlink - the same "leave it as is" case sync_submodule already covers.
git -C "$C/tracked" -c user.email=t@e.invalid -c user.name=t commit --allow-empty -qm local
TRACKED_HEAD_BEFORE="$(git -C "$C/tracked" rev-parse HEAD)"
out="$(run "$C" GIT_PLUGIN_SUBMODULE_INIT_RECURSIVE=1)"
check "tracked HEAD untouched" "$TRACKED_HEAD_BEFORE" "$(git -C "$C/tracked" rev-parse HEAD)"
check "nested now populated" "yes" "$(nested_populated "$C")"
check "second run is silent" "" "$(run "$C" GIT_PLUGIN_SUBMODULE_INIT_RECURSIVE=1)"
echo

echo "--- an already-populated nested submodule moved off its gitlink is left alone ---"
C="$(fresh_clone moved)"
run "$C" GIT_PLUGIN_SUBMODULE_INIT_RECURSIVE=1 >/dev/null
advance_sub_origin "$SANDBOX" deep d2
git -C "$C/tracked/nested" -c protocol.file.allow=always fetch -q origin
git -C "$C/tracked/nested" checkout -q origin/main
NESTED_HEAD_BEFORE="$(git -C "$C/tracked/nested" rev-parse HEAD)"
run "$C" GIT_PLUGIN_SUBMODULE_INIT_RECURSIVE=1 >/dev/null
check "nested HEAD untouched" "$NESTED_HEAD_BEFORE" "$(git -C "$C/tracked/nested" rev-parse HEAD)"
echo

report
