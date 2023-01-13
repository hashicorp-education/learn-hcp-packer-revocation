data "hcp-packer-iteration" "parent-east" {
  bucket_name = "learn-revocation-parent-us-east-2"
  channel     = "production"
}

data "hcp-packer-image" "parent-east" {
  bucket_name    = data.hcp-packer-iteration.parent-east.bucket_name
  iteration_id   = data.hcp-packer-iteration.parent-east.id
  cloud_provider = "aws"
  region         = "us-east-2"
}

data "hcp-packer-iteration" "parent-west" {
  bucket_name = "learn-revocation-parent-us-west-2"
  channel     = "production"
}

data "hcp-packer-image" "parent-west" {
  bucket_name    = data.hcp-packer-iteration.parent-west.bucket_name
  iteration_id   = data.hcp-packer-iteration.parent-west.id
  cloud_provider = "aws"
  region         = "us-west-2"
}

source "amazon-ebs" "child-east" {
  ami_name       = "learn-revocation-child-{{timestamp}}"
  region         = "us-east-2"
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
  region         = "us-west-2"
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
    bucket_name = "learn-revocation-child"
  }
  sources = [
    "source.amazon-ebs.child-east",
    "source.amazon-ebs.child-west"
  ]
}