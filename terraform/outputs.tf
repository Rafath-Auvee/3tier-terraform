output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.ec2.bastion_public_ip
}

output "web_server_public_ip" {
  description = "Public IP of the web server (Nginx)"
  value       = module.ec2.web_server_public_ip
}

output "app_server_public_ip" {
  description = "Public IP of the app server (Node.js)"
  value       = module.ec2.app_server_public_ip
}

output "rds_endpoint" {
  description = "RDS MySQL connection endpoint"
  value       = module.rds.rds_endpoint
}

output "rds_address" {
  description = "RDS MySQL hostname (without port)"
  value       = module.rds.rds_address
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${module.ec2.web_server_public_ip}"
}

output "health_check_url" {
  description = "URL to verify full 3-tier connectivity"
  value       = "http://${module.ec2.web_server_public_ip}/health"
}

output "ssh_bastion_command" {
  description = "SSH command to connect to bastion"
  value       = "ssh -i rafath-io.pem ubuntu@${module.ec2.bastion_public_ip}"
}

output "ssh_app_server_command" {
  description = "SSH to app server via bastion"
  value       = "ssh -i rafath-io.pem -J ubuntu@${module.ec2.bastion_public_ip} ubuntu@${module.ec2.app_server_public_ip}"
}
