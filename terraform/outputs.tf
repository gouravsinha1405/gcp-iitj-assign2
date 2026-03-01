output "mig_self_link" {
  value = google_compute_instance_group_manager.mig.self_link
}

output "instance_template" {
  value = google_compute_instance_template.tpl.self_link
}

output "network" {
  value = google_compute_network.vpc.self_link
}
