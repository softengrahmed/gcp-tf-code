# Configure the Google Cloud Provider
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Create VPC Network
resource "google_compute_network" "webserver_vpc" {
  name                    = "${var.environment}-webserver-vpc"
  auto_create_subnetworks = false
  description             = "VPC network for webserver infrastructure"
}

# Create Subnet
resource "google_compute_subnetwork" "webserver_subnet" {
  name          = "${var.environment}-webserver-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.webserver_vpc.id
  description   = "Subnet for webserver instances"
  
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Create Firewall Rules for Inbound Traffic
resource "google_compute_firewall" "webserver_inbound" {
  name    = "${var.environment}-webserver-inbound"
  network = google_compute_network.webserver_vpc.name
  
  description = "Firewall rules for inbound webserver traffic"
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "22"]
  }
  
  allow {
    protocol = "icmp"
  }
  
  source_ranges = var.allowed_source_ranges
  target_tags   = ["webserver"]
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Create Firewall Rules for Outbound Traffic
resource "google_compute_firewall" "webserver_outbound" {
  name      = "${var.environment}-webserver-outbound"
  network   = google_compute_network.webserver_vpc.name
  direction = "EGRESS"
  
  description = "Firewall rules for outbound webserver traffic"
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "53"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["53"]
  }
  
  allow {
    protocol = "icmp"
  }
  
  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["webserver"]
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Create Service Account for VM
resource "google_service_account" "webserver_sa" {
  account_id   = "${var.environment}-webserver-sa"
  display_name = "Webserver Service Account"
  description  = "Service account for webserver VM instances"
}

# Create IAM binding for Service Account
resource "google_project_iam_member" "webserver_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.webserver_sa.email}"
}

resource "google_project_iam_member" "webserver_sa_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.webserver_sa.email}"
}

# Create VM Instance with Webserver
resource "google_compute_instance" "webserver" {
  name         = "${var.environment}-webserver-vm"
  machine_type = var.machine_type
  zone         = var.zone
  
  description = "Webserver VM instance"
  
  tags = ["webserver", var.environment]
  
  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = var.disk_size
      type  = "pd-standard"
    }
    auto_delete = true
  }
  
  network_interface {
    network    = google_compute_network.webserver_vpc.id
    subnetwork = google_compute_subnetwork.webserver_subnet.id
    
    access_config {
      // Ephemeral public IP
      network_tier = "PREMIUM"
    }
  }
  
  service_account {
    email  = google_service_account.webserver_sa.email
    scopes = ["cloud-platform"]
  }
  
  metadata = {
    ssh-keys = var.ssh_public_key != "" ? "${var.ssh_user}:${var.ssh_public_key}" : ""
  }
  
  metadata_startup_script = templatefile("${path.module}/startup-script.sh", {
    project_id = var.project_id
  })
  
  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }
  
  lifecycle {
    create_before_destroy = true
  }
  
  depends_on = [
    google_compute_firewall.webserver_inbound,
    google_compute_firewall.webserver_outbound
  ]
}

# Create Static IP (Optional)
resource "google_compute_address" "webserver_static_ip" {
  count        = var.use_static_ip ? 1 : 0
  name         = "${var.environment}-webserver-static-ip"
  region       = var.region
  address_type = "EXTERNAL"
  description  = "Static IP for webserver"
}

# Create Health Check
resource "google_compute_http_health_check" "webserver_health_check" {
  name                = "${var.environment}-webserver-health-check"
  description         = "Health check for webserver"
  port                = 80
  request_path        = "/health"
  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}