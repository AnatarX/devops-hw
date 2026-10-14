variable "project_name" {
  description = "Префикс для имён Docker-объектов"
  type        = string
  default     = "devops-hw1"
}

variable "server_ip" {
  description = "IP сервера"
  type        = string
  default     = "111.88.162.121"
}

variable "docker_ssh_user" {
  description = "Пользователь для подключения к Docker (группа docker, без sudo)"
  type        = string
  default     = "deployer"
}

variable "admin_user" {
  description = "Пользователь с sudo, под которым создаётся vm-operator (модуль iam)"
  type        = string
  default     = "student"
}

variable "ssh_private_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

variable "nginx_image" {
  description = "Образ nginx (версия закреплена)"
  type        = string
  default     = "nginx:1.27-alpine"
}

variable "web_port" {
  description = "Нестандартный внешний порт nginx (80 занят compose-окружением)"
  type        = number
  default     = 8080
}

variable "web_subnet" {
  description = "Подсеть отдельной Docker-сети для nginx"
  type        = string
  default     = "172.30.0.0/24"
}

variable "operator_user" {
  description = "Пользователь с минимальными правами на управление сервисами"
  type        = string
  default     = "vm-operator"
}
