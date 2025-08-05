# AWS region (default region where ECS cluster and services will be deployed)
variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

# ARN for the ECS Task execution role (IAM role that allows ECS tasks to run)
variable "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

# Docker image URL for the application (this should be the image in your container registry)
variable "docker_image_url" {
  description = "URL of the Docker image"
  type        = string
}

# List of Subnet IDs (make sure these subnets exist in your VPC)
variable "subnet_ids" {
  description = "List of subnet IDs for ECS tasks"
  type        = list(string)
}

# Security Group ID (the security group that controls the ECS task access)
variable "security_group_id" {
  description = "Security Group ID to attach to the ECS service"
  type        = string
}
