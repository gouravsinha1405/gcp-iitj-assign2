# Architecture Design

This diagram shows the setup you deploy with Terraform:
- A VPC + subnet
- Firewall rules (SSH restricted, HTTP allowed)
- Instance template → Managed Instance Group (MIG)
- Autoscaler based on average CPU utilization
- IAM binding for restricted admin access

## Diagram (Mermaid)

```mermaid
flowchart TB
  user((Admin User)) -->|IAM: compute.instanceAdmin.v1| gcp["GCP Project"]

  subgraph net["VPC Network"]
    subgraph sub["Subnetwork"]
      mig["Managed Instance Group (MIG)"]
      vm1["VM instance 1"]
      vm2["VM instance 2 (scale out)"]
      vm3["VM instance 3 (scale out)"]
    end
  end

  tpl["Instance Template\n- e2-medium\n- startup script (nginx)"] --> mig
  mig --> vm1
  mig -.-> vm2
  mig -.-> vm3

  autos["Autoscaler\nCPU target: 60%\nmin: 1  max: 3"] --> mig

  internet((Internet)) -->|Firewall: allow tcp/80| mig
  adminpc((Admin IP)) -->|Firewall: allow tcp/22 from allowed_ssh_cidr| mig

  deny["Implicit deny for all other inbound"] -.-> mig
```

If you prefer, you can paste this Mermaid block into the report as well.
