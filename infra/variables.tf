variable "aws_region" {
  description = "AWS region to launch servers."
  default = "us-east-1"
}

variable "access_key" {}
variable "secret_key" {}

variable "user" {
  default = "ubuntu"
  description = "OS user"
}

variable "key_name" {
  description = "SSH key name in your AWS account for AWS instances"
}

variable "key_path" {
  description = "Path to the private key specified by key_name"
}

variable "nodes" {
  default = "3"
  description = "Number of swarm nodes to launch"
}
