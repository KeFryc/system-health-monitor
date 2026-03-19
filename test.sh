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

# --- Assign the result of monitoring functions to variables ---
CPU_TEST=$(check_cpu)
DISK_TEST=$(check_disk)
MEMORY_TEST=$(check_memory)
PROCESSES_TEST=$(check_processes)

# Run tests applicable for all monitoring functions (value set, status output, contains threshold)
generic_output_test(){
    local check_count=0
    local pass_count=0
    local fail_count=0
    local skip_count=0

    cat << EOF
===========================================================
Running basic output tests for all monitoring functions..
===========================================================
EOF

    for arg in "$@"; do
        local func_name="$arg"
        local func_value="${!func_name}"


        check_count=$(( check_count + 1 ))

        # Check if the monitoring function returns a result

        if ! [[ -z $func_value ]]; then
            log "PASS" "${func_name} returned a non-empty result"
            pass_count=$(( pass_count + 1 ))
        elif [[ -z $func_value ]]; then
            log "FAIL" "${func_name} returned empty result" >&2
            fail_count=$(( fail_count + 1 ))
            log "SKIP" "Skipping following ${func_name} runs due to the return value being empty"
            skip_count=$(( skip_count + 2 ))
            continue
        else
            log "ERROR" "Test didn't return the expected results"
        fi

        check_count=$(( check_count + 1 ))

        # Check the status output of the monitoring function
        if [[ "$func_value" == OK* || "$func_value" == ALERT* ]];then
            log "PASS" "${func_name} output contains correct status (OK or ALERT)"
            pass_count=$(( pass_count + 1 ))
        else
            log "FAIL" "${func_name} doesn't contact correct status output" >&2
            fail_count=$(( fail_count + 1 ))
        fi

        check_count=$(( check_count + 1 ))

        # Check if the results of monitoring function contain "Threshold"
        if [[ "$func_value" == *threshold* ]]; then
            log "PASS" "${func_name} output contains threshold"
            pass_count=$(( pass_count + 1 ))
        else
            log "FAIL" "${func_name} doesn't contain threshold" >&2
            fail_count=$(( fail_count + 1 ))
        fi

    done

cat << EOF
=======================================================
Testing is now finished with the following results:
Checks performed = $check_count
Checks passed = $pass_count
Checks failed = $fail_count
Checks skipped = $skip_count
=======================================================
EOF

    if ! [[ "$fail_count" -gt 0 ]]; then
        log "INFO" "All test runs have completed succesfully"
    else
        log "WARN" "Tests failed: $fail_count, tests skipped $skip_count"
        exit 1
    fi

}

generic_output_test "CPU_TEST" "DISK_TEST" "MEMORY_TEST" "PROCESSES_TEST"


