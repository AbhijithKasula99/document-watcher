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

show_help() {
    echo "Document Watcher"
    echo
    echo "Usage:"
    echo "    ./watcher.sh [OPTIONS]"
    echo
    echo "Options:"
    echo "    -h    Show help"
    echo "    -v    Show version"
}

show_version() {
    echo "Document Watcher v1.0.0"
}

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

    SUCCESS_COUNT=0
    FAILED_COUNT=0

    if [ "$FILE_COUNT" -gt 0 ]; then
        log INFO "Watcher started"
        log INFO "Folder verified"
        log INFO "$FILE_COUNT files found"

        # ===========================
        # TEMP DEBUG
        # ===========================
        echo "FILE_COUNT=$FILE_COUNT"

    else
        echo "No files in folder"
        return 0
    fi

    for file in "$WATCH_FOLDER"/*; do

        # ===========================
        # TEMP DEBUG
        # ===========================
        echo "DEBUG: file='$file'"

        echo "Processing: $file"

        if mv "$file" "$ARCHIVE_FOLDER"; then
            ((++SUCCESS_COUNT))
            log INFO "Moved $file"
        else
            status=$?
            ((++FAILED_COUNT))
            echo "DEBUG: mv failed with exit code $status"
            log ERROR "Failed $file"
        fi
    done

    # ===================================
    # Processing Summary
    # ===================================

    log INFO "Run completed."
    log INFO "Succeeded: $SUCCESS_COUNT"
    log INFO "Failed: $FAILED_COUNT"

    echo "==================================="
    echo "Processing Summary"
    echo "==================================="
    echo "Succeeded : $SUCCESS_COUNT"
    echo "Failed    : $FAILED_COUNT"

    if [ "$FAILED_COUNT" -gt 0 ]; then
        log ERROR "Processing failed"
        return 1
    else
        log INFO "Processing successful"
        return 0
    fi
}

display_header() {
    echo "==================================="
    echo "$APP_NAME"
    echo "==================================="
}

display_runtime_info() {
    echo "Current User : $(whoami)"
    echo "Current Time : $(date)"
    echo "Watch Folder : $WATCH_FOLDER"
}

display_statistics() {
    echo "PDF Files     : $PDF_COUNT"
    echo "PNG Files     : $PNG_COUNT"
    echo "TXT Files     : $TXT_COUNT"
    echo "Files Waiting : $FILE_COUNT"
}

# ===================================
# Command Line Options
# ===================================

while getopts "hv" option; do
    case "$option" in
        h)
            show_help
            exit 0
            ;;
        v)
            show_version
            exit 0
            ;;
        \?)
            echo "ERROR: Unknown option"
            exit 1
            ;;
    esac
done

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
