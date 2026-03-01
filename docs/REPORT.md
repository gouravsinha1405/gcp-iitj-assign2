# Document Report — GCP VM Auto-Scaling + Security

## Objective
Set up a VM-based workload on Google Cloud Platform (GCP), implement auto-scaling policies based on CPU utilization, and apply security controls (firewall rules + IAM).

## Important note about “auto-scaling a VM”
GCP auto-scaling is implemented for a **Managed Instance Group (MIG)**. A MIG manages a *set of VM instances* created from an instance template, and the autoscaler adjusts the number of instances based on metrics (CPU, load balancing, etc.).

## Step-by-step instructions

### A) Create a VM instance (via Instance Template)
This project creates VM instances through an **Instance Template** so that new identical VMs can be created automatically by the MIG.

1. Open Cloud Shell (or use local terminal with `gcloud`).
2. Enable the Compute Engine API:

```bash
gcloud services enable compute.googleapis.com
```

3. Confirm you have a project selected:

```bash
gcloud config get-value project
```

4. Review the instance startup behavior:
- The file [terraform/startup/startup.sh](../terraform/startup/startup.sh) installs NGINX and serves a simple HTML page.

### B) Deploy infrastructure with Terraform

1. Install Terraform (or use Cloud Shell).
2. Authentication (choose one):

Option 1: `gcloud` user login (Cloud Shell / local)

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

Option 2: Service account key JSON (works even if `gcloud` is not installed)

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/absolute/path/to/service-account-key.json"
```

3. Go to the Terraform folder:

```bash
cd terraform
```

4. Create a `terraform.tfvars` file with your values:

```hcl
project_id       = "YOUR_PROJECT_ID"
admin_user_email = "your.email@gmail.com"
# Optional overrides:
# region          = "asia-south1"
# zone            = "asia-south1-a"
# allowed_ssh_cidr = "YOUR_PUBLIC_IP/32"
```

5. Initialize and apply:

```bash
terraform init
terraform apply
```

Prerequisites that commonly block first-time projects:
- Billing must be enabled on the project (Compute Engine requires billing).
- The following APIs must be enabled:
  - Service Usage API (`serviceusage.googleapis.com`)
  - Compute Engine API (`compute.googleapis.com`)
  - IAM API (`iam.googleapis.com`)
  - Cloud Resource Manager API (`cloudresourcemanager.googleapis.com`)

What this creates:
- VPC + subnet
- Firewall rules:
  - allow inbound SSH (tcp/22) **only** from `allowed_ssh_cidr`
  - allow inbound HTTP (tcp/80) from anywhere (for demo)
- Instance template with startup script (NGINX)
- Managed Instance Group (MIG) with initial size = `min_replicas`
- Autoscaler based on average CPU utilization
- IAM binding granting limited Compute permissions to `admin_user_email`

### C) Configure auto-scaling policy (CPU based)
Auto-scaling is configured using a Compute Autoscaler attached to the MIG:
- min replicas: `min_replicas` (default 1)
- max replicas: `max_replicas` (default 3)
- CPU target: `cpu_target` (default 0.6 → 60%)

To adjust the policy, change values in `terraform.tfvars` (or variable defaults) and re-apply:

```bash
terraform apply
```

### D) Security measures

#### 1) IAM roles for restricted access
This project demonstrates restricted access by binding a specific user to a minimal set of Compute Engine permissions.

In this repo:
- A custom service account is used for the VMs (so no one uses default overly-permissive accounts).
- The `admin_user_email` gets:
  - `roles/compute.instanceAdmin.v1` (manage VM instances)
  - `roles/compute.viewer` (read-only visibility)

You can replace these roles with stricter ones depending on your rubric.

#### 2) Firewall rules (allow/deny)
Firewall is configured as:
- `allow-ssh-restricted`: allows tcp/22 only from `allowed_ssh_cidr` (ideally your IP `/32`)
- `allow-http`: allows tcp/80 from `0.0.0.0/0` for demo web access
- Everything else inbound is denied by default.

### E) Verification (show it works)

1. In GCP Console → Compute Engine → Instance groups, open the MIG and confirm instances exist.
2. Verify firewall:
- From a non-allowed IP, SSH should fail.
- From your allowed IP, SSH should work (if OS Login/keys are configured).
3. Verify HTTP:
- Get the external IP of one instance (from the MIG instances list) and open `http://EXTERNAL_IP/`.

### F) Demo: trigger scaling (simple approach)
To demonstrate autoscaling, generate CPU load on one VM instance.

Option 1: SSH and run a CPU burner (short duration):

```bash
sudo apt-get update -y
sudo apt-get install -y stress-ng
stress-ng --cpu 2 --timeout 180s
```

Then watch the autoscaler increase the number of instances in the MIG.

Option 2: Reduce the CPU target temporarily (e.g., `cpu_target = 0.2`) and apply, then restore.

### G) Cleanup

```bash
terraform destroy
```

## Deliverables mapping
- Document Report: this file.
- Architecture Design: [docs/ARCHITECTURE.md](ARCHITECTURE.md)
- Source Code Repo: push this folder to GitHub/GitLab and share the URL.
- Recorded Video Demo: record and upload (Drive/YouTube unlisted) and share the URL.

## Video demo checklist (what to record)
1. Show the Terraform code briefly (folders + key files).
2. Run `terraform apply` (or show the already-created resources).
3. Open Instance Group → show current size and autoscaler settings.
4. SSH to an instance and run `stress-ng` to raise CPU.
5. Refresh instance group page to show scale-out.
6. Show firewall rule list and explain:
   - SSH restricted CIDR
   - HTTP allowed
7. Show IAM bindings (who has admin vs viewer access).
8. End with `terraform destroy` (optional but good practice).

## Suggested video timeline (simple, 4–6 minutes)

00:00–00:30 — Intro
- State objective: VM autoscaling + IAM + firewall on GCP.

00:30–01:10 — Show IaC (this repo)
- Open `terraform/main.tf` and point to: instance template → MIG → autoscaler.
- Show `terraform/terraform.tfvars` values (project, region/zone, cpu_target, min/max).

01:10–02:00 — Show deployed resources (GCP Console)
- Compute Engine → Instance groups → `vcc-assignment-mig` (current size + instances).
- Open the MIG autoscaling settings (CPU target, min/max).

02:00–03:10 — Demonstrate workload / scaling trigger
- SSH to one MIG instance.
- Run:

```bash
sudo apt-get update -y
sudo apt-get install -y stress-ng
stress-ng --cpu 2 --timeout 180s
```

03:10–04:10 — Show scale-out
- Refresh MIG page and show instance count increasing (may take a few minutes; keep recording until it changes).

04:10–05:10 — Security controls
- VPC network → Firewall: show `allow-ssh-restricted` (your `/32`) and `allow-http`.
- IAM & Admin → IAM: show the role bindings for the admin email.

05:10–05:40 — Cleanup (optional)
- Show `terraform destroy` or mention cleanup step.

## Plagiarism clause
I confirm this submission is my own work. Any plagiarism (copying another student’s work or submitting uncredited material) will result in the submission being voided.
