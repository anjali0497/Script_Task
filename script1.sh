#!/bin/bash

# Default functions
LOG_FILE="/home/anjali/Tasks/script.log"
YAML_FILE="/home/anjali/Tasks/task.yml"  

# Log function
log() {
    local level=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

# Send email function
send_email() {
    local subject=$1
    local message=$2
    local recipient="anjalidhiman.as@gmail.com"  

    echo "$message" | mail -s "$subject" "$recipient"
}

# Functions for actions
create_user() {
    USER_NAME=$1
    USER_PASSWORD=$2
    USER_HOME=$3

    log "INFO" "Attempting to create user $USER_NAME with home directory $USER_HOME."

    if sudo useradd -m -d "$USER_HOME" -s /bin/bash "$USER_NAME" && echo "$USER_NAME:$USER_PASSWORD" | sudo chpasswd; then
        send_email "User Creation Success" "User $USER_NAME was successfully created with home directory $USER_HOME."
        log "SUCCESS" "User $USER_NAME created successfully."
    else
        send_email "User Creation Failure" "Failed to create user $USER_NAME."
        log "ERROR" "Failed to create user $USER_NAME."
    fi
}

list_user() {
    local users
    users=$(cut -d: -f1 /etc/passwd)  # Get all users

    log "INFO" "Attempting to list users."

    if [ -n "$users" ]; then
        echo "The following users are present on the system:"
        echo "$users"
        send_email "User Listing Success" "The following users are present on the system:\n\n$users"
        log "SUCCESS" "User listing successful. Users: $users"
    else
        send_email "User Listing Failure" "Failed to retrieve user list."
        log "ERROR" "Failed to retrieve user list."
    fi
}

delete_user() {
    USER_NAME=$1
    log "INFO" "Attempting to delete user $USER_NAME."

    if sudo userdel -r "$USER_NAME"; then
        send_email "User Deletion Success" "User $USER_NAME was successfully deleted."
        log "SUCCESS" "User $USER_NAME deleted successfully."
    else
        send_email "User Deletion Failure" "Failed to delete user $USER_NAME."
        log "ERROR" "Failed to delete user $USER_NAME."
    fi
}

install_software() {
    SOFTWARE_NAME=$1
    log "INFO" "Attempting to install software $SOFTWARE_NAME."
    if sudo apt update && sudo apt install -y "$SOFTWARE_NAME"; then
        send_email "Software Installation Success" "$SOFTWARE_NAME was successfully installed."
        log "SUCCESS" "Software $SOFTWARE_NAME installed successfully."
    else
        send_email "Software Installation Failure" "Failed to install $SOFTWARE_NAME."
        log "ERROR" "Failed to install software $SOFTWARE_NAME."
    fi
}

# Process YAML file to get task details
process_yaml() {
    local action=$1
    shift
    local params=("$@")

    # Get the command from the YAML file
    local command
    command=$(yq eval ".tasks.${action}.command" "$YAML_FILE")

    if [ -z "$command" ]; then
        echo "Task $action not found in YAML file."
        exit 1
    fi

    # Execute the command with parameters
    eval "$command"
}

# Check arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <action> [parameters]"
    exit 1
fi

ACTION=$1
shift

# Perform the requested action
case $ACTION in
    create_user)
        if [ "$#" -ne 3 ]; then
            echo "Usage: $0 create_user <username> <password> <home_directory>"
            exit 1
        fi
        create_user "$1" "$2" "$3"
        ;;
    list_user)
        list_user
        ;;
    delete_user)
        if [ "$#" -ne 1 ]; then
            echo "Usage: $0 delete_user <username>"
            exit 1
        fi
        delete_user "$1"
        ;;
    install_software)
        if [ "$#" -ne 1 ]; then
            echo "Usage: $0 install_software <software_name>"
            exit 1
        fi
        install_software "$1"
        ;;
    *)
        process_yaml "$ACTION" "$@"
        ;;
esac

