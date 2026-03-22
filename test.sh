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

# Separate log file to avoid polluting the production health check log
LOG_FILE="${LOG_DIR}/test-$(date +%d-%m-%Y).log"

# --- Event occurrence count variables ---
check_count=0
pass_count=0
fail_count=0
skip_count=0
error_count=0

# Guard each function before capturing its output - catches sourcing failures early
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

# =========================================================
# General output tests - apply to all monitoring functions
# =========================================================
general_output_test() {

    cat << EOF
=====================================================================================================
Running basic output tests for all monitoring functions..
=====================================================================================================
EOF

    for arg in "$@"; do
        local func_name="$arg"
        local func_value="${!func_name}"

        while IFS= read -r test_value; do

            local skip_check=""

            # Check if the monitoring functions return empty value
            check_count=$(( check_count + 1 ))

            if [[ -z "$test_value" ]]; then
                log "FAIL" "${func_name} returned an empty result"
                fail_count=$(( fail_count + 1 ))
                skip_check="TRUE"
            else
                log "PASS" "${func_name} returned a non empty result"
                pass_count=$(( pass_count + 1 ))
            fi

            # Check if output contains a valid status prefix
            check_count=$(( check_count + 1 ))

            if [[ "$skip_check" == "TRUE" ]]; then
                log "SKIP" "Status Output Test skipped due to previously listed FAILURE"
                skip_count=$(( skip_count + 1 ))
            elif [[ "$test_value" == OK* || "$test_value" == ALERT* ]]; then
                log "PASS" "${func_name} output contains correct status (OK or ALERT)"
                pass_count=$(( pass_count + 1 ))
            else
                log "FAIL" "${func_name} does not contain the correct status output"
                fail_count=$(( fail_count + 1 ))
            fi

            # Check if output contains the word "threshold"
            check_count=$(( check_count + 1 ))

            if [[ "$skip_check" == "TRUE" ]]; then
                log "SKIP" "Threshold Check Test skipped due to previously listed FAILURE"
                skip_count=$(( skip_count + 1 ))
            elif [[ "$test_value" == *threshold*  ]]; then
                log "PASS" "${func_name} output contains threshold"
                pass_count=$(( pass_count + 1 ))
            else
                log "FAIL" "${func_name} does not contain threshold"
                fail_count=$((fail_count + 1 ))
            fi

        done <<< "$func_value"
    done

cat << EOF
=====================================================================================================
Basic output test run is now finished
=====================================================================================================

EOF
}


# =========================================================
# CPU specific tests
# =========================================================
cpu_output_test() {

    local skip_check=""

    cat << EOF
=====================================================================================================
Running CPU specific output test
=====================================================================================================
EOF

    if [[ -z "$CPU_TEST" ]]; then
        log "ERROR" "CPU_TEST returned an empty result. All further checks will be skipped"
        error_count=$(( error_count + 1 ))
        skip_check="TRUE"
    fi

    # Verify output contains "CPU Usage:" followed by a number
    check_count=$(( check_count + 1 ))

    if [[ "$skip_check" == "TRUE" ]]; then
        log "SKIP" "Check skipped due to the empty value of CPU_TEST"
        skip_count=$(( skip_count + 1 ))
    elif [[ "$CPU_TEST" =~ "CPU Usage: "[0-9]+ ]]; then
        log "PASS" "CPU_TEST contains CPU Usage"
        pass_count=$(( pass_count + 1 ))
    else
        log "FAIL" "CPU_TEST does not contain CPU Usage"
        fail_count=$(( fail_count + 1 ))
    fi

    # Verify output contains a percentage sign
    check_count=$(( check_count + 1 ))

    if [[ "$skip_check" == "TRUE" ]]; then
        log "SKIP" "Check skipped due to the empty value of CPU_TEST"
        skip_count=$(( skip_count + 1 ))
    elif [[ $CPU_TEST == *%* ]]; then
        log "PASS" "CPU_TEST contains '%' sign"
        pass_count=$(( pass_count + 1 ))
    else
        log "FAIL" "CPU_TEST does not contain '%' sign"
        fail_count=$(( fail_count + 1))
    fi

    # Force threshold to 0 to verify ALERT triggers correctly regardless of actual CPU usage
    local original_threshold="$CPU_THRESHOLD"
    CPU_THRESHOLD=0
    local override_value
    override_value=$(check_cpu)

    # Check if the status is correctly set to "ALERT" when function runs with threshold at 0
    check_count=$(( check_count + 1 ))

    if [[ "$skip_check" == "TRUE" ]]; then
        log "SKIP" "Check skipped due to the empty value of CPU_TEST"
        skip_count=$(( skip_count + 1 ))
    elif [[ "$override_value" == *ALERT* ]]; then
        log "PASS" "Threshold override test passed. Alert displayed when set to 0."
        pass_count=$(( pass_count + 1 ))
    else
        log "FAIL" "Threshold override test failed, due to unexpected return value"
        fail_count=$(( fail_count + 1 ))
    fi

    # Restore before next test runs
    CPU_THRESHOLD="$original_threshold"

    cat << EOF
=====================================================================================================
Finished CPU specific output test
=====================================================================================================

EOF
}

# =========================================================
# DISK specific tests
# =========================================================
disk_output_test() {

    cat << EOF
=====================================================================================================
Running DISK specific output test
=====================================================================================================
EOF

     if [[ -z "$DISK_TEST" ]]; then
        log "ERROR" "DISK_TEST returned empty"
        error_count=$(( error_count + 1 ))
    else
        while IFS= read -r disk_line; do

            # Verify each partition line contains correct "Disk [name]: formatting"
            check_count=$(( check_count + 1 ))

            if [[ "$disk_line" =~ "Disk "\[.+\] ]]; then
                log "PASS" "DISK_TEST contains the correct 'Disk [name]:' formatting"
                pass_count=$(( pass_count + 1 ))
            else
                log "FAIL" "DISK_TEST does not contain correct 'Disk [name]:' formatting"
                fail_count=$(( fail_count + 1 ))
            fi

            # Verify each partition line contains a percentage sign
            check_count=$(( check_count + 1 ))

            if [[ "$disk_line" == *%* ]]; then
                log "PASS" "DISK_TEST contains '%' sign"
                pass_count=$(( pass_count + 1 ))
            else
                log "FAIL" "DISK_TEST does not contain '%' sign"
                fail_count=$(( fail_count + 1 ))
            fi

        done <<< "$DISK_TEST"

        # Force threshold to 0 to verify ALERT triggers correctly regardless of actual DISK usage
            local original_threshold="$DISK_THRESHOLD"
            DISK_THRESHOLD=0
            local override_value
            override_value=$(check_disk)

            check_count=$(( check_count + 1 ))

            if [[ "$override_value" == *ALERT* ]]; then
                log "PASS" "Threshold override test passed. Alert displayed when set to 0."
                pass_count=$(( pass_count + 1 ))
            else
                log "FAIL" "Threshold override test failed, due to unexpected return value"
                fail_count=$(( fail_count + 1 ))
            fi

            # Restore before next test runs
            DISK_THRESHOLD="$original_threshold"
    fi

    cat << EOF
=====================================================================================================
Finished DISK specific output test
=====================================================================================================

EOF
}

# ============================================================
# Memory specific tests
# ============================================================
memory_output_test() {

    local skip_check=""

    cat << EOF
=====================================================================================================
Running MEMORY specific output test
=====================================================================================================
EOF

    if [[ -z "$MEMORY_TEST" ]]; then
        log "ERROR" "MEMORY_TEST returned an empty result. All further checks will be skipped"
        error_count=$(( error_count + 1 ))
        skip_check="TRUE"
    fi

    # Verify output contains "Memory" phrase
    check_count=$(( check_count + 1 ))

    if [[ "$skip_check" == "TRUE" ]]; then
        log "SKIP" "Contains 'Memory' test skipped due to previously listed error"
        skip_count=$(( skip_count + 1 ))
    elif [[ "$MEMORY_TEST" == *Memory* ]]; then
        log "PASS" "MEMORY_TEST output contains 'Memory' phrase"
        pass_count=$(( pass_count + 1 ))
    else
        log "FAIL" "MEMORY_TEST output does not contain 'Memory' phrase"
        fail_count=$(( fail_count + 1 ))
    fi

    # Verify output contains a percentage sign
    check_count=$(( check_count + 1 ))

    if [[ "$skip_check" == "TRUE" ]]; then
        log "SKIP" "Contains '%' test skipped due to previously listed error"
        skip_count=$(( skip_count + 1 ))
    elif [[ "$MEMORY_TEST" == *%* ]]; then
        log "PASS" "MEMORY_TEST output contains '%' sign"
        pass_count=$(( pass_count + 1 ))
    else
        log "FAIL" "MEMORY_TEST output does not contain '%' sign"
        fail_count=$(( fail_count + 1 ))
    fi

    # Verify output contains the "MB" size denominator
    check_count=$(( check_count + 1 ))

    if [[ "$skip_check" == "TRUE" ]]; then
        log "SKIP" "Contains 'MB' test skipped due to previously listed error"
        skip_count=$(( skip_count + 1 ))
    elif [[ "$MEMORY_TEST" == *MB* ]]; then
        log "PASS" "MEMORY_TEST output contains correct size denominator 'MB'"
        pass_count=$(( pass_count + 1 ))
    else
        log "FAIL" "MEMORY_TEST output does not contain correct size denominator 'MB'"
        fail_count=$(( fail_count + 1 ))
    fi

    # Force threshold to 0 to verify ALERT triggers correctly regardless of actual MEMORY usage
    local original_threshold="$MEMORY_THRESHOLD"
    MEMORY_THRESHOLD=0
    local override_value
    override_value=$(check_memory)

    check_count=$(( check_count + 1 ))

    if [[ "$skip_check" == "TRUE" ]]; then
        log "SKIP" "Check skipped due to the empty value of MEMORY_TEST"
        skip_count=$(( skip_count + 1 ))
    elif [[ "$override_value" == *ALERT* ]]; then
        log "PASS" "Threshold override test passed. Alert displayed when set to 0."
        pass_count=$(( pass_count + 1 ))
    else
        log "FAIL" "Threshold override test failed, due to unexpected return value"
        fail_count=$(( fail_count + 1 ))
    fi

    # Restore before next test runs
    MEMORY_THRESHOLD="$original_threshold"

    cat << EOF
=====================================================================================================
Finished MEMORY specific output test
=====================================================================================================

EOF
}

# ============================================================
# Processes specific tests
# ============================================================
processes_output_test() {

    local skip_check=""

    cat << EOF
=====================================================================================================
Running PROCESSES specific output test
=====================================================================================================
EOF

    if [[ -z "$PROCESSES_TEST" ]]; then
        log "ERROR" "PROCESSES_TEST returned an empty result. All further checks will be skipped"
        error_count=$(( error_count + 1 ))
        skip_check="TRUE"
    fi

    # Verify output contains "Running Processes" phrase
    check_count=$(( check_count + 1 ))

    if [[ "$skip_check" == "TRUE" ]]; then
        log "SKIP" "Contains 'Running Processes' test skipped due to previously listed error"
        skip_count=$(( skip_count + 1 ))
    elif [[ "$PROCESSES_TEST" == *"Running Processes"* ]]; then
        log "PASS" "PROCESSES_TEST output contains 'Running Processes' phrase"
        pass_count=$(( pass_count + 1 ))
    else
        log "FAIL" "PROCESSES_TEST output does not contain 'Running Processes' phrase"
        fail_count=$(( fail_count + 1 ))
    fi

    # Verfy output does NOT contain a percentage sign - processes is a count not a percentage
    check_count=$(( check_count + 1 ))

    if [[ "$skip_check" == "TRUE" ]]; then
        log "SKIP" "Does not containing '%' test skipped due to previously listed error"
        skip_count=$(( skip_count + 1 ))
    elif ! [[ "$PROCESSES_TEST" == *%* ]]; then
        log "PASS" "PROCESSES_TEST output does not contain '%' sign"
        pass_count=$(( pass_count + 1 ))
    else
        log "FAIL" "PROCESSES_TEST output contains '%' sign"
        fail_count=$(( fail_count + 1 ))
    fi

    # Force threshold to 0 to verify ALERT triggers correctly regardless of actual PROCESS count
    local original_threshold="$PROCESS_THRESHOLD"
    PROCESS_THRESHOLD=0
    local override_value
    override_value=$(check_processes)

    check_count=$(( check_count + 1 ))

    if [[ "$skip_check" == "TRUE" ]]; then
        log "SKIP" "Check skipped due to the empty value of PROCESSES_TEST"
        skip_count=$(( skip_count + 1 ))
    elif [[ "$override_value" == *ALERT* ]]; then
        log "PASS" "Threshold override test passed. Alert displayed when set to 0."
        pass_count=$(( pass_count + 1 ))
    else
        log "FAIL" "Threshold override test failed, due to unexpected return value"
        fail_count=$(( fail_count + 1 ))
    fi

    # Restore before next test runs
    PROCESS_THRESHOLD="$original_threshold"

    cat << EOF
=====================================================================================================
Finished PROCESSES specific output test
=====================================================================================================

EOF
}

# ============================================================
# Result summary
# ============================================================
result_summary() {

    cat << EOF
=====================================================================================================
Test Summary
=====================================================================================================
Checks performed = $check_count
Checks passed = $pass_count
Checks failed = $fail_count
Checks skipped = $skip_count
Errors encountered = $error_count
=====================================================================================================
Final Result:
EOF

# Validate the test results, to ensure the correct return status for the script
    if ! [[ "$fail_count" -gt 0 || "$error_count" -gt 0 ]]; then
        log "INFO" "All test runs have completed successfully"
    else
        log "WARN" "Tests failed: $fail_count, tests skipped $skip_count, tests with errors $error_count"
        exit 1
    fi

    cat << EOF
=====================================================================================================
EOF
}

general_output_test "CPU_TEST" "DISK_TEST" "MEMORY_TEST" "PROCESSES_TEST"
cpu_output_test
disk_output_test
memory_output_test
processes_output_test
result_summary
