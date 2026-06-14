# Infrastructure and DevSecOps

Linux infrastructure, automation, and the security work that goes with it. The
same day-to-day I do for clients, written down properly, with security built in
rather than bolted on.

## What's inside

| Path | Contents |
|---|---|
| [`/terraform`](terraform/) | AWS web-fleet module. SSH locked to your CIDR, IMDSv2 enforced, encrypted volumes, Nginx, scalable instance count. Applied and destroyed on AWS to confirm it works. |
| [`/ansible`](ansible/) | Fleet-wide hardening playbook. Admin user, SSH lockdown, default-deny firewall, fail2ban, automatic security updates. |
| [`/scripts`](scripts/) | Bash tooling. Server health, SSL expiry, SSH bruteforce watch, WordPress maintenance with pre-update backups. |
| [`.github/workflows`](.github/workflows/) | CI that scans the IaC with tfsec and checkov and the scripts with shellcheck on every push. |

## Security posture

Every piece here defaults to the secure option:

- SSH key-only, no root login, scoped to a single `/32` and never `0.0.0.0/0`
- default-deny firewalls, fail2ban, and log-based bruteforce monitoring
- IMDSv2 enforced and encrypted root volumes on every EC2 instance
- least-privilege IAM, automatic security updates, secrets kept out of the repo
- security scanning (tfsec, checkov, shellcheck) wired into CI

## Hosting and control panels

cPanel/WHM, Plesk, OpenLiteSpeed, LiteSpeed Enterprise, Nginx, Apache, across AWS
(Lightsail and EC2), Hetzner, Linode, Contabo, and GCP.
