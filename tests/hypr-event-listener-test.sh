#!/bin/bash

set -euo pipefail

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_TMP=$(mktemp -d)
trap 'rm -rf -- "$TEST_TMP"' EXIT
export HYPR_EXTERNAL_LAYOUT_FILE="$TEST_TMP/layout.json"
LOG_FILE=/dev/null
REMOVE_DEBOUNCE=2
ADD_DEBOUNCE=2
WAKE_GRACE=15
CONNECTED_WAKE_GRACE=30
RECOVERY_COOLDOWN=5

source "$REPO_ROOT/scripts/.local/bin/hypr-event-listener"

MODE=present
CONNECTOR=connected
MOCK_NOW=100
MIGRATIONS=0
SAVES=0
RESTORES=0
RELOADS=0
MIGRATION_SUCCEEDS=1
RESTORE_SUCCEEDS=1

sleep() {
    MOCK_NOW=$((MOCK_NOW + ${1:-0}))
}

now_seconds() {
    printf '%s\n' "$MOCK_NOW"
}

read_monitor_snapshot() {
    case "$MODE" in
        present)
            MONITORS_JSON='[
                {"name":"eDP-1","dpmsStatus":true,"activeWorkspace":{"id":1}},
                {"name":"HDMI-A-1","dpmsStatus":true,"activeWorkspace":{"id":11}}
            ]'
            ;;
        awake)
            MONITORS_JSON='[
                {"name":"eDP-1","dpmsStatus":true,"activeWorkspace":{"id":1}}
            ]'
            ;;
        dormant)
            MONITORS_JSON='[
                {"name":"eDP-1","dpmsStatus":false,"activeWorkspace":{"id":1}}
            ]'
            ;;
        error)
            return 1
            ;;
    esac
}

connector_connected() {
    [[ "$CONNECTOR" == "connected" ]]
}

save_external_layout() {
    ((SAVES += 1))
}

migrate_windows_to_laptop() {
    ((MIGRATIONS += 1))
    ((MIGRATION_SUCCEEDS == 1))
}

restore_external_configuration() {
    ((RESTORES += 1))
    ((RESTORE_SUCCEEDS == 1))
}

request_monitor_reload() {
    ((RELOADS += 1))
}

reset_scenario() {
    STATE=unknown
    WAKE_GRACE_STARTED_AT=0
    LAST_RECOVERY=0
    LAYOUT_READY=0
    MODE=present
    CONNECTOR=connected
    MOCK_NOW=100
    MIGRATIONS=0
    SAVES=0
    RESTORES=0
    RELOADS=0
    MIGRATION_SUCCEEDS=1
    RESTORE_SUCCEEDS=1
}

assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    if [[ "$actual" != "$expected" ]]; then
        printf 'FAIL: %s (expected=%s actual=%s)\n' \
            "$message" "$expected" "$actual" >&2
        exit 1
    fi
}

reset_scenario
STATE=present
MODE=dormant
reconcile_state
assert_equal dormant "$STATE" "idle removal enters dormant"
MODE=present
reconcile_state
assert_equal present "$STATE" "idle flap returns directly to present"
assert_equal 0 "$MIGRATIONS" "idle flap does not migrate"
assert_equal 0 "$RESTORES" "idle flap does not restore"

reset_scenario
STATE=dormant
MODE=awake
reconcile_state
assert_equal wake-grace "$STATE" "wake starts grace period"
MOCK_NOW=110
reconcile_state
assert_equal wake-grace "$STATE" "slow HDMI remains protected during grace"
MODE=present
MOCK_NOW=111
reconcile_state
assert_equal present "$STATE" "HDMI can return during grace"
assert_equal 0 "$MIGRATIONS" "delayed HDMI wake does not migrate"
assert_equal 0 "$RESTORES" "delayed HDMI wake does not restore"

reset_scenario
STATE=present
MODE=awake
CONNECTOR=disconnected
reconcile_state
assert_equal absent "$STATE" "stable awake power loss becomes absent"
assert_equal 1 "$MIGRATIONS" "real power loss migrates once"
assert_equal 102 "$MOCK_NOW" "real power loss is debounced once"

MODE=present
reconcile_state
assert_equal present "$STATE" "real reconnect restores present state"
assert_equal 1 "$RESTORES" "real reconnect restores once"

reset_scenario
STATE=present
MODE=error
reconcile_state || true
assert_equal present "$STATE" "query failure preserves state"
assert_equal 0 "$MIGRATIONS" "query failure never migrates"

reset_scenario
STATE=absent
MODE=present
RESTORE_SUCCEEDS=0
reconcile_state || true
assert_equal present "$STATE" "restoration failure cannot override monitor presence"
reconcile_state
assert_equal 1 "$RESTORES" "a failed snapshot is not replayed"

reset_scenario
STATE=dormant
MODE=awake
CONNECTOR=connected
reconcile_state
MOCK_NOW=120
reconcile_state
assert_equal wake-grace "$STATE" "connected DRM receives extended wake grace"
assert_equal 1 "$RELOADS" "connected inactive HDMI requests monitor reload"
MOCK_NOW=131
reconcile_state
assert_equal absent "$STATE" "connected recovery grace is bounded"
assert_equal 1 "$MIGRATIONS" "bounded recovery eventually migrates"

reset_scenario
STATE=present
MODE=awake
CONNECTOR=disconnected
MIGRATION_SUCCEEDS=0
reconcile_state || true
assert_equal present "$STATE" "failed migration remains retryable"
assert_equal 1 "$SAVES" "failed migration captured one layout snapshot"
MIGRATION_SUCCEEDS=1
reconcile_state
assert_equal absent "$STATE" "migration retry reaches absent"
assert_equal 1 "$SAVES" "migration retry preserves the original snapshot"
assert_equal 2 "$MIGRATIONS" "migration was retried"

printf 'PASS: hypr-event-listener state scenarios\n'
