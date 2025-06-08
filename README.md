# Media Processor Project

This project automates the processing, optimization, and organization of media files (images and videos) in your Dropbox Camera Uploads folder. It is designed for robust, efficient, and transparent operation, with clear logging and modular scripts.

## Features
- **Image Conversion:** Converts HEIC images to JPG.
- **Image Processing:** Optimizes images for size and quality.
- **Video Processing:** Encodes videos (e.g., MOV to MP4) using HandBrakeCLI with high-quality settings.
- **File Organization:** Moves processed files into a structured directory based on type and date.
- **Comprehensive Logging:** All scripts log their actions, errors, and results to dated log files in the `logs/` directory.
- **Monthly Reports:** Python script to generate and email monthly reports with statistics and visualizations.

## Logging
- Each script uses a simple, robust logging function that writes timestamped messages to a log file in the `logs/` directory.
- Log files are named by script and date, e.g., `video_encoder_log_YYYYMMDD.txt`.
- Logs include start/end of processing, errors, file moves, and space savings.
- Example log entry:
  ```
  [2025-06-08 22:28:53] Successfully encoded /Users/christian/Dropbox/Camera Uploads/2025-07-08 17.00.30.mov
  ```

## Modularity
- Each script is responsible for a single task (conversion, processing, organization).
- Functions are used for repeated logic (e.g., logging).
- Scripts can be run independently or coordinated via the main `Media Processor.sh` script.

## Performance
- Scripts process files in a loop, handling only valid files.
- For most workflows, this is efficient and safe. For very large batches, consider parallelization (not enabled by default for safety).

## Version Control with Git
- The project is under Git version control. To use Git effectively:
  - **Commit after each major change:**
    ```
    git add .
    git commit -m "Describe your change"
    ```
  - **Check status:**
    ```
    git status
    ```
  - **View history:**
    ```
    git log --oneline
    ```
  - **Create branches for experiments:**
    ```
    git checkout -b feature/my-feature
    ```
- This ensures you can always revert to a previous working state and track all changes.

## Requirements
- Bash (macOS default)
- [HandBrakeCLI](https://handbrake.fr/) for video encoding
- [ImageMagick](https://imagemagick.org/) for image conversion
- [pandas](https://pandas.pydata.org/) and [matplotlib](https://matplotlib.org/) for report generation (Python)

## Usage
- Place media files in your Dropbox Camera Uploads folder.
- The scripts will process, optimize, and organize them automatically.
- Check the `logs/` directory for detailed logs of all actions.
- Use `generate_report.py` to create monthly reports.

## Contributing
- Please use feature branches and submit pull requests for review.
- Keep scripts modular and logging consistent.

## License
MIT License 