#!/usr/bin/env bash

module_postgresql_available() {
    [[ -d /var/log/postgresql ]] || [[ -d /var/lib/postgresql ]]
}

module_postgresql_estimate() {
    local total
    total=$(get_dir_size /var/log/postgresql)
    printf '%s\n' "$total"
}

module_postgresql_execute() {
    cleanup_postgres_logs
}

register_module "postgresql-logs" "application-logs" "root" "medium" \
    module_postgresql_available module_postgresql_estimate \
    module_postgresql_execute
