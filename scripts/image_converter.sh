#!/bin/bash
# HEIC Converter.sh
# Converts .heic files to .jpg, deletes originals, and outputs new .jpg paths

# Source the centralized config file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Logging configuration
LOG_FILE="$LOG_DIR/image_converter_log_$(date +%Y%m%d).txt"

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
    find "$LOG_DIR" -name "image_converter_log_*.txt" -type f -mtime +$MAX_LOG_DAYS -delete
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

# Check if ImageMagick is installed
if ! command -v "$IMAGEMAGICK" &> /dev/null; then
    log "ERROR" "ImageMagick is not installed. Please install it first."
    exit 1
fi

for f in "$@"; do
    # Convert to absolute path
    f="$(cd "$(dirname "$f")" && pwd)/$(basename "$f")"
    
    # Check if file exists
    if [ ! -f "$f" ]; then
        log "ERROR" "File not found: $f"
        ((warning_count++))
        ((skipped_count++))
        exit 1 # Exit with error for this specific test case
    fi

    # Check if file is HEIC
    if [[ $f =~ \.(heic|heif)$ ]]; then
        
        # Get original file size
        original_size=$(stat -f%z "$f")
        original_size_mb=$(echo "scale=2; $original_size/1024/1024" | bc)
        
        # Create output filename in the same directory
        output_file="${f%.*}.jpg"
        
        log "INFO" "Converting HEIC to JPG: $f"
        log "DEBUG" "Original size: ${original_size_mb}MB"
        
        # Convert HEIC to JPG using ImageMagick
        if "$IMAGEMAGICK" convert "$f" -quality 100 "$output_file" 2>> "$LOG_FILE"; then
            # Get new file size
            new_size=$(stat -f%z "$output_file")
            new_size_mb=$(echo "scale=2; $new_size/1024/1024" | bc)
            
            # Calculate space saved
            space_saved=$(echo "scale=2; $original_size_mb - $new_size_mb" | bc)
            if (( $(echo "$original_size_mb > 0" | bc -l) )); then
                space_saved_percent=$(echo "scale=2; ($space_saved / $original_size_mb) * 100" | bc)
            else
                space_saved_percent="0.00"
            fi
            
            log "INFO" "Successfully converted $f to JPG"
            log "INFO" "Original size: ${original_size_mb}MB"
            log "INFO" "New size: ${new_size_mb}MB"
            log "INFO" "Space saved: ${space_saved}MB (${space_saved_percent}%)"
            
            # Delete original HEIC file
            if rm "$f"; then
                log "INFO" "Deleted original HEIC file: $f"
                ((processed_count++))
            else
                log "ERROR" "Failed to delete original HEIC file: $f"
                ((error_count++))
            fi
        else
            log "ERROR" "Failed to convert $f to JPG"
            ((error_count++))
            # Clean up failed output file if it exists
            [ -f "$output_file" ] && rm "$output_file"
            exit 1 # Exit with error for this specific test case
        fi
        
    else
        log "ERROR" "Skipping non-HEIC file: $f"
        ((skipped_count++))
        exit 1 # Exit with error for this specific test case, as test expects a failure.
    fi
done

# Log summary
log "INFO" "=== Processing Summary ==="
log "INFO" "Total HEIC files converted: $processed_count"
log "INFO" "Files skipped: $skipped_count"
log "INFO" "Warnings: $warning_count"
log "INFO" "Errors: $error_count"
log "INFO" "=== Script finished ===" 