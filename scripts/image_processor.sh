#!/bin/bash
# Image Processor.sh
# Optimizes images using ImageOptim-CLI

set -euo pipefail

# Load configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/config.sh"

# Set up logging
LOG_FILE="$LOG_DIR/image_processor_log_$(date +%Y%m%d).txt"
mkdir -p "$LOG_DIR"

# Function to log messages
log() {
    local level="${1:-INFO}"
    local message="${2:-}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

# Check if imageoptim is installed
if ! command -v "imageoptim" &> /dev/null; then
    log "ERROR" "ImageOptim-CLI not found. Please install it: brew install imageoptim-cli"
    exit 1
fi

# Initialize counters
total_processed=0
total_skipped=0
total_warnings=0
total_errors=0

log "INFO" "=== Script started ==="

# Process all image files in the directory
for f in "$@"; do
    if [ ! -f "$f" ]; then
        log "ERROR" "File not found: $f"
        ((total_warnings++))
        ((total_skipped++))
        continue
    fi

    # Get file extension
    extension="${f##*.}"
    extension_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

    # Skip non-image files
    if [[ ! "$extension_lower" =~ ^(jpg|jpeg|png)$ ]]; then
        log "INFO" "Skipping non-image file: $f"
        ((total_skipped++))
        continue
    fi

    log "INFO" "Processing image: $f"
    
    # Get original file size
    original_size=$(du -h "$f" | cut -f1)
    original_bytes=$(stat -f%z "$f")
    
    # Optimize the image using ImageOptim-CLI
    if imageoptim "$f" -S --no-color 2>> "$LOG_FILE"; then
        # Get new file size
        new_size=$(du -h "$f" | cut -f1)
        new_bytes=$(stat -f%z "$f")
        
        # Calculate space saved
        space_saved=$((original_bytes - new_bytes))
        if [ "$original_bytes" -gt 0 ]; then
            space_saved_mb=$(echo "scale=2; $space_saved / 1048576" | bc)
            percent_saved=$(echo "scale=2; ($space_saved * 100) / $original_bytes" | bc)
        else
            space_saved_mb="0.00"
            percent_saved="0.00"
        fi
        
        log "INFO" "Successfully optimized $f"
        log "INFO" "Original size: $original_size"
        log "INFO" "New size: $new_size"
        log "INFO" "Space saved: ${space_saved_mb}MB ($percent_saved%)"
        ((total_processed++))
    else
        log "ERROR" "Failed to optimize $f"
        ((total_errors++))
    fi
done

# Print summary
log "INFO" "=== Processing Summary ==="
log "INFO" "Total images processed: $total_processed"
log "INFO" "Files skipped: $total_skipped"
log "INFO" "Warnings: $total_warnings"
log "INFO" "Errors: $total_errors"
log "INFO" "=== Script finished ==="

# Exit with error if any errors occurred
if [ $total_errors -gt 0 ]; then
    exit 1
fi 