resource "aws_security_group" "ec2_sg" {
  name        = "spring-boot-ec2-sg"
  description = "Permite acesso web a API Spring Boot"
  vpc_id      = aws_vpc.main_vpc.id

  # Regra de Entrada (Inbound): Quem pode entrar?
  ingress {
    description = "Permite trafego HTTP da internet"
    from_port   = 8080 # A porta padrao do Spring Boot
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # "0.0.0.0/0" significa "qualquer IP do mundo"
  }
  ingress {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }


  # Regra de Saida (Outbound): Para onde o servidor pode ir?
  egress {
    description = "Permite toda a saida para a internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # "-1" significa "todos os protocolos"
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

  # Regra de Entrada (Inbound): A magica acontece aqui
  ingress {
    description     = "Permite conexao apenas do Security Group do Spring Boot"
    from_port       = 5432 # Porta do PostgreSQL
    to_port         = 5432
    protocol        = "tcp"

    # Em vez de liberar IPs, nos liberamos a ID do outro Security Group!
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