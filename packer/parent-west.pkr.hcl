data "amazon-ami" "ubuntu" {
  region = "us-west-2"
  filters = {
    name = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  }
  most_recent = true
  owners      = ["099720109477"]
}

source "amazon-ebs" "west" {
  ami_name       = "learn-revocation-parent-{{timestamp}}"
  region         = "us-west-2"
  source_ami     = data.amazon-ami.ubuntu.id
  instance_type  = "t2.small"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false
}

build {
  hcp_packer_registry {
    bucket_name = "learn-revocation-parent-us-west-2"
  }
  sources = [
    "source.amazon-ebs.west"
  ]
}
