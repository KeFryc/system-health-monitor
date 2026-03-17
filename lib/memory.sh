#!/usr/bin/env bash
# ================================================
# lib/memory.sh - Memory usage monitoring function
# ================================================

check_memory() {
    # Verify that Memory THRESHOLD is set
    if [[ -z "$MEMORY_THRESHOLD" ]]; then
       echo "Error: Memory Threshold is not set. Verify the configuration file" >&2
       return 1
    fi

    # Verify that the Memory Threshold value is set correctly
    if ! [[ "$MEMORY_THRESHOLD" =~ ^[0-9]+$ && "$MEMORY_THRESHOLD" -le 100 ]]; then
        echo "Error: Memory Threshold is set to incorrect value. Verify the configuration file" >&2
        return 1
    fi

    # 'free -m' shows memory in megabytes
    # awk extracts total and used from the 'Mem: ' line
    local mem_total
    local mem_used
    mem_total=$(free -m | awk '/^Mem:/ {print $2}')
    mem_used=$(free -m | awk '/^Mem:/ {print $3}')

    local mem_usage
    mem_usage=$(awk "BEGIN {printf \"%.0f\",($mem_used / $mem_total) * 100}")

    local status="OK"
    if [ "$mem_usage" -ge "$MEMORY_THRESHOLD" ]; then
        status="ALERT"
    fi

    echo "${status} | Memory: ${mem_usage}% - ${mem_used}MB used of ${mem_total}MB (threshold: ${MEMORY_THRESHOLD}%)"
}
