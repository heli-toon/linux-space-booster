#!/usr/bin/env bash

module_system_logs_available() {
    [[ -d /var/log ]] || [[ "${INIT_SYSTEM:-unknown}" == "systemd" ]]
}

module_system_logs_estimate() {
    get_dir_size /var/log
}

module_system_logs_execute() {
    cleanup_system_logs
}

register_module "system-logs" "logs" "root" "medium" \
    module_system_logs_available module_system_logs_estimate \
    module_system_logs_execute
