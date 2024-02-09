terraform {
  required_version = ">= 0.12"
  required_providers {
    # aws = {
    #   version = "~> 4.35.0"
    # }
    consul = {
      source  = "hashicorp/consul"
      version = ">=2.20.0"
    }
  }
}