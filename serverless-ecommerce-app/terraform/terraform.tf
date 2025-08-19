terraform {
backend "s3" {
bucket = "statefile009"
key = "terraform/terraform.tfstate"
region = "us-east-1"
}
}