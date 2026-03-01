# GCP VM Auto-Scaling + Security (MIG)

Terraform code and documentation for a Google Cloud deployment using:
- Instance Template
- Managed Instance Group (MIG)
- Autoscaler (CPU utilization)
- Firewall rules (HTTP allow, SSH restricted)
- IAM bindings for restricted access

## Repository contents
- [terraform/main.tf](terraform/main.tf)
- [terraform/variables.tf](terraform/variables.tf)
- [terraform/versions.tf](terraform/versions.tf)
- [terraform/outputs.tf](terraform/outputs.tf)
- [terraform/startup/startup.sh](terraform/startup/startup.sh)
