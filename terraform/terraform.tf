terraform {
  cloud {
    workspaces {
      name = "learn-hcp-packer-revocation"
    }
  }

  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.45.0"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "0.52.0"
    }
  }

}
