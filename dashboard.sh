#!/usr/bin/env bash

# Bash System Health Dashboard
# Group members: Rose Thomas and Alfonso Sanchez
#
# Rose Thomas:
# - Main script structure
# - System Info
# - CPU & Memory
# - Disk Usage
# - Top Processes
# - Watch mode
# - Fedora testing
#
# Alfonso Sanchez:
# - Network
# - Services
# - Logins & Users
# - Recent Log Errors
# - Missing-command review
# - Ubuntu Server testing

WATCH_INTERVAL=5

print_section() {
    printf "\n============================================================\n"
    printf " %s\n" "$1"
    printf "============================================================\n"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

display_dashboard() {
    clear

    printf "############################################################\n"
    printf "#              LINUX SYSTEM HEALTH DASHBOARD               #\n"
    printf "############################################################\n"
    printf "Group: Rose Thomas and Alfonso Sanchez\n"
    printf "Generated: %s\n" "$(date)"
}

show_usage() {
    printf "Usage: %s [OPTION]\n" "$0"
    printf "\nOptions:\n"
    printf "  --watch    Refresh every %s seconds\n" "$WATCH_INTERVAL"
    printf "  --help     Display this help message\n"
}

main() {
    case "${1:-}" in
        "")
            display_dashboard
            ;;
        --watch)
            while true; do
                display_dashboard
                printf "\nRefreshing every %s seconds. Press Ctrl+C to stop.\n" \
                    "$WATCH_INTERVAL"
                sleep "$WATCH_INTERVAL"
            done
            ;;
        --help|-h)
            show_usage
            ;;
        *)
            printf "Error: Unknown option '%s'\n\n" "$1" >&2
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
