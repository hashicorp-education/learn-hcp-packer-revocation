variable "project" {
  type = string
  default = "learn-revocation"
}

variable "aws_west_region" {
  type = string
  default = "us-west-2"
}
variable "aws_east_region" {
  type = string
  default = "us-east-2"
}

data "hcp-packer-iteration" "parent-east" {
  bucket_name = "${var.project}-parent-${var.aws_east_region}"
  channel     = "production"
}

data "hcp-packer-image" "parent-east" {
  bucket_name    = data.hcp-packer-iteration.parent-east.bucket_name
  iteration_id   = data.hcp-packer-iteration.parent-east.id
  cloud_provider = "aws"
  region         = var.aws_east_region
}


data "hcp-packer-iteration" "parent-west" {
  bucket_name = "${var.project}-parent-${var.aws_west_region}"
  channel     = "production"
}

data "hcp-packer-image" "parent-west" {
  bucket_name    = data.hcp-packer-iteration.parent-west.bucket_name
  iteration_id   = data.hcp-packer-iteration.parent-west.id
  cloud_provider = "aws"
  region         = var.aws_west_region
}


source "amazon-ebs" "child-east" {
  ami_name       = "learn-revocation-child-{{timestamp}}"
  region         = var.aws_east_region
  source_ami     = data.hcp-packer-image.parent-east.id
  instance_type  = "t2.small"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false
  tags = {
    Name = "learn-revocation-child"
  }
}

source "amazon-ebs" "child-west" {
  ami_name       = "learn-revocation-child-{{timestamp}}"
  region         = var.aws_west_region
  source_ami     = data.hcp-packer-image.parent-west.id
  instance_type  = "t2.small"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false
  tags = {
    Name = "learn-revocation-child"
  }
}


build {
  hcp_packer_registry {
    bucket_name = "${var.project}-child"
  }
  sources = [
    "source.amazon-ebs.child-east",
    "source.amazon-ebs.child-west"
  ]
}