variable "project_id" {
  description = "The ID of the Google Cloud project."
  type        = string
  default     = "ardent-case-465107-c9"
}

variable "region" {
  description = "The region to create resources in."
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "The name of the GKE cluster."
  type        = string
  default     = "mycluster1"
}
