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
resource "google_container_cluster" "mycluster1" {
  name     = var.cluster_name
  location = var.region
  initial_node_count = 1
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

# Enable the 'servicemesh' feature on the fleet
resource "google_gke_hub_feature" "servicemesh" {
  provider = google-beta
  name     = "servicemesh"
  location = "global"
  depends_on = [google_project_service.apis]
}

# Configure automatic management of the service mesh on the cluster
resource "google_gke_hub_feature_membership" "servicemesh_member" {
  provider = google-beta
  location = "global"
  feature  = google_gke_hub_feature.servicemesh.name
  membership = google_container_cluster.mycluster1.fleet[0].membership
  mesh {
    management = "MANAGEMENT_AUTOMATIC"
  }
}
