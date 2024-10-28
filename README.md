# laravel


## Provision Remote State
An S3 bucket and DynamoDB table are used to store the remote state of the terraform code. I've provisioned this locally and stored the state in the `remote-state` folder. There are no expected changes to the remote state infra which is why it is not included in infra automation. 


1. cd remote-state
2. terraform init
3. terraform apply


## Configure Github Actions
1. Create a new repository secret with the name `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`


## Deploy Infra
Infrastructure is provisioned using terraform. The code is located in the `infra` folder. To provision the infra, run the following commands or the deploy-infra.yaml workflow will be triggered on push to the `main` branch.

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


## DNS
For the domain resolution to work, you will need to :
1. Create a public hosted zone in Route53 for `margaretriver.rentals`
2. Create a certificate in ACM for `margaretriver.rentals`
3. Verify the ownership of the domain in ACM



