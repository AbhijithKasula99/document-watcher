#!/bin/bash

CONFIG_FILE="$(dirname "$0")/../config/config.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found."
    echo "Expected: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

log() {
	if [ -z "$1" ]; then
		echo "ERROR: log() requires a message"
		return 1
	fi
	echo "$(date) $1" >> "$LOG_FILE"
}

APP_NAME="Document Watcher"


echo "==================================="
echo "$APP_NAME"
echo "==================================="

if [ ! -d "$WATCH_FOLDER" ]; then
    echo "ERROR: Watch folder does not exist."
    exit 2
fi

if [ ! -d "$ARCHIVE_FOLDER" ]; then
	echo "ERROR: Archive folder does not exist."
	exit 3
fi

echo "Current User: $USER"
echo "Current Time: $(date)"
echo "WATCH_FOLDER: $WATCH_FOLDER"

PDF_COUNT=$(find "$WATCH_FOLDER" -name "*.pdf" | wc -l)
echo "PDF Files: $PDF_COUNT"

PNG_COUNT=$(find "$WATCH_FOLDER" -name "*.png" | wc -l)
echo "PNG Files: $PNG_COUNT"

TXT_COUNT=$(find "$WATCH_FOLDER" -name "*.txt" | wc -l)
echo "TXT Files: $TXT_COUNT"

FILE_COUNT=$(find "$WATCH_FOLDER" -type f | wc -l)
echo "Files waiting: $FILE_COUNT"


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
