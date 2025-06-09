#!/bin/bash

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Function to log messages
log() {
    local level="${1:-INFO}"
    local message="${2:-}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
}

# Function to clean logs
clean_logs() {
    local log_dir="$LOG_DIR"
    local max_days="$MAX_LOG_DAYS"
    
    log "INFO" "Starting log cleanup..."
    log "INFO" "Removing logs older than $max_days days"
    
    # Find and remove old log files
    find "$log_dir" -type f -name "*_log_*.txt" -mtime +$max_days -exec rm -v {} \;
    
    # Count remaining log files
    local remaining_logs=$(find "$log_dir" -type f -name "*_log_*.txt" | wc -l)
    log "INFO" "Cleanup complete. $remaining_logs log files remaining"
}

# Run cleanup
clean_logs 