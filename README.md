# Template Repo

Use the Quickstart to start backend & frontend

> - Create a virtual environment using conda or venv or pipenv, for venv use `python3 -m venv myenv`
> - Activate the virtual environment using `source path/to/venv/myenv/bin/activate` for Linux/macOS & `path\to\venv\Scripts\activate` for Windows

> - Navigate to `./bot_service` Install all the dependencies using `pip3 install -r requirements.txt -U`
> - Add new dependencies in `./bot_service/src/backend/requirements.txt` &  update dependencies by navigating to `./bot_service/src/backend` & using `uv pip compile requirements.txt -o requirements.in`
> - Navigate to `./bot_service/src/backend` & use `./runner_api -e "./path/to/.env/file"` or `python3 runner_api.py -e  "./path/to/.env/file"`


> - To start the frontend, navigate to `./bot_service/src/frontend` & use `npm install` to install dependencies & `npm start` to start application

> - To bring the dev system up using docker use `docker compose -f docker-compose-main.yml up -d --build` & bring it down use `docker compose -f docker-compose-main.yml down`

NOTE : Running `docker buildx prune -a` & `docker builder prune -a` allows your system to be cleaned time to time

Reading the docs locally:
> - Use `pip3 install mkdocs-material` to install mkdocs
> - Use `python3 -m mkdocs serve -a localhost:8001` to start serving documentation locally
> - Use `mkdocs gh-deploy --force` to deploy the docs to GitHub pages

Running code quality tools:
> - Use `pip3 install pre-commit-hooks` to install pre-commit hooks & navigate to `./bot_service/`
> - Use `pre-commit install` & go ahead with regular git workflow upon which these rules will now be run automatically whenever code is committed


Running data migration using alembic:
> - Keep db migration update to date, navigate to `./bot_service/src/backend` and `alembic revision --autogenerate  -m "Done some foo bar changes in db"`
> - Use `alembic upgrade head` before conscutive application start to keep db schema updated
> - Make sure that every model's base is referenced in `./bot_service/src/backend/alembic/env.py` file for alembic to detect changes for.
