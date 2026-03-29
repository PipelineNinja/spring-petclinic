variable "ami_id" {
  description = "AMI ID for EC2"
  type        = string
  default     = "ami-02dfbd4ff395f2a1b"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Key pair name"
  type        = string
  default     = "petclinic-key"
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
  default     = "vpc-0a6f17787ba9bee47"
}

variable "subnet_id" {
  description = "Subnet ID where EC2 instance will be launched"
  type        = string
  default     = "subnet-0f85704087b4d0fe1"
}
