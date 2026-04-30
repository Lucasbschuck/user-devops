# 1. O Balde (S3) para guardar o arquivo
resource "aws_s3_bucket" "terraform_state" {
  # O nome do bucket precisa ser globalmente único em toda a AWS
  # Troque "lucas-devops" por algo único se der erro
  bucket = "lucas-devops-portfolio-tf-state"
  force_destroy = true
}

# 2. Ativar versionamento no S3 (Máquina do tempo)
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. O Cadeado (DynamoDB Table)
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "portfolio-tf-locks"
  billing_mode = "PAY_PER_REQUEST" # Só paga quando usa (Free Tier)
  hash_key     = "LockID" # O Terraform exige que a chave principal tenha esse nome exato

  attribute {
    name = "LockID"
    type = "S"
  }
}