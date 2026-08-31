#!/bin/bash

set -euo pipefail

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_TMP=$(mktemp -d)
LAYOUT_FILE="$TEST_TMP/layout.json"
DISPATCH_LOG="$TEST_TMP/dispatch.log"
export DISPATCH_LOG
trap 'rm -rf -- "$TEST_TMP"' EXIT

mock_hyprctl() {
    if [[ "$1" == "clients" && "$2" == "-j" ]]; then
        case "$MOCK_PHASE" in
            save)
                printf '%s\n' '[{
                    "address":"0x1",
                    "pid":101,
                    "class":"Example",
                    "title":"Window",
                    "workspace":{"id":11},
                    "floating":false,
                    "at":[10,20],
                    "size":[800,600]
                }]'
                ;;
            restore)
                printf '%s\n' '[{
                    "address":"0x1",
                    "pid":101,
                    "class":"Example",
                    "title":"Changed title",
                    "workspace":{"id":1},
                    "floating":false,
                    "at":[10,20],
                    "size":[800,600]
                }]'
                ;;
            unrelated)
                printf '%s\n' '[{
                    "address":"0x2",
                    "pid":202,
                    "class":"Example",
                    "title":"Window",
                    "workspace":{"id":1},
                    "floating":false,
                    "at":[10,20],
                    "size":[800,600]
                }]'
                ;;
            failure)
                return 1
                ;;
        esac
        return
    fi

    if [[ "$1" == "dispatch" ]]; then
        printf '%s\n' "$*" >> "$DISPATCH_LOG"
        return 0
    fi

    return 1
}

hyprctl() {
    mock_hyprctl "$@"
}
export -f hyprctl mock_hyprctl
export HYPR_EXTERNAL_LAYOUT_FILE="$LAYOUT_FILE"

export MOCK_PHASE=save
"$REPO_ROOT/scripts/.local/bin/hypr-save-layout" >/dev/null
[[ "$(jq -r 'length' "$LAYOUT_FILE")" == "1" ]]
saved_layout=$(<"$LAYOUT_FILE")

export MOCK_PHASE=failure
if "$REPO_ROOT/scripts/.local/bin/hypr-save-layout" >/dev/null 2>&1; then
    printf 'FAIL: layout save unexpectedly succeeded\n' >&2
    exit 1
fi
[[ "$(<"$LAYOUT_FILE")" == "$saved_layout" ]]

export MOCK_PHASE=restore
restore_output=$("$REPO_ROOT/scripts/.local/bin/hypr-restore-layout")
[[ "$restore_output" == *"Restored 1 / 1 window(s)"* ]]
[[ "$(<"$DISPATCH_LOG")" == *"11,address:0x1"* ]]

: > "$DISPATCH_LOG"
export MOCK_PHASE=unrelated
restore_output=$("$REPO_ROOT/scripts/.local/bin/hypr-restore-layout")
[[ "$restore_output" == *"Skipped closed window"* ]]
[[ ! -s "$DISPATCH_LOG" ]]

printf 'PASS: hypr layout save/restore scenarios\n'
