output "web_url" {
  value = "http://${var.server_ip}:${var.web_port}"
}

output "curl_command" {
  value = "curl -i http://${var.server_ip}:${var.web_port}"
}

output "network" {
  value = docker_network.web.name
}

output "volume" {
  value = docker_volume.html.name
}

output "container" {
  value = docker_container.nginx.name
}

output "operator_user" {
  value = module.iam.operator_user
}
