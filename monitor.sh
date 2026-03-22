#!/usr/bin/env bash

# ===========================================================
# monitor.sh - Main entry point for the system health monitors
# Usage: ./monitor.sh [-c cpu%] [-m memory%] [-d disk%] [-p processes]
# ===========================================================

# --- Safety Options ---
set -e          # Exit immediately if any command fails
set -u          # Treat unset variables as errors
set -o pipefail # A pipeline fails if any command in it fails

# --- Resolve Script Directory ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Source Configuration and Library Files ---
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib/cpu.sh"
source "${SCRIPT_DIR}/lib/disk.sh"
source "${SCRIPT_DIR}/lib/memory.sh"
source "${SCRIPT_DIR}/lib/processes.sh"
source "${SCRIPT_DIR}/lib/logging.sh"

# Ensure the log directory exists
mkdir -p "$LOG_DIR"

#===================================================
# Processing input options
#===================================================
while getopts ":c:p:d:m:h" option; do
    case $option in
        h)
        cat << EOF
Usage: ./monitor.sh [-c CPU%] [-m MEMORY%] [-d DISK%] [-p PROCESSES]
-c CPU usage threshold (0-100)
-m Memory usage threshold (0-100)
-d Disk usage threshold (0-100)
-p Process count threshold
-h Help
EOF
exit 0;;
        c)
            if [[ "$OPTARG" =~ ^[0-9]+$ && "$OPTARG" -le 100 ]]; then
                CPU_THRESHOLD="$OPTARG"
                log "INFO" "CPU threshold overridden to $OPTARG%"
            else
                echo "Invalid argument. Please select a number (integer) between 0 and 100." >&2
                exit 1
            fi;;
        d)
            if [[ "$OPTARG" =~ ^[0-9]+$ && "$OPTARG" -le 100 ]]; then
                DISK_THRESHOLD="$OPTARG"
                log "INFO" "Disk usage threshold overridden to $OPTARG%"
            else
                echo "Invalid argument. Please select a number (integer) between 0 and 100." >&2
                exit 1
            fi;;
        m)
            if [[ "$OPTARG" =~ ^[0-9]+$ && "$OPTARG" -le 100 ]]; then
                MEMORY_THRESHOLD="$OPTARG"
                log "INFO" "Memory usage threshold overridden to $OPTARG%"
            else
                echo "Invalid argument. Please select a number (integer) between 0 and 100." >&2
                exit 1
            fi;;
        p)
            if [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
                PROCESS_THRESHOLD="$OPTARG"
                log "INFO" "Process count threshold overridden to $OPTARG"
            else
                echo "Invalid argument. Please select a number (integer) that's greater or equal 0." >&2
            exit 1
            fi;;
        \?)
            echo "Error: Invalid option -$OPTARG" >&2
            exit 1;;
        :)
            echo "Error: Option -$OPTARG requires an argument" >&2
            exit 1;;
    esac
done
shift $(( OPTIND - 1 ))

# ======================================================
# Main health check
# ======================================================
run_health_check(){
    log "INFO" ======================================================
    log "INFO" "System Health Check Started"
    log "INFO" "Hostname: $(hostname)"
    log "INFO" "======================================================"

    local result
    local check_count=0
    local alert_count=0

    # --- CPU Checks ---
    if result=$(check_cpu); then
        check_count=$(( check_count + 1 ))
        if [[ "$result" == ALERT* ]]; then
            log "ALERT" "$result"
            notify-send "System Health Alert" "$result"
            alert_count=$(( alert_count + 1 ))
        else
            log "INFO" "$result"
        fi
    else
        log "WARN" "CPU check skipped"
    fi

    # --- Memory Checks ---
    if result=$(check_memory); then
        check_count=$(( check_count + 1 ))
        if [[ "$result" == ALERT* ]]; then
            log "ALERT" "$result"
            notify-send "System Health Alert" "$result"
            alert_count=$(( alert_count + 1 ))
        else
            log "INFO" "$result"
        fi
    else
        log "WARN" "MEMORY check skipped"
    fi

    # --- Disk Checks ---
    # Disk is handled via a loop because check_disk returns one line per partition

    while IFS= read -r disk_line; do
        if [[ -n "$disk_line" ]]; then
            check_count=$(( check_count + 1 ))
            if [[ "$disk_line" == ALERT* ]]; then
                log "ALERT" "$disk_line"
                notify-send "System Health Alert" "$disk_line"
                alert_count=$(( alert_count + 1 ))
            else
                log "INFO" "$disk_line"
            fi
        else
            log "WARN" "DISK_CHECK_SKIPPED"
        fi
    done < <(check_disk || true)

    # --- Processes Checks ---
    if result=$(check_processes); then
        check_count=$(( check_count + 1 ))
        if [[ "$result" == ALERT* ]]; then
            log "ALERT" "$result"
            notify-send "System Health Alert" "$result"
            alert_count=$(( alert_count + 1 ))
        else
            log "INFO" "$result"
        fi
    else
        log "WARN" "Processes check skipped"
    fi
    log "INFO" "======================================================"
    log "INFO" "Health Check Complete"
    log "INFO" "Summary: $check_count checks completed, $alert_count alerts, $(( check_count - alert_count )) passed"
    log "INFO" "======================================================"
}

run_health_check
