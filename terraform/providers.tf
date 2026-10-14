provider "docker" {
  host = "ssh://${var.docker_ssh_user}@${var.server_ip}:22"
  ssh_opts = [
    "-o", "StrictHostKeyChecking=accept-new",
    "-o", "BatchMode=yes",
    # одно ssh соединение, на сервере ufw limit
    "-o", "ControlMaster=auto",
    "-o", "ControlPath=~/.ssh/cm-%r@%h-%p",
    "-o", "ControlPersist=60",
    "-i", pathexpand(var.ssh_private_key_path),
  ]
}
