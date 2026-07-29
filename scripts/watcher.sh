#!/bin/bash

set -euo pipefail

# ===================================
# Project Paths
# ===================================


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WATCH_FOLDER="$PROJECT_ROOT/incoming"
ARCHIVE_FOLDER="$PROJECT_ROOT/archive"
LOG_FILE="$PROJECT_ROOT/logs/watcher.log"

# ===================================
# Configuration
# ===================================

CONFIG_FILE="$PROJECT_ROOT/config/config.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found."
    echo "Expected: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

APP_NAME="Document Watcher"

# ===================================
# Functions
# ===================================

log() {
    if [ $# -ne 2 ]; then
	echo "ERROR: log() requires a level and a message"
	return 1
    fi

    local level="$1"
    local message="$2"

    echo "$(date) [$level] $message" >> "$LOG_FILE"
}

validate_environment() {
    if [ ! -d "$WATCH_FOLDER" ]; then
        echo "ERROR: Watch folder does not exist."
        exit 2
    fi

    if [ ! -d "$ARCHIVE_FOLDER" ]; then
        echo "ERROR: Archive folder does not exist."
        exit 3
    fi
}

count_files() {
    PDF_COUNT=$(find "$WATCH_FOLDER" -name "*.pdf" | wc -l)
    PNG_COUNT=$(find "$WATCH_FOLDER" -name "*.png" | wc -l)
    TXT_COUNT=$(find "$WATCH_FOLDER" -name "*.txt" | wc -l)
    FILE_COUNT=$(find "$WATCH_FOLDER" -type f | wc -l)
}

process_files() {
    if [ "$FILE_COUNT" -gt 0 ]; then
        log INFO "Watcher started"
        log INFO "Folder verified"
        log INFO "$FILE_COUNT files found"

        if mv "$WATCH_FOLDER"/* "$ARCHIVE_FOLDER"; then
            log INFO "$FILE_COUNT files moved"
            log INFO "Files processed successfully"
        else
            log ERROR "Failed to move files"
            echo "ERROR: Failed to move files"
            exit 4
        fi
    else
        echo "No files in the folder"
    fi
}

display_header() {
	echo "==================================="
	echo "$APP_NAME"
	echo "==================================="
}

display_runtime_info() {
	echo "Current User: $USER"
	echo "Current Time: $(date)"
	echo "WATCH_FOLDER: $WATCH_FOLDER"
}

display_statistics() {
	echo "PDF Files: $PDF_COUNT"
	echo "PNG Files: $PNG_COUNT"
	echo "TXT Files: $TXT_COUNT"
	echo "Files waiting: $FILE_COUNT"
}

# ===================================
# Main Program
# ===================================

main() {

	display_header
	validate_environment
	display_runtime_info
	count_files
	display_statistics
	process_files
}

main

