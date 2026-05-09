#!/bin/bash

showaddress(){
  execution_time=$(date)
  private_ip=$(hostname -I | awk '{print $1}')
  
  if public_ip=$(curl -s --max-time 5 https://ifconfig.me); then
    status="ONLINE"
  else
    public_ip="UNREACHABLE"
    status="OFFLINE"
  fi

  cat << EOF 
--------------------------------------------
Execution time: ${execution_time}
Network status: ${status}
--------------------------------------------
Private IP: ${private_ip}
Public IP: ${public_ip}
--------------------------------------------
EOF
}

showaddress
