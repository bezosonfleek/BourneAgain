#!/bin/bash

read -p "User to be created:" user

if id "$user" &>/dev/null; then
  echo "Error: User $user already exists."
  exit 1
fi

expire_date=$(date -d "+1 year" +%Y-%m-%d)

read -p "Group to be added:" group

#add conditional statement for more groups

sudo useradd -m -s /bin/bash -G $group -e "$expire_date" $user

if [ $? -eq 0 ]; then
  echo "Account for $user created (expires: $expire_date)."
  sudo passwd $user 
else
  echo "Failed to create user."
  exit 1
fi