### The Problem
​Infrastructure "toil" often stems from engineers having to manually intervene when health checks fail on transient cloud resources. In high-scale environments like the AWS EC2 Control Plane, manual remediation doesn't scale.

### ​The Solution
- ​This project implements a self-healing infrastructure pattern using Terraform/OpenTofu. It automates the lifecycle of "unhealthy" resources by:
- ​Integrating native cloud health signals.
- ​Triggering automated replacement/repair logic without human intervention.
- ​Ensuring the infrastructure remains in the "Desired State."

### ​Key Technical Features
​- **Idempotency:** Designed to ensure that healing actions don't create "thundering herd" issues.
- **​Observability:** Dashboard implemented for consolidated viewing of metrics
- ​**Modular Design:** Easily portable to different cloud provider environments.

### ​Impact
​This pattern is a distilled version of the automation logic I used to achieve a 96% efficiency gain in fleet management, moving from manual "babysitting" to an autonomous recovery model.
