#!/usr/bin/env bash

# ====================================================
# lib/processes.sh - Process count monitoring function
# ====================================================

check_processes() {
    # 'ps aux' lists all processes for all users
    # 'wc -l' counts lines - subtract 1 for the header row
    local total_processes
    total_processes=$(ps aux | wc -l)
    total_processes=$((total_processes -1))

    local status="OK"
    if [ "$total_processes" -ge "PROCESS_THRESHOLD" ]; then
        status="ALERT"
    fi

    echo "${status} | Running Processes: ${total_processes} (threshold: ${PROCESS_THRESHOLD})"
}
