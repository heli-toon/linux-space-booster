#!/usr/bin/env bash

module_browser_caches_available() {
    [[ -d "${HOME:-/root}/.cache/mozilla" ]] ||
        [[ -d "${HOME:-/root}/.cache/google-chrome" ]] ||
        [[ -d "${HOME:-/root}/.cache/chromium" ]]
}

module_browser_caches_estimate() {
    local total=0 path
    for path in "${HOME:-/root}"/.cache/{mozilla/firefox,google-chrome,chromium}; do
        [[ -d "$path" ]] || continue
        total=$((total + $(get_dir_size "$path")))
    done
    printf '%s\n' "$total"
}

module_browser_caches_execute() {
    cleanup_browser_caches "${HOME:-/root}"
}

register_module "browser-caches" "user" "user" "low" \
    module_browser_caches_available module_browser_caches_estimate \
    module_browser_caches_execute
