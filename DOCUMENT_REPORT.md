# Document Report — GCP VM Auto-Scaling and Security

## Objective
Deploy a VM-based workload on Google Cloud Platform (GCP), configure automatic scaling based on CPU utilization, and apply basic security controls using IAM and firewall rules.

## Notes on the approach
GCP auto-scaling is applied to a **Managed Instance Group (MIG)**, which manages multiple identical VM instances created from an **Instance Template**. A single standalone VM does not auto-scale by itself; the MIG scales the number of VM instances.

## Prerequisites
- A GCP project with **Billing enabled**
- Permissions to manage Compute Engine, IAM, and networking resources
- Required APIs enabled:
  - Service Usage API (`serviceusage.googleapis.com`)
  - Compute Engine API (`compute.googleapis.com`)
  - IAM API (`iam.googleapis.com`)
  - Cloud Resource Manager API (`cloudresourcemanager.googleapis.com`)

## Step-by-step instructions for implementation

### 1) Create a VM instance on GCP (via Instance Template)
This implementation creates VM instances using an **Instance Template**, then uses a MIG to create actual VM instances from that template.

**Steps (Console method)**
1. Go to GCP Console → **Compute Engine**.
2. Go to **Instance templates** → **Create instance template**.
3. Choose:
   - Machine type (example: `e2-medium`)
   - Boot disk image (example: Debian 12)
4. Add a startup script (optional but useful for verification). Example purpose: install NGINX and serve a simple page.
5. Add network tags (example: `web`) to match firewall rules.
6. Create the instance template.

**Result**: An instance template that can be reused to create identical VMs.

### 2) Configure auto-scaling policies (CPU utilization)
Auto-scaling is configured by attaching an autoscaler to the MIG.

**Steps (Console method)**
1. Go to Compute Engine → **Instance groups** → **Create instance group**.
2. Select a **Managed instance group**.
3. Choose:
   - The instance template created earlier
   - Zone/region as required
   - Initial number of instances (example: 1)
4. After creating the MIG, open it and enable **Autoscaling**.
5. Configure autoscaling based on **CPU utilization**:
   - Minimum instances (example: 1)
   - Maximum instances (example: 3)
   - Target CPU utilization (example: 60%)
   - Cooldown period (example: 60 seconds)
6. Save.

**Verification**
- Increase CPU usage on a VM instance (e.g., run a CPU load tool) and observe the MIG scale out.
- When CPU drops, observe scale-in after cooldown.

### 3) Implement security measures

#### A) IAM roles for restricted access
Use IAM to limit who can view or administer compute resources.

**Steps (Console method)**
1. Go to **IAM & Admin → IAM**.
2. Click **Grant access**.
3. Add the required principal (user/service account).
4. Assign least-privilege roles, for example:
   - `Compute Instance Admin (v1)` (`roles/compute.instanceAdmin.v1`) for instance management
   - `Viewer` (`roles/viewer`) for read-only visibility
5. Save.

**Verification**
- Confirm the principal appears in the IAM list with the correct roles.

#### B) Firewall rules to allow/deny traffic
Firewall rules control inbound/outbound traffic to VMs (or to instances in the MIG using tags).

**Steps (Console method)**
1. Go to **VPC network → Firewall**.
2. Create an inbound allow rule for HTTP:
   - Direction: Ingress
   - Targets: specified target tags (example: `web`)
   - Source IP ranges: `0.0.0.0/0`
   - Protocols/ports: `tcp:80`
3. Create an inbound allow rule for SSH with restricted source:
   - Direction: Ingress
   - Targets: specified target tags (example: `web`)
   - Source IP ranges: your public IP `/32` (example: `X.X.X.X/32`)
   - Protocols/ports: `tcp:22`
4. Rely on the default behavior for deny: inbound traffic not explicitly allowed is blocked.

**Verification**
- From an allowed IP range, SSH should be reachable.
- From a non-allowed IP range, SSH should fail.
- HTTP should be reachable if you configured an external IP and allowed port 80.

## Implementation using Terraform (this repository)
This repository provides Terraform configuration that implements:
- VPC + subnet
- Firewall rules (HTTP allow; SSH restricted by CIDR)
- Instance template + startup script
- Managed Instance Group + autoscaler (CPU-based)
- IAM bindings for restricted access

Key files:
- `terraform/main.tf`
- `terraform/variables.tf`
- `terraform/terraform.tfvars.example`

## Plagiarism clause
I confirm this submission is my own work. Any plagiarism (copying another student’s work or submitting uncredited material) will result in the submission being voided.
