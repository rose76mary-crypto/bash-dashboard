#!/usr/bin/env bash

# Bash System Health Dashboard
# Group Members: Rose Thomas and Alfonso Sanchez
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
# - Ubuntu Server testing
# - Cross-distribution review

WATCH_INTERVAL=5

# ------------------------------------------------------------
# Utility Functions
# ------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_section() {
    printf "\n============================================================\n"
    printf " %s\n" "$1"
    printf "============================================================\n"
}

print_unavailable() {
    printf "%s: Command or information unavailable\n" "$1"
}

# ------------------------------------------------------------
# System Information
# ------------------------------------------------------------

system_info() {
    print_section "SYSTEM INFO"

    if command_exists hostname; then
        printf "Hostname:          %s\n" "$(hostname)"
    else
        print_unavailable "Hostname"
    fi

    if command_exists uname; then
        printf "Kernel Details:    %s\n" "$(uname -a)"
    else
        print_unavailable "Kernel Details"
    fi

    if command_exists uptime; then
        if uptime -p >/dev/null 2>&1; then
            printf "Uptime:            %s\n" "$(uptime -p)"
        else
            printf "Uptime:            %s\n" "$(uptime)"
        fi
    else
        print_unavailable "Uptime"
    fi

    if command_exists date; then
        printf "Current Date/Time: %s\n" "$(date)"
    else
        print_unavailable "Current Date/Time"
    fi
}

# ------------------------------------------------------------
# CPU and Memory
# ------------------------------------------------------------

get_cpu_usage() {
    if [[ ! -r /proc/stat ]]; then
        printf "Unavailable"
        return
    fi

    local cpu
    local user
    local nice
    local system
    local idle
    local iowait
    local irq
    local softirq
    local steal

    local idle_before
    local total_before
    local idle_after
    local total_after
    local total_difference
    local idle_difference

    read -r cpu user nice system idle iowait irq softirq steal _ < /proc/stat

    idle_before=$((idle + iowait))
    total_before=$((user + nice + system + idle + iowait + irq + softirq + steal))

    sleep 1

    read -r cpu user nice system idle iowait irq softirq steal _ < /proc/stat

    idle_after=$((idle + iowait))
    total_after=$((user + nice + system + idle + iowait + irq + softirq + steal))

    total_difference=$((total_after - total_before))
    idle_difference=$((idle_after - idle_before))

    if (( total_difference <= 0 )); then
        printf "0.0%%"
        return
    fi

    awk -v total="$total_difference" -v idle="$idle_difference" \
        'BEGIN {
            usage = 100 * (total - idle) / total
            printf "%.1f%%", usage
        }'
}

cpu_memory() {
    print_section "CPU & MEMORY"

    if [[ -r /proc/loadavg ]]; then
        read -r load1 load5 load15 _ < /proc/loadavg

        printf "Load Average:      %s, %s, %s\n" \
            "$load1" "$load5" "$load15"
    elif command_exists uptime; then
        printf "Load Average:      %s\n" "$(uptime)"
    else
        print_unavailable "Load Average"
    fi

    printf "CPU Usage:         %s\n" "$(get_cpu_usage)"

    printf "\nMemory and Swap Usage:\n"

    if command_exists free; then
        free -h
    elif [[ -r /proc/meminfo ]]; then
        grep -E \
            'MemTotal|MemFree|MemAvailable|SwapTotal|SwapFree' \
            /proc/meminfo
    else
        printf "Memory and swap information unavailable.\n"
    fi
}

# ------------------------------------------------------------
# Disk Usage
# ------------------------------------------------------------

disk_usage() {
    print_section "DISK USAGE"

    if command_exists df; then
        df -h
    else
        printf "The df command is unavailable.\n"
    fi
}

# ------------------------------------------------------------
# Top Processes
# ------------------------------------------------------------

top_processes() {
    print_section "TOP PROCESSES"

    if ! command_exists ps; then
        printf "The ps command is unavailable.\n"
        return
    fi

    printf "Top 5 Processes by CPU Usage:\n"

    printf "%-8s %-12s %-25s %-8s %-8s\n" \
        "PID" "USER" "COMMAND" "%CPU" "%MEM"

    ps -eo pid=,user=,comm=,%cpu=,%mem= --sort=-%cpu 2>/dev/null |
        head -n 5 |
        awk '{
            printf "%-8s %-12s %-25s %-8s %-8s\n",
            $1, $2, $3, $4, $5
        }'

    printf "\nTop 5 Processes by Memory Usage:\n"

    printf "%-8s %-12s %-25s %-8s %-8s\n" \
        "PID" "USER" "COMMAND" "%CPU" "%MEM"

    ps -eo pid=,user=,comm=,%cpu=,%mem= --sort=-%mem 2>/dev/null |
        head -n 5 |
        awk '{
            printf "%-8s %-12s %-25s %-8s %-8s\n",
            $1, $2, $3, $4, $5
        }'
}

# ------------------------------------------------------------
# Network
# ------------------------------------------------------------

get_default_gateway() {
    if command_exists ip; then
        ip route 2>/dev/null |
            awk '/^default/ {
                print $3
                exit
            }'
    else
        printf "Unavailable"
    fi
}

get_primary_interface() {
    if command_exists ip; then
        ip route 2>/dev/null |
            awk '/^default/ {
                print $5
                exit
            }'
    else
        printf "Unavailable"
    fi
}

get_primary_ip() {
    local interface="$1"

    if command_exists ip &&
        [[ -n "$interface" ]] &&
        [[ "$interface" != "Unavailable" ]]; then

        ip -4 address show "$interface" 2>/dev/null |
            awk '/inet / {
                split($2, address, "/")
                print address[1]
                exit
            }'
    else
        printf "Unavailable"
    fi
}

network_info() {
    print_section "NETWORK"

    local interface
    local primary_ip
    local gateway
    local established_connections

    interface="$(get_primary_interface)"
    gateway="$(get_default_gateway)"
    primary_ip="$(get_primary_ip "$interface")"

    [[ -z "$interface" ]] && interface="Unavailable"
    [[ -z "$gateway" ]] && gateway="Unavailable"
    [[ -z "$primary_ip" ]] && primary_ip="Unavailable"

    printf "Primary Interface:       %s\n" "$interface"
    printf "Primary IPv4 Address:    %s\n" "$primary_ip"
    printf "Default Gateway:         %s\n" "$gateway"

    if command_exists ss; then
        established_connections="$(
            ss -H state established 2>/dev/null | wc -l
        )"

        printf "Established Connections: %s\n" \
            "$established_connections"

    elif command_exists netstat; then
        established_connections="$(
            netstat -ant 2>/dev/null |
                awk '$6 == "ESTABLISHED" {count++}
                     END {print count + 0}'
        )"

        printf "Established Connections: %s\n" \
            "$established_connections"

    else
        printf "Established Connections: Command unavailable\n"
    fi
}

# ------------------------------------------------------------
# Services
# ------------------------------------------------------------

get_service_status() {
    local display_name="$1"
    shift

    local service_name
    local found_service=""

    if ! command_exists systemctl; then
        printf "%-18s %s\n" "$display_name:" \
            "systemctl unavailable"
        return
    fi

    for service_name in "$@"; do
        if systemctl list-unit-files \
            "${service_name}.service" \
            --no-legend 2>/dev/null |
            grep -q "^${service_name}.service"; then

            found_service="$service_name"
            break
        fi
    done

    if [[ -z "$found_service" ]]; then
        printf "%-18s %s\n" "$display_name:" \
            "Not installed"
        return
    fi

    if systemctl is-active --quiet "$found_service"; then
        printf "%-18s %-12s (%s)\n" \
            "$display_name:" "ACTIVE" "$found_service"

    elif systemctl is-failed --quiet "$found_service"; then
        printf "%-18s %-12s (%s)\n" \
            "$display_name:" "FAILED" "$found_service"

    else
        printf "%-18s %-12s (%s)\n" \
            "$display_name:" "INACTIVE" "$found_service"
    fi
}

services_status() {
    print_section "SERVICES"

    # Fedora usually uses sshd, crond, firewalld.
    # Ubuntu commonly uses ssh, cron, and ufw.
    get_service_status "SSH Service" sshd ssh
    get_service_status "Cron Service" crond cron
    get_service_status "Firewall Service" firewalld ufw
}

# ------------------------------------------------------------
# Logins and Users
# ------------------------------------------------------------

logins_users() {
    print_section "LOGINS & USERS"

    printf "Currently Logged-In Users:\n"

    if command_exists who; then
        if [[ -n "$(who)" ]]; then
            who
        else
            printf "No users are currently listed as logged in.\n"
        fi
    else
        printf "The who command is unavailable.\n"
    fi

    printf "\nLast 3 Login Records:\n"

    if command_exists last; then
        last -n 3 2>/dev/null
    else
        printf "The last command is unavailable.\n"
    fi
}

# ------------------------------------------------------------
# Recent Log Errors
# ------------------------------------------------------------

recent_log_errors() {
    print_section "RECENT LOG ERRORS"

    if ! command_exists journalctl; then
        printf "The journalctl command is unavailable.\n"
        return
    fi

    local errors

    errors="$(
        journalctl -p err -n 5 --no-pager 2>/dev/null
    )"

    if [[ -n "$errors" ]]; then
        printf "%s\n" "$errors"
    else
        printf "No readable error entries were found.\n"
        printf "Some logs may require sudo permissions.\n"
    fi
}

# ------------------------------------------------------------
# Dashboard Display
# ------------------------------------------------------------

display_dashboard() {
    if command_exists clear; then
        clear
    else
        printf "\033[2J\033[H"
    fi

    printf "############################################################\n"
    printf "#              LINUX SYSTEM HEALTH DASHBOARD               #\n"
    printf "############################################################\n"

    printf "Group Members: Rose Thomas and Alfonso Sanchez\n"

    if command_exists date; then
        printf "Generated:     %s\n" "$(date)"
    fi

    system_info
    cpu_memory
    disk_usage
    top_processes
    network_info
    services_status
    logins_users
    recent_log_errors

    printf "\n============================================================\n"
    printf " Dashboard complete\n"
    printf "============================================================\n"
}

# ------------------------------------------------------------
# Help Menu
# ------------------------------------------------------------

show_usage() {
    printf "Usage: %s [OPTION]\n" "$0"

    printf "\nOptions:\n"
    printf "  --watch    Refresh the dashboard every %s seconds\n" \
        "$WATCH_INTERVAL"
    printf "  --help     Display this help message\n"
    printf "  -h         Display this help message\n"
}

# ------------------------------------------------------------
# Main Program
# ------------------------------------------------------------

main() {
    if (( $# > 1 )); then
        printf "Error: Too many arguments.\n\n" >&2
        show_usage
        exit 1
    fi

    case "${1:-}" in
        "")
            display_dashboard
            ;;

        --watch)
            while true; do
                display_dashboard

                printf "\nRefreshing every %s seconds." \
                    "$WATCH_INTERVAL"
                printf " Press Ctrl+C to stop.\n"

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