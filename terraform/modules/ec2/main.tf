resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.bastion_sg_id]
  associate_public_ip_address = true

  tags = {
    Name        = "${var.project_name}-bastion"
    Environment = var.environment
    Role        = "bastion"
  }
}

resource "aws_instance" "app_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.app_sg_id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs git
    npm install -g pm2
    mkdir -p /home/ubuntu/backend-app
    chown -R ubuntu:ubuntu /home/ubuntu/backend-app
  EOF

  tags = {
    Name        = "${var.project_name}-app-server"
    Environment = var.environment
    Role        = "app"
  }
}

resource "aws_instance" "web_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.web_sg_id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/templates/nginx.sh.tpl", {
    app_server_ip = aws_instance.app_server.private_ip
  })

  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
    Role        = "web"
  }
}
