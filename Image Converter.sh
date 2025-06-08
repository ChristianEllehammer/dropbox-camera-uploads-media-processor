#!/bin/bash
# HEIC Converter.sh
# Converts .heic files to .jpg, deletes originals, and outputs new .jpg paths

set -e

LOG_DIR="$(dirname "$0")/logs"
LOG_FILE="$LOG_DIR/heic_converter_log_$(date +%Y%m%d).txt"
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

MAGICK="/opt/homebrew/bin/magick"
if [ ! -f "$MAGICK" ]; then
    log "ERROR: ImageMagick (magick) is not installed at $MAGICK"
    exit 1
fi

log "Starting HEIC conversion with $# arguments: $*"

converted_files=()

for file in "$@"; do
    if [ ! -f "$file" ]; then
        log "ERROR: File not found: $file"
        continue
    fi

    ext="${file##*.}"
    # Convert extension to lowercase using tr
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    if [ "$ext_lower" = "heic" ]; then
        jpg_file="${file%.*}.jpg"
        log "Converting $file to $jpg_file..."
        if "$MAGICK" "$file" "$jpg_file" 2>> "$LOG_FILE"; then
            log "Successfully converted $file to $jpg_file. Deleting original."
            rm "$file"
            converted_files+=("$jpg_file")
            echo "$jpg_file"
        else
            log "ERROR: Failed to convert $file"
            exit 1
        fi
    else
        log "Skipping non-HEIC file: $file"
    fi
done

log "Conversion complete. ${#converted_files[@]} file(s) converted." 