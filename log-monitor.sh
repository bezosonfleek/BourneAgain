#!/bin/bash

set -eou pipefail

if [ "$#" -ne 2 ]; then
        echo "Missing variables."
        echo "Usage $0 <file> <limit>"
        exit 1
fi

file=$1
threshold=$2

if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist."
        exit 1
fi

echo "Scanning $file for brute-force patterns (Threshold $threshold)..."
grep "Failed password" "$file" | awk '{print$(NF-3)}' | sort | uniq -c | sort -nr | while read -r count ip; do

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

        if [ $count -ge $threshold ]; then
                printf "🚨 %-4s | %-14s | %-20s\n" "$count" "$ip" "BREACHED THRESHOLD"
                printf "[%-19s] | IP: %-15s | FAILURES: %-4s | STATUS: BANNED\n" "$TIMESTAMP" "$ip" "$count" >> dummy/34.txt
        fi
done

echo "Scan complete."
