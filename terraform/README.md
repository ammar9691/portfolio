# Terraform: AWS web fleet

A small reusable module that stands up a web fleet in your default VPC, secure by
default rather than secured later:

- Security group with SSH locked to your CIDR (never 0.0.0.0/0), HTTP/HTTPS open
- IMDSv2 enforced on every instance, so the metadata endpoint cannot be abused via SSRF
- Encrypted root volumes
- Latest Ubuntu 22.04 LTS AMI looked up at plan time, not pinned to a stale image
- One Elastic IP per node, Nginx bootstrapped via user-data
- `instance_count` to scale the fleet up or down

## Use it

```bash
cp terraform.tfvars.example terraform.tfvars   # set key_name and your ssh cidr
terraform init
terraform plan
terraform apply
terraform output public_ips
```

Tear down with `terraform destroy`.

## Verified

Applied and destroyed on AWS during development. The instance came up with IMDSv2
required, an encrypted root volume, and Nginx serving HTTP 200, then everything
was destroyed so nothing lingers. SSH was scoped to a single `/32`, not the world.

## Notes

- State is local here for the demo. For real use, configure a remote backend
  (S3 with a DynamoDB lock). `*.tfstate` and `*.tfvars` are gitignored so no state
  or IP detail leaks.
- `ssh_ingress_cidr` is required with no default on purpose, so SSH is never
  accidentally opened to everyone.
- `tfsec` and `checkov` scan this module on every push (see `.github/workflows`).
  The intentional public web access is allowed via documented exceptions.
