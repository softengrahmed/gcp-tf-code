# VM Instance Outputs
output "vm_instance_name" {
  description = "Name of the VM instance"
  value       = google_compute_instance.webserver.name
}

output "vm_instance_id" {
  description = "ID of the VM instance"
  value       = google_compute_instance.webserver.id
}

output "vm_self_link" {
  description = "Self link of the VM instance"
  value       = google_compute_instance.webserver.self_link
}

output "vm_zone" {
  description = "Zone where the VM instance is located"
  value       = google_compute_instance.webserver.zone
}

# Network Outputs
output "external_ip" {
  description = "External IP address of the VM instance"
  value       = google_compute_instance.webserver.network_interface[0].access_config[0].nat_ip
}

output "internal_ip" {
  description = "Internal IP address of the VM instance"
  value       = google_compute_instance.webserver.network_interface[0].network_ip
}

output "static_ip" {
  description = "Static IP address (if enabled)"
  value       = var.use_static_ip ? google_compute_address.webserver_static_ip[0].address : null
}

# Network Infrastructure Outputs
output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.webserver_vpc.name
}

output "vpc_network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.webserver_vpc.id
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.webserver_subnet.name
}

output "subnet_cidr" {
  description = "CIDR range of the subnet"
  value       = google_compute_subnetwork.webserver_subnet.ip_cidr_range
}

# Firewall Outputs
output "inbound_firewall_rule" {
  description = "Name of the inbound firewall rule"
  value       = google_compute_firewall.webserver_inbound.name
}

output "outbound_firewall_rule" {
  description = "Name of the outbound firewall rule"
  value       = google_compute_firewall.webserver_outbound.name
}

# Service Account Outputs
output "service_account_email" {
  description = "Email of the service account"
  value       = google_service_account.webserver_sa.email
}

output "service_account_id" {
  description = "ID of the service account"
  value       = google_service_account.webserver_sa.id
}

# Connection Information
output "ssh_connection_command" {
  description = "SSH command to connect to the VM"
  value       = "gcloud compute ssh ${google_compute_instance.webserver.name} --zone=${google_compute_instance.webserver.zone} --project=${var.project_id}"
}

output "web_url" {
  description = "URL to access the web server"
  value       = "http://${google_compute_instance.webserver.network_interface[0].access_config[0].nat_ip}"
}

output "https_url" {
  description = "HTTPS URL to access the web server"
  value       = "https://${google_compute_instance.webserver.network_interface[0].access_config[0].nat_ip}"
}

# Health Check Output
output "health_check_name" {
  description = "Name of the health check"
  value       = google_compute_http_health_check.webserver_health_check.name
}

# Resource Summary
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    project_id      = var.project_id
    environment     = var.environment
    region          = var.region
    zone            = var.zone
    vm_name         = google_compute_instance.webserver.name
    machine_type    = var.machine_type
    vpc_name        = google_compute_network.webserver_vpc.name
    subnet_name     = google_compute_subnetwork.webserver_subnet.name
    external_ip     = google_compute_instance.webserver.network_interface[0].access_config[0].nat_ip
    internal_ip     = google_compute_instance.webserver.network_interface[0].network_ip
  }
}