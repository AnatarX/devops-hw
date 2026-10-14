locals {
  sudoers = <<-EOT
    ${var.operator_user} ALL=(root) NOPASSWD: /usr/bin/systemctl status docker, /usr/bin/systemctl start docker, /usr/bin/systemctl stop docker, /usr/bin/systemctl restart docker, /usr/bin/journalctl -u docker *, /usr/bin/docker ps, /usr/bin/docker compose -f /opt/app/docker-compose.yml ps, /usr/bin/docker compose -f /opt/app/docker-compose.yml restart
  EOT
}

resource "null_resource" "operator" {
  triggers = {
    host    = var.host
    user    = var.operator_user
    sudoers = sha256(local.sudoers)
    ssh_key = sha256(var.ssh_public_key)
  }

  connection {
    type        = "ssh"
    host        = var.host
    user        = var.bootstrap_user
    private_key = file(pathexpand(var.ssh_private_key_path))
  }

  provisioner "file" {
    content     = local.sudoers
    destination = "/tmp/operator.sudoers"
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "id ${var.operator_user} >/dev/null 2>&1 || sudo useradd -m -s /bin/bash ${var.operator_user}",
      "sudo passwd -l ${var.operator_user}",
      "sudo install -d -m 700 -o ${var.operator_user} -g ${var.operator_user} /home/${var.operator_user}/.ssh",
      "echo '${var.ssh_public_key}' | sudo tee /home/${var.operator_user}/.ssh/authorized_keys >/dev/null",
      "sudo chown ${var.operator_user}: /home/${var.operator_user}/.ssh/authorized_keys",
      "sudo chmod 600 /home/${var.operator_user}/.ssh/authorized_keys",
      "sudo visudo -cf /tmp/operator.sudoers",
      "sudo install -m 440 -o root -g root /tmp/operator.sudoers /etc/sudoers.d/${var.operator_user}",
      "rm -f /tmp/operator.sudoers",
    ]
  }
}
