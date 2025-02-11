  terraform {
    backend "s3" {
      bucket = "my-bucket101110101"  # Your existing S3 bucket for state and .env
      key    = "gcloud-terraform.tfstate/terraform.tfstate"  # Path for the Terraform state file
      region = "us-east-1"  # Your AWS region
      dynamodb_table = "terraform-gke"
      encrypt = true  # Enable encryption for the state file
    }
  }


  variable "GCP_PROJECT_ID" {
    default = "jovial-parsec-449808-s1"
  }

  variable "GCP_ZONE" { # a zone for zonal cluster used here.
    default = "us-central1-a"
  }

  variable "GCP_REGION" {
    default = "us-central1"

  }

  provider "google" {
      
    project = var.GCP_PROJECT_ID
    region  = var.GCP_REGION # default region for resources without specifying location.
  }


  # Create a GKE cluster, no need to specify initial node count, no need to specify project.
  resource "google_container_cluster" "primary" {
    name               = "ariel-flask-cluster"
    location           = var.GCP_ZONE
    initial_node_count = 1

    deletion_protection = false
    remove_default_node_pool = true

    network    = "default"
    subnetwork = "default"

    logging_service    = "logging.googleapis.com/kubernetes"
    monitoring_service = "monitoring.googleapis.com/kubernetes"

    addons_config {
      http_load_balancing {
        disabled = false
      }
    }
  }


  output "kubernetes_cluster_name" {
    value = google_container_cluster.primary.name
  }

  output "kubernetes_cluster_endpoint" {
    value = google_container_cluster.primary.endpoint
  }

  output "kubernetes_cluster_ca_certificate" {
    value = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  }

  # Create a node pool with auto-scaling enabled
  resource "google_container_node_pool" "primary_nodes" {
    name     = "ariel-node-pool"
    cluster  = google_container_cluster.primary.name
    location = var.GCP_ZONE
    node_count = 1

    autoscaling {
      min_node_count = 1
      max_node_count = 2
    }

    node_config {
      machine_type = "e2-medium"
      disk_size_gb = 15
      disk_type    = "pd-standard"
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]
    }

    management {
      auto_upgrade = true
      auto_repair  = true
    }
  } 