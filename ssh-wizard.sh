#!/bin/bash

# ssh-wizard
# @author: Ryan Hotton

# # FUNCTIONS

# asks for user's input and only returns a integer
function getInteger() {
    local input_text="$1"
    # optional
    local default="$2"
    local user_input=''
    # source: https://stackoverflow.com/a/4137381/8095383
    while ! [[ "$user_input" =~ ^[0-9]+$ ]]; do
        read -p "$input_text" user_input
        # optional
        if [[ -z "$user_input" ]]; then
            user_input="$default"
        fi
    done
    # return integer
    return $user_input
}

# takes a string and echos a string of the same length with dashes
function dashDivider() {
    local text="$1"
    local dashed_text=""
    local dash="-"
    # loop through length of the string
    for (( i=0; i<${#text}; i++ )); do
        dashed_text="$dashed_text$dash"
    done
    # echo dashes
    echo "$dashed_text"
}

function saveSSH() {
    ssh_path="$1"
    ssh_cmd="$2"
    # TODO
}

# clear screen for cleaner output
clear

# # DIRECTORY SETUP

# script_dir="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
# config_dir="/config"
# config_dir="$script_dir$config_dir"
# saved_ssh="/sshwizard.txt"
# mkdir -p "$config_dir"
# config_saved="$config_dir$saved_ssh"
# if ! [ -f $config_saved ]; then
#     echo -n > $config_saved
# fi

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
# get user input and verify if the input is valid, if not try again
while [[ "$ssh_key" -lt 0 ]] || [[ "$ssh_key" -gt "$private_keys_len" ]]; do
    getInteger "Please select one of the above ssh keys: "; ssh_key="$?"
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
getInteger "Port (default $default_port): " "$default_port"; port="$?"

# initialize ssh command
ssh_command="ssh $username@$host -p $port -i \"$ssh_key_path\""

# clear the screen again
clear
echo "\$ $ssh_command"
dashDivider "\$ $ssh_command"
eval $ssh_command

thank_you_msg="Thank you for using ssh-wizard."
dashDivider "$thank_you_msg"
echo "$thank_you_msg"

# exit script with success
exit 0