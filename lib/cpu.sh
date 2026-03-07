#!/usr/bin/env bash
# ========================================================
# lib/cpu.sh - CPU usage monitoring function
# ==========================================================

check_cpu(){
    # 'top' in batch mode, single iteration - extract the idle %
    # then subtract from 100 to get usage %
    local cpu_idle
    cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d'%' -f1)

    # Bash doesn't handle decimal arithmetic, so we use awk for this
    local cpu_usage
    cpu_usage=$(awk "BEGIN {printf \"%.0f\", 100 - $cpu_idle}")

    local status="OK"
    if ["cpu_usage" -ge "$CPU_THRESHOLD"]; then
        status="ALERT"
    fi

    echo "${status} | CPU Usage: ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
}
