#!/bin/bash

# ==============================================================================
# Script Name:  ssh_login_aggregator.sh
# Description:  Parses standard system authentication logs to extract, count,
#               and report successful and failed SSH connection attempts.
# ==============================================================================

set -euo pipefail

AUTH_LOG=""

# Log path evaluation module
if [[ -f "/var/log/auth.log" ]]; then
    AUTH_LOG="/var/log/auth.log"
elif [[ -f "/var/log/secure" ]]; then
    AUTH_LOG="/var/log/secure"
else
    echo "[-] Error: System authentication log targets not accessible." >&2
    exit 1
fi

echo "========================================================="
echo "               SSH ACCESS AUDITING REPORT                "
echo "               Generated: $(date)                        "
echo "========================================================="

# Quantify historical event states
SUCCESS_COUNT=$(grep -c "Accepted password\|Accepted publickey" "$AUTH_LOG" || echo 0)
FAILURE_COUNT=$(grep -c "Failed password" "$AUTH_LOG" || echo 0)

echo -e "Total Successful Sessions:\t$SUCCESS_COUNT"
echo -e "Total Failed Infractions:\t$FAILURE_COUNT"
echo "---------------------------------------------------------"

if [[ "$SUCCESS_COUNT" -gt 0 ]]; then
    echo "[+] Recent Authenticated Access Vectors:"
    grep "Accepted password\|Accepted publickey" "$AUTH_LOG" | awk '{print "    - "$1" "$2" "$3" | User: "$9" from "$11}' | tail -n 5
fi

echo ""

if [[ "$FAILURE_COUNT" -gt 0 ]]; then
    echo "[⚠️] Recent Target Authentication Invasions:"
    grep "Failed password for" "$AUTH_LOG" | awk '{print "    - "$1" "$2" "$3" | Invalid User: "$11" from "$13}' | tail -n 5
fi

echo "========================================================="
