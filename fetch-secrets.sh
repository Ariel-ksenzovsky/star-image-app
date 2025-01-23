#!/bin/bash

# Fetch secret from AWS Secrets Manager
secret=$(aws secretsmanager get-secret-value --secret-id .env --region us-east-1 --query SecretString --output text)

# Export secrets as environment variables
export DB_HOST=$(echo $secret | jq -r .DB_HOST)
export DB_USER=$(echo $secret | jq -r .DB_USER)
export DB_PASSWORD=$(echo $secret | jq -r .DB_PASSWORD)
export DB_NAME=$(echo $secret | jq -r .DB_NAME)
export FLASK_PORT=$(echo $secret | jq -r .FLASK_PORT)

docker-compose up --build