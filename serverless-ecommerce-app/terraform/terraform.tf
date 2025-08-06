terraform {
backend "s3" {
bucket = "statefile0990898"
key = "terraform/terraform.tfstate"
region = "us-east-1"
}
}