#!/bin/bash

# This script will create a deployment user and group, 
# create ssh key pair, send public key to authorized key file and create a config file for github

read -p "Enter deployment username to be created : " deployment_user
read -p "Enter deployment group to be created    : " deployment_group

# Create deployment group using a function
create_deployment_group() {
    sudo groupadd $deployment_group
}

# Create deployment user using a function
create_deployment_user() {
    sudo useradd -m -s /bin/bash $deployment_user
    sudo usermod -aG $deployment_group $deployment_user
    # sudo passwd $deployment_user
}

# Create ssh key pair named deploy using the deployment user using a function
create_ssh_key_pair() {
    su $deployment_user -c "mkdir ~/.ssh" $deployment_user
    su - -c "chmod 700 ~/.ssh" $deployment_user
    sudo su - $deployment_user -c "ssh-keygen -f ~/.ssh/"$deployment_user"_deploy -q -N '' " $deployment_user
}

# Send pubilic key to authorized-key file and set permissions using a function
send_public_key() {
    su $deployment_user -c "touch ~/.ssh/authorized_keys" $deployment_user
    sudo su $deployment_user -c "echo  $(cat /home/$deployment_user/.ssh/"$deployment_user"_deploy.pub) > ~/.ssh/authorized_keys" $deployment_user
    su $deployment_user -c "chmod 600 ~/.ssh/authorized_keys" $deployment_user
}

# create config file for github using a function
create_config_file() {
    su $deployment_user -c "touch ~/.ssh/config" $deployment_user
    sudo su $deployment_user -c "echo -e 'Host github.com\n\tHostName github.com\n\tUser git\n\tIdentityFile ~/.ssh/"$deployment_user"_deploy' > ~/.ssh/config" $deployment_user
    su $deployment_user -c "chmod 600 ~/.ssh/config" $deployment_user
}

confirmation() {
    echo -e ""
    echo -e "Further execution will attempt to create the following:"
    echo -e ""
    echo -e "Deployment user as                         : $deployment_user"
    echo -e "Deployment group as                        : $deployment_group"
    echo -e "Private deploy key pair at                 : /home/$deployment_user/.ssh/"$deployment_user"_deploy"
    echo -e "Public deploy key pair at                  : /home/$deployment_user/.ssh/"$deployment_user"_deploy.pub"
    echo -e "Authorized key at                          : /home/$deployment_user/.ssh/authorized_keys"
    echo -e "Config file for github with private key at : /home/$deployment_user/.ssh/config"
    echo -e ""
    read -p "Continue ? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
    
    create_deployment_group
    create_deployment_user
    create_ssh_key_pair
    send_public_key
    create_config_file

    echo -e ""
    echo -e "All resouces created successfully.."

    echo -e "Apply the following commands to complete the process.."
    echo -e ""
    echo "Add /home/$deployment_user/.ssh/"$deployment_user"_deploy.pub as Deploy key to Github repo access"
    echo "Add GitHub action secrets for SSH"
    echo "On your cloned repo run, "sudo chgrp -R $deployment_group [repo_name or path]""
    echo "To allow read,write,execute run, "sudo chmod -R g+rwX [repo_name or path]""
    echo "To set default group as $deployment_group for new files/dir "sudo chmod -R g+s [repo_name or path]" "
    echo "To add users into  $deployment_group run "sudo usermod -aG $deployment_group [username]""
    echo "Install Docker using https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository"
    echo "To allow users to run docker commands run "sudo usermod -aG docker [username]""
}

confirmation

"$@"