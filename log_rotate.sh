#!/usr/bin/env bash

# ===================================================
# log_rotate.sh - Log cleanup function
# ===================================================

# --- Safety Options ---
set -e          # Exit immediately if any command fails
set -u          # Treat unset variables as errors
set -o pipefail # A pipeline fails if any command in it fails

# --- Resolve Script Directory ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Source Configuration and Library Files ---
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib/logging.sh"


# --- Log removal function ---
remove_log(){

    cat << EOF
====================================
Starting Log Removal
====================================
EOF

    # Write file name that is removed to stdout and remove the file
    while IFS= read -r file; do
        log "INFO" "Removing: $file"
        rm "$file"
    done < <(find "${LOG_DIR}" -name "*.log" -mtime +30)

    cat << EOF

====================================
Log Removal Finished
====================================
EOF
}

# Execute "remove_log" function
remove_log
