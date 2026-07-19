#!/bin/bash

set -eou pipefail

if [ "$#" -ne 1 ]; then
        echo "Missing variables."
        echo "Usage: $0 <limit>"
        exit 1
fi

threshold=$1
output_file="dummy/34.txt"

echo "Scanning system journal for brute-force patterns (Threshold: $threshold)..."
echo "------------------------------------------------------------------------"

if [ ! -f "dummy/34.txt" ]; then
    printf "%-21s | %-16s | %-10s | %-25s\n" "[TIMESTAMP]" "IP ADDRESS" "FAILURES" "STATUS" >> "$output_file"
    printf "%-21s+%-18s+%-12s+%-25s\n" "---------------------" "---------------------" "----------------" "---------------" >> "$output_file"
fi

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

#grep "Failed password" "$file" | awk '{print$(NF-3)}' | sort | uniq -c | sort -nr | while read -r count ip; do (static file analysis)

LOG_DATA=$(journalctl _COMM=sshd 2>/dev/null | grep "Failed password" || true) #--since="18 hours ago"

if [ -z "$LOG_DATA" ]; then
    echo "No failed login patterns found."
else
    echo "$LOG_DATA" | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr | while read -r count ip; do

        if [ "$count" -ge "$threshold" ]; then
		GEOLOC=$(curl -s --max-time 3 "http://ip-api.com/{ip}?fields=country,city" | tr '\n' ',' | sed 's/,$//' || echo "Unknown Location")
#		GEOLOC=$(curl -s --max-time 3 "http://ip-api.com/"${ip}"?fields=country,city" | tr '\n' ',' | sed 's/,$//' || echo "Unknown Location")

		if [ -z "$GEOLOC" ]; then
			GEOLOC="Unkown Location."
		fi

                printf "🚨 %-4s | %-15s | %-30s\n" "$count" "$ip" "$GEOLOC" "BREACHED THRESHOLD"
                printf "[%-19s] | IP: %-16s | FAILURES: %-10s | STATUS: BANNED\n" "$TIMESTAMP" "$ip" "$count" "$GEOLOC" >> "$output_file"
        fi
done
fi

echo "------------------------------------------------------------------------"
echo "Scan complete."
