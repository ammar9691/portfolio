variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "name" {
  description = "Name prefix for tagged resources"
  type        = string
  default     = "web"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Number of identical web nodes to provision"
  type        = number
  default     = 2
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = string
}

variable "ssh_ingress_cidr" {
  description = "CIDR allowed to reach SSH (lock this to your IP, not 0.0.0.0/0)"
  type        = string
}

variable "tags" {
  description = "Extra tags applied to all resources"
  type        = map(string)
  default     = {}
}
