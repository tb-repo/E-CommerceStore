variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 Instance type"
  type        = string
  default     = "t3.small" # 2GB RAM is ideal for 5 containers
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "tb-ecommerce-app"
}