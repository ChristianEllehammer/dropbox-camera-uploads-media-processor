#!/bin/bash
# Media Processor.sh
# Coordinates between image conversion, video processing, image processing, and file organization

set -e

# Use absolute paths since this script is called from the folder action
SCRIPT_DIR="/Users/christian/Dropbox/Dokumenter/Computer/Scripts and Apps/Automator/Folder Actions/Dropbox - Camera Uploads"
IMAGE_CONVERTER="$SCRIPT_DIR/Image Converter.sh"
VIDEO_PROCESSOR="$SCRIPT_DIR/Video Processor.sh"
IMAGE_PROCESSOR="$SCRIPT_DIR/Image Processor.sh"
FILE_ORGANIZER="$SCRIPT_DIR/File Organizer.sh"

# Set up logging
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/coordinator_log_$(date +%Y%m%d).txt"
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Script started with $# arguments: $*"

# 1. Convert HEIC files to JPG (deletes originals)
log "Running Image Converter..."
if ! "$IMAGE_CONVERTER" "$@" 2>> "$LOG_FILE"; then
    log "ERROR: Image Converter failed"
    exit 1
fi

# 2. Encode videos to MP4 (deletes originals)
log "Running Video Processor..."
if ! "$VIDEO_PROCESSOR" "$@" 2>> "$LOG_FILE"; then
    log "ERROR: Video Processor failed"
    exit 1
fi

# 3. Run image processor on all input files
log "Running Image Processor..."
if ! "$IMAGE_PROCESSOR" "$@" 2>> "$LOG_FILE"; then
    log "ERROR: Image Processor failed"
    exit 1
fi

# 4. Run file organizer on all input files
log "Running File Organizer..."
if ! "$FILE_ORGANIZER" "$@" 2>> "$LOG_FILE"; then
    log "ERROR: File Organizer failed"
    exit 1
fi

log "Script completed successfully" 
