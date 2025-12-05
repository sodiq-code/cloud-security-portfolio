# 🧱 Week 3: Infrastructure as Code (Secure Storage)
**Status:** ✅ Deployed & Verified on LocalStack

## 1. Project Overview
This project demonstrates the transition from manual cloud provisioning to **Infrastructure as Code (IaC)**. I used **Terraform** to define a secure, encrypted storage architecture and deployed it to a local AWS emulator (**LocalStack**) to verify functionality without incurring cloud costs.

**Objective:** Master Terraform core workflows (`init`, `plan`, `apply`) while enforcing security best practices by default.

## 2. Infrastructure Architecture
This module provisions a "Secure-by-Design" S3 bucket. Unlike standard tutorials that launch insecure defaults, this infrastructure includes:

| Resource | Terraform Type | Purpose |
| :--- | :--- | :--- |
| **Log Bucket** | `aws_s3_bucket` | Primary storage container. |
| **Encryption Key** | `aws_kms_key` | Customer Managed Key (CMK) for controlling data access. |
| **Access Block** | `aws_s3_bucket_public_access_block` | Network-level block against public data exposure. |

## 3. Security Implementation
*This code was hardened to pass the Week 4 DevSecOps checks.*

* **Encryption at Rest:**
    * Enabled `aws_s3_bucket_server_side_encryption_configuration`.
    * Enforced `sse_algorithm = "aws:kms"`, ensuring data cannot be read without the specific KMS key.
* **Public Access Prevention:**
    * Applied a "Block Public Access" configuration to strictly reject any public ACLs or bucket policies.
    * Set ACL to `private`.

## 4. LocalStack Configuration
To enable offline development, the AWS Provider is configured to route requests to the local Docker container.

```hcl
provider "aws" {
  # ...
  endpoints {
    s3  = "http://localhost:4566"
    kms = "http://localhost:4566" # Required for encryption resource
  }
}