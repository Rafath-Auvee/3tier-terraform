# Terraform Outputs - Study Guide

## What Are Terraform Outputs?

After `terraform apply` completes, Terraform prints a summary called **outputs**.
These are values from the created resources that you need to use — IPs, URLs, endpoints, commands.

Run this anytime to see them:
```powershell
terraform output
```

---

## Our Outputs Explained

### 1. `bastion_public_ip`
```
bastion_public_ip = "x.x.x.x"
```
- The public IP of the **bastion host** EC2 instance
- This is your **only SSH entry point** into the infrastructure
- You SSH to this IP first, then jump to the app server

---

### 2. `web_server_public_ip`
```
web_server_public_ip = "x.x.x.x"
```
- The public IP of the **Nginx web server** EC2 instance
- This is the IP users visit in their browser
- Nginx listens on port 80 and forwards traffic to the Node.js app server

---

### 3. `app_server_public_ip`
```
app_server_public_ip = "x.x.x.x"
```
- The public IP of the **Node.js app server** EC2 instance
- Even though it has a public IP, the security group blocks all direct access
- Only the web server (port 3000) and bastion (port 22) can reach it
- You cannot open this IP in a browser — it is effectively private

---

### 4. `rds_endpoint`
```
rds_endpoint = "module6-mysql.xxxxxxxxxxxx.us-east-2.rds.amazonaws.com:3306"
```
- The full connection string for RDS MySQL (includes port 3306)
- Used in database clients or connection strings
- Format: `hostname:port`
- Example full connection: `mysql -h <hostname> -P 3306 -u appuser -p appdb`

---

### 5. `rds_address`
```
rds_address = "module6-mysql.xxxxxxxxxxxx.us-east-2.rds.amazonaws.com"
```
- Same as `rds_endpoint` but **without the port**
- Use this in your Node.js app as the `DB_HOST` environment variable
- The port (3306) is the default MySQL port and is set separately in the app

---

### 6. `application_url`
```
application_url = "http://x.x.x.x"
```
- The full URL to open in your browser to see the running application
- Points to the Nginx web server public IP on port 80
- Expected response: `Backend application layer is running`

---

### 7. `health_check_url`
```
health_check_url = "http://x.x.x.x/health"
```
- The URL that proves all 3 tiers are connected and working
- Nginx → Node.js → RDS → back to browser
- Expected response: `Application layer connected to database: Database layer connected successfully`
- If this works, the entire 3-tier stack is healthy

---

### 8. `ssh_bastion_command`
```
ssh_bastion_command = "ssh -i rafath-io.pem ubuntu@x.x.x.x"
```
- The exact command to SSH into the bastion host
- Replace `rafath-io.pem` with the full path to your key file
- Example: `ssh -i C:\Users\rbza9\rafath-io.pem ubuntu@x.x.x.x`

---

### 9. `ssh_app_server_command`
```
ssh_app_server_command = "ssh -i rafath-io.pem -J ubuntu@<bastion_ip> ubuntu@<app_ip>"
```
- The command to SSH **directly to the app server** through the bastion in one step
- `-J ubuntu@<bastion_ip>` means "jump through this host first" (ProxyJump)
- You never have to SSH to bastion first and then SSH again — one command does both
- This is the secure way to access private servers

---

## How Outputs Are Defined in Code

In `terraform/outputs.tf`:

```hcl
output "web_server_public_ip" {
  description = "Public IP of the web server (Nginx)"
  value       = module.ec2.web_server_public_ip
}
```

- `output "name"` — the name shown in the terminal
- `description` — human-readable explanation
- `value` — the actual value pulled from a resource or module

The value `module.ec2.web_server_public_ip` means:
- `module.ec2` — look inside the ec2 module
- `.web_server_public_ip` — get this output from that module

Which is defined in `terraform/modules/ec2/outputs.tf`:
```hcl
output "web_server_public_ip" {
  value = aws_instance.web_server.public_ip
}
```

Which pulls the real IP from the EC2 resource after AWS assigns it.

---

## Output Flow Diagram

```
AWS creates EC2 instance
        |
        v
aws_instance.web_server.public_ip  (real IP assigned by AWS)
        |
        v
modules/ec2/outputs.tf  →  output "web_server_public_ip"
        |
        v
terraform/outputs.tf    →  module.ec2.web_server_public_ip
        |
        v
Terminal: web_server_public_ip = "3.x.x.x"
```

---

## Useful Commands

| Command | What it does |
|---|---|
| `terraform output` | Show all outputs |
| `terraform output web_server_public_ip` | Show one specific output |
| `terraform output -json` | Show all outputs in JSON format |
| `terraform output -raw web_server_public_ip` | Show raw value (no quotes, good for scripts) |

---

## Why Outputs Matter for CI/CD

In the GitHub Actions workflow, these outputs are used as secrets:

| Terraform Output | GitHub Secret |
|---|---|
| `bastion_public_ip` | `BASTION_IP` |
| `app_server_public_ip` | `APP_SERVER_IP` |
| `rds_address` | `DB_HOST` |

After `terraform apply`, copy these values into your GitHub repository secrets
so the CI/CD pipeline can SSH into the servers and deploy the application.

---

## Destroy and Outputs

When you run `terraform destroy`, all resources are deleted and the outputs
become empty. Running `terraform output` after destroy shows nothing.

To get outputs back, you must run `terraform apply` again.
