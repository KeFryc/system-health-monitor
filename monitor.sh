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


#===================================================
# Processing input options
#===================================================

# Get the options
while getopts ":c:p:d:m:" option; do
    case $option in
        c)  # Change the CPU THRESHOLD temporarily
            if [[ "$OPTARG" =~ ^[0-9]+$ && "$OPTARG" -ge 0 && "$OPTARG" -le 100 ]]; then
                CPU_THRESHOLD="$OPTARG"
                echo "CPU % Threshold has been temporarily changed to $OPTARG"
            else
                echo "Invalid argument. Please select a number (integer) between 0 and 100."
                exit
            fi;;
        d)  # Change the Disk Usage % Threshold temporarily
            if [[ "$OPTARG" =~ ^[0-9]+$ && "$OPTARG" -ge 0 && "$OPTARG" -le 100 ]]; then
                DISK_THRESHOLD="$OPTARG"
                echo "Disk Usage % Threshold has been temporarily changed to $OPTARG"
            else
                echo "Invalid argument. Please select a number (integer) between 0 and 100."
                exit
            fi;;
        m)  # Change the Memory Usage % Threshold temporarily
            if [[ "$OPTARG" =~ ^[0-9]+$ && "$OPTARG" -ge 0 && "$OPTARG" -le 100 ]]; then
                MEMORY_THRESHOLD="$OPTARG"
                echo "Memory Usage % Threshold has been temporarily changed to $OPTARG"
            else
                echo "Invalid argument. Please select a number (integer) between 0 and 100."
                exit
            fi;;
        p)  # Change the Processes Count Threshold temporarily
            if [[ "$OPTARG" =~ ^[0-9]+$ && "$OPTARG" -ge 0 ]]; then
                PROCESS_THRESHOLD="$OPTARG"
                echo "Process threshold has been temporarily changed to $OPTARG"
            else
                echo "Invalid argument. Please select a number (integer) that's greater or equal 0."
            exit
            fi;;
        *)  # Invalid option
            echo "Error: Invalid option selected"
            exit;;

    esac
done
shift $(( OPTIND - 1 ))

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
    log "INFO" "Summary: $check_count checks completed, $alert_count alert, $(( check_count - alert_count )) passed"
    log "INFO" "======================================================"
}
run_health_check
