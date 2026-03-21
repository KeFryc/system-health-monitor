#!/usr/bin/env bash

# ========================================================
# test.sh - Monitoring function output test functionality
# ========================================================

# --- Safety Options ---
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
source "${SCRIPT_DIR}/lib/logging.sh"

# Override log filename, to ensure separation from standard logging process
LOG_FILE="${LOG_DIR}/test-$(date +%d-%m-%Y).log"

# Declare all variables for counting event occurence
check_count=0
pass_count=0
fail_count=0
skip_count=0
error_count=0

# --- Test if the monitoring function executes correctly and if so, assign the result to variable ---
if ! declare -f check_cpu > /dev/null; then
    log "ERROR" "check_cpu function not found - verify if it was sourced"
    error_count=$(( error_count + 1 ))
    CPU_TEST=""
else
    CPU_TEST=$(check_cpu)
fi

if ! declare -f check_disk > /dev/null; then
    log "ERROR" "check_disk function not found - verify if it was sourced"
    error_count=$(( error_count + 1 ))
    DISK_TEST=""
else
    DISK_TEST=$(check_disk)
fi

if ! declare -f check_memory > /dev/null; then
    log "ERROR" "check_memory function not found - verify if it was sourced"
    error_count=$(( error_count + 1 ))
    MEMORY_TEST=""
else
    MEMORY_TEST=$(check_memory)
fi

if ! declare -f check_processes > /dev/null; then
    log "ERROR" "check_processes function not found - verify if it was sourced"
    error_count=$(( error_count + 1 ))
    PROCESSES_TEST=""
else
    PROCESSES_TEST=$(check_processes)
fi

# Run tests applicable for all monitoring functions (value set, status output, contains threshold)
general_output_test(){

    cat << EOF
===========================================================
Running basic output tests for all monitoring functions..
===========================================================
EOF

    for arg in "$@"; do
        local func_name="$arg"
        local func_value="${!func_name}"
        local skip_check=""

        # Check if the monitoring function returns a result
        check_count=$(( check_count + 1 ))

        if [[ -z "$func_value" ]]; then
            log "FAIL" "${func_name} returned an empty result"
            fail_count=$(( fail_count + 1 ))
            skip_check="TRUE"
        else
            log "PASS" "${func_name} returned a non empty result"
            pass_count=$(( pass_count + 1 ))
        fi

        # Check the status output of the monitoring function
        check_count=$(( check_count + 1 ))

        if [[ "$skip_check" == "TRUE" ]]; then
            skip_count=$(( skip_count + 1 ))
        elif [[ "$func_value" == OK* || "$func_value" == ALERT* ]]; then
            log "PASS" "${func_name} output contains correct status (OK or ALERT)"
            pass_count=$(( pass_count + 1 ))
        else
            log "FAIL" "${func_name} does not contain the correct status output"
        fi

        # Check if the results of monitoring function contain "Threshold"
        check_count=$(( check_count + 1 ))

        if [[ "$skip_check" == "TRUE" ]]; then
            skip_count=$(( skip_count + 1 ))
        elif [[ "$func_value" == *threshold*  ]]; then
            log "PASS" "${func_name} output contains threshold"
            pass_count=$(( pass_count + 1 ))
        else
            log "FAIL" "${func_name} does not contain threshold"
            fail_count=$((fail_count + 1 ))
        fi


    done

cat << EOF
===========================================================
Basic output test run is now finished.
===========================================================

EOF
}

result_summary(){
    cat << EOF
===========================================================
Checks performed = $check_count
Checks passed = $pass_count
Checks failed = $fail_count
Checks skipped = $skip_count
Errors encountered = $error_count
===========================================================
EOF
    #Validating the results
    if ! [[ "$fail_count" -gt 0 || "$error_count" -gt 0 ]]; then
        log "INFO" "All test runs have completed succesfully"
    else
        log "WARN" "Tests failed: $fail_count, tests skipped $skip_count, tests with errors $error_count"
        exit 1
    fi
}

general_output_test "CPU_TEST" "DISK_TEST" "MEMORY_TEST" "PROCESSES_TEST"
result_summary
