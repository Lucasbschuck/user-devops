terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
backend "s3" {
    bucket         = "user-devops-tf-state-public-demo"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "user-devops-tf-locks"
    encrypt        = true
  }

}

provider "aws" {
  region = "us-east-1"
}