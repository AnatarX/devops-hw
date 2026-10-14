terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}
