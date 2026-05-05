# 1. O Bucket S3
resource "aws_s3_bucket" "terraform_state_backup" {
  bucket = "${var.s3_bucket_name}-backup"
  force_destroy = true
}

# 2. Ativar versionamento no S3 backup
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state_backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. DynamoDB Table
resource "aws_dynamodb_table" "terraform_locks_demo" {
  name         = "portfolio-tf-locks-demo"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}