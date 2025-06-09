#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Script paths (relative to SCRIPT_DIR)
IMAGE_CONVERTER="$SCRIPT_DIR/image_converter.sh"
VIDEO_PROCESSOR="$SCRIPT_DIR/video_processor.sh"
IMAGE_PROCESSOR="$SCRIPT_DIR/image_processor.sh"
FILE_ORGANIZER="$SCRIPT_DIR/file_organizer.sh"

# Tool paths (configurable via environment variables)
HANDBRAKE="${HANDBRAKE:-/opt/homebrew/bin/HandBrakeCLI}"
IMAGEMAGICK="${IMAGEMAGICK:-/opt/homebrew/bin/magick}"

# Log settings
LOG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/logs"
MAX_LOG_DAYS=30  # Keep logs for 30 days
LOG_LEVEL="${LOG_LEVEL:-INFO}"  # Can be DEBUG, INFO, WARNING, ERROR

# Base directory for organized files (configurable via environment variable)
BASE_DIR="${BASE_DIR:-$HOME/Dropbox/Billeder/Personlig/År}"

# Processing settings
IMAGE_QUALITY=85
VIDEO_QUALITY=23
VIDEO_PRESET="fast"

# Function to check if a command exists and is executable
check_command() {
    local cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        return 1
    fi
    return 0
}

# Function to check tool versions
check_tool_version() {
    local tool=$1
    local min_version=$2
    local current_version
    
    case $tool in
        "HandBrakeCLI")
            current_version=$("$HANDBRAKE" --version | head -n1 | cut -d' ' -f2)
            ;;
        "ImageMagick")
            current_version=$("$IMAGEMAGICK" -version | head -n1 | cut -d' ' -f3)
            ;;
        *)
            return 0  # Skip version check for other tools
            ;;
    esac
    
    if [ "$(printf '%s\n' "$min_version" "$current_version" | sort -V | head -n1)" != "$min_version" ]; then
        echo "ERROR: $tool version $current_version is older than required version $min_version"
        return 1
    fi
    return 0
}

# Validate required tools
validate_tools() {
    local missing_tools=()
    local version_errors=()
    
    # Check HandBrakeCLI
    if ! check_command "$HANDBRAKE"; then
        missing_tools+=("HandBrakeCLI")
    elif ! check_tool_version "HandBrakeCLI" "1.5.0"; then
        version_errors+=("HandBrakeCLI")
    fi
    
    # Check ImageMagick
    if ! check_command "$IMAGEMAGICK"; then
        missing_tools+=("ImageMagick")
    elif ! check_tool_version "ImageMagick" "7.0.0"; then
        version_errors+=("ImageMagick")
    fi
    
    # If any tools are missing, print error and exit
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo "ERROR: The following required tools are missing:"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        echo "Please install the missing tools and try again."
        exit 1
    fi
    
    # If any tools have version issues, print error and exit
    if [ ${#version_errors[@]} -gt 0 ]; then
        echo "ERROR: The following tools have version issues:"
        for tool in "${version_errors[@]}"; do
            echo "  - $tool"
        done
        echo "Please update the tools to the required versions."
        exit 1
    fi
}

# Validate script paths
validate_scripts() {
    local missing_scripts=()
    
    # Check all script files
    for script in "$IMAGE_CONVERTER" "$VIDEO_PROCESSOR" "$IMAGE_PROCESSOR" "$FILE_ORGANIZER"; do
        if [ ! -f "$script" ] || [ ! -x "$script" ]; then
            missing_scripts+=("$(basename "$script")")
        fi
    done
    
    # If any scripts are missing, print error and exit
    if [ ${#missing_scripts[@]} -gt 0 ]; then
        echo "ERROR: The following required scripts are missing or not executable:"
        for script in "${missing_scripts[@]}"; do
            echo "  - $script"
        done
        exit 1
    fi
}

# Check permissions
check_permissions() {
    if [ ! -w "$BASE_DIR" ]; then
        echo "ERROR: No write permission for $BASE_DIR"
        exit 1
    fi
    
    if [ ! -w "$LOG_DIR" ]; then
        echo "ERROR: No write permission for $LOG_DIR"
        exit 1
    fi
}

# Create required directories
setup_directories() {
    mkdir -p "$LOG_DIR"
    mkdir -p "$BASE_DIR"
}

# Run validation on source
validate_tools
validate_scripts
check_permissions
setup_directories 