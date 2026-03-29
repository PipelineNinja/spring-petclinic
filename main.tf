# Security Group (matches existing AWS SG)
resource "aws_security_group" "petclinic_sg" {
  name        = "petclinic-sg"
  description = "Allow SSH and App access"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App Access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "petclinic-sg"
  }
}

# EC2 Instance running Petclinic
resource "aws_instance" "petclinic_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.petclinic_sg.id]
  subnet_id              = var.subnet_id

  user_data = <<-EOF
#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# Wait for Docker to initialize
sleep 30

# Pull and run container with restart policy
docker pull kishormore123/spring-petclinic:latest
docker run -d --name spring-petclinic -p 8080:8080 --restart unless-stopped kishormore123/spring-petclinic:latest
EOF

  tags = {
    Name = "petclinic-terraform-server"
  }
}
