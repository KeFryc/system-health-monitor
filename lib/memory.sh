#!/usr/bin/env bash
# ================================================
# lib/memory.sh - Memory usage monitoring function
# ================================================

check_memory() {
    # 'free -m' shows memory in megabytes
    # awk extracts total and used from the 'Mem: ' line
    local mem_total
    local mem_used
    mem_total=$(free -m | awk '/^Mem:/ {print $2}')
    mem_used=$(free -m | awk '/^Mem:/ {print $3}')

    local mem_usage
    mem_usage=$(awk "BEGIN {printf \"%.0f\",($mem_used / $mem_total) * 100}")

    local status="OK"
    if [ "$mem_usage" -ge "MEMORY_THRESHOLD" ]; then
        status="ALERT"
    fi

    echo "${status} | Memory: ${mem_usage}% - ${mem_used}MB used of ${mem_total}MB (threshold: ${MEMORY_THRESHOLD}%)"
}
