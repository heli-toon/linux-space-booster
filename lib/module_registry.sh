#!/usr/bin/env bash

# The registry is the single source of truth for cleanup capabilities exposed
# by the command line and interactive front ends.

declare -ag MODULE_NAMES=()
declare -Ag MODULE_CATEGORY=()
declare -Ag MODULE_PRIVILEGE=()
declare -Ag MODULE_RISK=()
declare -Ag MODULE_AVAILABLE_FN=()
declare -Ag MODULE_ESTIMATE_FN=()
declare -Ag MODULE_EXECUTE_FN=()
declare -Ag MODULE_STATUS=()

register_module() {
    local name="$1"
    local category="$2"
    local privilege="$3"
    local risk="$4"
    local available_fn="$5"
    local estimate_fn="$6"
    local execute_fn="$7"

    [[ -n "${MODULE_EXECUTE_FN[$name]+x}" ]] || MODULE_NAMES+=("$name")
    MODULE_CATEGORY["$name"]="$category"
    MODULE_PRIVILEGE["$name"]="$privilege"
    MODULE_RISK["$name"]="$risk"
    MODULE_AVAILABLE_FN["$name"]="$available_fn"
    MODULE_ESTIMATE_FN["$name"]="$estimate_fn"
    MODULE_EXECUTE_FN["$name"]="$execute_fn"
}

module_is_available() {
    local name="$1"
    local check_fn="${MODULE_AVAILABLE_FN[$name]:-}"
    [[ -n "$check_fn" ]] || return 1
    "$check_fn"
}

module_estimate() {
    local name="$1"
    local estimate_fn="${MODULE_ESTIMATE_FN[$name]:-}"
    [[ -n "$estimate_fn" ]] || return 1
    "$estimate_fn"
}

module_analyze() {
    local name="$1"
    if [[ -z "${MODULE_EXECUTE_FN[$name]+x}" ]]; then
        log_message "ERROR" "Unknown cleanup module: $name"
        return "$EXIT_BAD_ARGS"
    fi

    if ! module_is_available "$name"; then
        MODULE_STATUS["$name"]="unavailable"
        printf '%s\t%s\t%s\n' "$name" "unavailable" "0"
        return 0
    fi

    local estimate
    if ! estimate=$(module_estimate "$name"); then
        MODULE_STATUS["$name"]="error"
        log_message "ERROR" "Unable to estimate cleanup module: $name"
        return "$EXIT_ERROR"
    fi
    if [[ ! "$estimate" =~ ^[0-9]+$ ]]; then
        MODULE_STATUS["$name"]="error"
        log_message "ERROR" "Invalid estimate from cleanup module: $name"
        return "$EXIT_ERROR"
    fi

    MODULE_STATUS["$name"]="available"
    printf '%s\t%s\t%s\n' "$name" "available" "$estimate"
}

analyze_registered_modules() {
    local name
    for name in "${MODULE_NAMES[@]}"; do
        module_analyze "$name" || return "$?"
    done
}

preview_registered_module() {
    local name="$1"
    local previous_dry_run="${DRY_RUN:-false}"

    if ! module_is_available "$name"; then
        module_skip "$name" "Unavailable on this system"
        return 0
    fi

    DRY_RUN=true
    local result
    if run_registered_module "$name"; then
        result=0
    else
        result=$?
    fi
    DRY_RUN="$previous_dry_run"
    return "$result"
}

run_registered_module() {
    local name="$1"
    local execute_fn="${MODULE_EXECUTE_FN[$name]:-}"
    if [[ -z "$execute_fn" ]]; then
        log_message "ERROR" "Unknown cleanup module: $name"
        MODULES_FAILED=$((MODULES_FAILED + 1))
        return "$EXIT_BAD_ARGS"
    fi

    if ! module_is_available "$name"; then
        module_skip "$name" "Unavailable on this system"
        return 0
    fi

    "$execute_fn"
}

list_registered_modules() {
    local name
    for name in "${MODULE_NAMES[@]}"; do
        printf '%s\t%s\t%s\t%s\n' "$name" \
            "${MODULE_CATEGORY[$name]}" "${MODULE_PRIVILEGE[$name]}" "${MODULE_RISK[$name]}"
    done
}
