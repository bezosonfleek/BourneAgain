#!/usr/bin/env bash

discord_webhook="https://discord.com/api/webhooks/YOUR_WEBHOOK_URL"

threshold=75

df -h | awk 'NR > 1 && $6 !~ /^\/snap/ && $6 !~ /^\/usr\/lib\/wsl/ {sub(/%/, "", $5); print $5, $6}' | while read -r disk_usage mount_point; do
    if [ "$disk_usage" -ge "$threshold" ]; then
        echo "Threshold exceeded for $mount_point. Current usage: ${disk_usage}%"
        curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"🚨 **System Alert** 🚨\n**Server:** \$(hostname)\n**Mount Point:** \${mount_point}\n**Disk Usage:** \${disk_usage}%\"}" "$discord_webhook"
    fi
done
