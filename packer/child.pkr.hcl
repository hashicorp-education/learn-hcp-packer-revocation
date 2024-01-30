data "hcp-packer-version" "parent-east" {
  bucket_name  = "learn-revocation-parent-us-east-2"
  channel_name = "production"
}

data "hcp-packer-artifact" "parent-east" {
  bucket_name         = data.hcp-packer-version.parent-east.bucket_name
  version_fingerprint = data.hcp-packer-version.parent-east.fingerprint
  platform            = "aws"
  region              = "us-east-2"
}

data "hcp-packer-version" "parent-west" {
  bucket_name  = "learn-revocation-parent-us-west-2"
  channel_name = "production"
}

data "hcp-packer-artifact" "parent-west" {
  bucket_name         = data.hcp-packer-version.parent-west.bucket_name
  version_fingerprint = data.hcp-packer-version.parent-west.fingerprint
  platform            = "aws"
  region              = "us-west-2"
}

source "amazon-ebs" "child-east" {
  ami_name       = "learn-revocation-child-{{timestamp}}"
  region         = "us-east-2"
  source_ami     = data.hcp-packer-artifact.parent-east.external_identifier
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
  source_ami     = data.hcp-packer-artifact.parent-west.external_identifier
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