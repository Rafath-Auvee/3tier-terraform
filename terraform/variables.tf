variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "module6"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI ID (us-east-2 Ohio)"
  type        = string
  default     = "ami-0cb91c7de36eed2cb"
}

variable "instance_type" {
  description = "EC2 instance type (free tier)"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "db_name" {
  description = "RDS database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "RDS master password — set via TF_VAR_db_password env var"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class (free tier)"
  type        = string
  default     = "db.t3.micro"
}
