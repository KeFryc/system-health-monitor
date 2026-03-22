# System Health Monitor

A Bash based system monitoring tool that tracks CPU, memory, disk, and process usage on a Linux system. Runs automatically via cron, logs health status with threshold-based alerting, sends desktop notifications on alerts, and includes automated log rotation and a test suite for CI integration.

## What It Does

- Monitors CPU usage, memory usage, disk usage per partition and process count
- Compares each metric against a configurable threshold defined in 'config.sh
- Logs results to a daily log file with timestamps and severity levels
- Raises 'ALERT' entries when any metric exceeds its threshold
- Sends desktop notifications via 'notify-send' when ALERT is detected
- Supports temporary threshold overrides via command line arguments
- Rotates log files automatically, removing entries older than 30 days
- Includes a test suite (`test.sh`) that validates output format and threshold behaviour for each monitoring function

## Project Structure

system-health-monitor/
├── monitor.sh          # Main entry point — run this to start the health check
├── log_rotate.sh       # Log rotation script — run separately via cron
├── test.sh             # Test suite — validates monitoring function output
├── config.sh           # Thresholds and logging configuration
├── lib/
│   ├── cpu.sh          # CPU usage monitoring function
│   ├── disk.sh         # Disk usage monitoring function (per partition)
│   ├── memory.sh       # Memory usage monitoring function
│   ├── processes.sh    # Process count monitoring function
│   └── logging.sh      # Logging utility
└── logs/
    └── .gitkeep        # Keeps the logs directory tracked by

## Requirements

- Linux (tested on Ubuntu 22.04)
- Bash 4.0 or higher
- Standard GNU utilities: `top`, `free`, `df`, `ps`, `awk`, `date`, `find`
- `notify-send` for desktop notifications (part of `libnotify-bin` on Ubuntu)

## Setup

### 1. Clone the repository

git clone https://github.com/KeFryc/system-health-monitor.git
cd system-health-monitor

### 2. Make scripts executable

chmod +x monitor.sh log_rotate.sh test.sh lib/*.sh

### 3. Run manually and confirm that it runs as expected

./monitor.sh

### 4. Run the test suite

./test.sh

All tests should pass before scheduling via cron.

### 5. Schedule with cron

realpath monitor.sh
realpath log_rotate.sh

Open your crontab:
crontab -e

Add the following lines, replacing the paths with your actual output from `realpath`:

# Run health monitor every 5 minutes
*/5 * * * * /absolute/path/to/monitor.sh >> /absolute/path/to/logs/cron.log 2>&1

# Run log rotation daily at midnight
0 0 * * * /absolute/path/to/log_rotate.sh >> /absolute/path/to/logs/cron.log 2>&1

Verify the cron jobs were saved:
crontab -l

## Configuration

Edit config.sh to adjust thresholds:

| Variable          | Default | Description                       |
|-------------------|---------|-----------------------------------|
| CPU_THRESHOLD     | 80      | CPU % that triggers an alert      |
| MEMORY_THRESHOLD  | 80      | Memory % that triggers an alert   |
| DISK_THRESHOLD    | 85      | Disk % that triggers an alert     |
| PROCESS_THRESHOLD | 250     | Process count that triggers alert |

## Command-Line Overrides

Thresholds can be temporarily overridden at runtime without editing `config.sh`. The override applies only to that single run.

./monitor.sh [-c CPU%] [-m MEMORY%] [-d DISK%] [-p PROCESSES]

| Flag | Description                        | Valid values     |
|------|------------------------------------|------------------|
| `-c` | Override CPU threshold             | Integer 0–100    |
| `-m` | Override memory threshold          | Integer 0–100    |
| `-d` | Override disk threshold            | Integer 0–100    |
| `-p` | Override process count threshold   | Any integer ≥ 0  |
| `-h` | Display help                       | —                |

Example:

# Run with a lower CPU threshold to test alerting
./monitor.sh -c 10

## Log Output

Log files are created in logs/, named by date: logs/health-DD-MM-YYYY.log
logs/test-DD-MM-YYYY.log
logs/cron.log

Example:
[2026-03-13 20:40:01] [INFO] [OK | Disk [/]: 31% used (threshold: 85%)]
[2026-03-13 20:40:01] [ALERT] [ALERT | Running Processes: 248 (threshold: 200)]

## Alert Notifications

When an alert is detected, a desktop notification is sent via `notify-send`:
System Health Alert
ALERT | Running Processes: 261 (threshold: 250)

> Note: `notify-send` requires a graphical session. It will have no effect when running headlessly via cron on a server without a display.

## Log Rotation

`log_rotate.sh` removes all `.log` files in the `logs/` directory that are older than 30 days. It is designed to run independently of `monitor.sh` on its own cron schedule.

Log entries are written for each file removed:
[2026-03-20 00:00:01] [INFO] [Removing: logs/health-17-02-2026.log]

## Test Suite

`test.sh` validates the output format and threshold behaviour of each monitoring function. It is designed to be run manually during development and automatically as part of a CI pipeline.

Tests performed:

- Each function returns a non-empty result
- Each function output starts with `OK` or `ALERT`
- Each function output contains the word `threshold`
- CPU output contains `CPU Usage:` followed by a number and a `%` sign
- Memory output contains `Memory`, a `%` sign, and an `MB` denominator
- Disk output contains correct `Disk [name]:` formatting and a `%` sign per partition
- Processes output contains `Running Processes` and does **not** contain `%`
- All four functions correctly trigger `ALERT` when their threshold is forced to 0

Exit codes:
- `0` — all tests passed
- `1` — one or more tests failed or produced an error

## Known Limitations

- `notify-send` requires an active graphical session — alerts will not appear in headless or server environments
- The `general_output_test` in `test.sh` evaluates disk output as a multi-line string — per-line validation is handled separately in `disk_output_test`
- Kubernetes and container-based deployment are out of scope for this version — planned for a future revision

---

## Future Improvements

The following enhancements are planned for a later revision once additional tooling is introduced:
- GitHub Actions CI pipeline running `test.sh` on every push
- Boundary and regression tests in `test.sh`
- Integration test confirming end-to-end log file creation
- Terraform-based cloud deployment of the monitoring tool
