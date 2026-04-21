terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Remote state — replace bucket/key with real values
  backend "s3" {
    bucket = "health-system-tfstate"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"
  name   = var.project
  region = var.aws_region
}

module "iam" {
  source  = "./modules/iam"
  project = var.project
}

module "rds" {
  source             = "./modules/rds"
  project            = var.project
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
  db_secret_arn      = var.db_secret_arn
}

module "ecs" {
  source               = "./modules/ecs"
  project              = var.project
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  private_subnet_ids   = module.vpc.private_subnet_ids
  execution_role_arn   = module.iam.ecs_execution_role_arn
  task_role_arn        = module.iam.ecs_task_role_arn
  image                = var.container_image
  db_secret_arn        = var.db_secret_arn
  acm_certificate_arn  = var.acm_certificate_arn
}
