# 1. Cria a "Role" (O cargo/função)
resource "aws_iam_role" "ec2_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# 2. Cria a "Policy" (O que esse cargo pode fazer)
resource "aws_iam_role_policy" "ssm_read" {
  name = "ssm-read-permissions"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter", "ssm:GetParameters"]
      Resource = "*" # Em produção, você limitaria ao ARN do seu parâmetro
    }]
  })
}

# 3. Cria o "Profile" (O crachá físico que a EC2 'veste')
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ssm-instance-profile"
  role = aws_iam_role.ec2_role.name
}