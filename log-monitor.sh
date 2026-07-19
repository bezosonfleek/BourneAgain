#!/usr/bin/env bash

set -eou pipefail

if [ "$#" -ne 1 ]; then
        echo "Error: Missing required arguments."
        echo "Usage: $0 <limit_threshold>"
        exit 1
fi

threshold="$1"
output_file="dummy/34.txt"

echo "Scanning system journal for brute-force patterns (Threshold: ${threshold})..."
echo "------------------------------------------------------------------------"

if [ ! -f "$output_file" ]; then
    mkdir -p "$(dirname "$output_file")"
    printf "%-21s | %-16s | %-10s | %-25s\n" "[TIMESTAMP]" "IP ADDRESS" "FAILURES" "LOCATION" >> "$output_file"
    printf "%-21s+%-18s+%-12s+%-25s\n" "---------------------" "------------------" "------------" "-------------------------" >> "$output_file"
fi

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

LOG_DATA=$(journalctl _COMM=sshd 2>/dev/null | grep "Failed password" || true) ## The '|| true' preserves script execution if no matches are found

if [ -z "$LOG_DATA" ]; then
    echo "No failed login patterns found."
else
    # Process patterns via Process Substitution to avoid subshell scoping traps
    while read -r count ip; do

        [[ -z "$ip" ]] && continue

        if [ "$count" -ge "$threshold" ]; then

            GEOLOC=$(curl -s --max-time 3 "http://ip-api.com{ip}?fields=country,city" | tr '\n' ',' | sed 's/,$//' || echo "Unknown Location")

            if [ -z "$GEOLOC" ] || [ "$GEOLOC" = "," ]; then
                GEOLOC="Unknown Location"
            fi

            printf "🚨 Failures: %-4s | IP: %-15s | Loc: %-30s\n" "$count" "$ip" "$GEOLOC"
            printf "[%-19s] | %-16s | %-10s | %-25s\n" "$TIMESTAMP" "$ip" "$count" "$GEOLOC" >> "$output_file"

	fi
    done < <(echo "$LOG_DATA" | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr)
fi

echo "------------------------------------------------------------------------"
echo "Scan complete."
