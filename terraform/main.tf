provider "aws" {
  alias  = "west"
  region = var.aws_region_west
}
provider "aws" {
  alias  = "east"
  region = var.aws_region_east
}
provider "hcp" {}

locals {
  project = "learn-revocation"
}

data "hcp_packer_iteration" "child" {
  bucket_name = "${var.project}-child"
  channel     = var.hcp_channel
}

# us-east-2 region resources

resource "aws_vpc" "east" {
  provider   = aws.east
  cidr_block = "10.1.0.0/16"
}
resource "aws_subnet" "east1" {
  provider   = aws.east
  vpc_id     = aws_vpc.east.id
  cidr_block = "10.1.1.0/24"
}
resource "aws_subnet" "east2" {
  provider   = aws.east
  vpc_id     = aws_vpc.east.id
  cidr_block = "10.1.2.0/24"
}

resource "aws_security_group" "east_egress" {
  provider = aws.east
  name     = "allow_outbound"
  vpc_id   = aws_vpc.east.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "hcp_packer_image" "aws_east" {
  bucket_name    = data.hcp_packer_iteration.child.bucket_name
  iteration_id   = data.hcp_packer_iteration.child.ulid
  cloud_provider = "aws"
  region         = var.aws_region_east
}

resource "aws_instance" "east" {
  provider                    = aws.east
  ami                         = data.hcp_packer_image.aws_east.cloud_image_id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.east2.id
  vpc_security_group_ids      = [aws_security_group.east_egress.id]
  associate_public_ip_address = false

  tags = {
    Name                   = "${var.project}-${var.aws_region_east}"
    HCP_Packer_Iteration   = data.hcp_packer_iteration.child.id
    HCP_Packer_Fingerprint = data.hcp_packer_iteration.child.fingerprint
  }
}


# us-west-2 region resources

resource "aws_vpc" "west" {
  provider   = aws.west
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "west1" {
  provider   = aws.west
  vpc_id     = aws_vpc.west.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "west_egress" {
  provider = aws.west
  name     = "allow_outbound"
  vpc_id   = aws_vpc.west.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "hcp_packer_image" "aws_west" {
  bucket_name  = data.hcp_packer_iteration.child.bucket_name
  iteration_id = data.hcp_packer_iteration.child.ulid
  #iteration_id = "01GKA7AA5S07F2438XPGCDJ1C6"
  cloud_provider = "aws"
  region         = var.aws_region_west
}

resource "aws_instance" "west" {
  provider                    = aws.west
  ami                         = data.hcp_packer_image.aws_west.cloud_image_id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.west1.id
  vpc_security_group_ids      = [aws_security_group.west_egress.id]
  associate_public_ip_address = false

  tags = {
    Name                   = "${var.project}-${var.aws_region_west}"
    HCP_Packer_Iteration   = data.hcp_packer_iteration.child.id
    HCP_Packer_Fingerprint = data.hcp_packer_iteration.child.fingerprint
  }
}


