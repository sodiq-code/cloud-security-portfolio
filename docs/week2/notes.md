# Week 2 — Logging, Detections & Visibility

## 1. CloudTrail Setup

- S3 bucket created for logs:
  - Name: `afsod-cloudtrail-logs-12345`
  - Region: `eu-east-1`
  - Public access: BLOCKED (all 4 options enabled)

- Trail created:
  - Name: `afsod-security-trail`
  - Scope: Management events (Read + Write), single region only
  - Data events: Disabled (to control cost at this stage)
  - Destination: S3 bucket above

- Verification:
  - Opened Event history and saw events like `StartLogging`, `CreateTrail`, `ConsoleLogin`
  - This proves CloudTrail is recording management activity

- Why this matters for a junior cloud security role:
  - CloudTrail is the main audit log – you use it to investigate “who did what, when, and from where”.
  - Keeping it in a private S3 bucket is critical so attackers can’t delete or read your logs.
  - It is a foundational service for security monitoring and incident response.

  ## 2. Billing Guardrail

- Created a monthly cost budget for: $10 (example)
- Alerts:
  - 50%, 80% and 100%thresholds send an email to me
- Purpose:
  - Ensure CloudTrail/GuardDuty or other tests never silently run up large bills
