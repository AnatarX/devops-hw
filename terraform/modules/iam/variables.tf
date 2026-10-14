variable "host" {
  type = string
}

variable "bootstrap_user" {
  type = string
}

variable "ssh_private_key_path" {
  description = "Приватный ключ для входа под bootstrap_user"
  type        = string
}

variable "operator_user" {
  type = string
}

variable "ssh_public_key" {
  type = string
}
