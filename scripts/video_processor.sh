#!/bin/bash
# Video Processor.sh
# Encodes videos to H.264 MP4 format using HandBrakeCLI
# Optimized for iPhone videos with various resolutions and framerates

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Set up logging
LOG_FILE="$LOG_DIR/video_encoder_log_$(date +%Y%m%d).txt"
mkdir -p "$LOG_DIR"

# Function to log messages
log() {
    local level="${1:-INFO}"
    local message="${2:-}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

# Check if HandBrakeCLI is installed
if [ ! -f "$HANDBRAKE" ]; then
    log "ERROR" "HandBrakeCLI not found at $HANDBRAKE"
    log "ERROR" "Please install HandBrakeCLI with: brew install handbrake"
    exit 1
fi

# Initialize counters
processed=0
skipped=0
warnings=0
errors=0

log "INFO" "=== Script started ==="

# Process each file
for f in "$@"; do
    # Only process MOV files
    if [[ $f =~ \.(mov|MOV)$ ]]; then
        log "INFO" "Processing video: $f"
        
        # Get original size
        original_size=$(du -h "$f" | cut -f1)
        original_bytes=$(stat -f%z "$f")
        
        # Create output filename (no temp suffix)
        output_file="${f%.*}.mp4"
        
        # Encode video using HandBrakeCLI
        if "$HANDBRAKE" -i "$f" -o "$output_file" -e x264 -q 23 -B 160 2>> "$LOG_FILE"; then
            # Get new size
            new_size=$(du -h "$output_file" | cut -f1)
            new_bytes=$(stat -f%z "$output_file")
            
            # Calculate space saved
            saved_bytes=$((original_bytes - new_bytes))
            saved_mb=$(echo "scale=2; $saved_bytes/1048576" | bc)
            saved_percent=$(echo "scale=2; ($saved_bytes/$original_bytes)*100" | bc)
            
            # Verify the output file exists and has content
            if [ -f "$output_file" ] && [ -s "$output_file" ]; then
                # Delete original MOV file
                if rm -f "$f"; then
                    log "INFO" "Successfully encoded $f"
                    log "INFO" "Original size: $original_size"
                    log "INFO" "New size: $new_size"
                    log "INFO" "Space saved: ${saved_mb}MB (${saved_percent}%)"
                    log "INFO" "Deleted original file: $f"
                    ((processed++))
                else
                    log "ERROR" "Failed to delete original file: $f"
                    # Clean up the output file since we couldn't delete the original
                    rm -f "$output_file"
                    ((errors++))
                fi
            else
                log "ERROR" "Output file is missing or empty: $output_file"
                rm -f "$output_file"
                ((errors++))
            fi
        else
            # Clean up output file if encoding failed
            [ -f "$output_file" ] && rm -f "$output_file"
            log "ERROR" "Failed to encode $f"
            ((errors++))
        fi
    else
        log "INFO" "Skipping non-MOV file: $f"
        ((skipped++))
    fi
done

# Log summary
log "INFO" "=== Processing Summary ==="
log "INFO" "Total videos processed: $processed"
log "INFO" "Files skipped: $skipped"
log "INFO" "Warnings: $warnings"
log "INFO" "Errors: $errors"
log "INFO" "=== Script finished ==="

# Exit with error if any errors occurred
if [ $errors -gt 0 ]; then
    exit 1
fi 