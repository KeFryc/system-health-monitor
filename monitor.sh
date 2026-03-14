#!/usr/bin/env bash

# ===========================================================
# monitor.sh - Main entry point for the sytem health monitors
# Usage: ./monitor.sh
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

# ============================================================
# Logging Functionality
# ============================================================

# Ensure the log directory exists
mkdir -p "$LOG_DIR"

log() {
    #Usage: log "LEVEL" "message"
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    local log_line="[${timestamp}] [${level}] [${message}]"
    # Write to the log file AND print to the terminal at the same time
    echo "$log_line" | tee -a "$LOG_FILE"

}

# ======================================================
# Main health check
# ======================================================

run_health_check(){
    log "INFO" "========================================="
    log "INFO" "System Health Check Started"
    log "INFO" "Hostname: $(hostname)"
    log "INFO" "========================================="

    local result
    local check_count=0
    local alert_count=0

    # CPU
    result=$(check_cpu)
    check_count=$(( check_count + 1 ))
    if [[ "$result" == ALERT* ]]; then
        log "ALERT" "$result"
        notify-send "System Health Alert" "$result"
        alert_count=$(( alert_count + 1 ))
    else
        log "INFO" "$result"
    fi

    # Memory
    result=$(check_memory)
    check_count=$(( check_count + 1 ))
    if [[ "$result" == ALERT* ]]; then
        log "ALERT" "$result"
        notify-send "System Health Alert" "$result"
        alert_count=$(( alert_count + 1 ))
    else
        log "INFO" "$result"
    fi

    # Disk - produces multiple lines, so a loop is necessary
    while IFS= read -r disk_line; do
        check_count=$(( check_count + 1 ))
        if [[ "$disk_line" == ALERT* ]]; then
            log "ALERT" "$disk_line"
            notify-send "System Health Alert" "$disk_line"
            alert_count=$(( alert_count + 1 ))
        else
            log "INFO" "$disk_line"
        fi
    done < <(check_disk)

    # Processes
    result=$(check_processes)
    check_count=$(( check_count + 1 ))
    if [[ "$result" == ALERT* ]]; then
        log "ALERT" "$result"
        notify-send "System Health Alert" "$result"
        alert_count=$(( alert_count + 1 ))
    else
        log "INFO" "$result"
    fi

    log "INFO" "Health Check Complete"
    log "INFO" "Summary: $check_count checks completed, $alert_count alert, $(( $check_count - $alert_count )) passed"
    log "INFO" "======================================================"


}

run_health_check
