#!/usr/bin/env bash

read -r -p "Name to decode: " name

for (( i=0; i<${#name}; i++)); do
	char="${name:$i:1}"
done

echo "Processing string..."
echo "$name" | tr 'A-Za-z' 'N-ZA-Mn-za-m'
