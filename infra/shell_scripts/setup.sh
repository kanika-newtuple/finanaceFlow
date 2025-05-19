#!/bin/bash

# This script will create a deployment user and group,
# create ssh key pair, send public key to authorized key file and create a config file for github

# Define colors as variables
GREEN="\033[1;32m"
CYAN="\033[1;36m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
BOLD="\033[1m"
UNDERLINE="\033[4m"
# Define no color
NC="\033[0m" # No Color


# Validate username function
validate_username() {
    local username=$1
    # Check if username is empty
    if [[ -z "$username" ]]; then
        echo -e "${RED}Error: Username cannot be empty${NC}"
        return 1
    fi
    # Check if username follows valid format (alphanumeric, underscore, hyphen)
    if ! [[ "$username" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Error: Username must contain only letters, numbers, underscore, or hyphen${NC}"
        return 1
    fi
    # Check if username already exists
    if id "$username" &>/dev/null; then
        echo -e "${RED}Error: User '$username' already exists${NC}"
        return 1
    fi
    return 0
}

# Validate group name function
validate_group() {
    local group=$1
    # Check if group name is empty
    if [[ -z "$group" ]]; then
        echo -e "${RED}Error: Group name cannot be empty${NC}"
        return 1
    fi
    # Check if group name follows valid format
    if ! [[ "$group" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Error: Group name must contain only letters, numbers, underscore, or hyphen${NC}"
        return 1
    fi
    return 0
}

# Get validated user input
get_valid_inputs() {
    local valid_input=false
    
    while [ "$valid_input" = false ]; do
        echo -e "${CYAN}Enter deployment username to be created : ${NC}" 
        read deployment_user
        if validate_username "$deployment_user"; then
            valid_input=true
        else
            echo -e "${YELLOW}Please try again.${NC}"
            valid_input=false
        fi
    done
    
    valid_input=false
    while [ "$valid_input" = false ]; do
        echo -e "${CYAN}Enter deployment group to be created    : ${NC}"
        read deployment_group
        if validate_group "$deployment_group"; then
            valid_input=true
        else
            echo -e "${YELLOW}Please try again.${NC}"
            valid_input=false
        fi
    done
}

# Get user inputs with validation
get_valid_inputs

# Create deployment group using a function
create_deployment_group() {
    echo -e "${GREEN}Creating Deployment group...${NC}"
    sudo groupadd $deployment_group
}

# Create deployment user using a function
create_deployment_user() {
    echo -e "${GREEN}Creating Deployment user...${NC}"
    
    # Create group if it doesn't exist
    if ! getent group $deployment_group >/dev/null; then
        sudo groupadd $deployment_group
    fi

    # Create user and assign primary group
    sudo useradd -m -s /bin/bash -g $deployment_group $deployment_user

    # Add user to additional groups (optional)
    sudo usermod -aG $deployment_group $deployment_user

    # Uncomment if you want to set a password manually
    # sudo passwd $deployment_user
}

# Create ssh key pair named deploy using the deployment user using a function
create_ssh_key_pair() {
    echo -e "${GREEN}Creating ssh key pair...${NC}"
    sudo su $deployment_user -c "mkdir -p ~/.ssh" $deployment_user
    sudo su - -c "chmod 700 ~/.ssh" $deployment_user
    sudo su - $deployment_user -c "ssh-keygen -f ~/.ssh/"$deployment_user"_deploy -q -N '' " $deployment_user
}

# Send pubilic key to authorized-key file and set permissions using a function
send_public_key() {
    echo -e "${GREEN}Sending public key to authorized key file for ssh access...${NC}"
    sudo su $deployment_user -c "touch ~/.ssh/authorized_keys" $deployment_user
    sudo su $deployment_user -c "echo  $(cat /home/$deployment_user/.ssh/"$deployment_user"_deploy.pub) > ~/.ssh/authorized_keys" $deployment_user
    sudo su $deployment_user -c "chmod 600 ~/.ssh/authorized_keys" $deployment_user
}

# create config file for github using a function
create_config_file() {
    echo -e "${GREEN}Creating config file for github...${NC}"
    sudo su $deployment_user -c "touch ~/.ssh/config" $deployment_user
    sudo su $deployment_user -c "echo -e 'Host github.com\n\tHostName github.com\n\tUser git\n\tIdentityFile ~/.ssh/"$deployment_user"_deploy' > ~/.ssh/config" $deployment_user
    sudo su $deployment_user -c "chmod 600 ~/.ssh/config" $deployment_user
}

confirmation() {
    echo -e ""
    echo -e "${BOLD}${UNDERLINE}Further execution will attempt to create the following:${NC}"
    echo -e ""
    echo -e "${BOLD}Deployment user as                         :${NC} ${CYAN}$deployment_user${NC}"
    echo -e "${BOLD}Deployment group as                        :${NC} ${CYAN}$deployment_group${NC}"
    echo -e "${BOLD}Private deploy key pair at                 :${NC} ${CYAN}/home/$deployment_user/.ssh/"$deployment_user"_deploy${NC}"
    echo -e "${BOLD}Public deploy key pair at                  :${NC} ${CYAN}/home/$deployment_user/.ssh/"$deployment_user"_deploy.pub${NC}"
    echo -e "${BOLD}Authorized key at                          :${NC} ${CYAN}/home/$deployment_user/.ssh/authorized_keys${NC}"
    echo -e "${BOLD}Config file for github with private key at :${NC} ${CYAN}/home/$deployment_user/.ssh/config${NC}"
    echo -e ""
    echo -e "${YELLOW}Continue ? (Y/N): ${NC}" 
    read confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

    create_deployment_group
    create_deployment_user
    create_ssh_key_pair
    send_public_key
    create_config_file

    echo -e ""
    echo -e "${GREEN}${BOLD}All resources created successfully!${NC}"

    echo -e "${YELLOW}${BOLD}Apply the following commands to complete the process:${NC}"
    echo -e ""
    echo -e "${CYAN}1. Add Deploy key to Github for repo access:${NC}"
    echo -e "   /home/$deployment_user/.ssh/"$deployment_user"_deploy.pub"
    echo -e "${CYAN}2. Add GitHub action secrets to setup SSH into the VM using the deployment user credentials${NC}"
    echo -e "${CYAN}3. [Optional] On your cloned repo run:${NC}"
    echo -e "   sudo chgrp -R $deployment_group [repo_name or path]"
    echo -e "${CYAN}4. [Optional] To allow read,write,execute run:${NC}"
    echo -e "   sudo chmod -R g+rwX [repo_name or path]"
    echo -e "${CYAN}5. [Optional] To set default group as $deployment_group for new files/dir:${NC}"
    echo -e "   sudo chmod -R g+s [repo_name or path]"
    echo -e "${CYAN}6. [Optional] To add users into $deployment_group run:${NC}"
    echo -e "   sudo usermod -aG $deployment_group [username]"
    echo -e "${CYAN}7. [Optional] Install Docker using:${NC}"
    echo -e "   https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository"
    echo -e "${CYAN}8. [Optional] To allow users to run docker commands run:${NC}"
    echo -e "   sudo usermod -aG docker [username]"
}

confirmation

"$@"
