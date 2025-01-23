#!/bin/bash

# Fetch secret from AWS Secrets Manager
secret=$(aws secretsmanager get-secret-value --secret-id my-env-secrets --region us-east-1 --query SecretString --output text)

# Export database-related secrets as environment variables
export DB_HOST=$(echo $secret | jq -r .DB_HOST)
export DB_USER=$(echo $secret | jq -r .DB_USER)
export DB_PASSWORD=$(echo $secret | jq -r .DB_PASSWORD)
export DB_NAME=$(echo $secret | jq -r .DB_NAME)
export FLASK_PORT=$(echo $secret | jq -r .FLASK_PORT)

# Fetch AWS credentials from AWS Secrets Manager
aws_secrets=$(aws secretsmanager get-secret-value --secret-id my-env-secrets --region us-east-1 --query SecretString --output text)

# Export AWS credentials as environment variables
export AWS_ACCESS_KEY_ID=$(echo $aws_secrets | jq -r .AWS_ACCESS_KEY_ID)
export AWS_SECRET_ACCESS_KEY=$(echo $aws_secrets | jq -r .AWS_SECRET_ACCESS_KEY)
export AWS_REGION=$(echo $aws_secrets | jq -r .AWS_REGION)

# Run Docker Compose
docker-compose up --build
