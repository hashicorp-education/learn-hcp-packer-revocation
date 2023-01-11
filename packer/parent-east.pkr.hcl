data "amazon-ami" "ubuntu" {
  region = "us-east-2"
  filters = {
    name = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  }
  most_recent = true
  owners      = ["099720109477"]
}

source "amazon-ebs" "east" {
  ami_name       = "learn-revocation-parent-{{timestamp}}"
  region         = "us-east-2"
  source_ami     = data.amazon-ami.ubuntu.id
  instance_type  = "t2.small"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false
  tags = {
    Name = "learn-revocation-parent"
  }
}

build {
  hcp_packer_registry {
    bucket_name = "learn-revocation-parent-us-east-2"
  }
  sources = [
    "source.amazon-ebs.east"
  ]
}
