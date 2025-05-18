#!/bin/bash

# Function to parse an env file and return formatted environment variables
parse_env_file() {
    local env_file="$1"
    local all_env_vars=""
    
    # Load and process each line from the .env file
    while IFS='=' read -r key value; do
        # Skip empty lines and comments
        [[ -z "$key" || "$key" == \#* ]] && continue
        
        # Remove surrounding quotes and whitespace
        og_key="$key"
        key=$(echo "$key" | xargs | tr '[:upper:]' '[:lower:]' | tr '_' '-')
        value=$(echo "$value" | xargs | sed -e 's/^"//' -e 's/"$//')
        
        # build a space separated string of secrets
        all_env_vars+="\"$og_key\"=\"$value\" "
    done < "$env_file"
    
    # Return the collected environment variables
    echo "$all_env_vars"
}

# Function to set secrets in Key Vault
set_key_vault_secrets() {
    local vault_name="$1"
    local env_file="$2"
    
    # Load and process each line from the .env file
    while IFS='=' read -r key value; do
        # Skip empty lines and comments
        [[ -z "$key" || "$key" == \#* ]] && continue
        
        # Format key and value
        key=$(echo "$key" | xargs | tr '[:upper:]' '[:lower:]' | tr '_' '-')
        value=$(echo "$value" | xargs | sed -e 's/^"//' -e 's/"$//')
        
        echo "Setting secret: $key" >&2
        az keyvault secret set --vault-name "$vault_name" --name "$key" --value "$value" >/dev/null
    done < "$env_file"
}

# Function to process env file and set secrets in Key Vault (for backward compatibility)
process_env_file() {
    local vault_name="$1"
    local env_file="$2"
    
    # Set the secrets in Key Vault
    set_key_vault_secrets "$vault_name" "$env_file"
    
    # Parse and return env vars
    parse_env_file "$env_file"
}

# Check if the script is being called with arguments
if [ $# -ge 2 ]; then
    if [ "$1" = "process_env_file" ]; then
        # Call the function and output the result directly
        process_env_file "$2" "$3"
        exit 0
    elif [ "$1" = "parse_env_file" ]; then
        # Only parse the env file without setting secrets
        parse_env_file "$2"
        exit 0
    elif [ "$1" = "set_key_vault_secrets" ]; then
        # Only set secrets without returning parsed variables
        set_key_vault_secrets "$2" "$3"
        exit 0
    fi
fi

# If we get here, the script is being sourced or run without proper arguments
echo "Usage: $0 [process_env_file|parse_env_file|set_key_vault_secrets] <args...>" >&2
echo "  process_env_file <vault_name> <env_file>  - Set secrets and return parsed variables" >&2
echo "  parse_env_file <env_file>                - Only parse env file without setting secrets" >&2
echo "  set_key_vault_secrets <vault_name> <env_file> - Only set secrets in Key Vault" >&2
exit 1

# Uncomment to list all secrets from Key Vault
# for secret_name in $(az keyvault secret list --vault-name $VAULT_NAME --query "[].name" -o tsv); do
#     secret_value=$(az keyvault secret show --vault-name $VAULT_NAME --name $secret_name --query value -o tsv)
#     echo "$secret_name=$secret_value"
# done
