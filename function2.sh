#!/bin/bash

showaddress(){
  execution_time=$(date "+%d-%m-%Y %H:%M:%S")
  private_ip=$(hostname -I | awk '{print $1}')

  if public_ip=$(curl -s --max-time 5 https://ifconfig.me); then
    status="ONLINE"
    exit_code=0
  else
    public_ip="UNREACHABLE"
    status="OFFLINE"
    exit_code=1
  fi

  cat << EOF | tee -a net-audit.log
-------------------------------------
Execution time: ${execution_time}
Network status: ${status}
Private IP: ${private_ip:-"N/A"}
Public IP : ${public_ip}
-------------------------------------
EOF

  return $exit_code
}

showaddress
