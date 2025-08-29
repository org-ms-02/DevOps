provider "aws" {
  region = "us-east-1"
}


resource "aws_ecs_cluster" "ecs_cluster" {
  name = "devops-ecs-cluster"
}


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


resource "aws_lambda_function" "user_auth_lambda" {
  function_name = "user-authentication"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 60
  s3_bucket     = "lamdha9098"
  s3_key        = "user-auth.zip"
}


resource "aws_lambda_function" "payment_processing_lambda" {
  function_name = "payment-processing"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 60
  s3_bucket     = "lamdha9098"
  s3_key        = "payment-processing.zip"
}


resource "aws_ecs_task_definition" "app_task" {
  family                   = "devops-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn

  container_definitions = jsonencode([{
    name      = "devops-app"
    image     = var.docker_image_url  
    portMappings = [
      {
        containerPort = 5000  
        hostPort      = 5000  
      }
    ]
  }])
}


resource "aws_ecs_service" "app_service" {
  name            = "devops-app-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids 
    assign_public_ip = true 
    security_groups  = [var.security_group_id]  
  }

  depends_on = [aws_ecs_task_definition.app_task]
}


output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster.name
}


output "ecs_service_name" {
  value = aws_ecs_service.app_service.name
}


output "lambda_user_auth_function" {
  value = aws_lambda_function.user_auth_lambda.function_name
}

output "lambda_payment_processing_function" {
  value = aws_lambda_function.payment_processing_lambda.function_name
}
