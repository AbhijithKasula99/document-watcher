#!/bin/bash

APP_NAME="Document Watcher"
WATCH_FOLDER="$HOME/doc-ops/incoming"
ARCHIVE_FOLDER="$HOME/doc-ops/archive"
LOG_FILE="$HOME/doc-ops/logs/watcher.log"

echo "==================================="
echo "$APP_NAME"
echo "==================================="

echo "Current User: $USER"
echo "Current Time: $(date)"
echo "WATCH_FOLDER: $WATCH_FOLDER"

if [ -d "$WATCH_FOLDER" ]; then
	echo "Incoming folder exists."
else
	echo "Incoming folder not found."
fi


PDF_COUNT=$(find "$WATCH_FOLDER" -name "*.pdf" | wc -l)
echo "PDF Files: $PDF_COUNT"

PNG_COUNT=$(find "$WATCH_FOLDER" -name "*.png" | wc -l)
echo "PNG Files: $PNG_COUNT"

TXT_COUNT=$(find "$WATCH_FOLDER" -name "*.txt" | wc -l)
echo "TXT Files: $TXT_COUNT"

FILE_COUNT=$(find "$WATCH_FOLDER" -type f | wc -l)
echo "Files waiting: $FILE_COUNT"


if [ "$FILE_COUNT" -gt 0 ]; then
	mv "$WATCH_FOLDER"/* "$ARCHIVE_FOLDER"
	echo "$(date) Watcher started" >> "$LOG_FILE"
	echo "$(date) Folder verified" >> "$LOG_FILE"
	echo "$(date) $FILE_COUNT files found" >> "$LOG_FILE"
	echo "$(date) $FILE_COUNT files moved" >> "$LOG_FILE"
	echo "$(date) Files processed successfully" >> "$LOG_FILE"
else
	echo "No files in the folder"
fi
