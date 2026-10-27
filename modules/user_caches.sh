#!/usr/bin/env bash

module_user_caches_available() {
    [[ -d "${HOME:-/root}/.cache" ]]
}

module_user_caches_estimate() {
    get_dir_size "${HOME:-/root}/.cache"
}

module_user_caches_execute() {
    cleanup_user_caches
}

register_module "user-caches" "user" "root" "low" \
    module_user_caches_available module_user_caches_estimate \
    module_user_caches_execute
