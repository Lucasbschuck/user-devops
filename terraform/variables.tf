# Variables para configuração

variable "ssh_allowed_ips" {
  description = "Lista de IPs permitidos para acesso SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  
  validation {
    condition     = length(var.ssh_allowed_ips) > 0
    error_message = "Você deve especificar pelo menos um IP para SSH."
  }
}

variable "s3_bucket_name" {
  description = "Nome único para bucket S3 de Terraform state"
  type        = string
  default     = "user-devops-tf-state-random"
  
  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.s3_bucket_name))
    error_message = "Nome do bucket deve seguir as regras do S3."
  }
}

variable "aws_region" {
  description = "Região AWS para deploy"
  type        = string
  default     = "us-east-1"
}
