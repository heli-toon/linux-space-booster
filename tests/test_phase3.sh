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

analysis=$(analyze_registered_modules)
while IFS=$'\t' read -r module_name status estimate; do
    [[ -n "$module_name" ]] || continue
    [[ "$status" == "available" || "$status" == "unavailable" ]] || {
        printf 'not ok - %s has a valid analysis status\n' "$module_name" >&2
        exit 1
    }
    [[ "$estimate" =~ ^[0-9]+$ ]] || {
        printf 'not ok - %s has a numeric estimate\n' "$module_name" >&2
        exit 1
    }
done <<< "$analysis"
printf 'ok - registry modules expose analysis results\n'

preview_target=$(mktemp)
preview_module() {
    printf 'preview\n' >> "$preview_target"
}
preview_available() {
    return 0
}
preview_estimate() {
    printf '0\n'
}
register_module "test-preview" "test" "user" "low" \
    preview_available preview_estimate preview_module
MODULE_EXECUTE_FN["test-preview"]="preview_module"
DRY_RUN=false
preview_registered_module "test-preview"
assert_equals "$DRY_RUN" "false" "module preview restores dry-run state"
assert_equals "$(cat "$preview_target")" "preview" \
    "module preview invokes the registered execute function"
rm -f -- "$preview_target"

printf 'Phase 3 registry tests passed\n'
