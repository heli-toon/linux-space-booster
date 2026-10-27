#!/usr/bin/env bash

module_temp_files_available() {
    [[ -d /tmp ]]
}

module_temp_files_estimate() {
    get_dir_size /tmp
}

module_temp_files_execute() {
    cleanup_temp_files
}

register_module "temporary-files" "temporary-files" "root" "low" \
    module_temp_files_available module_temp_files_estimate \
    module_temp_files_execute
