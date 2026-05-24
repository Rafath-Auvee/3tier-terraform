# aws-3tier-terraform

A complete 3-tier application on AWS provisioned with Terraform and deployed automatically via GitHub Actions CI/CD.

Built as part of a DevOps course — Module 6. The same application was previously deployed manually via the AWS Console (Module 5). This version replaces all manual steps with Infrastructure as Code.

---

## Architecture

```
Internet
    |
    v
[AWS Default VPC - Default Public Subnet]
    |
    +------+------------------+------------------+
    |      |                  |                  |
[Bastion] [Web Server]   [App Server]       [RDS MySQL]
 SSH :22   Nginx :80      Node.js :3000       MySQL :3306
           (public)       (public IP but       (private,
                           SG blocks           SG blocks
                           direct access)      direct access)
```

### Request Flow

```
Browser → Nginx :80 → Node.js :3000 → RDS MySQL :3306
SSH → Bastion :22 → App Server :22 (ProxyJump)
```

### Security via Security Groups (not subnet isolation)

| Resource   | Accepts traffic from                                  |
| ---------- | ----------------------------------------------------- |
| Bastion    | SSH from anywhere (0.0.0.0/0)                         |
| Web server | HTTP from anywhere, SSH from bastion only             |
| App server | Port 3000 from web server only, SSH from bastion only |
| RDS        | Port 3306 from app server only                        |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Infrastructure | Terraform |
| Cloud | AWS (VPC, EC2, RDS, NAT Gateway) |
| Web server | Nginx |
| Backend | Node.js + Express |
| Database | AWS RDS MySQL 8.0 |
| CI/CD | GitHub Actions |

---

## Project Structure

```
aws-3tier-terraform/
├── terraform/
│   ├── providers.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   └── modules/
│       ├── vpc/               # VPC, subnets, IGW, NAT, route tables
│       ├── security_groups/   # SGs for bastion, web, app, RDS
│       ├── ec2/               # Bastion, web server, app server
│       │   └── templates/
│       │       └── nginx.sh.tpl
│       └── rds/               # RDS MySQL instance + subnet group
├── app/
│   └── backend/
│       ├── server.js          # Node.js Express app
│       └── package.json
├── .github/
│   └── workflows/
│       └── deploy.yml         # CI/CD pipeline
└── README.md
```

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.6
- [AWS CLI](https://aws.amazon.com/cli/) configured (`aws configure`)
- An AWS key pair created in your target region
- A GitHub repository with Actions enabled

---

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/<your-username>/aws-3tier-terraform.git
cd aws-3tier-terraform
```

### 2. Update terraform.tfvars

Edit `terraform/terraform.tfvars`:

```hcl
aws_region   = "us-east-1"
project_name = "module6"
environment  = "dev"
key_name     = "your-key-pair-name"
```

### 3. Set the database password

**Linux/Mac:**
```bash
export TF_VAR_db_password="YourStrongPassword123"
```

**Windows PowerShell:**
```powershell
$env:TF_VAR_db_password = "YourStrongPassword123"
```

### 4. Deploy infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

After apply completes, Terraform prints the outputs:

```
bastion_public_ip      = "x.x.x.x"
web_server_public_ip   = "x.x.x.x"
app_server_private_ip  = "10.0.11.x"
rds_endpoint           = "module6-mysql.xxxx.us-east-1.rds.amazonaws.com:3306"
application_url        = "http://x.x.x.x"
ssh_bastion_command    = "ssh -i your-key.pem ubuntu@x.x.x.x"
ssh_app_server_command = "ssh -i your-key.pem -J ubuntu@<bastion> ubuntu@<app>"
```

### 5. Initialize the database

SSH to the app server via bastion:

```bash
ssh -i your-key.pem -J ubuntu@<BASTION_IP> ubuntu@<APP_SERVER_PRIVATE_IP>
```

Connect to RDS and create the schema:

```bash
mysql -h <RDS_ADDRESS> -u appuser -p appdb
```

```sql
CREATE TABLE messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message VARCHAR(255) NOT NULL
);

INSERT INTO messages (message) VALUES ('Database layer connected successfully');
```

### 6. Deploy the application

Clone this repo on the app server and start with PM2:

```bash
cd /home/ubuntu/backend-app
git clone https://github.com/<your-username>/aws-3tier-terraform.git .
cd app/backend
npm install

DB_HOST=<RDS_ADDRESS> \
DB_USER=appuser \
DB_PASSWORD=<your-password> \
DB_NAME=appdb \
pm2 start server.js --name backend-app

pm2 save
pm2 startup
```

### 7. Verify

| URL | Expected Result |
|---|---|
| `http://<web_server_ip>` | `Backend application layer is running` |
| `http://<web_server_ip>/health` | `Application layer connected to database: Database layer connected successfully` |

---

## CI/CD Pipeline

Every push to `main` that changes files under `app/` triggers the GitHub Actions workflow:

1. SSHs into the bastion host
2. ProxyJumps to the private app server
3. Pulls latest code
4. Runs `npm install`
5. Restarts the PM2 process

### Required GitHub Secrets

Go to your repo → **Settings → Secrets and variables → Actions** and add:

| Secret | Value |
|---|---|
| `BASTION_IP` | Bastion public IP (from Terraform output) |
| `APP_SERVER_IP` | App server private IP (from Terraform output) |
| `SSH_PRIVATE_KEY` | Full contents of your `.pem` file |
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |
| `DB_HOST` | RDS address without port (from Terraform output) |
| `DB_USER` | `appuser` |
| `DB_PASSWORD` | Your RDS password |
| `DB_NAME` | `appdb` |

---

## Security Groups

| Security Group | Inbound Rule | Source |
|---|---|---|
| bastion-sg | SSH :22 | `0.0.0.0/0` |
| web-sg | HTTP :80 | `0.0.0.0/0` |
| web-sg | SSH :22 | bastion-sg |
| app-sg | TCP :3000 | web-sg |
| app-sg | SSH :22 | bastion-sg |
| rds-sg | MySQL :3306 | app-sg |

---

## Destroy Infrastructure

To tear down all AWS resources:

```bash
cd terraform
terraform destroy
```

---

## Comparison: Manual vs Terraform

| | Module 5 (Manual) | Module 6 (Terraform) |
|---|---|---|
| Setup method | AWS Console | `terraform apply` |
| VPC | Default VPC | Custom VPC |
| Subnets | All public | Public + Private |
| Database | MySQL on EC2 | AWS RDS (managed) |
| SSH access | Direct to all | Via bastion only |
| Deployment | Manual | GitHub Actions |
| Reproducible | No | Yes |
