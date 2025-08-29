terraform {
backend "s3" {
bucket = "terraformstate9090"
key = "terraform/terraform.tfstate"
region = "us-east-1"
}
}