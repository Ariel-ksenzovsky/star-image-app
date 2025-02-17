# Star Image App

## Python Application

The **Star Image App** is a Flask-based web application that displays a random image from a database and tracks visitor counts. It serves Prometheus-compatible metrics and is deployed in a Kubernetes environment. The application is built and deployed using a GitHub Actions workflow, automating the CI/CD process.

## Workflow Overview
![my_project_Diagram](https://github.com/user-attachments/assets/faad518d-d50d-4b69-9647-0dbd0caee94b)

## Workflow Setup

Ensure you have these credentials saved as **secrets** in your repository settings:
- **AWS_ACCESS_KEY_ID**: AWS access key for authentication.
- **AWS_SECRET_ACCESS_KEY**: AWS secret key for authentication.
- **DB_PASSWORD**: Password for the MySQL database.
- **DOCKER_PASSWORD**: Docker Hub password for pushing images.
- **DOCKER_USERNAME**: Docker Hub username.
- **GCP_PROJECT**: Google Cloud project ID.
- **GCP_SA_KEY**: Google Cloud service account key JSON.
- **MYSQL_ROOT_PASSWORD**: Root password for MySQL.

Ensure you have these credentials saved as **variables** in your repository settings:
- **DB_HOST**: Hostname of the MySQL database.
- **DB_NAME**: Name of the MySQL database.
- **DB_USER**: Username for the MySQL database.
- **FLASK_PORT**: Port on which the Flask application runs.

## Docker

The application is containerized using Docker to ensure consistency across different environments.

### Dockerfile
The `Dockerfile` defines the build process for the application, setting up the necessary Python environment and dependencies, and running the application inside a container.

### Docker Compose (Local Testing)
For local testing, `docker-compose.yml` is used to set up the application along with a MySQL database. This allows developers to run the entire stack locally before deploying it to production.

## Terraform (Infrastructure as Code)

Terraform is used to provision the necessary cloud infrastructure components. This includes:
- **Google Kubernetes Engine (GKE)**: Deploys a Kubernetes cluster.
- **AWS S3 Bucket**: Stores Helm charts.
- **DynamoDB Table**: Manages Terraform state locking.

### GKE Cluster Creation
The Terraform configuration provisions a Kubernetes cluster on Google Cloud Platform, ensuring a scalable and managed environment for the application.

### Backend Configuration in S3
Terraform state files are stored in an AWS S3 bucket to enable remote state management. This setup ensures that multiple developers can work on infrastructure changes without conflicts.

### DynamoDB Lock for State Management
A DynamoDB table is used for state locking to prevent concurrent Terraform executions, maintaining the integrity of infrastructure updates.

## Kubernetes & Helm

Helm is used to deploy the application to the Kubernetes cluster, automating resource creation and management.

### Helm Chart Configuration
The Helm chart includes configurations for the application deployment, service, and optional ingress setup. This allows for a structured and repeatable deployment process.

### Helm Package & S3 Storage
Helm charts are packaged and stored in an S3 bucket, enabling version-controlled deployments. The packaged charts can then be installed from the S3 storage into the Kubernetes cluster.

## Cleanup Workflow

A scheduled GitHub Actions workflow removes:
- **Docker images older than one month** from Docker Hub.
- **Helm charts older than one month** from the GCP bucket.

This ensures that outdated resources are cleaned up automatically, optimizing storage usage and maintaining an efficient deployment pipeline.

---

This setup ensures a streamlined deployment and management process for the Star Image App.

