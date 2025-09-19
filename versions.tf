# Terraform and Provider Version Requirements

terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  # Optional: Configure remote state backend
  # Uncomment and configure for team collaboration
  # backend "gcs" {
  #   bucket  = "your-terraform-state-bucket"
  #   prefix  = "terraform/state"
  # }
}