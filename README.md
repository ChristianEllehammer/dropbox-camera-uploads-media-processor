# Dropbox Camera Uploads Media Processor

This project provides a set of scripts to automatically process media files uploaded to your Dropbox Camera Uploads folder. It handles:
- Converting HEIC photos to JPG
- Optimizing JPG images (with configurable quality and no resizing by default)
- Converting MOV videos to MP4
- Organizing files into a structured folder system based on date

## Prerequisites

- macOS (tested on macOS Sonoma)
- Dropbox installed and configured
- Required tools:
  - HandBrakeCLI (for video conversion)
  - ImageOptim (for image optimization)
  - ImageMagick (for HEIC conversion)

## Installation

1. Clone this repository to your local machine
2. Install required tools:
   ```bash
   brew install handbrake imagemagick
   brew install --cask imageoptim
   ```
3. Make all scripts executable:
   ```bash
   chmod +x scripts/*.sh
   ```
4. Configure the `config.sh` file with your paths and preferences.

## Project Structure

```
.
├── scripts/
│   ├── clean_logs.sh
│   ├── config.sh
│   ├── file_organizer.sh
│   ├── image_converter.sh
│   ├── image_processor.sh
│   ├── media_processor.sh
│   ├── video_processor.sh
│   └── test_workflow.sh
├── logs/
├── test_files/
├── README.md
├── .gitignore
```

## Usage

- All scripts are now in the `scripts/` directory.
- Main entry point: `scripts/media_processor.sh`
- Test workflow: `scripts/test_workflow.sh`
- Clean logs: `scripts/clean_logs.sh`

### Example

```bash
# Process files
./scripts/media_processor.sh /path/to/file1.heic /path/to/file2.mov

# Run the test suite
./scripts/test_workflow.sh

# Clean old logs
./scripts/clean_logs.sh
```

## Logs

All operations are logged in the `logs/` directory:
- `media_processor_log_YYYYMMDD.txt`: Main workflow logs
- `image_converter_log_YYYYMMDD.txt`: HEIC conversion logs
- `image_processor_log_YYYYMMDD.txt`: JPG optimization logs
- `video_encoder_log_YYYYMMDD.txt`: Video conversion logs
- `organizer_log_YYYYMMDD.txt`: File organization logs

## Testing

The project includes a test script to validate the entire workflow:

```bash
./scripts/test_workflow.sh
```

This will:
1. Create test files (HEIC, JPG, MOV)
2. Run each processing step
3. Verify the results
4. Clean up test files

The test script will show:
- ✓ Green checkmarks for passed tests
- ✗ Red X marks for failed tests
- Detailed error messages for any failures

## Recent Improvements

This project has undergone several improvements to enhance stability and functionality:

- **Removed Locking Mechanism:** The redundant file locking mechanism has been completely removed, simplifying the codebase as processing is inherently sequential.
- **Accurate File Organization:** The file organizer script now correctly extracts dates from filenames in the "YYYY-MM-DD HH.MM.SS" format, ensuring accurate file placement.
- **Configurable Image Quality:** Image processing now defaults to 100% quality for JPGs, and the `IMAGE_MAX_WIDTH` setting has been removed, preserving original image dimensions by default. These settings are configurable in `config.sh`.
- **Centralized Logging:** All processing and organization logs are now consistently stored in the main `logs/` directory, improving log management and debugging.
- **Robust Error Handling:** Enhanced error reporting in individual scripts ensures that issues with non-existent or invalid files are clearly identified and reported during testing and operation.

## Troubleshooting

### Common Issues

1. **HEIC files not converting:**
   - Check if ImageMagick is installed: `which magick`
   - Verify HEIC support: `magick identify -list format | grep HEIC`

2. **JPG files not optimizing:**
   - Check if ImageOptim is installed: `ls /Applications/ImageOptim.app`
   - Try running ImageOptim manually on a test file

3. **MOV files not converting:**
   - Check if HandBrakeCLI is installed: `which HandBrakeCLI`
   - Verify video codec support: `HandBrakeCLI --version`

4. **Files not being organized:**
   - Check if the base directory exists: `ls "$BASE_DIR"`
   - Verify file permissions: `ls -l "$BASE_DIR"`

### Running Tests

To run the test suite:
```bash
./scripts/test_workflow.sh
```