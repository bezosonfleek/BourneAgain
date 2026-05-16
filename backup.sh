#!/bin/bash

source_dir="$HOME/bash-scripts"
backup_dest="$HOME/backups"
date_stamp=$(date +%Y-%m-%d_%H%M)
file_name="backup_${date_stamp}.tar.gz"

# Create backup directory if it doesn't exist
[[ ! -d "$backup_dest" ]] && mkdir -p "$backup_dest"

echo "Starting backup of $source_dir..."

if tar -czf "$backup_dest/$file_name" "$source_dir" 2>/dev/null; then
    echo "Backup successful: $backup_dest/$file_name"
    echo "Size: $(du -h "$backup_dest/$file_name" | cut -f1)"
else
    echo "Error: Backup failed."
    exit 1
fi
