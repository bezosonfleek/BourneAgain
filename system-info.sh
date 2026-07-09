#!/bin/bash

# ==============================================================================
# Script Name:  system_dashboard.sh
# Description:  Gathers local hardware resources and system states to generate
#               an administrative information dashboard summary.
# ==============================================================================

set -euo pipefail

# Metrics harvesting blocks
OS_INFO=$(HOSTNAME= lsb_release -ds 2>/dev/null || cat /etc/os-release | grep "PRETTY_NAME" | cut -d= -f2 | tr -d '"')
KERNEL=$(uname -r)
UPTIME=$(uptime -p)
CPU_LOAD=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"%"}')
MEM_FREE=$(free -h | grep Mem | awk '{print $4" / "$2" free"}')
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5" utilized ("$4" remaining)"}')
PRIMARY_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || echo "No network gateway")

clear
echo "========================================================="
echo "               SYSTEM PERFORMANCE DASHBOARD              "
echo "               Hostname: $(hostname)                     "
echo "========================================================="
echo -e "Platform OS:\t\t$OS_INFO"
echo -e "Kernel Version:\t\t$KERNEL"
echo -e "System Uptime:\t\t$UPTIME"
echo "---------------------------------------------------------"
echo -e "CPU Utilization:\t$CPU_LOAD"
echo -e "Memory Footprint:\t$MEM_FREE"
echo -e "Root Filesystem:\t$DISK_USAGE"
echo "---------------------------------------------------------"
echo -e "Primary Network IP:\t$PRIMARY_IP"
echo "========================================================="
