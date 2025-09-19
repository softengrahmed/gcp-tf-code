# GCP Webserver with Terraform

This Terraform configuration deploys a secure webserver on Google Cloud Platform (GCP) with proper networking, firewall rules, and monitoring.

## 🏗️ Architecture

The infrastructure includes:

- **Compute Instance**: VM running Ubuntu with Nginx webserver
- **VPC Network**: Custom VPC with dedicated subnet
- **Firewall Rules**: Inbound and outbound security rules
- **Service Account**: Dedicated service account with minimal permissions
- **Health Checks**: HTTP health check endpoint
- **Monitoring**: Google Cloud Ops Agent for logs and metrics
- **Optional Static IP**: Can be enabled for production use

## 📋 Prerequisites

1. **Google Cloud Platform Account**
   - Active GCP project with billing enabled
   - Necessary APIs enabled (see below)

2. **Terraform Installation**
   ```bash
   # Install Terraform (version >= 1.0)
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

3. **Google Cloud SDK**
   ```bash
   # Install gcloud CLI
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL
   gcloud init
   ```

4. **Authentication**
   ```bash
   # Authenticate with GCP
   gcloud auth login
   gcloud auth application-default login
   ```

## 🔧 Required GCP APIs

Enable the following APIs in your GCP project:

```bash
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable monitoring.googleapis.com
```

## 🚀 Quick Start

1. **Clone and Navigate**
   ```bash
   git clone https://github.com/softengrahmed/gcp-tf-code.git
   cd gcp-tf-code
   git checkout feature/gcp-webserver-vm
   ```

2. **Configure Variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
   
   Edit `terraform.tfvars` with your project details:
   ```hcl
   project_id = "your-gcp-project-id"
   region     = "us-central1"
   zone       = "us-central1-a"
   environment = "dev"
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Plan the Deployment**
   ```bash
   terraform plan
   ```

5. **Deploy the Infrastructure**
   ```bash
   terraform apply
   ```

6. **Access Your Webserver**
   - The external IP will be displayed in the output
   - Visit `http://EXTERNAL_IP` to see your webserver
   - Health check: `http://EXTERNAL_IP/health`

## 📁 File Structure

```
.
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                # Output values
├── startup-script.sh          # VM initialization script
├── terraform.tfvars.example   # Example variables file
└── README.md                 # This documentation
```

## ⚙️ Configuration Options

### VM Configuration
- **Machine Type**: From `e2-micro` (free tier) to larger instances
- **Disk Size**: 20GB default, adjustable up to 1000GB
- **Image**: Ubuntu 20.04 LTS (customizable)

### Network Security
- **Firewall Rules**: HTTP (80), HTTPS (443), SSH (22), ICMP
- **Source Ranges**: Configurable IP allowlists
- **VPC**: Dedicated VPC with custom subnet

### Optional Features
- **Static IP**: Enable for production environments
- **Monitoring**: Google Cloud Ops Agent integration
- **Logging**: VPC flow logs and firewall logs

## 🔐 Security Features

- **Minimal IAM Permissions**: Service account with only required roles
- **Firewall Protection**: Configured inbound/outbound rules
- **Security Headers**: Nginx configured with security headers
- **Automatic Updates**: Unattended security updates enabled
- **Local Firewall**: UFW configured for additional protection

## 📊 Monitoring & Logging

The deployment includes:

- **Google Cloud Ops Agent**: System and application metrics
- **Custom Health Checks**: HTTP endpoint monitoring
- **Log Aggregation**: Centralized logging to Cloud Logging
- **Monitoring Script**: Automated health monitoring

## 🛠️ Management Commands

### SSH Access
```bash
# SSH to the instance
gcloud compute ssh INSTANCE_NAME --zone=ZONE --project=PROJECT_ID

# Or use the command from terraform output
terraform output ssh_connection_command
```

### View Logs
```bash
# View startup script logs
gcloud compute ssh INSTANCE_NAME --zone=ZONE --command="sudo tail -f /var/log/startup-script.log"

# View nginx logs
gcloud compute ssh INSTANCE_NAME --zone=ZONE --command="sudo tail -f /var/log/nginx/access.log"
```

### Update Infrastructure
```bash
# Make changes to terraform files, then:
terraform plan
terraform apply
```

### Destroy Infrastructure
```bash
terraform destroy
```

## 🌍 Multi-Environment Setup

### Development
```hcl
environment = "dev"
machine_type = "e2-micro"
use_static_ip = false
allowed_source_ranges = ["0.0.0.0/0"]
```

### Staging
```hcl
environment = "staging"
machine_type = "e2-small"
use_static_ip = true
allowed_source_ranges = ["10.0.0.0/8"]
```

### Production
```hcl
environment = "prod"
machine_type = "e2-standard-2"
use_static_ip = true
allowed_source_ranges = ["203.0.113.0/24"]  # Your office IP range
```

## 🚨 Troubleshooting

### Common Issues

1. **API Not Enabled**
   ```bash
   gcloud services enable compute.googleapis.com
   ```

2. **Insufficient Permissions**
   ```bash
   gcloud auth application-default login
   ```

3. **Quota Exceeded**
   - Check your GCP quotas in the console
   - Consider using smaller machine types

4. **SSH Connection Issues**
   ```bash
   # Add your SSH key to the instance
   gcloud compute ssh INSTANCE_NAME --zone=ZONE --ssh-key-file=~/.ssh/id_rsa
   ```

### Debugging

1. **Check startup script logs**:
   ```bash
   gcloud compute ssh INSTANCE_NAME --zone=ZONE --command="sudo cat /var/log/startup-script.log"
   ```

2. **Verify services are running**:
   ```bash
   gcloud compute ssh INSTANCE_NAME --zone=ZONE --command="sudo systemctl status nginx"
   ```

3. **Check firewall rules**:
   ```bash
   gcloud compute firewall-rules list
   ```

## 💰 Cost Optimization

- **Use `e2-micro`** for development (eligible for free tier)
- **Enable preemptible instances** for non-production workloads
- **Schedule instances** to shut down during off-hours
- **Use appropriate disk sizes** (don't over-provision)

## 🔄 Updates and Maintenance

### Regular Maintenance
```bash
# Connect to instance and update packages
gcloud compute ssh INSTANCE_NAME --zone=ZONE
sudo apt update && sudo apt upgrade -y
```

### Terraform State Management
```bash
# View current state
terraform show

# Import existing resources
terraform import google_compute_instance.webserver projects/PROJECT_ID/zones/ZONE/instances/INSTANCE_NAME
```

## 📞 Support

If you encounter issues:

1. Check the [GCP Documentation](https://cloud.google.com/docs)
2. Review [Terraform GCP Provider docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
3. Check startup script logs for deployment issues
4. Verify GCP quotas and billing

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

**Note**: Remember to destroy resources when not needed to avoid unnecessary charges:
```bash
terraform destroy
```