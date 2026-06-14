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

resource "aws_security_group" "web" {
  name        = "${var.name}-sg"
  description = "Web server: SSH from admin CIDR, HTTP/HTTPS from anywhere"
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  count                  = var.instance_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web.id]
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
