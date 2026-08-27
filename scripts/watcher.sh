#!/bin/bash

set -euo pipefail

# ===================================
# Project Paths
# ===================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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

validate_configuration() {
    if [ -z "${SUPPORTED_TYPES:-}" ]; then
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

    if mv "$file" "$FAILED_FOLDER/"; then
	return 0
    else
	return 1
    fi

}

write_failure_metadata() {
    local file="$1"
    local type="$2"
    local phase="$3"
    local reason="$4"
    local timestamp="$5"

    local filename
    local metadata_file

    filename=$(basename "$file")
    metadata_file="$FAILED_FOLDER/$filename.meta"

    {
        echo "FILE=$filename"
        echo "TYPE=$type"
        echo "PHASE=$phase"
        echo "REASON=$reason"
        echo "TIMESTAMP=$timestamp"
    } > "$metadata_file"
}

verify_quarantine() {
    local quarantined_file="$1"
    local metadata_file="$2"

    if [ -f "$quarantined_file" ] && [ -f "$metadata_file" ]; then
        return 0
    else
        return 1
    fi
}


handle_processing_failure() {
    local -n output=$1
    local file="$2"
    local type="$3"
    local phase="$4"
    local reason="$5"

    local timestamp
    local filename
    local quarantined_file
    local metadata_file

    output[metadata]="NOT_ATTEMPTED"
    output[quarantine]="NOT_ATTEMPTED"
    output[verification]="NOT_ATTEMPTED"

    timestamp=$(date)
    filename=$(basename "$file")
    quarantined_file="$FAILED_FOLDER/$filename"
    metadata_file="$FAILED_FOLDER/$filename.meta"

    if write_failure_metadata \
        "$file" \
        "$type" \
        "$phase" \
        "$reason" \
        "$timestamp"; then

        output[metadata]="SUCCESS"
        log INFO "Failure metadata written: $filename"
    else
        output[metadata]="FAILED"
        log ERROR "Failure metadata write failed: $filename"
        echo "ERROR: Failure metadata write failed: $filename"
    fi

    if quarantine_file "$file"; then
        output[quarantine]="SUCCESS"
        log INFO "Quarantine succeeded: $filename"

        if [ "${output[metadata]}" = "SUCCESS" ]; then
            if verify_quarantine "$quarantined_file" "$metadata_file"; then
                output[verification]="SUCCESS"
                log INFO "Quarantine verified: $filename"
            else
                output[verification]="FAILED"
                log ERROR "Quarantine verification failed: $filename"
                echo "ERROR: Quarantine verification failed: $filename"
            fi
        else
            output[verification]="NOT_ATTEMPTED"
            log WARNING "Quarantine verification not attempted: metadata failed: $filename"
            echo "WARNING: Quarantine verification not attempted: metadata failed"
        fi
    else
        output[quarantine]="FAILED"
        log ERROR "Quarantine failed: $filename"
        echo "ERROR: Quarantine failed: $filename"
    fi
}

process_files() {

    SUCCESS_COUNT=0
    FAILED_COUNT=0
    SKIPPED_COUNT=0
    QUARANTINE_FAILED_COUNT=0
    METADATA_FAILED_COUNT=0
    VERIFICATION_FAILED_COUNT=0

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

            declare -A failure_result

            handle_processing_failure \
                failure_result \
                "$file" \
                "$TYPE" \
                "PROCESSING" \
                "SIMULATED_PROCESSING_ERROR"

            if [ "${failure_result[metadata]}" = "FAILED" ]; then
                ((++METADATA_FAILED_COUNT))
            fi

            if [ "${failure_result[quarantine]}" = "FAILED" ]; then
                ((++QUARANTINE_FAILED_COUNT))
            fi

            if [ "${failure_result[verification]}" = "FAILED" ]; then
                ((++VERIFICATION_FAILED_COUNT))
            fi

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
    log INFO "Metadata failed: $METADATA_FAILED_COUNT"
    log INFO "Quarantine failed: $QUARANTINE_FAILED_COUNT"
    log INFO "Verification failed: $VERIFICATION_FAILED_COUNT"

    echo "==================================="
    echo "Processing Summary"
    echo "==================================="
    echo "Processed : $FILE_COUNT"
    echo "Succeeded : $SUCCESS_COUNT"
    echo "Skipped   : $SKIPPED_COUNT"
    echo "Failed    : $FAILED_COUNT"
    echo "Quarantine Failed   : $QUARANTINE_FAILED_COUNT"
    echo "Metadata Failed     : $METADATA_FAILED_COUNT"
    echo "Verification Failed : $VERIFICATION_FAILED_COUNT"

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
