terraform {
  cloud {
    workspaces {
      name = "learn-hcp-packer-revocation"
    }
  }

  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31.0"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.82.0"
    }
  }

}
