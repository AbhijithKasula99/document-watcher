#!/bin/bash

# ===================================
# Configuration
# ===================================

CONFIG_FILE="$(dirname "$0")/../config/config.env"

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
    if [ -z "$1" ]; then
        echo "ERROR: log() requires a message"
        return 1
    fi

    echo "$(date) $1" >> "$LOG_FILE"
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
        log "Watcher started"
        log "Folder verified"
        log "$FILE_COUNT files found"

        if mv "$WATCH_FOLDER"/* "$ARCHIVE_FOLDER"; then
            log "$FILE_COUNT files moved"
            log "Files processed successfully"
        else
            log "Failed to move files"
            echo "ERROR: Failed to move files"
            exit 4
        fi
    else
        echo "No files in the folder"
    fi
}

# ===================================
# Main Program
# ===================================

echo "==================================="
echo "$APP_NAME"
echo "==================================="

validate_environment

echo "Current User: $USER"
echo "Current Time: $(date)"
echo "WATCH_FOLDER: $WATCH_FOLDER"

count_files

echo "PDF Files: $PDF_COUNT"
echo "PNG Files: $PNG_COUNT"
echo "TXT Files: $TXT_COUNT"
echo "Files waiting: $FILE_COUNT"

process_files
