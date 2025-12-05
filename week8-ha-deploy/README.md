#  Project A+: High Availability & Auto-Scaling
**Status:** ✅ Deployed & Verified on LocalStack

## 1. Overview
This project is an architectural upgrade to [Project A](../week6-deploy). While Project A focused on security segmentation, **Project A+** focuses on **Resilience, Scalability, and Layer 7 Defense**.

It transforms a single-server architecture into a **Self-Healing Fleet** using Application Load Balancers (ALB) and Auto Scaling Groups (ASG), protected by a Web Application Firewall (WAF).

## 2. Architecture & Traffic Flow
`Internet` -> **`WAF`** (SQLi Block) -> **`ALB`** (Traffic Dist.) -> **`Security Group`** (Port 80) -> **`EC2 Instances`** (Private)

## 3. Key Features Implemented
| Component | Function | Why it matters (DevOps) |
| :--- | :--- | :--- |
| **Application Load Balancer** | Distributes traffic | Removes the "Single Point of Failure" of a single server. |
| **Auto Scaling Group** | `min=2`, `max=3` | **Self-Healing:** If a server crashes, ASG replaces it instantly. |
| **Web Application Firewall** | AWS Managed Rules | **AppSec:** Blocks SQL Injection and XSS attacks at the edge. |
| **Dynamic AMI** | Launch Template | Defines the "Blueprint" for all new servers (Hardened config). |

## 4. Engineering Challenges (Solved)
* **Provider Conflict:** Pinned AWS Provider to `v4.67.0` to resolve a compatibility bug between Terraform `v5.x` and LocalStack's S3 API.
* **Lab Constraints:** Configured `.trivyignore` to accept HTTP (Port 80) and Open Egress risks specifically for the local simulation environment.


## 5. Artifacts
* **Infrastructure Code:** [main.tf](./main.tf)
* **Scaling Evidence:**
  *(Screenshot verifying Auto Scaling Group capacity of 2 instances)*
  ![High Availability Success](../docs/week8/screenshots/ha-success.png)

## 6. Deployment Verification
To deploy this stack locally:
```bash
terraform init
terraform apply --auto-approve