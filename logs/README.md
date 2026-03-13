# System Health Monitor

A Bash-based system monitoring tool that tracks CPU, memory, disk and process usage on a Linux operating system. It runs automatically via cron and logs health status with threshold-based alerting.

## What It Does

- Monitors CPU, memory, disk (per partition with exception of virtual disks), and process count
- Compares each metric agains a configurable threshold
- Logs results to a daily log file with timestamps and severity levels
- Raises ALERT entries when any metric exceeds its threshold
- Runs automatically on a schedule via cron

## Requirements
- Linux (tested on Ubuntuy 22.04)
- Bash 4.0 or higher
- Standard GNU utilities: top, free, df, ps, awk, date

## Setup

### 1. Clone the repository
git clone https://github.com/KeFryc/system-health-monitor.git
cd system-health-monitor

### 2. Make scripts executable
chmod +x monitor.sh lib/*.sh

### 3. Run manually and confirm that it runs as expected
./monitor.sh

### 4. Schedule with cron (by default every 5 minutes)
realpath monitor.sh (to find absolute path of the script)
crontab -e
# Add: */5 * * * * /absolute/path/to/monitor.sh >> /absolute/path/to/logs/cron.log 2>&1

## Configuration

Edit config.sh to adjust thresholds:

| Variable          | Default | Description                       |
|-------------------|---------|-----------------------------------|
| CPU_THRESHOLD     | 80      | CPU % that triggers an alert      |
| MEMORY_THRESHOLD  | 80      | Memory % that triggers an alert   |
| DISK_THRESHOLD    | 85      | Disk % that triggers an alert     |
| PROCESS_THRESHOLD | 200     | Process count that triggers alert |

## Log Output

Log files are created in logs/, named by date: health-DD-MM-YYYY.log

Example:
[2026-03-13 20:40:01] [INFO] [OK | Disk [/]: 31% used (threshold: 85%)]
[2026-03-13 20:40:01] [ALERT] [ALERT | Running Processes: 248 (threshold: 200)]
