resource "aws_security_group" "ec2_sg" {
  name        = "spring-boot-ec2-sg"
  description = "Permite acesso web a API Spring Boot"
  vpc_id      = aws_vpc.main_vpc.id

  # Regra de Entrada (Inbound):
  ingress {
    description = "Permite trafego HTTP da internet"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #
  }
  ingress {
      description = "SSH from your IP only"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_allowed_ips
    }
  ingress {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Prometheus monitoring"
    }


  # Regra de Saida (Outbound):
  egress {
    description = "Permite toda a saida para a internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-security-group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "postgresql-rds-sg"
  description = "Permite acesso ao banco apenas vindo da EC2"
  vpc_id      = aws_vpc.main_vpc.id

  # Regra de Entrada (Inbound):
  ingress {
    description     = "Permite conexao apenas do Security Group do Spring Boot"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"

    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    description = "Permite saida do banco"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-security-group"
  }

}