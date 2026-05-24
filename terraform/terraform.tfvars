aws_region   = "us-east-2"
project_name = "module6"
environment  = "dev"

# Set this to your EC2 key pair name in AWS
key_name = "rafath-io"

# db_password must be set via environment variable:
#   export TF_VAR_db_password="YourStrongPassword123"  (Linux/Mac)
#   $env:TF_VAR_db_password = "YourStrongPassword123"  (PowerShell)
