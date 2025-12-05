#  Cloud Security & DevSecOps Portfolio
**By JIMOH SODIQ BOLAJI **

![Status](https://img.shields.io/badge/Status-Completed-success) ![Focus](https://img.shields.io/badge/Focus-AWS%20%7C%20Terraform%20%7C%20Python-blue) ![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-orange)

##  Executive Summary
This repository documents my 12-week intensive journey building a production-grade **Cloud Security Portfolio**. It demonstrates my ability to architect, secure, automate, and govern cloud infrastructure using **Infrastructure as Code (Terraform)** and **DevSecOps** principles.

Unlike standard tutorials, this portfolio focuses on **"Real-World" implementation**: solving LocalStack compatibility issues, writing Python automation for SOC tasks, and conducting Linux forensics.

---

##  Project Index (The Work)

| Project Phase | Folder Link | Key Technologies | Description |
| :--- | :--- | :--- | :--- |
| **DevSecOps Guardrails** | **[View Security Report](./docs/week4/README.md)** | GitHub Actions, Trivy | **(Shift-Left)** Automated vulnerability scanning pipeline that blocks insecure Terraform commits before deployment. |
| **Project A: Secure Network** | **[View Architecture Report](week6-deploy\README.md)** | VPC, IAM, Subnets | A "Secure-by-Design" segmented network with Public/Private isolation and Least Privilege Identity. |
| **Project A+: High Availability** | **[`week8-ha-deploy`](./week8-ha-deploy)** | ALB, ASG, WAF | **(DevOps Upgrade)** Refactored Project A to support auto-scaling, load balancing, and Layer 7 Web Application Firewall protection. |
| **Observability & Logging** | **[`week6-deploy`](./week6-deploy)** | CloudTrail, S3, KMS | Centralized, encrypted audit logging and automated threat detection (GuardDuty). |
| **Security Automation (SOAR)** | **[`automation`](./automation)** | Python (Boto3) | A custom script that auto-remediates threats by dynamically updating Network ACLs to block malicious IPs. |
| **Digital Forensics** | **[`forensics`](./forensics)** | Linux, Grep, Bash | Simulated a compromised server investigation to identify indicators of compromise (IoCs) from raw logs. |
| **Project B: Enterprise Governance** | **[`governance`](./governance)** | AWS Organizations, SCPs | **(GRC Upgrade)** Implemented multi-account guardrails to enforce region locks and log integrity across an organization. |

---

##  Skills Matrix

| Domain | Skills Demonstrated in Code |
| :--- | :--- |
| **Cloud Infrastructure** | AWS VPC, EC2, S3, IAM, Route Tables, Internet Gateways |
| **Infrastructure as Code** | **Terraform:** Modules, State Management, Provider Pinning (v4.67/v5) |
| **DevSecOps** | **Trivy:** "Shift-Left" scanning in CI/CD pipeline |
| **Security Engineering** | WAF Configuration, KMS Encryption, Security Groups, NACLs |
| **Automation** | **Python (Boto3):** API interaction for remediation |
| **Operations** | **LocalStack:** Docker-based cloud emulation and debugging |

---

##  Key Engineering Challenges Solved
*Engineering is about solving problems, not just writing code. Here are specific technical hurdles I overcame:*

* **Docker-in-Docker Networking:** Resolved LocalStack compute/EC2 failures by configuring socket mounting and privileged mode in `docker-compose.yml`.
* **Provider Compatibility:** Debugged and pinned the AWS Terraform Provider to `v4.67.0` to resolve S3 Control API conflicts in the simulation environment.
* **IAM Policy Logic:** Fixed circular dependency and wildcard risks in IAM policies to enforce true Least Privilege.

---

##  Certifications & Education
* **B.Eng Computer Engineering** (FUTA, 2025)
* **Certified in Cybersecurity (CC)** - *ISC2 (In Progress)*

---
*This portfolio is built with Terraform, AWS, and LocalStack.*