provider "azurerm" {
  features {}
}

terraform {
  backend "s3" {
    bucket         = "my-bucket101110101"
    key            = "azure-aks-terraform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-aks"
    encrypt        = true
  }
}

resource "azurerm_kubernetes_cluster" "flask-project" {
  name                = "flask-project"       # Kubernetes cluster name
  location            = "East US"             # Your preferred Azure region
  resource_group_name = "rg-kubernetes"      
  dns_prefix         = "flask-project-dns"    # DNS prefix for the cluster
  automatic_upgrade_channel = "patch"
  azure_policy_enabled = false
  cost_analysis_enabled = false
  http_application_routing_enabled = false
  image_cleaner_enabled = true
  image_cleaner_interval_hours = 168
  local_account_disabled = false
  oidc_issuer_enabled = true
  open_service_mesh_enabled = false
  tags = {}
  auto_scaler_profile {
    balance_similar_node_groups = false
    daemonset_eviction_for_empty_nodes_enabled = false
    daemonset_eviction_for_occupied_nodes_enabled = true
    empty_bulk_delete_max = "10"
    expander                   = "random"
    max_graceful_termination_sec = 600
    max_node_provisioning_time = "15m"
    max_unready_nodes = 3
    max_unready_percentage = 45
    scale_down_delay_after_add = "10m"
    scale_down_delay_after_delete = "10s"
    scale_down_delay_after_failure = "3m"
    scale_down_unneeded = "10m"
    scale_down_unready = "10m"
    scale_down_utilization_threshold = "0.5"
    scan_interval = "10s"
    skip_nodes_with_local_storage = false
    skip_nodes_with_system_pods = true
  }

  default_node_pool {
    auto_scaling_enabled = true
    fips_enabled = false
    host_encryption_enabled = false
    kubelet_disk_type = "OS"
    max_count = 5
    max_pods = 110
    min_count = 2
    node_labels = {}
    node_public_ip_enabled = false
    only_critical_addons_enabled = false
    tags = {}
    zones = []
    name       = "agentpool"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
    os_disk_size_gb = 128
    os_sku = "Ubuntu"
    upgrade_settings {
      drain_timeout_in_minutes = 0
      max_surge = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  maintenance_window_auto_upgrade {
    day_of_month = 0
    day_of_week  = "Sunday"
    duration     = 4
    frequency    = "Weekly"
    interval     = 1
    start_date = "2025-01-26T00:00:00Z"
    start_time = "00:00"
    utc_offset = "+00:00"
  }

  maintenance_window_node_os {
    day_of_month = 0
    day_of_week  = "Sunday"
    duration     = 4
    frequency    = "Weekly"
    interval     = 1
    start_date = "2025-01-26T00:00:00Z"
    start_time = "00:00"
    utc_offset = "+00:00"
  }

}

  output "client_id" {
    value = azurerm_kubernetes_cluster.flask-project.identity[0].principal_id
  }
