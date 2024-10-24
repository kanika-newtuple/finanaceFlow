# To use github actions for CI/CD make the following changes


### Add the following github action secrets for if setting up dev environment
>- HOST_DEV
>- USERNAME_DEV
>- SSH_KEY_DEV
>- REPO_PATH_DEV

### Add the following github action secrets for if setting up prod environment
>- HOST_PROD
>- USERNAME_PROD
>- SSH_KEY_PROD
>- REPO_PATH_PROD


where *Host* is the IP address of the vm, *username* is the user which can ssh into the vm, *ssh_key* is private ssh key for same user and repo_path is the full path to the repo on the vm

- Run the setup [script](setup.sh), to create deployment group, user, authorized_keys & git config

- The repo needs to be cloned using [deploy keys](https://newtuple.atlassian.net/wiki/spaces/DAKB/pages/196847/Everything+about+SSH#How-to-setup-a-Production-server-with-repo-access-to-GitHub%3A) intially on the vm with all `.env` files being created in the respective backend at `/fantastic-fiesta/bot_service/src/backend/etc/.env` and frontend `/fantastic-fiesta/bot_service/src/frontend/etc/.env`

## Some things to be taken care of
>- A `.env` with contents from [sample](.env_sample) at root level is required for the commom services
>- The **main** branch is development env, the **prod** branch is for production env, any code that is pushed/merged into branches triggers respective env deployment however this behavour is configurable
>- Make sure that ports in health check job for github actions are updated to get accurate health status upon deployment
>- Update the docker & docker compose file as per needed in main & prod versions, and add any common service in `docker-compose-services.yml`, 
>- Any files which need not be version controlled should be added `.gitignore` like .env, credentials etc