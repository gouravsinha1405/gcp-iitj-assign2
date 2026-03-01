locals {
  common_labels = {
    project = "vcc-assignment"
  }
}

resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "iam" {
  project = var.project_id
  service = "iam.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"

  disable_on_destroy = false
}

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false

  depends_on = [google_project_service.compute]
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id

  depends_on = [google_project_service.compute]
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc.name

  depends_on = [google_project_service.compute]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

resource "google_compute_firewall" "allow_ssh_restricted" {
  name    = "allow-ssh-restricted"
  network = google_compute_network.vpc.name

  depends_on = [google_project_service.compute]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_ssh_cidr]
  target_tags   = ["web"]
}

resource "google_service_account" "vm_sa" {
  account_id   = "vcc-mig-vm"
  display_name = "VCC MIG VM service account"

  depends_on = [google_project_service.iam]
}

resource "google_project_iam_member" "admin_instance_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "user:${var.admin_user_email}"

  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_project_iam_member" "admin_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "user:${var.admin_user_email}"

  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_compute_instance_template" "tpl" {
  name_prefix  = "${var.instance_template_name}-"
  machine_type = var.machine_type
  tags         = ["web"]
  labels       = local.common_labels

  depends_on = [google_project_service.compute]

  disk {
    source_image = "projects/debian-cloud/global/images/family/debian-12"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      # ephemeral public IP for demo
    }
  }

  metadata_startup_script = file("${path.module}/startup/startup.sh")

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_health_check" "http" {
  name = "vcc-http-hc"

  depends_on = [google_project_service.compute]

  http_health_check {
    port = 80
  }
}

resource "google_compute_instance_group_manager" "mig" {
  name               = var.mig_name
  base_instance_name = "vcc-mig"
  zone               = var.zone

  depends_on = [google_project_service.compute]

  version {
    instance_template = google_compute_instance_template.tpl.id
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.http.id
    initial_delay_sec = 60
  }

  target_size = var.min_replicas
}

resource "google_compute_autoscaler" "cpu" {
  name   = "vcc-mig-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.mig.id

  depends_on = [google_project_service.compute]

  autoscaling_policy {
    min_replicas    = var.min_replicas
    max_replicas    = var.max_replicas
    cooldown_period = 60

    cpu_utilization {
      target = var.cpu_target
    }
  }
}
