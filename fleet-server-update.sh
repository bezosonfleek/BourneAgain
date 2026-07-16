#!/usr/bin/env bash

servers=("122.99.67.45" "165.43.43.54" "53.21.54.69") #add to .env to avoid hardocding
echo "${servers[@]}"

user="bezos"
ssh_key=/dummy/keys/ssh-key.pem
failed_servers=()

for server in "${servers[@]}"; do
	echo "=== Starting update on ${server} ==="

	if ! ssh -i "$ssh_key" -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "${user}@$server" \
	     "sudo apt-get update && sudo apt-get upgrade -y"; then
		echo "❌ Error: Failed to update ${server}. Skipping to next host..." >&2
		failed_servers+=("$server")
		continue
	fi
	echo "✅ Successfully updated ${server}"
	echo "-----------------------------------"
done

if [ ${#failed_servers[@]} -ne 0 ]; then
	echo "Fleet update complete with failures on: ${failed_servers[*]}"
	exit 1
else
	echo "All servers updated succesfully."
fi
