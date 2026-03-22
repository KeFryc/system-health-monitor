#!/usr/bin/env bash
# ========================================================
# lib/cpu.sh - CPU usage monitoring function
# ==========================================================

check_cpu(){

    # Verify that CPU THRESHOLD is set
    if [[ -z "$CPU_THRESHOLD" ]]; then
       log "WARN" "CPU Threshold is not set. Verify the configuration file"
       return 1
    fi

    # Verify that the CPU Threshold value is set correctly
    if ! [[ "$CPU_THRESHOLD" =~ ^[0-9]+$ && "$CPU_THRESHOLD" -le 100 ]]; then
        log "WARN" "CPU Threshold is set to incorrect value. Verify the configuration file"
        return 1
    fi

    # 'top' in batch mode, single iteration - extract the idle % then subtract from 100 to get usage %
    local cpu_idle
    cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d'%' -f1)

    # Bash doesn't handle decimal arithmetic - we use awk for rounding
    local cpu_usage
    cpu_usage=$(awk "BEGIN {printf \"%.0f\", 100 - $cpu_idle}")

    local status="OK"
    if [ "$cpu_usage" -ge "$CPU_THRESHOLD" ]; then
        status="ALERT"
    fi

    echo "${status} | CPU Usage: ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
}
