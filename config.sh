#!/usr/bin/env bash
# ==============================================================
# config.sh - Configuration and threshold for the health monitor
# ==============================================================

# --- CPU ---
CPU_THRESHOLD=80

# --- Memory ---
MEMORY_THRESHOLD=80

# --- Disk ---
DISK_THRESHOLD=85

# --- Processes ---
PROCESS_THRESHOLD=200

# --- Logging ---
LOG_DIR="$(dirname "$0")/logs"
LOG_FILE="${LOG_DIR}/health-$(date +%d-%m-%Y).log"
