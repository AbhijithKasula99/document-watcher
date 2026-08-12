#!/bin/bash

FAILED_TESTS=0

source "$(dirname "$0")/../scripts/watcher.sh"

test_file_type() {
    result=$(get_file_type "$1")

    if [ "$result" = "$2" ]; then
        echo "PASS: $1 → $result"
    else
        echo "FAIL: $1 → expected $2, got $result"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

test_file_type "document.pdf" "PDF"
test_file_type "image.png" "PNG"
test_file_type "notes.txt" "TXT"
test_file_type "archive.zip" "UNKNOWN"
test_file_type "photo.jpg" "UNKNOWN"
test_file_type "data.csv" "UNKNOWN"

if [ "$FAILED_TESTS" -gt 0 ]; then
    exit 1
else
    exit 0
fi
