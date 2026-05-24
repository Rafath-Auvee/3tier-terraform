variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "bastion_sg_id" {
  type = string
}

variable "web_sg_id" {
  type = string
}

variable "app_sg_id" {
  type = string
}
