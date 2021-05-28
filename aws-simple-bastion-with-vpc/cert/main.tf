/*
Main Terraform template that builds the infrastructure defined in the modules.

Author: Chad Bartel
Date:   2021-04-03
*/

# Declare required Terraform providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}


# Local variables
locals {
  tags = {
    Terraform = true
    env       = var.environment
    workspace = terraform.workspace
    project   = var.project_name
  }
  state_bucket = format(
    "%s-%s-%s",
    var.environment,
    var.region,
    var.state_bucket
  )
  lock_table = format(
    "%s-%s",
    var.environment,
    var.lock_table
  )
}


# Create AWS Terraform provider
provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = merge(
      var.default_tags,
      local.tags
    )
  }
}


# Execute VPC module
module "vpc" {
  source                = "./modules/vpc"
  my_ip_address         = var.my_ip_address
  vpc_cidr              = "10.0.0.0/16"
  public_subnet_a_cidr  = "10.0.0.0/24"
  private_subnet_a_cidr = "10.0.1.0/24"
  availability_zone     = var.availability_zone
  environment           = var.environment
}

# Execute EC2 module
module "ec2" {
  source            = "./modules/ec2"
  key_name          = var.key_name
  public_key        = var.public_key
  instance_type     = "t2.micro"
  public_subnet_id  = module.vpc.aws_public_subnet_id_a
  private_subnet_id = module.vpc.aws_private_subnet_id_a
  bastion_sg        = module.vpc.bastion_sg
  private_sg        = module.vpc.private_sg
  availability_zone = var.availability_zone
  environment       = var.environment
  depends_on = [
    module.vpc
  ]
}