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
grep "Failed password" "$LOG_FILE" | awk '{print $(NF-3)}' | sort | uniq -c | while read -r count ip; do

	if [ $count -ge "$THRESHOLD" ]; then
		echo "🚨 ALERT: IP $ip has breached threshold with $count failures!"
		echo "$(date) - BANNED: $ip ($count failures)" >> dummy/banned_ips.log
	fi
done

echo "Scan complete."
