#!/bin/bash

set -eou pipefail

source_dir="$HOME/bash-scripts"
backup_dest="$HOME/backups"
date_stamp=$(date +%Y-%m-%d_%H%M)
file_name="backup_${date_stamp}.tar.gz"

if [[ ! -d "$source_dir" ]]; then
	echo "Source directory does not exist..." >&2
	exit 1
fi

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

# To view backup contents: tar -tvf backup_file.tar.gz
# To recover files: tar -xzf backup_file.tar.gz -C /path/to/restore
