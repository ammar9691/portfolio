output "public_ips" {
  description = "Elastic IPs of the web fleet"
  value       = aws_eip.web[*].public_ip
}

output "instance_ids" {
  description = "EC2 instance IDs"
  value       = aws_instance.web[*].id
}

output "ssh" {
  description = "SSH commands, one per node"
  value       = [for ip in aws_eip.web[*].public_ip : "ssh ubuntu@${ip}"]
}
