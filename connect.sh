#!/bin/bash

# ==============================================================================
# Script Name:  ip_connectivity_tester.sh
# Description:  Performs a parallel ping sweep over an array of IP targets
#               to map network connectivity assets.
# ==============================================================================

set -euo pipefail

# Configuration: Define your network nodes or lab IPs here
TARGET_IPS=(
    "192.168.0.1"
    "192.168.0.5"
    "192.168.0.28"
    "192.168.0.215"
    "8.8.8.8"
    "1.1.1.1"
)

echo "========================================================="
echo "               NETWORK CONNECTIVITY TESTING              "
echo "               Started: $(date '+%Y-%m-%d %H:%M:%S')     "
echo "========================================================="

ONLINE_HOSTS=0
OFFLINE_HOSTS=0

for ip in "${TARGET_IPS[@]}"; do
    # -c 1: send 1 packet, -W 1: wait 1 second max for a response
    if ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
        echo -e "[+] HOST ONLINE:\t$ip"
        ((ONLINE_HOSTS++))
    else
        echo -e "[-] HOST UNREACHABLE:\t$ip"
        ((OFFLINE_HOSTS++))
    fi
done

echo "---------------------------------------------------------"
echo "Scan Complete. Summary: $ONLINE_HOSTS Online | $OFFLINE_HOSTS Unreachable"
echo "========================================================="
