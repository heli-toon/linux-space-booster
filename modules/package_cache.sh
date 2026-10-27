#!/usr/bin/env bash

module_package_cache_available() {
    [[ "${PACKAGE_MANAGER:-none}" != "none" ]] &&
        [[ -n "$(package_manager_cache_path)" ]]
}

module_package_cache_estimate() {
    get_dir_size "$(package_manager_cache_path)"
}

module_package_cache_execute() {
    cleanup_apt_cache
}

register_module "package-cache" "packages" "root" "low" \
    module_package_cache_available module_package_cache_estimate \
    module_package_cache_execute
