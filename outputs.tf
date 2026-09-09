output "container_id" {
  description = "ID of the managed container"
  value       = docker_container.web.id
}

output "container_ip" {
  description = "Internal bridge network IP address of the container"
  value       = docker_container.web.network_data[0].ip_address
}

output "external_port" {
  description = "Host port used to reach the container"
  value       = var.external_port
}