#!/bin/bash
# Video Processor.sh
# Encodes videos to H.264 MP4 format using HandBrakeCLI
# Optimized for iPhone videos with various resolutions and framerates

set -e

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Set up logging
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/video_encoder_log_$(date +%Y%m%d).txt"
mkdir -p "$LOG_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Script started ===" >> "$LOG_FILE"

# Check if HandBrakeCLI is installed
if [ ! -f "$HANDBRAKE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: HandBrakeCLI not found at $HANDBRAKE" >> "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Please install HandBrakeCLI with: brew install handbrake" >> "$LOG_FILE"
    exit 1
fi

# Initialize counters
processed=0
skipped=0
warnings=0
errors=0

# Process each file
for f in "$@"; do
    # Only process MOV files
    if [[ $f =~ \.(mov|MOV)$ ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Processing video: $f" >> "$LOG_FILE"
        
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
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Successfully encoded $f" >> "$LOG_FILE"
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Original size: $original_size" >> "$LOG_FILE"
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] New size: $new_size" >> "$LOG_FILE"
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Space saved: ${saved_mb}MB (${saved_percent}%)" >> "$LOG_FILE"
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Deleted original file: $f" >> "$LOG_FILE"
                    ((processed++))
                else
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to delete original file: $f" >> "$LOG_FILE"
                    # Clean up the output file since we couldn't delete the original
                    rm -f "$output_file"
                    ((errors++))
                fi
            else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Output file is missing or empty: $output_file" >> "$LOG_FILE"
                rm -f "$output_file"
                ((errors++))
            fi
        else
            # Clean up output file if encoding failed
            [ -f "$output_file" ] && rm -f "$output_file"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to encode $f" >> "$LOG_FILE"
            ((errors++))
        fi
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Skipping non-MOV file: $f" >> "$LOG_FILE"
        ((skipped++))
    fi
done

# Log summary
echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Processing Summary ===" >> "$LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Total videos processed: $processed" >> "$LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Files skipped: $skipped" >> "$LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Warnings: $warnings" >> "$LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Errors: $errors" >> "$LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Script finished ===" >> "$LOG_FILE"

# Exit with error if any errors occurred
if [ $errors -gt 0 ]; then
    exit 1
fi 