#!/usr/bin/env bash

module_snap_available() {
    command -v snap >/dev/null 2>&1
}

module_snap_estimate() {
    get_dir_size /var/lib/snapd/snaps
}

module_snap_execute() {
    cleanup_snap_packages
}

register_module "snap" "packages" "root" "high" \
    module_snap_available module_snap_estimate module_snap_execute
