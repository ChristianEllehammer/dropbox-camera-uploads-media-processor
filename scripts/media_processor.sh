#!/bin/bash
# Media Processor.sh
# Main orchestrator script that coordinates the processing of media files

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Set up logging
LOG_FILE="$LOG_DIR/media_processor_log_$(date +%Y%m%d).txt"
mkdir -p "$LOG_DIR"

# Function to log messages
log() {
    local level="${1:-INFO}"
    local message="${2:-}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

# Initialize counters
total_processed=0
total_skipped=0
total_warnings=0
total_errors=0

log "INFO" "=== Script started ==="
log "INFO" "Processing files: $@"

# Process each file
for f in "$@"; do
    # Convert to absolute path
    f="$(cd "$(dirname "$f")" && pwd)/$(basename "$f")"
    
    # Check if file exists
    if [ ! -f "$f" ]; then
        log "WARNING" "File not found: $f"
        ((total_warnings++))
        continue
    fi

    # Get file extension
    extension="${f##*.}"
    extension_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

    # Process based on file type
    if [[ "$extension_lower" == "heic" ]]; then
        # Step 1: Convert HEIC to JPG
        log "INFO" "Converting HEIC to JPG: $f"
        if "$SCRIPT_DIR/image_converter.sh" "$f"; then
            # Get the new JPG file path
            jpg_file="${f%.*}.jpg"
            if [ -f "$jpg_file" ]; then
                # Step 2: Optimize the JPG
                log "INFO" "Optimizing JPG: $jpg_file"
                if "$SCRIPT_DIR/image_processor.sh" "$jpg_file"; then
                    # Step 3: Organize the optimized JPG
                    log "INFO" "Organizing optimized JPG: $jpg_file"
                    if "$SCRIPT_DIR/file_organizer.sh" "$jpg_file"; then
                        log "INFO" "Successfully processed HEIC file: $f"
                        ((total_processed++))
                    else
                        log "ERROR" "Failed to organize JPG file: $jpg_file"
                        ((total_errors++))
                    fi
                else
                    log "ERROR" "Failed to optimize JPG file: $jpg_file"
                    ((total_errors++))
                fi
            else
                log "ERROR" "JPG file not found after conversion: $jpg_file"
                ((total_errors++))
            fi
        else
            log "ERROR" "Failed to convert HEIC file: $f"
            ((total_errors++))
        fi
    elif [[ "$extension_lower" == "mov" ]]; then
        # Step 1: Convert MOV to MP4
        log "INFO" "Converting MOV to MP4: $f"
        if "$SCRIPT_DIR/video_processor.sh" "$f"; then
            # Get the new MP4 file path
            mp4_file="${f%.*}.mp4"
            if [ -f "$mp4_file" ]; then
                # Step 2: Organize the MP4
                log "INFO" "Organizing MP4: $mp4_file"
                if "$SCRIPT_DIR/file_organizer.sh" "$mp4_file"; then
                    log "INFO" "Successfully processed MOV file: $f"
                    ((total_processed++))
                else
                    log "ERROR" "Failed to organize MP4 file: $mp4_file"
                    ((total_errors++))
                fi
            else
                log "ERROR" "MP4 file not found after conversion: $mp4_file"
                ((total_errors++))
            fi
        else
            log "ERROR" "Failed to convert MOV file: $f"
            ((total_errors++))
        fi
    elif [[ "$extension_lower" =~ ^(jpg|jpeg|png)$ ]]; then
        # Step 1: Optimize the image
        log "INFO" "Optimizing image: $f"
        if "$SCRIPT_DIR/image_processor.sh" "$f"; then
            # Step 2: Organize the optimized image
            log "INFO" "Organizing optimized image: $f"
            if "$SCRIPT_DIR/file_organizer.sh" "$f"; then
                log "INFO" "Successfully processed image file: $f"
                ((total_processed++))
            else
                log "ERROR" "Failed to organize image file: $f"
                ((total_errors++))
            fi
        else
            log "ERROR" "Failed to optimize image file: $f"
            ((total_errors++))
        fi
    else
        log "WARNING" "Unsupported file type: $f"
        ((total_warnings++))
        ((total_skipped++))
    fi
done

# Log summary
log "INFO" "=== Processing Summary ==="
log "INFO" "Total files processed: $total_processed"
log "INFO" "Files skipped: $total_skipped"
log "INFO" "Warnings: $total_warnings"
log "INFO" "Errors: $total_errors"
log "INFO" "=== Script finished ==="

# Exit with error if any errors occurred
if [ $total_errors -gt 0 ]; then
    exit 1
fi 
