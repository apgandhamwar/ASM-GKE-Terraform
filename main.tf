# Configure the Google Cloud provider
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.0.0"
    }
  }
}

# Use the Google provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Use the Google Beta provider, which is required for the `google_gke_hub_feature_membership` resource
provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Get the project details
data "google_project" "project" {
  project_id = var.project_id
}

# Enable required Google Cloud APIs for the project
resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com",
    "gkehub.googleapis.com",
    "mesh.googleapis.com",
  ])
  project = var.project_id
  service = each.key
  disable_dependent_services = true
}

# Create a GKE cluster and register it to a Fleet
resource "google_container_cluster" "asm_cluster" {
  name     = var.cluster_name
  location = var.region
  depends_on = [google_project_service.apis]

  # Enable features required by Anthos Service Mesh
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # Register the cluster to the project's Fleet
  fleet {
    project = data.google_project.project.name
  }
}
