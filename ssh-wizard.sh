#!/usr/bin/env bash

# ssh-wizard
# @author: Ryan Hotton

# version number
version_number=0

# # FUNCTIONS

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

# asks for user's input and only returns a integer
function getInteger() {
    local input_text="$1"
    # optional
    local default="$2"
    local user_input=""
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

# asks user for yes (y) or no (n)
function getAnswer() {
    local input_text="$1"
    # optional
    local default="$2"
    local user_input=""
    local answer=0
    while ! [[ "${user_input,,}" == "y" || "${user_input,,}" == "n" ]]; do
        read -p "$input_text" user_input
        # optional
        if [[ -z "$user_input" ]]; then
            user_input="$default"
        fi
    done
    # convert answer to integer 0 = n, 1 = y
    if [[ "${user_input,,}" == "n" ]]; then
        answer=0
    fi
    if [[ "${user_input,,}" == "y" ]]; then
        answer=1
    fi
    # return answer as integer 0 = n, 1 = y
    return $answer
}

# execute SSH command
function executeSSH() {
    local ssh_cmd="$1"
    echo "\$ $ssh_cmd"
    dashDivider "\$ $ssh_cmd"
    eval $ssh_cmd

    local thank_you_msg="Thank you for using ssh-wizard."
    dashDivider "$thank_you_msg"
    echo "$thank_you_msg"
}

# save ssh command if no duplicate exists and assign it an id
function saveSSH() {
    # declare variables
    local ssh_path="$1"
    local ssh_cmd="$2"
    local ssh_counter=0
    local ssh_id=0
    local duplicate=0
    # only read file if it exists
    if [ -f $ssh_path ]; then
        while read -r ssh_line; do
            ssh_counter="${ssh_line%%:*}"
            if [[ "$ssh_cmd" == "${ssh_line#*:}" ]]; then
                duplicate=1
                break
            fi
            if ((ssh_id < ssh_counter)); then
                ssh_id=$ssh_counter
            fi
        done < "$ssh_path"
        # make new ssh id, must be an id that doesn't already exist
        ((ssh_id++))
    fi
    # save if no duplicate
    if [ "$duplicate" -eq 0 ]; then
        echo "$ssh_id:$ssh_cmd" >> $ssh_path
    fi
}

# clear screen for cleaner output
clear

# # DIRECTORY SETUP

script_dir="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
config_dir="/config"
config_dir="$script_dir$config_dir"
saved_ssh="/sshwiz.$version_number.txt"
mkdir -p "$config_dir"
config_saved="$config_dir$saved_ssh"
if ! [ -f $config_saved ]; then
    echo -n > $config_saved
fi

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

# save ssh command
getAnswer "Would you like to save the ssh command for future use? y/n: " "y"; save_answer="$?"
if [[ "$save_answer" -eq 1 ]]; then
    saveSSH "$config_saved" "$ssh_command"
fi

# clear the screen again
clear
executeSSH "$ssh_command"

# exit script with success
exit 0