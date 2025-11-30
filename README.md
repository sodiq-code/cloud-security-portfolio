# 🛡️ PROJECT A: HARDENED WEB APPLICATION (SECURE BASELINE)

## 1. Executive Summary
This project implements an Enterprise-Ready Architecture cloud environment using **Infrastructure as Code (Terraform)**. It demonstrates a "Security First" architecture designed to protect sensitive workloads against network intrusion, unauthorized access, and data exfiltration.

**Core Capabilities:**
* **Network Segmentation:** Isolated Public/Private subnets to reduce attack surface.
* **Identity Management:** Least-Privilege IAM Roles replacing static access keys.
* **DevSecOps:** Automated CI/CD guardrails (Trivy) preventing insecure deployments.
* **Observability:** Centralized audit logging (CloudTrail) and automated threat detection (GuardDuty).

## 2. Architecture
![Project A Final Architecture](docs/week7/architecture_diagram_final.png)

**Design Decisions:**
* **VPC Isolation:** Custom VPC with strict route tables ensures the private subnet has zero direct internet exposure.
* **Immutable Infrastructure:** All resources are provisioned via Terraform modules, ensuring consistency and eliminating configuration drift.

## 3. Security Implementation Details

### A. Infrastructure Security (Network & IAM)
* **Zero Trust Identity:** EC2 instances utilize IAM Roles with scoped permissions.
    * *Policy:* `s3:GetObject` restricted strictly to the Logging Bucket (ARN).
    * *Benefit:* Eliminates credential theft risk; limits blast radius.
* **Traffic Control:** Security Groups function as a stateful firewall, strictly allow-listing HTTP (Port 80) traffic only.

### B. DevSecOps & Automation
* **Shift-Left Security:** Integrated `Aqua Security Trivy` into the GitHub Actions pipeline.
    * *Mechanism:* The build automatically fails if High/Critical vulnerabilities (e.g., Public S3 buckets, unencrypted volumes) are detected.
    * *Result:* 100% of deployed code complies with security standards before reaching production.

### C. Observability & Compliance
* **Audit Trail:** CloudTrail enabled globally to track all API activity.
* **Secure Storage:** Logs are shipped to a dedicated S3 bucket with:
    * Server-Side Encryption (AES-256).
    * Public Access Block (BPA) enabled.
* **Threat Detection:** GuardDuty active for intelligent threat hunting.

## 4. Technical Artifacts
| Component | Source Code | Status |
| :--- | :--- | :--- |
| **Network Module** | [`vpc`](./modules/vpc) | ✅ Ready |
| **Security Module** | [`security`](./modules/security) | ✅ Production Ready |
| **Identity Module** | [`iam`](./modules/iam) | ✅ Production Ready |
| **Deployment Video** | https://www.loom.com/share/3974d3689f974e0eaccf47e1763adacf | 🚀 Live Demo |

---
*Built with Terraform, AWS, and LocalStack.*