#!/bin/bash
# Test workflow script for Dropbox Camera Uploads Media Processor

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Test directories
TEST_DIR="$SCRIPT_DIR/test_files"
TEST_INPUT="$TEST_DIR/input"
TEST_OUTPUT="$TEST_DIR/output"
TEST_TEMP="$TEST_DIR/temp"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Use new script names in the scripts/ directory
IMAGE_CONVERTER="$SCRIPT_DIR/image_converter.sh"
VIDEO_PROCESSOR="$SCRIPT_DIR/video_processor.sh"
IMAGE_PROCESSOR="$SCRIPT_DIR/image_processor.sh"
FILE_ORGANIZER="$SCRIPT_DIR/file_organizer.sh"

# Function to print test results
print_result() {
    local test_name=$1
    local status=$2
    local message=$3
    
    if [ "$status" -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $test_name: $message"
    else
        echo -e "${RED}✗${NC} $test_name: $message"
    fi
}

# Function to create test files
create_test_files() {
    mkdir -p "$TEST_INPUT"
    mkdir -p "$TEST_OUTPUT"
    mkdir -p "$TEST_TEMP"
    
    # Create test HEIC file
    "$IMAGEMAGICK" -size 100x100 xc:white "$TEST_INPUT/test.heic"
    
    # Create test JPG file
    "$IMAGEMAGICK" -size 100x100 xc:white "$TEST_INPUT/test.jpg"
    
    # Create test MOV file (1 second of black video)
    ffmpeg -f lavfi -i color=c=black:s=100x100:d=1 "$TEST_INPUT/test.mov" -y
    
    # Create test files with special characters
    "$IMAGEMAGICK" -size 100x100 xc:white "$TEST_INPUT/test with spaces.heic"
    "$IMAGEMAGICK" -size 100x100 xc:white "$TEST_INPUT/test'with'quotes.heic"
    "$IMAGEMAGICK" -size 100x100 xc:white "$TEST_INPUT/test-with-dashes.heic"
    
    # Create large test files
    "$IMAGEMAGICK" -size 4000x3000 xc:white "$TEST_INPUT/large.heic"
    ffmpeg -f lavfi -i color=c=black:s=3840x2160:d=10 "$TEST_INPUT/large.mov" -y
}

# Function to clean up test files
cleanup_test_files() {
    rm -rf "$TEST_INPUT" "$TEST_OUTPUT" "$TEST_TEMP"
}

# Function to test HEIC conversion
test_heic_conversion() {
    local status=0
    local message=""
    
    # Test basic conversion
    if "$IMAGE_CONVERTER" "$TEST_INPUT/test.heic"; then
        if [ -f "$TEST_INPUT/test.jpg" ]; then
            message="Basic HEIC conversion successful"
        else
            status=1
            message="HEIC conversion failed - output file not found"
        fi
    else
        status=1
        message="HEIC conversion failed"
    fi
    
    print_result "HEIC Conversion" $status "$message"
    return $status
}

# Function to test JPG optimization
test_jpg_optimization() {
    local status=0
    local message=""
    
    # Test basic optimization
    if "$IMAGE_PROCESSOR" "$TEST_INPUT/test.jpg"; then
        if [ -f "$TEST_INPUT/test.jpg" ]; then
            message="Basic JPG optimization successful"
        else
            status=1
            message="JPG optimization failed - output file not found"
        fi
    else
        status=1
        message="JPG optimization failed"
    fi
    
    print_result "JPG Optimization" $status "$message"
    return $status
}

# Function to test MOV conversion
test_mov_conversion() {
    local status=0
    local message=""
    
    # Test basic conversion
    if "$VIDEO_PROCESSOR" "$TEST_INPUT/test.mov"; then
        if [ -f "$TEST_INPUT/test.mp4" ]; then
            message="Basic MOV conversion successful"
        else
            status=1
            message="MOV conversion failed - output file not found"
        fi
    else
        status=1
        message="MOV conversion failed"
    fi
    
    print_result "MOV Conversion" $status "$message"
    return $status
}

# Function to test file organization
test_file_organization() {
    local status=0
    local message=""
    
    # Test basic organization
    if "$FILE_ORGANIZER" "$TEST_INPUT/test.jpg"; then
        if [ -d "$BASE_DIR/$(date +%Y)" ]; then
            message="Basic file organization successful"
        else
            status=1
            message="File organization failed - target directory not found"
        fi
    else
        status=1
        message="File organization failed"
    fi
    
    print_result "File Organization" $status "$message"
    return $status
}

# Function to test special characters
test_special_characters() {
    local status=0
    local message=""
    
    # Test files with spaces
    if "$IMAGE_CONVERTER" "$TEST_INPUT/test with spaces.heic" && \
       "$IMAGE_CONVERTER" "$TEST_INPUT/test'with'quotes.heic" && \
       "$IMAGE_CONVERTER" "$TEST_INPUT/test-with-dashes.heic"; then
        message="Special character handling successful"
    else
        status=1
        message="Special character handling failed"
    fi
    
    print_result "Special Characters" $status "$message"
    return $status
}

# Function to test large files
test_large_files() {
    local status=0
    local message=""
    
    # Test large HEIC
    if "$IMAGE_CONVERTER" "$TEST_INPUT/large.heic"; then
        if [ -f "$TEST_INPUT/large.jpg" ]; then
            message="Large HEIC conversion successful"
        else
            status=1
            message="Large HEIC conversion failed"
        fi
    else
        status=1
        message="Large HEIC conversion failed"
    fi
    
    # Test large MOV
    if [ $status -eq 0 ]; then
        if "$VIDEO_PROCESSOR" "$TEST_INPUT/large.mov"; then
            if [ -f "$TEST_INPUT/large.mp4" ]; then
                message="Large file handling successful"
            else
                status=1
                message="Large MOV conversion failed"
            fi
        else
            status=1
            message="Large MOV conversion failed"
        fi
    fi
    
    print_result "Large Files" $status "$message"
    return $status
}

# Function to test error handling
test_error_handling() {
    local overall_status=0
    local test_status
    local test_message

    # Test with non-existent file
    if ! "$IMAGE_CONVERTER" "$TEST_INPUT/nonexistent.heic" 2>/dev/null; then
        test_status=0
        test_message="Error handling for non-existent files working"
    else
        test_status=1
        test_message="Error handling for non-existent files failed"
        overall_status=1
    fi
    print_result "Error Handling (Non-existent)" $test_status "$test_message"

    # Test with invalid file
    echo "invalid" > "$TEST_INPUT/invalid.heic"
    if ! "$IMAGE_CONVERTER" "$TEST_INPUT/invalid.heic" 2>/dev/null; then
        test_status=0
        test_message="Error handling for invalid files working"
    else
        test_status=1
        test_message="Error handling for invalid files failed"
        overall_status=1
    fi
    print_result "Error Handling (Invalid)" $test_status "$test_message"

    # Return the overall status of the error handling tests
    return $overall_status
}

# Main test execution
main() {
    echo "Starting test suite..."
    echo "====================="
    
    # Create test files
    create_test_files
    
    # Run tests
    test_heic_conversion
    test_jpg_optimization
    test_mov_conversion
    test_file_organization
    test_special_characters
    test_large_files
    test_error_handling
    
    # Clean up
    cleanup_test_files
    
    echo "====================="
    echo "Test suite completed"
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi 