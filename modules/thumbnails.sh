#!/usr/bin/env bash

module_thumbnails_available() {
    [[ -d "${HOME:-/root}/.cache/thumbnails" ]]
}

module_thumbnails_estimate() {
    get_dir_size "${HOME:-/root}/.cache/thumbnails"
}

module_thumbnails_execute() {
    cleanup_thumbnails_dir "${HOME:-/root}"
}

register_module "thumbnails" "user" "user" "low" \
    module_thumbnails_available module_thumbnails_estimate \
    module_thumbnails_execute
