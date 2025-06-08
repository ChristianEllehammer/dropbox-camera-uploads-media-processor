#!/bin/bash
# Video Processor.sh
# Encodes videos to H.264 MP4 format using HandBrakeCLI
# Optimized for iPhone videos with various resolutions and framerates

set -e

# Set up logging
SCRIPT_DIR="/Users/christian/Dropbox/Dokumenter/Computer/Scripts and Apps/Automator/Folder Actions/Dropbox - Camera Uploads"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/video_encoder_log_$(date +%Y%m%d).txt"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check if HandBrakeCLI is installed
if ! command -v /opt/homebrew/bin/HandBrakeCLI &> /dev/null; then
    log_message "ERROR: HandBrakeCLI not found. Please install it using: brew install handbrake"
    exit 1
fi

# Process each video file
log_message "Starting video encoding with $# arguments: $@"

# Initialize counter for successful encodings
encoded_count=0

for input_file in "$@"; do
    # Check if file exists
    if [ ! -f "$input_file" ]; then
        log_message "ERROR: File not found: $input_file"
        continue
    fi

    # Get file extension
    extension="${input_file##*.}"
    extension_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

    # Skip non-video files
    if [[ ! "$extension_lower" =~ ^(mov|mp4|m4v|avi|mkv|webm)$ ]]; then
        log_message "Skipping non-video file: $input_file"
        continue
    fi

    # Skip if already MP4
    if [ "$extension_lower" = "mp4" ]; then
        log_message "Skipping already encoded MP4 file: $input_file"
        # Run File Organizer on the MP4 file
        "$SCRIPT_DIR/File Organizer.sh" "$input_file"
        continue
    fi

    # Create output filename
    output_file="${input_file%.*}.mp4"
    temp_output_file="${output_file}.tmp"
    
    log_message "Encoding $input_file to $temp_output_file..."

    # Get original file size
    original_size=$(stat -f %z "$input_file")
    original_size_mb=$(echo "scale=2; $original_size / 1048576" | bc)

    # Encode video with high quality settings to temp file
    /opt/homebrew/bin/HandBrakeCLI \
        -i "$input_file" \
        -o "$temp_output_file" \
        --preset "HQ 1080p30 Surround" \
        --optimize

    # Check if encoding was successful and temp file is valid and non-empty
    if [ $? -eq 0 ] && [ -f "$temp_output_file" ] && [ $(stat -f %z "$temp_output_file") -gt 100000 ]; then
        # Move temp file to final output
        mv "$temp_output_file" "$output_file"
        log_message "Moved $temp_output_file to $output_file (finalized)"

        # Get new file size
        new_size=$(stat -f %z "$output_file")
        new_size_mb=$(echo "scale=2; $new_size / 1048576" | bc)
        
        # Calculate space saved
        space_saved=$(echo "scale=2; $original_size_mb - $new_size_mb" | bc)
        percent_saved=$(echo "scale=1; ($space_saved / $original_size_mb) * 100" | bc)
        
        log_message "Successfully encoded $input_file"
        log_message "Original size: ${original_size_mb}MB"
        log_message "New size: ${new_size_mb}MB"
        log_message "Space saved: ${space_saved}MB (${percent_saved}%)"
        
        # Delete original file
        rm "$input_file"
        log_message "Deleted original file: $input_file"
        
        # Run File Organizer on the new MP4 file only
        "$SCRIPT_DIR/File Organizer.sh" "$output_file"
        
        encoded_count=$((encoded_count + 1))
    else
        log_message "ERROR: Failed to encode $input_file or output file is invalid."
        # Clean up temp file if it exists
        [ -f "$temp_output_file" ] && rm "$temp_output_file"
    fi

done

log_message "Encoding complete. $encoded_count file(s) encoded." 