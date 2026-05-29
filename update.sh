#!/bin/bash

# ==============================================================================
# Script Name:  automated_system_update.sh
# Description:  Automates package manager synchronization, updates, and space
#               reclamation across multiple Linux distributions.
# ==============================================================================

set -euo pipefail

LOG_FILE="/var/log/system_updater.log"

# Root enforcement module
if [[ $EUID -ne 0 ]]; then
   echo "[-] Error: This maintenance script must be run with sudo privileges." >&2
   exit 1
fi

exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================================="
echo "               STARTING SYSTEM MAINTENANCE               "
echo "               Timestamp: $(date)                        "
echo "========================================================="

# OS detection and updating engine
if command -v apt-get &> /dev/null; then
    echo "[+] Debian/Ubuntu environment identified."
    echo "[+] Fetching fresh package updates..."
    apt-get update -y
    echo "[+] Applying security and software upgrades..."
    apt-get upgrade -y
    echo "[+] Purging residual dependencies and caches..."
    apt-get autoremove -y
    apt-get clean -y
elif command -v dnf &> /dev/null; then
    echo "[+] RHEL/Rocky/Fedora environment identified."
    echo "[+] Mirroring repositories and applying updates..."
    dnf upgrade -y
    echo "[+] Cleaning up downloaded metadata and packages..."
    dnf clean all -y
else
    echo "[-] Operational Failure: Unsupported package manager architecture." >&2
    exit 1
fi

echo "[+] Optimizing log spaces..."
find /var/log -type f -name "*.log" -size 0 -delete

echo "========================================================="
echo "               MAINTENANCE CYCLE SUCCESSFUL             "
echo "========================================================="
