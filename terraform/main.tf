data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "security_groups" {
  source       = "./modules/security_groups"
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = data.aws_vpc.default.id
}

module "ec2" {
  source        = "./modules/ec2"
  project_name  = var.project_name
  environment   = var.environment
  ami_id        = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = data.aws_subnets.default.ids[0]
  bastion_sg_id = module.security_groups.bastion_sg_id
  web_sg_id     = module.security_groups.web_sg_id
  app_sg_id     = module.security_groups.app_sg_id
}

module "rds" {
  source            = "./modules/rds"
  project_name      = var.project_name
  environment       = var.environment
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  db_instance_class = var.db_instance_class
  rds_sg_id         = module.security_groups.rds_sg_id
  subnet_ids        = data.aws_subnets.default.ids
}
