#!/usr/bin/env bash

# ========================================
# lib/logging.sh - Logging functionality
#=========================================

log(){
    # Usage: log "LEVEL" "message"
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Configure formatting
    local log_line="[${timestamp}] [${level}] [${message}]"

    # Write to the log file AND print to the terminal at the same time
    echo "$log_line" | tee "$LOG_FILE"
}
