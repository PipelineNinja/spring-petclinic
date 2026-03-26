output "ec2_public_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.petclinic_server.public_ip
}
