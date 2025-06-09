#!/bin/bash

# Enable case-insensitive matching
shopt -s nocasematch

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the centralized config file
source "$SCRIPT_DIR/config.sh"

# Logging configuration
LOG_FILE="$LOG_DIR/organizer_log_$(date +%Y%m%d).txt"

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

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
    find "$LOG_DIR" -name "organizer_log_*.txt" -type f -mtime +$MAX_LOG_DAYS -delete
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
    DEST=""

    # Check if file exists
    if [ ! -f "$f" ]; then
        log "WARNING" "File not found: $f"
        ((warning_count++))
        ((skipped_count++))
        continue
    fi

    # Extract the year and month from the filename using regex
    if [[ $f =~ ([0-9]{4})-([0-9]{2})-([0-9]{2}) ]]; then
        year="${BASH_REMATCH[1]}"
        month="${BASH_REMATCH[2]}"
        
        # Determine the file type (photo or video) based on the file extension
        if [[ $f =~ \.(jpg|jpeg|png|dng|gif|heic|heif)$ ]]; then
            # Photo file destination
            dest="$BASE_DIR/$year/$year-$month/$year-$month - Blandet/Billeder"
            log "DEBUG" "Identified as photo file"
        elif [[ $f =~ \.(mp4|mov|avi|m4v)$ ]]; then
            # Video file destination
            dest="$BASE_DIR/$year/$year-$month/$year-$month - Blandet/Videoer"
            log "DEBUG" "Identified as video file"
        else
            log "WARNING" "Unsupported file type: $f"
            ((warning_count++))
            ((skipped_count++))
            continue
        fi
    else
        log "WARNING" "Could not extract date from filename: $f"
        ((warning_count++))
        ((skipped_count++))
        continue
    fi

    # Set the destination directory if identified
    if [[ -n "$dest" ]]; then
        DEST="$dest"
        log "DEBUG" "Destination set to: $DEST"
    fi

    # Move the file to the destination directory if it exists
    if [[ -n "$DEST" ]]; then
        mkdir -p "$DEST"
        log "INFO" "Moving $f to $DEST"
        
        # Move the file and check for errors
        if mv "$f" "$DEST"; then
            log "INFO" "Successfully moved $f to $DEST"
            ((processed_count++))
        else
            log "ERROR" "Error moving $f to $DEST"
            ((error_count++))
        fi
    else
        log "WARNING" "No matching destination found for $f"
        ((warning_count++))
        ((skipped_count++))
    fi
done

# Log summary
log "INFO" "=== Processing Summary ==="
log "INFO" "Total files processed: $processed_count"
log "INFO" "Files skipped: $skipped_count"
log "INFO" "Warnings: $warning_count"
log "INFO" "Errors: $error_count"
log "INFO" "=== Script finished ==="