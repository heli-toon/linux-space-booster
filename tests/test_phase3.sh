#!/usr/bin/env bash
# Phase 3 tests for the cleanup module registry.
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="$ROOT_DIR/linux_space_booster.sh"

# shellcheck source=../linux_space_booster.sh
source "$SCRIPT"

assert_equals() {
    local actual=$1
    local expected=$2
    local message=$3
    if [[ "$actual" == "$expected" ]]; then
        printf 'ok - %s\n' "$message"
    else
        printf 'not ok - %s (expected %q, got %q)\n' "$message" "$expected" "$actual" >&2
        exit 1
    fi
}

expected_modules=(
    package-cache
    system-logs
    temporary-files
    user-caches
    browser-caches
    thumbnails
    snap
    postgresql-logs
    pentesting-tools
    old-kernels
)

assert_equals "${#MODULE_NAMES[@]}" "${#expected_modules[@]}" \
    "registry contains every migrated cleanup module"

for module_name in "${expected_modules[@]}"; do
    [[ -n "${MODULE_EXECUTE_FN[$module_name]:-}" ]] || {
        printf 'not ok - %s has an execute function\n' "$module_name" >&2
        exit 1
    }
    [[ -n "${MODULE_ESTIMATE_FN[$module_name]:-}" ]] || {
        printf 'not ok - %s has an estimate function\n' "$module_name" >&2
        exit 1
    }
    [[ -n "${MODULE_AVAILABLE_FN[$module_name]:-}" ]] || {
        printf 'not ok - %s has an availability check\n' "$module_name" >&2
        exit 1
    }
done
printf 'ok - all modules expose metadata and lifecycle functions\n'

listed_modules=$(list_registered_modules | cut -f1)
for module_name in "${expected_modules[@]}"; do
    grep -Fx "$module_name" <<< "$listed_modules" >/dev/null || {
        printf 'not ok - %s is visible through the registry listing\n' "$module_name" >&2
        exit 1
    }
done
printf 'ok - registry listing exposes all modules\n'

printf 'Phase 3 registry tests passed\n'
