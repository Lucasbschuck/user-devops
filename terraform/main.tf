terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
backend "s3" {
    bucket         = "lucas-devops-portfolio-tf-state" # O mesmo nome que você colocou no state.tf
    key            = "global/s3/terraform.tfstate"     # O caminho da pasta lá dentro do balde
    region         = "us-east-1"
    dynamodb_table = "portfolio-tf-locks"              # O nome da tabela do cadeado
    encrypt        = true
  }

}

provider "aws" {
  region = "us-east-1"
}