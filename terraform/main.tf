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

module "vpc_east" {
  source = "terraform-aws-modules/vpc/aws"
  providers = {
    aws = aws.east
  }

  name = "${var.project}-east"
  cidr = "10.1.0.0/16"
  azs             = ["us-east-2a"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
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
  subnet_id                   = module.vpc_east.private_subnets[0]
  vpc_security_group_ids      = [module.vpc_east.default_security_group_id]
  associate_public_ip_address = false

  tags = {
    Name                   = "${var.project}-${var.aws_region_east}"
  }
}


# us-west-2 region resources

module "vpc_west" {
  source = "terraform-aws-modules/vpc/aws"
  providers = {
    aws = aws.west
  }

  name = "${var.project}-west"
  cidr = "10.2.0.0/16"
  azs             = ["us-west-2a"]
  private_subnets = ["10.2.1.0/24", "10.2.2.0/24"]
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
  subnet_id                   = module.vpc_west.private_subnets[0]
  vpc_security_group_ids      = [module.vpc_west.default_security_group_id]
  associate_public_ip_address = false

  tags = {
    Name                   = "${var.project}-${var.aws_region_west}"
  }
}


