# Project Configuration
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for VM instances"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# Network Configuration
variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.1.0/24"
  
  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "Subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "allowed_source_ranges" {
  description = "List of source IP ranges allowed to access the webserver"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# VM Configuration
variable "machine_type" {
  description = "The machine type for the VM instance"
  type        = string
  default     = "e2-micro"
  
  validation {
    condition = contains([
      "e2-micro", "e2-small", "e2-medium", "e2-standard-2", "e2-standard-4",
      "n1-standard-1", "n1-standard-2", "n1-standard-4",
      "n2-standard-2", "n2-standard-4"
    ], var.machine_type)
    error_message = "Machine type must be a valid GCP machine type."
  }
}

variable "vm_image" {
  description = "The VM image for the instance"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2004-lts"
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
  
  validation {
    condition     = var.disk_size >= 10 && var.disk_size <= 1000
    error_message = "Disk size must be between 10 and 1000 GB."
  }
}

# SSH Configuration
variable "ssh_user" {
  description = "SSH username for accessing the VM"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key for accessing the VM"
  type        = string
  default     = ""
  sensitive   = true
}

# Optional Features
variable "use_static_ip" {
  description = "Whether to use a static IP address"
  type        = bool
  default     = false
}

variable "enable_logging" {
  description = "Enable VPC flow logs and firewall logs"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable monitoring for the VM instance"
  type        = bool
  default     = true
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = list(string)
  default     = []
}