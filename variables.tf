variable "region" {
  description = "AWS region to host the network"
  default     = "us-east-1"
}

variable "vpc" {
  description = "AWS VPC name"
  default = "ci"
}

variable "availability-zones" {
  description = "The availability-zones to create"
  default = "us-east-1a"
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  default     = "10.128.0.0/16"
}

variable "ami" {
  description = "Base AMI to launch the instances for containers"
  #https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html
  default = "ami-40286957"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 8080
}
