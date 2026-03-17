#!/usr/bin/env bash
# ============================================
# lib/disk.sh - Disk usage monitoring function
# ============================================

check_disk(){
    #Verify that DISK THRESHOLD is set
    if [[ -z "$DISK_THRESHOLD" ]]; then
       echo "Error: DISK Threshold is not set. Verify the configuration file" >&2
       return 1
    fi

    # Verify that the DISK Threshold value is set correctly
    if ! [[ "$DISK_THRESHOLD" =~ ^[0-9]+$ && "$DISK_THRESHOLD" -le 100 ]]; then
        echo "Error: DISK Threshold is set to incorrect value. Verify the configuration file" >&2
        return 1
    fi

    local found_alert=false

    # Read each line from df output, skipping the header row
    while IFS=  read -r line; do

        local usage
        local mount
        local filesystem
        usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        mount=$(echo "$line" | awk '{print $6}')
        filesystem=$(echo "$line" | awk '{print $1}')

        # Skip virtual/pseudo filesystems - they are not real disks
        if [[ "$filesystem" == tmpfs* ]] || [[ "$filesystem" == devtmpfs* ]] || [[ "$filesystem" == udev* ]]; then
            continue
        fi

        local status="OK"
        if [ "$usage" -ge "$DISK_THRESHOLD" ]; then
            status="ALERT"
            found_alert=true
        fi

        echo "${status} | Disk [${mount}]: ${usage}% used (threshold: ${DISK_THRESHOLD}%)"

    done < <(df -h | tail -n +2)
}
