#!/bin/bash


# This script is intended to be run as root or with sudo privileges.
# It will nginx reverse proxy to a subdomain and assign SSL certificate using Let's Encrypt ACME.

# Define colors as variables
GREEN="\033[1;32m"
CYAN="\033[1;36m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
BOLD="\033[1m"
UNDERLINE="\033[4m"
# Define no color
NC="\033[0m" # No Color


# Validate subdomain
while true; do
    echo -e "${CYAN}Enter subdomain to be used: ${NC}"
    read subdomain
    if [[ -z "$subdomain" ]]; then
        echo -e "${RED}Error: Subdomain cannot be empty.${NC}"
    elif ! [[ "$subdomain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "${RED}Error: Invalid subdomain format. Use format like 'sub.example.com'${NC}"
    else
        break
    fi
done

# Validate application port
while true; do
    echo -e "${CYAN}Enter application port: ${NC}" 
    read application_port
    if [[ -z "$application_port" ]]; then
        echo -e "${RED}Error: Application port cannot be empty.${NC}"
    elif ! [[ "$application_port" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: Port must be a number.${NC}"
    elif [[ "$application_port" -lt 1024 || "$application_port" -gt 65535 ]]; then
        echo -e "${RED}Error: Port must be between 1024 and 65535.${NC}"
    else
        break
    fi
done

# Validate SSL certificate confirmation
while true; do
    echo -e "${CYAN}Do you want to assign SSL certificate to subdomain using Let's Encrypt ACME? (y/n): ${NC}"
    read ssl_cert_confirmation
    if [[ "$ssl_cert_confirmation" =~ ^[yYnN]$ ]]; then
        break
    else
        echo -e "${RED}Error: Please enter 'y' or 'n'.${NC}"
    fi
done

create_reverse_conf_file() {
    echo -e "${GREEN}Creating conf file for ${CYAN}$subdomain${GREEN} ..${NC}"
    sudo bash -c "cat > /etc/nginx/conf.d/$subdomain.conf << 'EOL'
server {
    listen 80;
    server_name $subdomain;
    location / {
        proxy_pass http://localhost:$application_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL"
    sudo nginx -t
    sudo systemctl restart nginx
}

assign_ssl_cert() {    
    echo -e "${GREEN}Assigning SSL certificate to ${CYAN}$subdomain${GREEN} ..${NC}"
    sudo certbot --nginx -d $subdomain
}

confirmation() {
    echo -e ""
    echo -e "${BOLD}Further execution will attempt to create the following:${NC}"
    echo -e ""
    echo -e "Review and add addtional reverse proxy rules at                        : ${CYAN}/etc/nginx/conf.d/$subdomain.conf${NC}"
    echo -e "SSL certificate for ${CYAN}$subdomain${NC} using Let's Encrpyt ACME at : ${CYAN}/etc/letsencrypt/live/$subdomain${NC}"
    echo -e ""
    read -p "Continue ? (Y/N): " confirm
    if [[ "$confirm" =~ ^[yY]$ ]]; then
        create_reverse_conf_file
        if [[ "$ssl_cert_confirmation" =~ ^[yY]$ ]]; then
            assign_ssl_cert
        fi
        echo -e ""
        echo -e "${GREEN}${BOLD}All resources created successfully..${NC}"
        echo -e "${YELLOW}Check nginx error logs using '${UNDERLINE}sudo tail -f /var/log/nginx/error.log${NC}${YELLOW}'${NC}"
        echo -e "${YELLOW}Check nginx access logs using '${UNDERLINE}sudo tail -f /var/log/nginx/access.log${NC}${YELLOW}'${NC}"
    else
        echo -e "${RED}Operation canceled.${NC}"
        exit 1
    fi
}

confirmation

"$@"
