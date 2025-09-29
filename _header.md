# Load Balancing Tier

This module simulates one that would be created by the SRE/Infrastructure team for this architecture.
In this module, we will use Terraform to create two load balancers, each with a public IP and a health probe for port 80.

Although this is a simple architecture, we aim to simulate real-time IT team workflows and collaboration following best practices.

- In the testing environment, I opened port 22 on the external load balancer.
- In the production environment, I commented out that block and instead added a BASTION host for secure access.