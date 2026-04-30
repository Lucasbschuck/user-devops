# 1. Gerador de senha aleatória
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "db_password_param" {
  name  = "/devops-portfolio/db/spring.datasource.password"
  type  = "SecureString"
  value = random_password.db_password.result
}

resource "aws_ssm_parameter" "db_url_param" {
  name  = "/devops-portfolio/db/spring.datasource.url"
  type  = "String"
  value = "jdbc:postgresql://${aws_db_instance.postgres.endpoint}/userdb"
}

resource "aws_ssm_parameter" "db_ddl_auto_param" {
  name  = "/devops-portfolio/db/spring.jpa.hibernate.ddl-auto"
  type  = "String"
  value = "update"
}

resource "aws_ssm_parameter" "db_user_param" {
  name  = "/devops-portfolio/db/spring.datasource.username"
  type  = "String"
  value = "lucas"
}

# O Servidor de Banco de Dados (RDS PostgreSQL)
resource "aws_db_instance" "postgres" {
  identifier             = "user-devops-db"
  engine                 = "postgres"
  engine_version         = "16.3"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20

  # Dados iniciais do banco
  db_name                = "userdb"
  username               = "lucas"
  password               = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible    = false
  skip_final_snapshot    = true
}