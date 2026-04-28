# 1. Gerador de senha aleatória (O Terraform cria, ninguem vê)
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# 2. Guardando os dados com o caminho que o Spring espera
resource "aws_ssm_parameter" "db_password_param" {
  name  = "/devops-portfolio/db/spring.datasource.password" # Nome completo da propriedade
  type  = "SecureString"
  value = random_password.db_password.result
}

resource "aws_ssm_parameter" "db_url_param" {
  name  = "/devops-portfolio/db/spring.datasource.url" # Nome completo da propriedade
  type  = "String"
  # Adicionamos o prefixo JDBC e o nome do banco no final
  value = "jdbc:postgresql://${aws_db_instance.postgres.endpoint}/userdb"
}

resource "aws_ssm_parameter" "db_user_param" {
  name  = "/devops-portfolio/db/spring.datasource.username"
  type  = "String"
  value = "lucas"
}

# 3. O Servidor de Banco de Dados (RDS PostgreSQL)
resource "aws_db_instance" "postgres" {
  identifier             = "user-devops-db"
  engine                 = "postgres"
  engine_version         = "16.3"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20

  # Dados iniciais do banco
  db_name                = "userdb"
  username               = "lucas"
  password               = random_password.db_password.result # Usa a senha gerada acima

  # Conectando com a rede segura que criamos antes
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name # Fica na subnet privada
  vpc_security_group_ids = [aws_security_group.rds_sg.id] # Usa o porteiro que só aceita a EC2

  publicly_accessible    = false # Reforça que não tem IP público
  skip_final_snapshot    = true  # Essencial para testes, permite deletar o banco sem erro

  resource "aws_ssm_parameter" "db_ddl_auto_param" {
    name  = "/devops-portfolio/db/spring.jpa.hibernate.ddl-auto"
    type  = "String"
    value = "update" # Diz para o Hibernate criar as tabelas
  }
}