#!/bin/bash

set -eou pipefail

if [ "$#" -ne 2 ]; then
	echo "Missing arguments."
	echo "Usage: $0 <path_to_file> <failure_threshold>"
	exit 1
fi

LOG_FILE=$1
THRESHOLD=$2

if [ ! -f "$LOG_FILE" ]; then
	echo "Error: File $LOG_FILE does not exist."
	exit 1
fi

echo "Scanning $LOG_FILE for brute-force patterns (Threshold: $THRESHOLD)..."
failed=$(grep "Failed password" "$LOG_FILE")
echo "$failed"

echo "Scan complete."
