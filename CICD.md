# To use github actions for CI/CD make the following changes

Asssuming the repo you are going to setup CI/CD for is in the below structure

```
.
├── CICD.md
├── LGTM
│   ├── grafana
│   │   └── defaults.ini
│   ├── loki
│   │   └── loki-config.yml
│   ├── prometheus
│   │   └── prometheus.yml
│   └── tempo
│       └── tempo.yml
├── Makefile
├── OTEL
│   └── otel-collector-config.yaml
├── README.md
├── bot_service
│   ├── dockerfiles
│   │   ├── api.Dockerfile
│   │   └── ui.Dockerfile
│   └── src
│       ├── backend
│       │   ├── LLM
│       │   │   ├── __init__.py
│       │   │   ├── __pycache__
│       │   │   └── manager.py
│       │   ├── __pycache__
│       │   ├── alembic
│       │   │   ├── README
│       │   │   ├── __init__.py
│       │   │   ├── __pycache__
│       │   │   ├── env.py
│       │   │   ├── script.py.mako
│       │   │   └── versions
│       │   │       ├── 2025_01_11_2002-239b3b78d573_initialize_db_models.py
│       │   │       ├── 2025_01_11_2002-635d9283a785_initialize_db_models.py
│       │   │       └── __pycache__
│       │   ├── alembic.ini
│       │   ├── auth
│       │   │   ├── __init__.py
│       │   │   ├── __pycache__
│       │   │   └── manager.py
│       │   ├── common
│       │   │   ├── __init__.py
│       │   │   ├── __pycache__
│       │   │   ├── configuration.py
│       │   │   ├── controller.py
│       │   │   ├── data_model.py
│       │   │   ├── logger.py
│       │   │   └── utils.py
│       │   ├── config_ini_sample
│       │   ├── database
│       │   │   ├── __init__.py
│       │   │   ├── __pycache__
│       │   │   └── manager.py
│       │   ├── env_sample
│       │   ├── etc
│       │   │   └── config.ini
│       │   ├── exceptions
│       │   │   ├── __init__.py
│       │   │   ├── __pycache__
│       │   │   ├── config.py
│       │   │   ├── db.py
│       │   │   ├── pb.py
│       │   │   └── user.py
│       │   ├── health
│       │   │   ├── __init__.py
│       │   │   ├── __pycache__
│       │   │   ├── controller.py
│       │   │   ├── manager.py
│       │   │   └── models.py
│       │   ├── main.py
│       │   ├── metrics
│       │   │   ├── __init__.py
│       │   │   ├── __pycache__
│       │   │   ├── controller.py
│       │   │   ├── manager.py
│       │   │   └── models
│       │   │       ├── __init__.py
│       │   │       ├── __pycache__
│       │   │       ├── interfaces
│       │   │       │   ├── __init__.py
│       │   │       │   └── metics.py
│       │   │       ├── request
│       │   │       │   ├── __init__.py
│       │   │       │   └── metrics.py
│       │   │       └── responses
│       │   │           ├── __init__.py
│       │   │           ├── __pycache__
│       │   │           └── metrics.py
│       │   ├── monitoring
│       │   │   ├── __init__.py
│       │   │   ├── __pycache__
│       │   │   └── prometheus.py
│       │   ├── requirements.in
│       │   ├── requirements.txt
│       │   ├── store
│       │   │   ├── __init__.py
│       │   │   ├── __pycache__
│       │   │   └── prompt.py
│       │   ├── tests
│       │   │   ├── __init__.py
│       │   │   ├── __pycache__
│       │   │   └── unit_tests
│       │   │       ├── __init__.py
│       │   │       ├── __pycache__
│       │   │       ├── conf.py
│       │   │       └── test_health.py
│       │   └── user
│       │       ├── __init__.py
│       │       ├── __pycache__
│       │       ├── controller.py
│       │       ├── db_models.py
│       │       ├── manager.py
│       │       └── models
│       │           ├── __init__.py
│       │           ├── __pycache__
│       │           ├── interface.py
│       │           ├── request.py
│       │           └── response.py
│       ├── frontend
│       │   ├── craco.config.js
│       │   ├── etc
│       │   │   └── sample.md
│       │   ├── package.json
│       │   ├── public
│       │   │   └── index.html
│       │   └── src
│       │       └── index.js
│       └── logs
├── deploy.sh
├── docker-compose-main.yml
├── docker-compose-prod.yml
├── docker-compose-services.yml
├── docs
│   ├── 1.Setting up CICD.md
│   ├── 2.Alembic.md
│   ├── 3.Observability.md
│   ├── 4.OpenTelemetery.md
│   ├── 5.Kubernetes.md
│   ├── grafana_dashb.png
│   ├── index.md
│   ├── k8.png
│   ├── obs.png
│   └── otel.png
├── experiments
│   └── experiments.ipynb
├── infra
│   ├── Makefile
│   └── helm
│       ├── bot_service
│       │   ├── Chart.yaml
│       │   └── templates
│       │       ├── config_map.yaml
│       │       ├── hpa.yaml
│       │       ├── service_deployment.yaml
│       │       ├── service_ingress.yaml
│       │       └── service_service.yaml
│       ├── langfuse-k8s
│       │   ├── Chart.lock
│       │   ├── Chart.yaml
│       │   ├── README.md
│       │   ├── charts
│       │   │   └── postgresql-15.5.38.tgz
│       │   └── templates
│       │       ├── _helpers.tpl
│       │       ├── deployment.yaml
│       │       ├── extra-manifests.yaml
│       │       ├── hpa.yaml
│       │       ├── ingress.yaml
│       │       ├── nextauth-secret.yaml
│       │       ├── postgresql-secret.yaml
│       │       ├── service.yaml
│       │       └── serviceaccount.yaml
│       ├── pushgateway
│       │   ├── Chart.yaml
│       │   └── templates
│       │       ├── pvc.yaml
│       │       ├── service_deployment.yaml
│       │       ├── service_ingress.yaml
│       │       └── service_service.yaml
│       └── tesseract
│           ├── Chart.yaml
│           └── templates
│               ├── hpa.yaml
│               ├── service_deployment.yaml
│               ├── service_ingress.yaml
│               └── service_service.yaml
├── mkdocs.yml
└── setup.sh
```

- Login into the VM
- Run the setup [script](setup.sh) as sudo/superuser to create deployment group, user, authorized_keys for ssh & git config for git
- The repo needs to be cloned using [deploy keys](https://newtuple.atlassian.net/wiki/spaces/DAKB/pages/196847/Everything+about+SSH#How-to-setup-a-Production-server-with-repo-access-to-GitHub%3A) as DEV/PROD intially on the vm with all `.env` files being created in the respective backend at `/fantastic-fiesta/bot_service/src/backend/etc/.env` and frontend `/fantastic-fiesta/bot_service/src/frontend/etc/.env`
- Use the new user details to populate the details where ever required

### Add the following github action secrets for if setting up dev environment
>- HOST_DEV
>- USERNAME_DEV
>- SSH_KEY_DEV
>- REPO_PATH_DEV
>- DEV_BRANCH

### Add the following github action secrets for if setting up prod environment
>- HOST_PROD
>- USERNAME_PROD
>- SSH_KEY_PROD
>- REPO_PATH_PROD
>- PROD_BRANCH


where *Host* is the IP address of the vm, *username* is the user which can ssh into the vm in this case the deployment user which got created, *ssh_key* is private ssh key for same user and repo_path is the full path to the repo on the vm


## Some things to be taken care of
>- A `.env` with contents from [sample](.env_sample) at root level is required for the commom services
>- The **main** branch is development env, the **prod** branch is for production env, any code that is pushed/merged into branches triggers respective env deployment however this behavour is configurable
>- Make sure that ports in health check job for github actions are updated to get accurate health status upon deployment
>- Update the docker & docker compose file as per needed in main & prod versions, and add/remove any common service in `docker-compose-services.yml`,
>- Any files which need not be version controlled should be added `.gitignore` like .env, credentials etc
