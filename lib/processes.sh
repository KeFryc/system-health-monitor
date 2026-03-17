#!/usr/bin/env bash

# ====================================================
# lib/processes.sh - Process count monitoring function
# ====================================================

check_processes() {

    # Verify that Process THRESHOLD is set
    if [[ -z "$PROCESS_THRESHOLD" ]]; then
       log "WARN" "Process Threshold is not set. Verify the configuration file" >&2
       return 1
    fi

    # Verify that the Process Threshold value is set correctly
    if ! [[ "$PROCESS_THRESHOLD" =~ ^[0-9]+$ ]]; then
        log "WARN" "Process Threshold is set to incorrect value. Verify the configuration file" >&2
        return 1
    fi


    # 'ps aux' lists all processes for all users
    # 'wc -l' counts lines - subtract 1 for the header row
    local total_processes
    total_processes=$(ps aux | wc -l)
    total_processes=$((total_processes -1))

    local status="OK"
    if [ "$total_processes" -ge "$PROCESS_THRESHOLD" ]; then
        status="ALERT"
    fi

    echo "${status} | Running Processes: ${total_processes} (threshold: ${PROCESS_THRESHOLD})"
}
