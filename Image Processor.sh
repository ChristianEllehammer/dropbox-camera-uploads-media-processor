#!/bin/bash

# Enable case-insensitive matching
shopt -s nocasematch

# Logging configuration
LOG_DIR="/Users/christian/Dropbox/Dokumenter/Computer/Scripts and Apps/Automator/Folder Actions/Dropbox - Camera Uploads/logs"
LOG_FILE="$LOG_DIR/optimizer_log_$(date +%Y%m%d).txt"
MAX_LOG_DAYS=30  # Keep logs for 30 days
LOG_LEVEL="INFO"  # Can be DEBUG, INFO, WARNING, ERROR

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Path to ImageOptim CLI
IMAGEOPTIM_CLI="/opt/homebrew/bin/imageoptim"

# Function to format file size in human readable format with one decimal place
format_size() {
    local size=$1
    local units=("B" "KB" "MB" "GB")
    local unit=0
    local display_size=$size
    
    # Use awk for floating point arithmetic
    while [ $(awk "BEGIN {print ($display_size >= 1024)}") -eq 1 ] && [ $unit -lt ${#units[@]} ]; do
        display_size=$(awk "BEGIN {printf \"%.1f\", $display_size/1024}")
        unit=$((unit + 1))
    done
    echo "$display_size ${units[$unit]} ($size bytes)"
}

# Function to log messages with timestamp and log level
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Convert log level to numeric value for comparison
    local level_num=0
    case $LOG_LEVEL in
        "DEBUG") level_num=0 ;;
        "INFO") level_num=1 ;;
        "WARNING") level_num=2 ;;
        "ERROR") level_num=3 ;;
    esac
    
    local msg_level_num=0
    case $level in
        "DEBUG") msg_level_num=0 ;;
        "INFO") msg_level_num=1 ;;
        "WARNING") msg_level_num=2 ;;
        "ERROR") msg_level_num=3 ;;
    esac
    
    # Only log if message level is >= configured log level
    if [ $msg_level_num -ge $level_num ]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
}

# Function to rotate old logs
rotate_logs() {
    find "$LOG_DIR" -name "optimizer_log_*.txt" -type f -mtime +$MAX_LOG_DAYS -delete
}

# Initialize error tracking
declare -i error_count=0
declare -i warning_count=0
declare -i processed_count=0
declare -i skipped_count=0

# Rotate old logs
rotate_logs

# Log script start
log "INFO" "=== Script started ==="
log "INFO" "Processing files: $@"

for f in "$@"; do
    # Check if file exists
    if [ ! -f "$f" ]; then
        log "ERROR" "File does not exist: $f"
        ((error_count++))
        continue
    fi

    # Check if file is an image (supported types)
    if [[ $f =~ \.(jpg|jpeg|png|gif|heic|heif|webp|tiff|tif)$ ]]; then
        # Get original file size
        original_size=$(stat -f%z "$f")
        original_size_formatted=$(format_size $original_size)
        
        log "INFO" "Optimizing $f with ImageOptim..."
        log "DEBUG" "Original size: $original_size_formatted"
        
        # Change to the directory containing the file
        cd "$(dirname "$f")" || {
            log "ERROR" "Could not change to directory: $(dirname "$f")"
            ((error_count++))
            continue
        }
        
        # Run ImageOptim with just the filename
        if "$IMAGEOPTIM_CLI" --no-quit "$(basename "$f")" 2>> "$LOG_FILE"; then
            # Get new file size
            new_size=$(stat -f%z "$f")
            new_size_formatted=$(format_size $new_size)
            saved_size=$((original_size - new_size))
            saved_size_formatted=$(format_size $saved_size)
            if [ $original_size -gt 0 ]; then
                savings_percent=$(awk "BEGIN {printf \"%.1f\", ($saved_size*100)/$original_size}")
            else
                savings_percent="0.0"
            fi
            
            log "INFO" "Optimization details for $f:"
            log "INFO" "  Original size: $original_size_formatted"
            log "INFO" "  New size:      $new_size_formatted"
            log "INFO" "  Space saved:   $saved_size_formatted (${savings_percent}%)"
            log "INFO" "  (Original: $original_size bytes, New: $new_size bytes, Saved: $saved_size bytes)"
            ((processed_count++))
        else
            log "ERROR" "Error optimizing $f (Exit code: $?)"
            ((error_count++))
        fi
    else
        log "WARNING" "Skipping non-image file: $f"
        ((skipped_count++))
        ((warning_count++))
    fi
done

# Log summary
log "INFO" "=== Processing Summary ==="
log "INFO" "Total files processed: $processed_count"
log "INFO" "Files skipped: $skipped_count"
log "INFO" "Warnings: $warning_count"
log "INFO" "Errors: $error_count"
log "INFO" "=== Script finished ===" 