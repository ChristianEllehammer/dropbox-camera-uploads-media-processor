# Dropbox Camera Uploads Optimizer and Organizer

This folder action automatically optimizes and organizes photos and videos uploaded to your Dropbox Camera Uploads folder.

## Overview

The system consists of three main components:
1. **Image Optimizer**: Compresses images using ImageOptim CLI while maintaining quality
2. **Organizer**: Sorts files into a structured folder hierarchy based on date
3. **Folder Action**: Triggers the process when new files are added to the Camera Uploads folder

## Requirements

- macOS
- ImageOptim CLI (`brew install imageoptim-cli`)
- Dropbox account with Camera Uploads enabled
- Folder Actions enabled in macOS

## Installation

1. Clone or download this repository to your local machine
2. Install ImageOptim CLI:
   ```bash
   brew install imageoptim-cli
   ```
3. Make the scripts executable:
   ```bash
   chmod +x "Image Optimizer.sh" "Organizer.sh" "Image Optimizer and Organizer.sh"
   ```
4. Set up the folder action:
   - Right-click on your Dropbox Camera Uploads folder
   - Select "Folder Actions Setup..."
   - Click "+" and select your Camera Uploads folder
   - Click "Attach a Script"
   - Select "Image Optimizer and Organizer.scpt"
   - Ensure "Enable Folder Actions" is checked

## Configuration

### Logging
- Log files are stored in the `logs` directory
- Log rotation is set to 30 days by default
- Log levels: DEBUG, INFO, WARNING, ERROR
- Default level: INFO

### File Organization
- Photos are moved to: `Dropbox/Billeder/Personlig/År/[YEAR]/[YEAR]-[MONTH]/[YEAR]-[MONTH] - Blandet/Billeder`
- Videos are moved to: `Dropbox/Billeder/Personlig/År/[YEAR]/[YEAR]-[MONTH]/[YEAR]-[MONTH] - Blandet/Videoer`

### Supported File Types
- Images: jpg, jpeg, png, gif, heic, heif, webp, tiff, tif
- Videos: mp4, mov, avi, m4v

## Usage

The system runs automatically when new files are added to your Dropbox Camera Uploads folder. Each file is:
1. Optimized (if it's an image)
2. Moved to the appropriate folder based on its date and type

## Monitoring and Reports

Monthly reports are generated and sent via email, including:
- Number of files processed
- Total space saved
- Average optimization percentage
- Common errors or warnings
- Performance metrics

## Troubleshooting

### Common Issues

1. **Scripts not running**
   - Check if Folder Actions are enabled
   - Verify script permissions
   - Check log files for errors

2. **Files not being optimized**
   - Ensure ImageOptim CLI is installed
   - Check if the file type is supported
   - Verify log files for specific errors

3. **Files not being organized**
   - Check if the filename contains a valid date (YYYY-MM format)
   - Verify destination folders exist
   - Check log files for specific errors

### Log Files

- Optimizer logs: `logs/optimize_log_YYYYMMDD.txt`
- Organizer logs: `logs/move_log_YYYYMMDD.txt`

## Contributing

Feel free to submit issues and enhancement requests! 