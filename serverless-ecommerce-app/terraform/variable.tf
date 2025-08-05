
variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}


variable "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}


variable "docker_image_url" {
  description = "URL of the Docker image"
  type        = string
}


variable "subnet_ids" {
  description = "List of subnet IDs for ECS tasks"
  type        = list(string)
}


variable "security_group_id" {
  description = "Security Group ID to attach to the ECS service"
  type        = string
}
