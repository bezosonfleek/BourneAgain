#!/usr/bin/env bash

threshold=75

df -h | awk 'NR > 1 {sub(/%/, "", $5); print $5, $6}' | while read -r disk_usage mount_point; do
    if [ "$disk_usage" -ge "$threshold" ]; then
        echo "Threshold exceeded for $mount_point. Current usage: $disk_usage"
    fi
done
