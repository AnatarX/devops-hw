resource "docker_network" "web" {
  name   = "${var.project_name}-net"
  driver = "bridge"

  # без gateway plan каждый раз пересоздаёт сеть
  ipam_config {
    subnet  = var.web_subnet
    gateway = cidrhost(var.web_subnet, 1)
  }
}

resource "docker_volume" "html" {
  name = "${var.project_name}-html"
}

resource "docker_image" "nginx" {
  name         = var.nginx_image
  keep_locally = true
}

resource "docker_container" "nginx" {
  name    = "${var.project_name}-nginx"
  image   = docker_image.nginx.image_id
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.web.name
  }

  # 80 занят compose
  ports {
    internal = 80
    external = var.web_port
  }

  volumes {
    volume_name    = docker_volume.html.name
    container_path = "/usr/share/nginx/html"
  }

  upload {
    file = "/usr/share/nginx/html/index.html"
    content = templatefile("${path.module}/files/index.html.tftpl", {
      network = docker_network.web.name
      volume  = docker_volume.html.name
      port    = var.web_port
    })
  }

  healthcheck {
    test     = ["CMD", "wget", "-q", "-O", "/dev/null", "http://127.0.0.1/"]
    interval = "10s"
    timeout  = "3s"
    retries  = 3
  }
}

module "iam" {
  source = "./modules/iam"

  host                 = var.server_ip
  bootstrap_user       = var.admin_user
  ssh_private_key_path = var.ssh_private_key_path
  operator_user        = var.operator_user
  ssh_public_key       = trimspace(file(pathexpand(var.ssh_public_key_path)))
}
