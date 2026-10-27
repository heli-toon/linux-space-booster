#!/usr/bin/env bash

module_kernels_available() {
    [[ "${PACKAGE_MANAGER:-none}" == "apt" ]]
}

module_kernels_estimate() {
    printf '0\n'
}

module_kernels_execute() {
    cleanup_old_kernels
}

register_module "old-kernels" "system" "root" "high" \
    module_kernels_available module_kernels_estimate module_kernels_execute
