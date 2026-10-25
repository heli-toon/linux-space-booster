#!/usr/bin/env bash
# Phase 2 tests for platform detection and package-manager adapter capability checks.
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="$ROOT_DIR/linux_space_booster.sh"

assert_equals() {
    local actual=$1
    local expected=$2
    local message=$3
    if [[ "$actual" == "$expected" ]]; then
        printf 'ok - %s\n' "$message"
    else
        printf 'not ok - %s (expected %q, got %q)\n' "$message" "$expected" "$actual" >&2
        exit 1
    fi
}

# Sourcing exposes helpers without invoking the application's main function.
# shellcheck source=../linux_space_booster.sh
source "$SCRIPT"

make_fake_bin() {
    local bindir=$1
    shift
    mkdir -p "$bindir"

    for tool in "$@"; do
        case "$tool" in
            apt-get|dpkg|dnf|pacman|apk)
                printf '#!/usr/bin/env bash\nexit 0\n' > "$bindir/$tool"
                chmod +x "$bindir/$tool"
                ;;
        esac
    done
}

fake_bin=$(mktemp -d)
trap 'PATH="/usr/sbin:/usr/bin:/bin:/usr/local/sbin:/usr/local/bin"; rm -rf -- "$fake_bin"' EXIT

make_fake_bin "$fake_bin" apt-get dpkg
PATH="$fake_bin:/usr/sbin:/usr/bin:/bin"
OS_ID="ubuntu"
PACKAGE_MANAGER=""
detect_package_manager
assert_equals "$PACKAGE_MANAGER" "apt" "detect_package_manager selects APT on Ubuntu"
assert_equals "$(package_manager_cache_path)" "/var/cache/apt/archives" "APT cache path is correct"

make_fake_bin "$fake_bin" dnf
PATH="$fake_bin:/usr/sbin:/usr/bin:/bin"
OS_ID="fedora"
PACKAGE_MANAGER=""
detect_package_manager
assert_equals "$PACKAGE_MANAGER" "dnf" "detect_package_manager selects DNF on Fedora"
assert_equals "$(package_manager_cache_path)" "/var/cache/dnf" "DNF cache path is correct"

make_fake_bin "$fake_bin" pacman
PATH="$fake_bin:/usr/sbin:/usr/bin:/bin"
OS_ID="arch"
PACKAGE_MANAGER=""
detect_package_manager
assert_equals "$PACKAGE_MANAGER" "pacman" "detect_package_manager selects Pacman on Arch"
assert_equals "$(package_manager_cache_path)" "/var/cache/pacman/pkg" "Pacman cache path is correct"

make_fake_bin "$fake_bin" apk
PATH="$fake_bin:/usr/sbin:/usr/bin:/bin"
OS_ID="alpine"
PACKAGE_MANAGER=""
detect_package_manager
assert_equals "$PACKAGE_MANAGER" "apk" "detect_package_manager selects APK on Alpine"
assert_equals "$(package_manager_cache_path)" "/var/cache/apk" "APK cache path is correct"

PATH="/nonexistent"
OS_ID="unknown"
PACKAGE_MANAGER=""
detect_package_manager
assert_equals "$PACKAGE_MANAGER" "none" "detect_package_manager stays in degraded mode when no adapter is available"
assert_equals "$(package_manager_name)" "none" "package_manager_name reports no adapter"

PACKAGE_MANAGER="dnf"
if (cleanup_old_kernels >/dev/null 2>&1); then
    printf 'ok - kernel cleanup is skipped on non-APT systems\n'
else
    printf 'not ok - kernel cleanup should skip on non-APT systems\n' >&2
    exit 1
fi

printf 'Phase 2 detection tests passed\n'
