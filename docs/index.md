# Getting Started

## Project layout

    mkdocs.yml    # The configuration file.
    docs/
        index.md  # The documentation homepage.
        1.Setting up CICD.md # Setup CI/CD for the application on a VM
        2.Alembic.md # Use data migration for the schema changes
        3.Observability.md # Instrument your applicaton to collect obs data
        4.OpenTelemetery.md # Standard for collection obs data
        5.Kubernetes.md # Deploy your application to K8
        6.Setting up Nginx.md # Setup reverse proxy using nginx
        7.Setting up Reverse proxy using Treafik.md # Setup reverse proxy using treafik
        8.IAC.md # Provision & manage using infrastuction as a code using opentofu
        
        ...       # Other markdown pages, images and other files.

## About

## How to read the documentation?

Here's how to navigate through this documentation:

1. Start with understanding how to set up CI/CD for the application by reviewing [Setting up CICD](./1.Setting%20up%20CICD.md).
2. Learn about database schema management and migrations through [Alembic](./2.Alembic.md).
3. Understand how to implement application monitoring by following [Observability](./3.Observability.md).
4. Explore the standardized approach to collecting observability data using [OpenTelemetry](./4.OpenTelemetery.md).
5. Deploy your application to Kubernetes by following [Kubernetes](./5.Kubernetes.md).
6. Setup reverse proxy using nginx for your application by following [Reverse proxy using Nginx](./6.Setting%20up%20Reverse%20proxy%20using%20Nginx%20copy.md).
7. Setup reverse proxy using traefik for your application by following [Reverse proxy using Traefik](./7.Setting%20up%20Reverse%20proxy%20using%20Traefik.md).
8. Provision & manage using infrastuction as a code using opentofu [IAC](./8.Infrastructure%20as%20Code.md).
9. Additional documentation files are available for more specific topics and features.

## Commands to load the documentation locally

- Below are the commands that can be used to load the documentation on your machine locally.

* `mkdocs serve -a localhost:8001` - Start the live-reloading docs server.
* `mkdocs build` - Build the documentation site.
* `mkdocs -h` - Print help message and exit.
* `mkdocs gh-deploy --force` - Deploy docs to Github pages
