terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    linode = {
      source = "linode/linode"
      version = "3.7.0"
    }
  }
}