# provisions a web fleet in the account default vpc, secure by default:
# a security group with ssh locked to your cidr, the latest ubuntu 22.04 ami,
# N instances with imdsv2 enforced and encrypted root volumes, nginx via
# user-data, and one elastic ip per node.

locals {
  common_tags = merge({ Project = var.name, ManagedBy = "terraform" }, var.tags)
}

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# http and https are intentionally public, this is a web server. ssh is locked to
# a single admin cidr. outbound is open so the host can pull os and security
# updates. these are documented, accepted exceptions, not oversights.
#tfsec:ignore:aws-ec2-no-public-ingress-sgr
#tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group" "web" {
  #checkov:skip=CKV_AWS_260:http/80 is public by design on a web server
  #checkov:skip=CKV_AWS_277:https/443 is public by design on a web server
  #checkov:skip=CKV_AWS_382:outbound is required for os and security updates
  name        = "${var.name}-sg"
  description = "web server: ssh from admin cidr, http/https from anywhere"
  vpc_id      = data.aws_vpc.default.id
  tags        = local.common_tags

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "allow all outbound for os and security updates"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# least-privilege instance role. enables SSM session manager for management,
# so the box is reachable without opening or relying on SSH.
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "web" {
  name               = "${var.name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "web" {
  name = "${var.name}-profile"
  role = aws_iam_role.web.name
}

resource "aws_instance" "web" {
  count                  = var.instance_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.web.name
  monitoring             = true
  ebs_optimized          = true
  tags                   = merge(local.common_tags, { Name = "${var.name}-${count.index + 1}" })

  user_data = <<-EOF
    #!/usr/bin/env bash
    set -e
    apt-get update -y
    apt-get install -y nginx
    systemctl enable --now nginx
    echo "<h1>${var.name}-${count.index + 1} provisioned by Terraform</h1>" > /var/www/html/index.html
  EOF

  metadata_options {
    http_tokens = "required" # enforce IMDSv2
  }
  root_block_device {
    encrypted = true
  }
}

resource "aws_eip" "web" {
  count    = var.instance_count
  instance = aws_instance.web[count.index].id
  domain   = "vpc"
  tags     = merge(local.common_tags, { Name = "${var.name}-${count.index + 1}" })
}
