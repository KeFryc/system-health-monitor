#!/usr/bin/env bash

# ===================================================
# log_rotate.sh - Log cleanup function
# ===================================================

# --- Safety Options ---

set -e          # Exit immediately if any command fails
set -u          # Treat unset variables as errors
set -o pipefail # A pipeline fails if any command in it fails

# --- Log Directory ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"


# --- Log removal function ---
remove_log(){

    cat << EOF
====================================
Starting Log Removal
====================================
EOF

    # Write file name that is removed to stdout and remove the file
    while IFS= read -r file; do
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Removing: $file"
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
