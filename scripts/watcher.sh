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
FAILED_FOLDER="$PROJECT_ROOT/failed"

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

validate_configuration() {
    if [ -z "$SUPPORTED_TYPES" ]; then
        echo "ERROR: SUPPORTED_TYPES is not configured."
        log ERROR "SUPPORTED_TYPES is not configured."
        exit 4
    fi
}

count_files() {
    PDF_COUNT=$(find "$WATCH_FOLDER" -name "*.pdf" | wc -l)
    PNG_COUNT=$(find "$WATCH_FOLDER" -name "*.png" | wc -l)
    TXT_COUNT=$(find "$WATCH_FOLDER" -name "*.txt" | wc -l)
    FILE_COUNT=$(find "$WATCH_FOLDER" -type f | wc -l)
}

get_file_type() {
    case "$1" in
        *.pdf) echo "PDF" ;;
        *.png) echo "PNG" ;;
        *.txt) echo "TXT" ;;
        *)     echo "UNKNOWN" ;;
    esac
}

is_supported_document() {
    local file="$1"
    local type

    type=$(get_file_type "$file")

    case ",$SUPPORTED_TYPES," in
        *,"$type",*) return 0 ;;
        *)            return 1 ;;
    esac
}

archive_file() {
	mv "$1" "$ARCHIVE_FOLDER"
}


discover_files() {
	find "$1" -type f
}


quarantine_file() {
    local file="$1"
    mv "$file" "$FAILED_FOLDER/"
}

process_files() {

    SUCCESS_COUNT=0
    FAILED_COUNT=0
    SKIPPED_COUNT=0

    if [ "$FILE_COUNT" -gt 0 ]; then
        log INFO "Watcher started"
        log INFO "Folder verified"
        log INFO "$FILE_COUNT files found"
    else
        echo "No files in folder"
        return 0
    fi

    while read -r file; do
        echo "Processing: $file"

	TYPE=$(get_file_type "$file")
	echo "Document type: $TYPE"

	if [ "$(basename "$file")" = "fail.pdf" ]; then
    		echo "Processing failed: $file"
    		echo "Failure reason: SIMULATED_PROCESSING_ERROR"
    		FAILED_COUNT=$((FAILED_COUNT + 1))
		quarantine_file "$file"
    		continue
	fi

	if ! is_supported_document "$file"; then
    		echo "Skipping unsupported file: $file"
    		log WARNING "Unsupported file skipped: $file"
		((++SKIPPED_COUNT))
    		continue
	fi

        if archive_file "$file"; then
            ((++SUCCESS_COUNT))
            log INFO "Moved $file"
        else
            ((++FAILED_COUNT))
            log ERROR "Failed $file"
        fi
    done < <(discover_files "$WATCH_FOLDER")

    # ===================================
    # Processing Summary
    # ===================================

    log INFO "Run completed."
    log INFO "Processed: $FILE_COUNT"
    log INFO "Succeeded: $SUCCESS_COUNT"
    log INFO "Skipped: $SKIPPED_COUNT"
    log INFO "Failed: $FAILED_COUNT"

    echo "==================================="
    echo "Processing Summary"
    echo "==================================="
    echo "Processed : $FILE_COUNT"
    echo "Succeeded : $SUCCESS_COUNT"
    echo "Skipped   : $SKIPPED_COUNT"
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
    validate_configuration
    display_runtime_info
    count_files
    display_statistics
    process_files
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main
fi
