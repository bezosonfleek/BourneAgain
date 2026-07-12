#!/bin/bash

set -eou pipefail

if [ "$#" -ne 1 ]; then
        echo "Missing variables."
        echo "Usage: $0 <limit>"
        exit 1
fi

threshold=$1

echo "Scanning system journal for brute-force patterns (Threshold: $threshold)..."
echo "------------------------------------------------------------------------"

if [ ! -f "dummy/34.txt" ]; then
    printf "%-21s | %-19s | %-14s | %-15s\n" "[TIMESTAMP]" "IP ADDRESS" "FAILURES" "STATUS" >> dummy/34.txt
    printf "%-21s+%-21s+%-16s+%-15s\n" "---------------------" "---------------------" "----------------" "---------------" >> dummy/34.txt
fi

journalctl _COMM=sshd --since="18 hours ago" 2>/dev/null | grep "Failed password" | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr | while read -r count ip; do

        TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

        if [ "$count" -ge "$threshold" ]; then
                printf "🚨 %-4s | %-14s | %-20s\n" "$count" "$ip" "BREACHED THRESHOLD"
                printf "[%-19s] | IP: %-15s | FAILURES: %-4s | STATUS: BANNED\n" "$TIMESTAMP" "$ip" "$count" >> dummy/34.txt
        fi
done

echo "------------------------------------------------------------------------"
echo "Scan complete."
