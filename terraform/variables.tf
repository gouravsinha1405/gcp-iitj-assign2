variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "asia-south1-a"
}

variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "vcc-assignment-net"
}

variable "subnet_name" {
  description = "Subnetwork name"
  type        = string
  default     = "vcc-assignment-subnet"
}

variable "mig_name" {
  description = "Managed instance group name"
  type        = string
  default     = "vcc-assignment-mig"
}

variable "instance_template_name" {
  description = "Instance template name"
  type        = string
  default     = "vcc-assignment-template"
}

variable "machine_type" {
  description = "Machine type"
  type        = string
  default     = "e2-medium"
}

variable "min_replicas" {
  description = "Autoscaler minimum instances"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Autoscaler maximum instances"
  type        = number
  default     = 3
}

variable "cpu_target" {
  description = "Target CPU utilization (0.0 - 1.0)"
  type        = number
  default     = 0.6
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into instances (use your public IP/32)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "admin_user_email" {
  description = "User who can administer instances (least-privilege IAM example)"
  type        = string
}
