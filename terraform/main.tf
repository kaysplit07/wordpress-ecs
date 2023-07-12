terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ecr
module "aws-ecr" {
  source = "./modules/aws-ecr"
  region = "us-east-1"
  tags   = {
	environment = "dev"
	project     = "ecs-wordpress"
	terraform   = true
  }
}

output "arn" {
  value = module.aws-ecr.arn
}

output "repository_url" {
  value = module.aws-ecr.repository_url
}

# vpc
module "aws_vpc" {
  source            = "./modules/aws-vpc"
  region            = "us-east-1"
  availability_zone = "us-east-1a"
  tags              = {
	environment = "dev"
	project     = "ecs-wordpress"
	terraform   = true
  }
}

output "vpc_id" {
  value = module.aws_vpc.vpc_id
}

output "availability_zone" {
  value = module.aws_vpc.availability_zone
}

output "subnet_id" {
  value = module.aws_vpc.subnet_id
}

output "sg_id" {
  value = module.aws_vpc.sg_id
}

# ecs
module "aws_ecs" {
  source = "./modules/aws-ecs"
  region = "us-east-1"
  tags   = {
	environment = "dev"
	project     = "ecs-wordpress"
	terraform   = true
  }
}

output "ecs_cluster_id" {
  value = module.aws_ecs.cluster_id
}

output "ecs_cloudwatch_group_name" {
  value = module.aws_ecs.cloudwatch_group_name
}

# rds

module "aws_rds" {
  source                  = "./modules/aws-rds"
  vpc_id                  = local.vpc_id
  region                  = "us-east-1"
  availability_zone       = "us-east-1a"
  allowed_security_groups = [
	local.sg_id]
  db_port                 = 3306
  db_name                 = "wordpress"
  db_allocated_storage    = 5
  db_instance_class       = "db.t2.micro"
  db_storage_type         = "gp2"
  db_username             = "wordpress"
  db_engine               = "mariadb"
  db_engine_version       = "10.5"
  db_parameter_group_name = "default.mysql10.5"
  db_skip_final_snapshot  = true
  tags                    = {
	environment = "dev"
	project     = "ecs-wordpress"
	terraform   = true
  }
}

output "db_endpoint" {
  value = module.aws_rds.db_endpoint
}

output "db_address" {
  value = module.aws_rds.db_address
}

output "db_port" {
  value = module.aws_rds.db_port
}

output "db_username" {
  value = module.aws_rds.db_username
}

output "db_password" {
  value     = module.aws_rds.db_password
  sensitive = true
}

locals {
  # Networking
  vpc_id                        = module.aws_vpc.vpc_id
  subnet_id                     = module.aws_vpc.subnet_id
  sg_id                         = module.aws_vpc.sg_id
  # RDS
  db_username                   = module.aws_rds.db_username
  db_host                       = module.aws_rds.db_address
  db_password                   = module.aws_rds.db_password
  db_port                       = module.aws_rds.db_port
  # ECS
  ecs_cloudwatch_log_group_name = module.aws_ecs.cloudwatch_group_name
  ecs_cluster_id                = module.aws_ecs.cluster_id
  # ECR
  repository_url                = module.aws-ecr.repository_url
}

module "aws-ecs-wordpress" {
  source                    = "./modules/aws-ecs-wordpress"
  region                    = "us-east-1"
  vpc_id                    = local.vpc_id
  subnet_id                 = local.subnet_id
  sg_id                     = local.sg_id
  cloudwatch_log_group_name = local.ecs_cloudwatch_log_group_name
  wordpress_db_host         = local.db_host
  wordpress_db_name         = "wordpress"
  wordpress_db_user         = local.db_username
  wordpress_db_password     = local.db_password
  wordpress_db_port         = local.db_port
  wordpress_port            = 80
  repository_url            = local.repository_url
  image_tag                 = "latest"
  desired_count             = 1
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
  fargate_cpu               = 256
  fargate_memory            = 512
  ecs_cluster_id            = local.ecs_cluster_id
  tags                      = {
	environment = "dev"
	project     = "ecs-wordpress"
	terraform   = true
  }
}

output "wordpress_admin_password" {
  description = "The Wordpress admin password"
  value       = module.aws-ecs-wordpress.wordpress_admin_password
  sensitive   = true
}
