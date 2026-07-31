#!/usr/bin/env bash

read -p "Enter Github username: " username

#echo "Github username is "$username"."

curl -s "https://api.github.com/users/$username" | awk -F '"' '/"name":/ {print $4}'
