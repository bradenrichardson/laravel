# laravel


## Provision Remote State

1. cd remote-state
2. terraform init
3. terraform apply

## Configure Github Actions

1. Create a new repository secret with the name `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`


## Deploy Infra

1. cd infra
2. terraform init
3. terraform apply

Or

1. Push to the `main` branch with changes to /infra

## Deploy App Locally

1. cd app
2. docker-compose up --build

## Deploy App to ECS

1. Push to the `main` branch with changes to /app

