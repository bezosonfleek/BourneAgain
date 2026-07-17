#!/usr/bin/env bash

if [ -f "/home/bezos/.env" ]; then
    source "/home/bezos/.env"
fi

echo "List of servers:"
printf  "%s\n" "${servers[@]}"
echo

#echo -e "List of servers:\n$(printf '%s\n' "${servers[@]}")"

ssh_key=/home/bezos/bash-scripts/essentials/fleet-svr-key.pem
failed_servers=()

for server in "${servers[@]}"; do
	echo "==================== Starting update on ${server} ===================="

	if ! ssh -i "$ssh_key" -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "${user}@$server" \
	     "sudo apt-get update && sudo apt-get upgrade -y"; then
		echo "❌ Error: Failed to update ${server}. Skipping to next host..." >&2
		failed_servers+=("$server")
		continue
	fi
	echo "✅ Successfully updated ${server}"
#	echo "----------------------------------------"
done

if [ ${#failed_servers[@]} -ne 0 ]; then
	echo "Fleet update complete with failures on:"
	printf "%s\n" "${failed_servers[@]}"
	exit 1
else
	echo "All servers updated succesfully."
fi
