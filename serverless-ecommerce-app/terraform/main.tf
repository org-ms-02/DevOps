provider "aws" {
  region = "us-east-1"
}

# Create ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "devops-ecs-cluster"
}

# Create IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# Create Lambda Function for user-authentication
resource "aws_lambda_function" "user_auth_lambda" {
  function_name = "user-authentication"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 60
  s3_bucket     = "your-lambda-code-s3-bucket"
  s3_key        = "user-auth.zip"
}

# Create Lambda Function for payment-processing
resource "aws_lambda_function" "payment_processing_lambda" {
  function_name = "payment-processing"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 60
  s3_bucket     = "your-lambda-code-s3-bucket"
  s3_key        = "payment-processing.zip"
}

# ECS Task Definition for the App
resource "aws_ecs_task_definition" "app_task" {
  family                   = "devops-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn

  container_definitions = jsonencode([{
    name      = "devops-app"
    image     = var.docker_image_url  # Docker image URL from JFrog
    portMappings = [
      {
        containerPort = 5000  # The port on which the app runs inside the container
        hostPort      = 5000  # The port mapping on the host
      }
    ]
  }])
}

# ECS Service for the App
resource "aws_ecs_service" "app_service" {
  name            = "devops-app-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids  # The IDs of the subnets
    assign_public_ip = true  # Ensures the service has a public IP
    security_groups  = [var.security_group_id]  # The Security Group for ECS task
  }

  depends_on = [aws_ecs_task_definition.app_task]
}

# Output ECS Cluster Name
output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster.name
}

# Output ECS Service Name
output "ecs_service_name" {
  value = aws_ecs_service.app_service.name
}

# Output Lambda Function Names
output "lambda_user_auth_function" {
  value = aws_lambda_function.user_auth_lambda.function_name
}

output "lambda_payment_processing_function" {
  value = aws_lambda_function.payment_processing_lambda.function_name
}
