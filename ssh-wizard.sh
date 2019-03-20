#!/bin/bash

# ssh-wizard
# @author: Ryan Hotton

# clear screen for cleaner output
clear

# # SSH KEY RETRIEVAL

# private keys array
private_keys=()

# loop through all public keys
for public_key in ~/.ssh/*.pub
do
    # check if public key is a valid file (.pub)
    if [ -r $public_key ]; then
        # check if private key is a valid file
        private_key=${public_key%.pub}
        if [ -r $private_key ]; then
            #  if valid add to array
            private_keys+=($private_key)
        fi
    fi
done

# get length of array
private_keys_len=${#private_keys[@]}

# exit if there are no ssh keys on the system
if [ "$private_keys_len" -eq 0 ]; then
    # TODO: allow user to create ssh key within the wizard
    echo "Error: Please generate a ssh key."
    exit 1
fi

# substract array length for future use
private_keys_len=$((private_keys_len-1))

echo "SSH Keys:"
for pki in ${!private_keys[@]}; do
  echo [$pki] ${private_keys[pki]##*/}
done

ssh_key=-1
while [[ "$ssh_key" -lt 0 ]] || [[ "$ssh_key" -gt "$private_keys_len" ]]; do
    # get user input and verify if the input is valid, if not try again
    read -p 'Please select one of the above ssh keys: ' ssh_key
    # source: https://stackoverflow.com/a/4137381/8095383
    if ! [[ "$ssh_key" =~ ^[0-9]+$ ]] ; then
        ssh_key=-1
    fi
done

# ssh key path
ssh_key_path=${private_keys[ssh_key]}

# # SSH PARAMETERS

# default port
default_port=22

# clear the screen again
clear

read -p "Username: " username
read -p "Hostname or IP Address: " host
read -p "Port (default $default_port): " port

# verify port number, if not apply default
if ! [[ "$port" =~ ^[0-9]+$ ]] ; then
    port=22
fi

# initialize ssh command
ssh_command="ssh $username@$host -p $port -i \"$ssh_key_path\""

# clear the screen again
clear
echo "\$ $ssh_command"
eval $ssh_command

echo ""
echo "Thank you for using ssh-wizard."

# exit script with success
exit 0