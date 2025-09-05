output "wordpress_vm_ip" {
  description = "Public IP address of the WordPress VM"
  value       = google_compute_instance.wordpress_vm.network_interface[0].access_config[0].nat_ip
}
